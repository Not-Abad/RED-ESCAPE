
extends Area2D

@export var speed: float = 250.0
@export var max_distance: float = 800.0

var direction: Vector2 = Vector2.ZERO
var start_position: Vector2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	start_position = global_position

	animated_sprite.play("proyectil")

	# Detectar impactos
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:

	# Mover el proyectil
	global_position += direction * speed * delta

	# Eliminarlo si supera la distancia máxima
	if global_position.distance_to(start_position) >= max_distance:
		queue_free()


func _on_area_entered(area: Area2D) -> void:

	# Eliminar al tocar el área de daño del jugador
	if area.is_in_group("player") or area.is_in_group("player_hurtbox"):
		queue_free()


func _on_body_entered(body: Node2D) -> void:

	# Eliminar al tocar el cuerpo del jugador
	if body.is_in_group("player"):
		queue_free()
