# dungeon_builder.gd
extends Node2D

@export var tilemap_layer: TileMapLayer
@export var bsp_generator: Node

@export_group("Entidades")
@export var player_scene: PackedScene = preload("res://scenes/character.tscn")
@export var weapon_scene: PackedScene

@export_group("Enemigos")
## Escenas de enemigos que podrán aparecer (se elegirá una al azar por cada spawn)
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://modules/enemies/enemies_plantong/enemies_plantong.tscn")
]
@export var min_enemies_per_room: int = 5
@export var max_enemies_per_room: int = 8
## Si está activo, la sala de Spawn del jugador no generará enemigos
@export var ignore_spawn_room: bool = true

@export var source_id: int = 0

@export_group("Suelos")
@export var base_floor_tile := Vector2i(0, 0)
@export var variation_floor_tiles: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 0), 
	Vector2i(2, 1), Vector2i(3, 0), Vector2i(3, 1), Vector2i(4, 0), 
	Vector2i(4, 1), Vector2i(5, 0), Vector2i(5, 1)
]
@export_range(0.0, 1.0) var floor_variation_chance: float = 0.55
@export_range(0.0, 1.0) var variation_chance: float = 0.55

@export_group("Muros Norte (Fachada y Techo Superior)")
@export var base_wall_front_tile := Vector2i(0, 2)            ## Fachada del muro norte
@export var wall_top_tile := Vector2i(0, 2)                    ## Alias de fachada norte
@export var variation_wall_front_tiles: Array[Vector2i] = [
	Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3)
]
@export_range(0.0, 1.0) var wall_variation_chance: float = 0.25
@export var wall_roof_top_outline := Vector2i(2, 5)            ## Contorno SUPERIOR / Loza horizontal

@export_group("Muro Sur (Contorno Inferior)")
@export var wall_bottom_tile := Vector2i(2, 4)                ## Contorno INFERIOR horizontal

@export_group("Muros Laterales")
@export var wall_left_tile := Vector2i(0, 4)                  ## Contorno vertical izquierdo
@export var wall_side_left := Vector2i(0, 4)                  ## Alias
@export var wall_right_tile := Vector2i(0, 5)                 ## Contorno vertical derecho

@export_group("Las 4 Esquinas en L")
@export var wall_corner_top_left := Vector2i(7, 7)             ## Remate superior izquierdo
@export var wall_corner_top_right := Vector2i(7, 7)            ## Remate superior derecho
@export var wall_corner_down_left := Vector2i(3, 4)           ## Esquina inferior izquierda
@export var wall_corner_bottom_left := Vector2i(0, 4)          ## Alias
@export var wall_corner_down_right := Vector2i(4, 4)          ## Esquina inferior derecha
@export var wall_corner_bottom_right := Vector2i(7, 1)        ## Alias

@export_group("Obstáculos y Pasillos")
@export var pillar_tile := Vector2i(12, 1)
@export var hallway_tile := Vector2i(0, 0)

var current_player: CharacterBody2D
var active_room_triggers: Array[Area2D] = []

func _ready() -> void:
	if not tilemap_layer:
		tilemap_layer = get_node_or_null("TileMapLayer") as TileMapLayer

	if not bsp_generator:
		bsp_generator = get_node_or_null("BSPGenerator")
		if not bsp_generator and ResourceLoader.exists("res://modules/map/bsp/bsp_generator.gd"):
			var bsp_script = load("res://modules/map/bsp/bsp_generator.gd")
			bsp_generator = Node.new()
			bsp_generator.set_script(bsp_script)
			add_child(bsp_generator)

	if not tilemap_layer:
		push_error("DungeonBuilder: Debes asignar un nodo 'TileMapLayer' en el Inspector.")
		return

	if bsp_generator and bsp_generator.has_method("generate_dungeon"):
		var dungeon_info = bsp_generator.generate_dungeon()
		if dungeon_info:
			render_dungeon(dungeon_info)
			spawn_player_in_last_room(dungeon_info)
			spawn_weapon_in_last_room(dungeon_info)
			_setup_room_triggers(dungeon_info)

func render_dungeon(info: RefCounted) -> void:
	if not tilemap_layer:
		tilemap_layer = get_node_or_null("TileMapLayer") as TileMapLayer
		if not tilemap_layer:
			return

	tilemap_layer.clear()
	_clear_room_triggers()

	var room_floors: Dictionary = {}
	var hallway_floors: Dictionary = {}
	var all_floors: Dictionary = {}

	# 1. Registrar suelos transitables
	for room in info.rooms:
		for pos in room.floor_positions:
			room_floors[pos] = true
			all_floors[pos] = true

	for hall in info.hallways:
		for x in range(hall.position.x, hall.end.x):
			for y in range(hall.position.y, hall.end.y):
				var pos = Vector2i(x, y)
				hallway_floors[pos] = true
				all_floors[pos] = true

	# --- PINTAR SUELOS ---
	var active_chance = floor_variation_chance if floor_variation_chance != 0.55 else variation_chance
	for pos in room_floors.keys():
		var tile_to_place = base_floor_tile
		if not variation_floor_tiles.is_empty() and randf() < active_chance:
			tile_to_place = variation_floor_tiles.pick_random()
		tilemap_layer.set_cell(pos, source_id, tile_to_place)

	for pos in hallway_floors.keys():
		tilemap_layer.set_cell(pos, source_id, hallway_tile)

	# 2. CONSTRUIR Y EVALUAR LA TOPOLOGÍA DEL PERÍMETRO
	_build_and_render_perimeters(all_floors)

	# --- PINTAR PILARES ---
	for room in info.rooms:
		if "obstacle_positions" in room:
			for pos in room.obstacle_positions:
				tilemap_layer.set_cell(pos, source_id, pillar_tile)

## Configura las áreas activadoras de detección por cada sala del mapa
func _setup_room_triggers(info: RefCounted) -> void:
	if enemy_scenes.is_empty():
		push_warning("DungeonBuilder: No hay 'enemy_scenes' asignadas para instanciar enemigos.")
		return

	var last_room = info.rooms.back() if not info.rooms.is_empty() else null

	for room in info.rooms:
		# Omitir la sala de Spawn inicial
		if ignore_spawn_room:
			if "room_type" in room and room.room_type == BSPRoom.RoomType.SPAWN:
				continue
			if room == last_room:
				continue

		if room.floor_positions.is_empty():
			continue

		_create_trigger_for_room(room)

## Crea un Area2D adaptado al tamaño de la sala
func _create_trigger_for_room(room: BSPRoom) -> void:
	var area_trigger := Area2D.new()
	area_trigger.name = "RoomTrigger_" + str(room.bounds.position)

	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()

	# Calcular dimensiones del suelo interior en píxeles locales
	var tile_size := Vector2(tilemap_layer.tile_set.tile_size) if tilemap_layer.tile_set else Vector2(16, 16)
	var room_inner_size_tiles := Vector2(room.bounds.size - Vector2i(2, 2))
	var size_in_pixels := room_inner_size_tiles * tile_size * tilemap_layer.scale

	rect_shape.size = size_in_pixels
	shape.shape = rect_shape

	# Posicionar el área en el centro de la habitación
	var center_tile := room.get_center() if room.has_method("get_center") else (room.bounds.position + room.bounds.size / 2)
	var local_center := tilemap_layer.map_to_local(center_tile)
	area_trigger.position = local_center

	area_trigger.add_child(shape)
	tilemap_layer.add_child(area_trigger)
	active_room_triggers.append(area_trigger)

	# Escuchar cuándo entra el jugador
	area_trigger.body_entered.connect(_on_room_entered.bind(room, area_trigger))

func _on_room_entered(body: Node2D, room: BSPRoom, trigger_area: Area2D) -> void:
	if body.is_in_group("player"):
		# Desactivar monitoreo diferido para evitar ejecuciones dobles
		trigger_area.set_deferred("monitoring", false)
		
		# Generar enemigos fuera del paso de física (flushing queries)
		call_deferred("_spawn_enemies_in_room", room)
		
		# Eliminar el activador de la lista y del árbol de nodos
		active_room_triggers.erase(trigger_area)
		trigger_area.queue_free()

## Instancia entre min_enemies_per_room y max_enemies_per_room en celdas de suelo aleatorias
func _spawn_enemies_in_room(room: BSPRoom) -> void:
	var available_tiles: Array[Vector2i] = room.floor_positions.duplicate()
	if available_tiles.is_empty():
		return

	available_tiles.shuffle()
	var spawn_count := randi_range(min_enemies_per_room, max_enemies_per_room)
	spawn_count = mini(spawn_count, available_tiles.size())

	for i in range(spawn_count):
		var selected_scene: PackedScene = enemy_scenes.pick_random()
		if selected_scene == null:
			continue

		var enemy_instance = selected_scene.instantiate() as Node2D
		if enemy_instance == null:
			continue

		var tile_pos: Vector2i = available_tiles[i]
		var spawn_pos: Vector2 = tilemap_layer.map_to_local(tile_pos)

		enemy_instance.global_position = tilemap_layer.to_global(spawn_pos)
		
		get_tree().current_scene.add_child(enemy_instance)

func _clear_room_triggers() -> void:
	for area in active_room_triggers:
		if is_instance_valid(area):
			area.queue_free()
	active_room_triggers.clear()

## Evalúa la intersección entre salas, pasillos y bordes perimetrales para asignar assets sin crear azulejos flotantes
func _build_and_render_perimeters(all_floors: Dictionary) -> void:
	# A) Detectar Fachadas Norte (Celdas no transitables con suelo directamente abajo)
	var facades: Dictionary = {}
	for f in all_floors.keys():
		var north_cell = f + Vector2i(0, -1)
		if not all_floors.has(north_cell):
			facades[north_cell] = true

	# B) Detectar Lozas de Techo Plana (1 celda directamente arriba de cada Fachada Norte)
	var roof_flats: Dictionary = {}
	for f_pos in facades.keys():
		var roof_cell = f_pos + Vector2i(0, -1)
		if not all_floors.has(roof_cell):
			roof_flats[roof_cell] = true

	# C) Evaluar remates de esquina en L para el techo en intersecciones o extremos de pared
	var roof_corners_tl: Dictionary = {}
	var roof_corners_tr: Dictionary = {}

	for f_pos in facades.keys():
		# Remate Izquierdo: Si no hay fachada ni suelo a la izquierda del tramo
		var left_facade = facades.has(f_pos + Vector2i(-1, 0))
		var left_floor = all_floors.has(f_pos + Vector2i(-1, 0))
		if not left_facade and not left_floor:
			var tl_corner = f_pos + Vector2i(-1, -1)
			if not all_floors.has(tl_corner) and not facades.has(tl_corner):
				roof_corners_tl[tl_corner] = true

		# Remate Derecho: Si no hay fachada ni suelo a la derecha del tramo
		var right_facade = facades.has(f_pos + Vector2i(1, 0))
		var right_floor = all_floors.has(f_pos + Vector2i(1, 0))
		if not right_facade and not right_floor:
			var tr_corner = f_pos + Vector2i(1, -1)
			if not all_floors.has(tr_corner) and not facades.has(tr_corner):
				roof_corners_tr[tr_corner] = true

	# D) Detectar Muros Sur (Celdas con suelo arriba)
	var south_walls: Dictionary = {}
	for f in all_floors.keys():
		var south_cell = f + Vector2i(0, 1)
		if not all_floors.has(south_cell) and not facades.has(south_cell) and not roof_flats.has(south_cell):
			south_walls[south_cell] = true

	# E) Detectar Muros Laterales Izquierdos y Derechos
	var left_walls: Dictionary = {}
	var right_walls: Dictionary = {}

	for f in all_floors.keys():
		var w_cell = f + Vector2i(-1, 0)
		if not all_floors.has(w_cell) and not facades.has(w_cell) and not roof_flats.has(w_cell) and not roof_corners_tl.has(w_cell) and not roof_corners_tr.has(w_cell):
			left_walls[w_cell] = true

		var e_cell = f + Vector2i(1, 0)
		if not all_floors.has(e_cell) and not facades.has(e_cell) and not roof_flats.has(e_cell) and not roof_corners_tl.has(e_cell) and not roof_corners_tr.has(e_cell):
			right_walls[e_cell] = true

	# Empalmar los bordes verticales para que suban hasta tocar el techo
	for f_pos in facades.keys():
		var left_edge = f_pos + Vector2i(-1, 0)
		if not all_floors.has(left_edge) and not facades.has(left_edge):
			left_walls[left_edge] = true

		var right_edge = f_pos + Vector2i(1, 0)
		if not all_floors.has(right_edge) and not facades.has(right_edge):
			right_walls[right_edge] = true

	# --- PINTAR CADA ELEMENTO EN EL TILEMAP ---

	# 1. Fachadas Norte de ladrillo
	for pos in facades.keys():
		var front_tile = base_wall_front_tile
		if not variation_wall_front_tiles.is_empty() and randf() < wall_variation_chance:
			front_tile = variation_wall_front_tiles.pick_random()
		tilemap_layer.set_cell(pos, source_id, front_tile)

	# 2. Lozas de techo horizontales planas
	for pos in roof_flats.keys():
		tilemap_layer.set_cell(pos, source_id, wall_roof_top_outline)

	# 3. Esquinas Top-Left en L (Remate de techo con pared izquierda)
	for pos in roof_corners_tl.keys():
		tilemap_layer.set_cell(pos, source_id, wall_corner_top_left)

	# 4. Esquinas Top-Right en L (Remate de techo con pared derecha)
	for pos in roof_corners_tr.keys():
		tilemap_layer.set_cell(pos, source_id, wall_corner_top_right)

	# 5. Muros Sur y Esquinas Inferiores en L
	for pos in south_walls.keys():
		var has_left_sw = south_walls.has(pos + Vector2i(-1, 0))
		var has_right_sw = south_walls.has(pos + Vector2i(1, 0))

		if not has_left_sw and has_right_sw:
			tilemap_layer.set_cell(pos, source_id, wall_corner_down_left)
		elif has_left_sw and not has_right_sw:
			tilemap_layer.set_cell(pos, source_id, wall_corner_down_right)
		else:
			tilemap_layer.set_cell(pos, source_id, wall_bottom_tile)

	# 6. Muros Laterales Izquierdos y Derechos
	for pos in left_walls.keys():
		if not facades.has(pos) and not roof_flats.has(pos) and not roof_corners_tl.has(pos) and not south_walls.has(pos):
			tilemap_layer.set_cell(pos, source_id, wall_left_tile)

	for pos in right_walls.keys():
		if not facades.has(pos) and not roof_flats.has(pos) and not roof_corners_tr.has(pos) and not south_walls.has(pos):
			tilemap_layer.set_cell(pos, source_id, wall_right_tile)

func spawn_player_in_last_room(info: RefCounted) -> void:
	if not player_scene or info.rooms.is_empty():
		return

	var old_players = get_tree().get_nodes_in_group("player")
	for p in old_players:
		p.queue_free()

	var last_room = info.rooms.back()
	var center_tile: Vector2i = Vector2i.ZERO

	if last_room.has_method("get_center"):
		center_tile = last_room.get_center()
	elif "floor_positions" in last_room and not last_room.floor_positions.is_empty():
		center_tile = last_room.floor_positions[last_room.floor_positions.size() / 2]

	current_player = player_scene.instantiate() as CharacterBody2D
	if current_player == null:
		return

	current_player.add_to_group("player")
	tilemap_layer.add_child(current_player)
	current_player.position = tilemap_layer.map_to_local(center_tile)
	current_player.z_index = 10

## Instancia el arma en el suelo de la sala inicial del jugador
func spawn_weapon_in_last_room(info: RefCounted) -> void:
	if weapon_scene == null:
		print("❌ ATENCIÓN: 'weapon_scene' está NULL en el Inspector del DungeonBuilder.")
		return

	if info.rooms.is_empty():
		print("❌ ATENCIÓN: La lista de habitaciones del mapa está vacía.")
		return

	var last_room = info.rooms.back()
	var center_tile: Vector2i = Vector2i.ZERO

	if last_room.has_method("get_center"):
		center_tile = last_room.get_center()
	elif "floor_positions" in last_room and not last_room.floor_positions.is_empty():
		center_tile = last_room.floor_positions[last_room.floor_positions.size() / 2]

	var weapon_instance = weapon_scene.instantiate() as Node2D
	if weapon_instance == null:
		print("❌ ATENCIÓN: No se pudo instanciar la escena del arma.")
		return

	# Añadir directamente al TileMapLayer para heredar su escala y coordenadas
	tilemap_layer.add_child(weapon_instance)
	
	# Colocar el arma 2 baldosas a la derecha del centro de la sala
	var weapon_tile: Vector2i = center_tile + Vector2i(2, 0)
	weapon_instance.position = tilemap_layer.map_to_local(weapon_tile)
	weapon_instance.z_index = 10  # Dibuja el arma por encima de las baldosas de suelo

	print("✅ Arma aparecida en posición: ", weapon_instance.position)
