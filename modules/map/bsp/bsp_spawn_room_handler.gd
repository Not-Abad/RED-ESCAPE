class_name BSPSpawnRoomHandler extends RefCounted

func create_spawn_room(spawn_position: Vector2i, spawn_size: Vector2i) -> BSPRoom:
	var bounds := Rect2i(spawn_position, spawn_size)
	var spawn_room := BSPRoom.new(bounds, BSPRoom.RoomType.SPAWN)
	spawn_room.shape_type = BSPRoom.ShapeType.RECTANGLE

	var w = bounds.size.x
	var h = bounds.size.y

	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var rx = x - bounds.position.x
			var ry = y - bounds.position.y
			var pos = Vector2i(x, y)

			if rx == 0 or rx == w - 1 or ry == 0 or ry == h - 1:
				spawn_room.wall_positions.append(pos)
			else:
				spawn_room.floor_positions.append(pos)

	return spawn_room
