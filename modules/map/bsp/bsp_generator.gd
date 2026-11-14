class_name BSPGenerator extends Node

@export_group("Configuración del Mapa")
@export var map_size: Vector2i = Vector2i(60, 50)
@export var min_rooms: int = 7
@export var max_rooms: int = 12
@export var min_room_size: Vector2i = Vector2i(8, 8)
@export_range(1, 4) var corridor_width: int = 2
@export var extra_loop_count: int = 2

@export_group("Sala de Spawn Externa")
@export var enable_custom_spawn: bool = true
@export var spawn_room_size: Vector2i = Vector2i(12, 10)
@export var spawn_margin_x: int = 6 ## Separación a la derecha del mapa principal

var partitioner: BSPPartitioner
var shaper: BSPRoomShaper
var hallway_generator: BSPHallwayGenerator
var spawn_handler: BSPSpawnRoomHandler

func _init() -> void:
	partitioner = BSPPartitioner.new()
	shaper = BSPRoomShaper.new()
	spawn_handler = BSPSpawnRoomHandler.new()

func generate_dungeon() -> BSPDungeonInfo:
	var info := BSPDungeonInfo.new()
	hallway_generator = BSPHallwayGenerator.new(corridor_width, extra_loop_count)

	var current_max_rooms = randi_range(min_rooms, max_rooms)

	# FASE 1: Árbol BSP dentro del área (0,0) a map_size
	var root_area := Rect2i(Vector2i.ZERO, map_size)
	info.root = BSPRoomNode.new(root_area)
	var leaves = partitioner.partition(info.root, current_max_rooms, min_room_size)

	# FASE 2: Esculpir salas rectangulares simples
	info.rooms = shaper.process_rooms(leaves, min_room_size)

	# FASE 3: Pasillos principales entre salas del árbol
	var all_rects = info.get_room_rects()
	info.hallways = hallway_generator.generate_hallways(info.root, all_rects)

	# FASE 4: Crear sala de Spawn EXTERNA en la Esquina Superior Derecha
	if enable_custom_spawn:
		# Posición calculada en código: X pasa el borde derecho del mapa
		var spawn_pos := Vector2i(map_size.x + spawn_margin_x, 0)
		var spawn_room := spawn_handler.create_spawn_room(spawn_pos, spawn_room_size)

		info.rooms.append(spawn_room)
		all_rects.append(spawn_room.bounds)

		# FASE 5: Trazar pasillo desde la sala Spawn a la sala más cercana del mapa
		_connect_spawn_to_nearest_room(spawn_room, info, all_rects)

	return info

func _connect_spawn_to_nearest_room(spawn_room: BSPRoom, info: BSPDungeonInfo, all_rects: Array[Rect2i]) -> void:
	var spawn_idx = all_rects.find(spawn_room.bounds)
	if spawn_idx == -1:
		return

	var spawn_center = Vector2(spawn_room.bounds.position + spawn_room.bounds.size / 2)
	var closest_idx := -1
	var min_dist := 999999.0

	for i in range(all_rects.size()):
		if i == spawn_idx:
			continue
		var room_center = Vector2(all_rects[i].position + all_rects[i].size / 2)
		var dist = spawn_center.distance_squared_to(room_center)
		if dist < min_dist:
			min_dist = dist
			closest_idx = i

	if closest_idx != -1:
		var connected_pairs: Array[Vector2i] = []
		var room_doors: Dictionary = {}
		var connection = hallway_generator._try_connect_rooms(
			spawn_idx, closest_idx, all_rects, connected_pairs, room_doors
		)
		if not connection.is_empty():
			info.hallways.append_array(connection)
