extends Area2D

## Se emite cuando la bala golpea algo. Quien la dispara (el arma) la escucha.
signal impacto(cuerpo: Node2D, dano: int)

## Velocidad de la bala en píxeles por segundo.
@export var velocidad: float = 600.0
## Segundos antes de que la bala desaparezca sola si no choca con nada.
@export var vida_segundos: float = 3.0
## Color de la bala (negro por defecto). Se puede cambiar en el Inspector.
@export var color: Color = Color.DARK_GOLDENROD
## Largo de la bala en píxeles (de la base a la punta).
@export var largo: float = 20.0
## Ancho de la bala en píxeles.
@export var ancho: float = 8.0

## Efecto que aparece al chocar. Si lo dejas vacío se carga res://scenes/impact.tscn
@export var escena_impacto: PackedScene

## Hacia dónde viaja. Quien la dispara la asigna antes de añadirla a la escena.
var direccion: Vector2 = Vector2.RIGHT

## Daño que hace al golpear. Lo asigna el arma al dispararla.
var dano: int = 1

func _ready() -> void:
	rotation = direccion.angle()
	# La zona de colisión es un rectángulo del mismo tamaño que el dibujo
	var forma: RectangleShape2D = RectangleShape2D.new()
	forma.size = Vector2(largo, ancho)
	$CollisionShape2D.shape = forma

	body_entered.connect(_on_body_entered)
	get_tree().create_timer(vida_segundos).timeout.connect(queue_free)
	if escena_impacto == null and ResourceLoader.exists("res://scenes/impact.tscn"):
		escena_impacto = load("res://scenes/impact.tscn")

# Movimiento lineal: avanza siempre en línea recta en la misma dirección
func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta

# Dibujo temporal con forma de bala: cuerpo recto y punta redondeada hacia donde viaja.
# Cuando tengas el sprite de la bala, puedes borrar esta función y añadir un Sprite2D.
func _draw() -> void:
	var mitad_ancho: float = ancho / 2.0
	var x_trasera: float = -largo / 2.0
	var x_punta: float = largo / 2.0
	var largo_punta: float = minf(ancho, largo)   # cuánto mide la parte redondeada
	var x_curva: float = x_punta - largo_punta     # dónde empieza la curva

	var puntos: PackedVector2Array = PackedVector2Array([Vector2(x_trasera, -mitad_ancho)])
	var pasos: int = 6
	for i in range(pasos + 1):
		var ang: float = -PI / 2.0 + PI * float(i) / float(pasos)
		puntos.append(Vector2(x_curva + cos(ang) * largo_punta, sin(ang) * mitad_ancho))
	puntos.append(Vector2(x_trasera, mitad_ancho))
	draw_colored_polygon(puntos, color)


func _on_body_entered(body: Node2D) -> void:
	# Ignora al propio jugador: su cuerpo está en la misma capa que los arbustos
	# y, cuando el arma apunta sobre el cuerpo, la bala nace dentro de él.
	if body.name == "Character":
		return

	# Avisa a quien esté escuchando (el arma, un marcador de puntos, sonidos...)
	impacto.emit(body, dano)
	# Si el objeto golpeado sabe recibir daño, se lo aplica
	if body.has_method("recibir_dano"):
		body.recibir_dano(dano)

	_crear_impacto()
	queue_free()

# Crea el efecto de impacto en el punto donde chocó la bala
func _crear_impacto() -> void:
	if escena_impacto == null:
		return
	var efecto = escena_impacto.instantiate()
	efecto.direccion = direccion
	efecto.position = global_position
	get_tree().current_scene.add_child.call_deferred(efecto)
