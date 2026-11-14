extends CharacterBody2D

@export var speed: float = 100.0
@export var health: int = 2  # Sistema de salud (2 impactos)

var player: Node2D = null
var is_attacking: bool = false
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $Timer # Controla el cooldown y duración del golpe

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null and has_node("/root/main/Character"):
		player = get_node("/root/main/Character")

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		velocity = Vector2.ZERO
		return

	# Si está atacando, congelamos movimiento hasta que el timer termine
	if is_attacking:
		velocity = Vector2.ZERO
		if attack_timer.is_stopped():
			is_attacking = false # Terminó el ataque
		move_and_slide()
		return

	var distance: float = global_position.distance_to(player.global_position)

	# Si alcanza la distancia de ataque al jugador
	if distance < 38.0:
		velocity = Vector2.ZERO
		if attack_timer.is_stopped():
			trigger_attack()
		else:
			if animation_player.current_animation != "idle_front":
				animation_player.play("idle_front")
		move_and_slide()
		return

	# Persecución normal con animaciones direccionales
	var direction: Vector2 = global_position.direction_to(player.global_position)
	velocity = direction * speed

	var anim: String = "walk_front"
	if abs(direction.y) > abs(direction.x):
		if direction.y < 0:
			anim = "walk_back"
		else:
			anim = "walk_front"
	else:
		sprite.flip_h = direction.x < 0
		anim = "walk_front_side"

	if animation_player.current_animation != anim:
		animation_player.play(anim)

	move_and_slide()

# Disparo del ataque en función de la posición del jugador
func trigger_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	
	var attack_anim: String = "attack_front"
	if player != null:
		var attack_dir: Vector2 = global_position.direction_to(player.global_position)
		if abs(attack_dir.y) > abs(attack_dir.x):
			if attack_dir.y < 0:
				attack_anim = "attack_back"
			else:
				attack_anim = "_attack_front"
		else:
			sprite.flip_h = attack_dir.x < 0
			attack_anim = "_attack_front_side"

	if animation_player.has_animation(attack_anim):
		animation_player.play(attack_anim)
	elif animation_player.has_animation("attack_front"):
		animation_player.play("attack_front")
	
	attack_timer.start(0.6)

# Recepción de daño desde la Hurtbox o Bala
func take_damage(damage: int) -> void:
	if is_dead:
		return

	health -= damage
	print("Enemigo dañado. Vida restante: ", health)

	if health <= 0:
		die()
	else:
		if animation_player.has_animation("hurt"):
			animation_player.play("hurt")

# Gestión del estado de muerte y liberación de memoria
func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	
	# Desactivar colisiones para evitar interacciones post-mortem
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)

	if animation_player.has_animation("die"):
		animation_player.play("die")
		await animation_player.animation_finished
	
	queue_free()

# Manejadores de señal opcionales
func _on_attack_range_body_entered(_body: Node2D) -> void:
	pass

func _on_attack_range_body_exited(_body: Node2D) -> void:
	pass
