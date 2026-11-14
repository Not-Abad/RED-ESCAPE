extends Node2D

## Se emite cada vez que una bala de esta arma golpea algo.
signal dano_infligido(objetivo: Node, cantidad: int)

## Posición de la mano derecha del personaje, relativa al Character (está escalado x3).
## Al apuntar a la izquierda el arma pasa a la mano izquierda (X espejada).
@export var hand_offset: Vector2 = Vector2(4, 5)
## Ajuste extra del arma respecto a la mano (normalmente 0,0).
@export var grip_offset: Vector2 = Vector2.ZERO
## Activalo si el dibujo del arma tiene el cañón hacia la IZQUIERDA (así el cañón sale hacia afuera).
@export var invertir_arma: bool = true
## Punto del dibujo que se agarra (el mango), como fracción de la parte visible de la imagen
## (0,0 = esquina superior izquierda, 1,1 = inferior derecha). Medido sobre la imagen original:
## con el cañón a la izquierda, el mango queda a la derecha, por ejemplo (0.8, 0.6).
@export var grip_ratio: Vector2 = Vector2(0.8, 0.6)

@export_group("Disparo")
## Escena de la bala. Si la dejas vacía se carga res://scenes/bullet.tscn
@export var escena_bala: PackedScene
## Segundos entre disparo y disparo.
@export var cadencia: float = 0.25
## Daño que hace cada bala.
@export var dano: int = 1
## Mueve el punto por donde sale la bala (en unidades del arma) si no coincide con la punta del cañón.
@export var punta_ajuste: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D2
@onready var pickup_area: Area2D = $Area2D

var jugador_cerca: bool = false
var jugador: CharacterBody2D = null
var equipada: bool = false
var _detras: bool = false
var _mira_izq: bool = false
var _enfriamiento: float = 0.0
var _punta_local: Vector2 = Vector2(30, 0)
var _escala_base: Vector2 = Vector2.ONE

func _ready() -> void:
	_escala_base = sprite.scale

	# En el suelo, el nodo queda justo donde se ve el dibujo.
	position += sprite.position
	sprite.position = Vector2.ZERO
	if pickup_area.has_node("CollisionShape2D"):
		pickup_area.get_node("CollisionShape2D").position = Vector2.ZERO

	# Conexiones seguras por código
	if not pickup_area.body_entered.is_connected(_on_area_2d_body_entered):
		pickup_area.body_entered.connect(_on_area_2d_body_entered)
	if not pickup_area.body_exited.is_connected(_on_area_2d_body_exited):
		pickup_area.body_exited.connect(_on_area_2d_body_exited)

	if escena_bala == null and ResourceLoader.exists("res://scenes/bullet.tscn"):
		escena_bala = load("res://scenes/bullet.tscn")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if equipada:
		return
	if body.name == "Character":
		jugador_cerca = true
		jugador = body as CharacterBody2D

func _on_area_2d_body_exited(body: Node2D) -> void:
	if equipada:
		return
	if body == jugador:
		jugador_cerca = false
		jugador = null

func _process(delta: float) -> void:
	if not equipada:
		return
	_apuntar()
	_enfriamiento = maxf(_enfriamiento - delta, 0.0)
	if _quiere_disparar() and _enfriamiento <= 0.0:
		_disparar()

# Recoger con la tecla E: evento discreto (evita recogida múltiple continua por frame)
func _unhandled_input(event: InputEvent) -> void:
	if equipada or not jugador_cerca:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		recoger_arma()

func recoger_arma() -> void:
	
	scale = Vector2(1.0 / 3.0, 1.0 / 3.0)
	
	if jugador == null:
		return

	# Control de frame para no recoger 2 armas al mismo tiempo
	var frame: int = Engine.get_process_frames()
	if jugador.has_meta("recogida_frame") and jugador.get_meta("recogida_frame") == frame:
		return
	jugador.set_meta("recogida_frame", frame)

	# Si ya llevaba otra arma equipada, la suelta
	for otra in get_tree().get_nodes_in_group("arma_equipada"):
		if otra != self and otra.has_method("soltar"):
			otra.soltar()

	equipada = true
	add_to_group("arma_equipada")

	pickup_area.set_deferred("monitoring", false)
	pickup_area.set_deferred("monitorable", false)

	reparent(jugador, false)
	position = hand_offset
	rotation = 0.0
	scale = Vector2(1.0 / 3.0, 1.0 / 3.0) # Compensa la escala del personaje

	sprite.position = grip_offset
	sprite.rotation = 0.0
	_alinear_sprite()

# Regresa el arma al suelo y reactiva el detector
func soltar() -> void:
	if not equipada:
		return
	equipada = false
	remove_from_group("arma_equipada")
	_detras = false
	jugador_cerca = false
	jugador = null

	var pos: Vector2 = global_position
	reparent(get_tree().current_scene, false)
	position = pos
	rotation = 0.0
	scale = Vector2.ONE

	sprite.position = Vector2.ZERO
	sprite.offset = Vector2.ZERO
	sprite.rotation = 0.0
	sprite.scale = _escala_base
	pickup_area.set_deferred("monitoring", true)
	pickup_area.set_deferred("monitorable", true)

func _alinear_sprite() -> void:
	var tex: Texture2D = sprite.texture
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null:
		return
	var usado: Rect2i = img.get_used_rect()
	if usado.size == Vector2i.ZERO:
		return
	var centro_tex: Vector2 = Vector2(tex.get_size()) / 2.0
	var agarre: Vector2 = Vector2(usado.position) + Vector2(usado.size) * grip_ratio
	sprite.centered = true
	sprite.offset = centro_tex - agarre

	var fraccion_canon: float = grip_ratio.x if invertir_arma else 1.0 - grip_ratio.x
	var esc: Vector2 = _escala_base.abs()
	_punta_local = Vector2(
		usado.size.x * fraccion_canon * esc.x,
		(0.3 - grip_ratio.y) * usado.size.y * esc.y
	)

func _apuntar() -> void:
	var dir: Vector2 = jugador.ultima_direccion_mira

	# Zona muerta (-0.15 a 0.15) para evitar cambio constante de mano al apuntar verticalmente
	if dir.x < -0.15:
		_mira_izq = true
	elif dir.x > 0.15:
		_mira_izq = false
	var mira_izq: bool = _mira_izq

	rotation = dir.angle()

	sprite.scale = Vector2(
		_escala_base.x * (-1.0 if invertir_arma else 1.0),
		_escala_base.y * (-1.0 if mira_izq else 1.0)
	)
	sprite.position = Vector2(grip_offset.x, -grip_offset.y if mira_izq else grip_offset.y)
	position = Vector2(-hand_offset.x if mira_izq else hand_offset.x, hand_offset.y)

	# Orden de dibujo (delante o detrás del cuerpo) según orientación del sprite
	var orientacion: String = jugador.ultima_orientacion
	var detras: bool = orientacion == "back" or orientacion == "back_side"
	if detras != _detras:
		_detras = detras
		var cuerpo: Node = jugador.get_node("Sprite2D")
		var nuevo_indice: int = cuerpo.get_index() if detras else jugador.get_child_count() - 1
		jugador.move_child(self, nuevo_indice)

func _quiere_disparar() -> bool:
	if InputMap.has_action("shoot") and Input.is_action_pressed("shoot"):
		return true
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.5

func _disparar() -> void:
	if escena_bala == null:
		push_warning("No se encontró la escena de la bala: revisa que bullet.tscn esté en res://scenes/")
		return
	_enfriamiento = cadencia

	var punta: Vector2 = _punta_local + punta_ajuste
	if _mira_izq:
		punta.y = -punta.y

	var bala = escena_bala.instantiate()
	bala.direccion = Vector2.from_angle(global_rotation)
	if "dano" in bala:
		bala.dano = dano
	if bala.has_signal("impacto"):
		bala.impacto.connect(_on_bala_impacto)
	get_tree().current_scene.add_child(bala)
	bala.global_position = to_global(punta)

func _on_bala_impacto(cuerpo: Node, cantidad: int) -> void:
	dano_infligido.emit(cuerpo, cantidad)
