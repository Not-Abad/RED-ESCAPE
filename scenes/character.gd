extends CharacterBody2D

const SPEED: float = 300.0
const ROLL_SPEED: float = 520.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var ultima_orientacion: String = "front"
var ultima_direccion_mira: Vector2 = Vector2.DOWN
var usando_mando: bool = false

# Control del Dodge Roll
var is_rolling: bool = false
var is_invulnerable: bool = false
var roll_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	# Si ya conectaste la señal desde el editor visual, comenta o borra esta línea:
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		usando_mando = false

func _physics_process(_delta: float) -> void:
	# 1. Bloqueo de físicas mientras rueda
	if is_rolling:
		velocity = roll_direction * ROLL_SPEED
		move_and_slide()
		return

	# 2. Movimiento normal
	var input_vector: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED
	move_and_slide()
	
	# 3. Dirección de mira
	var aim_dir: Vector2 = obtener_direccion_mira()
	
	# 4. Input de esquiva
	if Input.is_action_just_pressed("dodge"):
		iniciar_dodge_roll(input_vector, aim_dir)
		return

	# 5. Animaciones estándar de caminado/quieto
	gestionar_animaciones(input_vector, aim_dir)

func iniciar_dodge_roll(input_vector: Vector2, aim_dir: Vector2) -> void:
	is_rolling = true
	is_invulnerable = true
	
	# Si hay movimiento se rueda hacia él; si no, hacia donde apunta la mira
	if input_vector != Vector2.ZERO:
		roll_direction = input_vector.normalized()
	else:
		roll_direction = aim_dir.normalized()

	# Flip horizontal según la dirección del roll
	if roll_direction.x < 0:
		sprite.flip_h = true
	elif roll_direction.x > 0:
		sprite.flip_h = false

	# Determina la orientación del roll en base a hacia dónde rueda
	var y: float = roll_direction.y
	var orientacion_roll: String = "front"

	if y < -0.75:
		orientacion_roll = "back"
	elif y > 0.75:
		orientacion_roll = "front"
	elif y < -0.2:
		orientacion_roll = "back_side"
	else:
		orientacion_roll = "front_side"

	# OJO: Si en tu AnimationPlayer escribiste "fornt" con la 'r' antes de la 'n',
	# cambia "front" por "fornt" aquí abajo para que no marque error:
	if orientacion_roll == "front":
		# anim.play("dodgeRoll_fornt") # Descomenta si tiene la errata en el editor
		anim.play("dodgeRoll_front")
	else:
		anim.play("dodgeRoll_" + orientacion_roll)

func _on_animation_finished(anim_name: StringName) -> void:
	# Se apaga la invulnerabilidad cuando termina cualquier variante de dodgeRoll
	if anim_name.begins_with("dodgeRoll_"):
		is_rolling = false
		is_invulnerable = false

func recibir_dano(cantidad: int) -> void:
	if is_invulnerable:
		return
	print("Daño recibido: ", cantidad)

func obtener_direccion_mira() -> Vector2:
	var stick_aim: Vector2 = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", 0.2)
	
	if stick_aim != Vector2.ZERO:
		usando_mando = true
		ultima_direccion_mira = stick_aim.normalized()
	elif not usando_mando:
		var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
		if mouse_dir != Vector2.ZERO:
			ultima_direccion_mira = mouse_dir
			
	return ultima_direccion_mira

func gestionar_animaciones(mov_dir: Vector2, aim_dir: Vector2) -> void:
	if aim_dir.x < 0:
		sprite.flip_h = true
	elif aim_dir.x > 0:
		sprite.flip_h = false

	var y: float = aim_dir.y

	if y < -0.75:
		ultima_orientacion = "back"
	elif y > 0.75:
		ultima_orientacion = "front"
	elif y < -0.2:
		ultima_orientacion = "back_side"
	else:
		ultima_orientacion = "front_side"

	var estado: String = "walk_" if mov_dir != Vector2.ZERO else "idle_"
	anim.play(estado + ultima_orientacion)
