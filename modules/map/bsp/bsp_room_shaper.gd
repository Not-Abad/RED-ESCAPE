class_name BSPRoomShaper extends RefCounted

## Convierte las hojas del árbol en salas rectangulares simples
func process_rooms(leaves: Array[BSPRoomNode], min_room_size: Vector2i) -> Array[BSPRoom]:
	var created_rooms: Array[BSPRoom] = []

	for leaf in leaves:
		# 1. Reducir el tamaño de la sala dentro de la hoja (Shrink)
		var area = leaf.area
		var max_w = area.size.x - 2
		var max_h = area.size.y - 2
		var room_w = randi_range(min_room_size.x, max_w)
		var room_h = randi_range(min_room_size.y, max_h)
		var offset_x = randi_range(1, area.size.x - room_w - 1)
		var offset_y = randi_range(1, area.size.y - room_h - 1)
		leaf.room = Rect2i(area.position + Vector2i(offset_x, offset_y), Vector2i(room_w, room_h))

		# 2. Instanciar BSPRoom rectangular
		var room_obj := BSPRoom.new(leaf.room, BSPRoom.RoomType.DEFAULT)
		room_obj.shape_type = BSPRoom.ShapeType.RECTANGLE

		# 3. Geometría: Perímetro = Muro, Centro = Suelo
		_build_rectangular_geometry(room_obj)
		created_rooms.append(room_obj)

	return created_rooms

func _build_rectangular_geometry(room: BSPRoom) -> void:
	var bounds = room.bounds
	var w = bounds.size.x
	var h = bounds.size.y

	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var rx = x - bounds.position.x
			var ry = y - bounds.position.y
			var pos = Vector2i(x, y)

			if rx == 0 or rx == w - 1 or ry == 0 or ry == h - 1:
				room.wall_positions.append(pos)
			else:
				room.floor_positions.append(pos)
