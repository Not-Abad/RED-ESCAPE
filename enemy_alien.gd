extends CharacterBody2D

@export var speed = 100.0

var player = null

@onready var sprite = $AnimatedSprite2D


func _ready():
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta):

	if player == null:
		return

	var direction = global_position.direction_to(player.global_position)

	velocity = direction * speed

	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	if sprite.animation != "walk":
		sprite.play("walk")

	move_and_slide()
