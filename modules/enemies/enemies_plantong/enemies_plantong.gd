extends CharacterBody2D


# ==========================================
# CONFIGURACIÓN
# ==========================================

@export var speed: float = 100.0
@export var health: int = 3 # 3 puntos de vida (3 balas para morir)

# Peso de generación de Plantong
const SPAWN_WEIGHT: int = 1
@export var spawn_weight: int = SPAWN_WEIGHT

# Consultar el peso sin instanciar Plantong
static func get_spawn_weight() -> int:
	return SPAWN_WEIGHT

# Avisar a la habitación cuando Plantong muera
signal enemy_died(enemy_ref, weight)


# ==========================================
# VARIABLES
# ==========================================

var player: Node2D = null

var player_in_range: bool = false
var is_attacking: bool = false
var is_taking_damage: bool = false
var is_dead: bool = false

var primer_disparo_realizado: bool = false
var segundo_disparo_realizado: bool = false


# ==========================================
# REFERENCIAS A LOS NODOS
# ==========================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var attack_range: Area2D = $AttackRange
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var hurt_box: Area2D = $HurtBox

@onready var punto_izquierdo: Marker2D = $PuntoDisparoIzquierdo
@onready var punto_derecho: Marker2D = $PuntoDisparoDerecho


# ==========================================
# ESCENA DEL PROYECTIL
# ==========================================

const PROYECTIL_ESCENA = preload(
	"res://modules/enemies/enemies_plantong/proyectil_plantong.tscn"
)


# ==========================================
# INICIALIZACIÓN
# ==========================================

func _ready() -> void:

	# Buscar al jugador mediante su grupo
	player = get_tree().get_first_node_in_group("player") as Node2D

	# Conectar detección del rango de ataque
	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)

	# Conectar temporizador
	attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)

	# Conectar animaciones
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_attack_frame_changed)

	# Conectar detección de impactos por áreas
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	hurt_box.body_entered.connect(_on_hurt_box_body_entered)

	# Reproducir animación inicial
	animated_sprite.play("idle")


# ==========================================
# MOVIMIENTO Y SEGUIMIENTO DEL JUGADOR
# ==========================================

func _physics_process(_delta: float) -> void:

	# No moverse durante ataque, daño o muerte
	if is_dead or is_attacking or is_taking_damage:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Buscar al jugador si todavía no se encontró
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	# Si no existe un jugador, permanecer quieto
	if player == null:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
		move_and_slide()
		return

	# Si el jugador está dentro del rango, atacar
	if player_in_range:
		velocity = Vector2.ZERO
		iniciar_ataque()
		move_and_slide()
		return

	# Calcular dirección hacia el jugador
	var direction: Vector2 = global_position.direction_to(
		player.global_position
	)

	# Aplicar velocidad
	velocity = direction * speed

	# Elegir animación según la dirección horizontal
	if abs(direction.x) > 0.01:
		if direction.x < 0:
			animated_sprite.play("left_walk")
		else:
			animated_sprite.play("right_walk")
	else:
		animated_sprite.play("idle")

	move_and_slide()


# ==========================================
# DETECCIÓN DEL RANGO DE ATAQUE
# ==========================================

func _on_attack_range_body_entered(body: Node2D) -> void:

	if body.is_in_group("player"):
		player = body
		player_in_range = true
		iniciar_ataque()


func _on_attack_range_body_exited(body: Node2D) -> void:

	if body == player:
		player_in_range = false


# ==========================================
# EJECUCIÓN DEL ATAQUE
# ==========================================

func iniciar_ataque() -> void:

	if is_dead or is_attacking or is_taking_damage:
		return

	if not player_in_range:
		return

	# Evitar ataques mientras el temporizador esté activo
	if not attack_cooldown.is_stopped():
		return

	is_attacking = true
	velocity = Vector2.ZERO

	# Reiniciar control de disparos
	primer_disparo_realizado = false
	segundo_disparo_realizado = false

	# Reproducir animación de ataque
	animated_sprite.play("attack")


# Detectar los cuadros de la animación de ataque
func _on_attack_frame_changed() -> void:

	if animated_sprite.animation != "attack":
		return

	# Segundo cuadro: disparo del tentáculo izquierdo
	if animated_sprite.frame == 1 and not primer_disparo_realizado:
		disparar_proyectil(punto_izquierdo)
		primer_disparo_realizado = true

	# Tercer cuadro: disparo del tentáculo derecho
	elif animated_sprite.frame == 2 and not segundo_disparo_realizado:
		disparar_proyectil(punto_derecho)
		segundo_disparo_realizado = true


# Crear y disparar un proyectil
func disparar_proyectil(punto: Marker2D) -> void:

	if not is_instance_valid(player):
		return

	var proyectil = PROYECTIL_ESCENA.instantiate()

	# Agregar el proyectil a la escena actual
	get_tree().current_scene.add_child(proyectil)

	# Colocar el proyectil en la punta del tentáculo
	proyectil.global_position = punto.global_position

	# Calcular dirección hacia el jugador
	proyectil.direction = punto.global_position.direction_to(
		player.global_position
	)


# ==========================================
# TEMPORIZADOR DE ATAQUE
# ==========================================

func _on_attack_cooldown_timeout() -> void:

	if player_in_range:
		iniciar_ataque()


# ==========================================
# RECEPCIÓN DE DAÑO
# ==========================================

## Método llamado directamente por las balas (bullet.gd) al colisionar
func recibir_dano(dano_recibido: int) -> void:
	take_damage(dano_recibido)


func _on_hurt_box_area_entered(area: Area2D) -> void:

	if _es_ataque_del_jugador(area):
		take_damage(1)


func _on_hurt_box_body_entered(body: Node2D) -> void:

	if _es_ataque_del_jugador(body):
		take_damage(1)


# Identificar si el objeto que tocó a Plantong
# pertenece a un ataque o proyectil del jugador
func _es_ataque_del_jugador(objeto: Node) -> bool:

	return (
		objeto.is_in_group("player_attack")
		or objeto.is_in_group("player_projectile")
		or objeto.is_in_group("player_bullet")
	)


func take_damage(damage: int) -> void:

	if is_dead or is_taking_damage:
		return

	if damage <= 0:
		return

	# Restar vida
	health -= damage

	# Comprobar si Plantong murió
	if health <= 0:
		morir()

	else:
		# Reproducir animación de daño
		is_taking_damage = true
		velocity = Vector2.ZERO

		animated_sprite.play("damage")


# ==========================================
# MUERTE DEL ENEMIGO
# ==========================================

func morir() -> void:

	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_taking_damage = false
	player_in_range = false

	velocity = Vector2.ZERO

	# Detener temporizador
	attack_cooldown.stop()

	# Desactivar detección de ataque y daño con set_deferred para evitar errores de física
	attack_range.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitoring", false)

	# Desactivar colisión física
	$CollisionShape2D.set_deferred("disabled", true)

	# Desactivar colisión de HurtBox
	if hurt_box.has_node("CollisionShape2D"):
		hurt_box.get_node("CollisionShape2D").set_deferred("disabled", true)

	# Reproducir animación de muerte
	animated_sprite.play("die")


# ==========================================
# FINALIZACIÓN DE ANIMACIONES
# ==========================================

func _on_animation_finished() -> void:

	# Cuando termina el ataque
	if animated_sprite.animation == "attack":

		is_attacking = false

		# Iniciar tiempo de espera entre ataques
		attack_cooldown.start()

	# Cuando termina la animación de daño
	elif animated_sprite.animation == "damage":

		is_taking_damage = false

	# Cuando termina la animación de muerte
	elif animated_sprite.animation == "die":

		# Avisar a la habitación que el enemigo murió
		enemy_died.emit(self, spawn_weight)

		# Eliminar Plantong de la escena
		queue_free()
