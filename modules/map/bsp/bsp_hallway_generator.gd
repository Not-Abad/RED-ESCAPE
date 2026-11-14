class_name BSPHallwayGenerator extends RefCounted

var corridor_width: int = 1
var extra_loop_count: int = 2

func _init(_corridor_width: int = 1, _extra_loop_count: int = 2) -> void:
	corridor_width = _corridor_width
	extra_loop_count = _extra_loop_count

func generate_hallways(root: BSPRoomNode, all_rooms: Array[Rect2i]) -> Array[Rect2i]:
	var connected_pairs: Array[Vector2i] = []
	var room_doors: Dictionary = {}
	
	var hallways = _create_bsp_hallways(root, all_rooms, connected_pairs, room_doors)
	_add_extra_loop_connections(hallways, all_rooms, connected_pairs, room_doors)
	
	return hallways

func _create_bsp_hallways(
	node: BSPRoomNode, 
	all_rooms: Array[Rect2i], 
	connected_pairs: Array[Vector2i], 
	room_doors: Dictionary
) -> Array[Rect2i]:
	var hallways: Array[Rect2i] = []
	if node.is_leaf():
		return hallways
		
	hallways.append_array(_create_bsp_hallways(node.left, all_rooms, connected_pairs, room_doors))
	hallways.append_array(_create_bsp_hallways(node.right, all_rooms, connected_pairs, room_doors))
	
	var leaves_a = node.left.get_leaves()
	var leaves_b = node.right.get_leaves()
	
	var candidates: Array[Dictionary] = []
	for la in leaves_a:
		var idx_a = all_rooms.find(la.room)
		var ca = Vector2(la.room.position) + Vector2(la.room.size) / 2.0
		for lb in leaves_b:
			var idx_b = all_rooms.find(lb.room)
			var cb = Vector2(lb.room.position) + Vector2(lb.room.size) / 2.0
			candidates.append({
				"idx_a": idx_a,
				"idx_b": idx_b,
				"dist": ca.distance_squared_to(cb)
			})
			
	candidates.sort_custom(func(a, b): return a["dist"] < b["dist"])
	
	for cand in candidates:
		var connection = _try_connect_rooms(cand["idx_a"], cand["idx_b"], all_rooms, connected_pairs, room_doors)
		if not connection.is_empty():
			hallways.append_array(connection)
			break
			
	return hallways

func _try_connect_rooms(
	idx_a: int, 
	idx_b: int, 
	all_rooms: Array[Rect2i], 
	connected_pairs: Array[Vector2i], 
	room_doors: Dictionary
) -> Array[Rect2i]:
	var pair_key = Vector2i(mini(idx_a, idx_b), maxi(idx_a, idx_b))
	if pair_key in connected_pairs:
		return []
		
	var room_a = all_rooms[idx_a]
	var room_b = all_rooms[idx_b]
	
	var doors_a = _get_valid_door_candidates(room_a, idx_a, room_doors)
	var doors_b = _get_valid_door_candidates(room_b, idx_b, room_doors)
	
	if doors_a.is_empty() or doors_b.is_empty():
		return []
		
	var best_path: Array[Vector2i] = []
	var min_path_len := 999999
	var best_door_a := Vector2i.ZERO
	var best_door_b := Vector2i.ZERO
	
	for da in doors_a:
		for db in doors_b:
			var candidate_paths: Array[Array] = []
			
			if da.x == db.x or da.y == db.y:
				candidate_paths.append(_generate_line_pts(da, db))
			else:
				var corner1 = Vector2i(db.x, da.y)
				var path1 = _generate_line_pts(da, corner1)
				var seg1_2 = _generate_line_pts(corner1, db)
				path1.append_array(seg1_2.slice(1))
				candidate_paths.append(path1)
				
				var corner2 = Vector2i(da.x, db.y)
				var path2 = _generate_line_pts(da, corner2)
				var seg2_2 = _generate_line_pts(corner2, db)
				path2.append_array(seg2_2.slice(1))
				candidate_paths.append(path2)
				
			for path in candidate_paths:
				if path.size() < min_path_len and _is_path_strictly_valid(path, idx_a, idx_b, all_rooms):
					min_path_len = path.size()
					best_path = path
					best_door_a = da
					best_door_b = db
					
	if not best_path.is_empty():
		connected_pairs.append(pair_key)
		
		if not room_doors.has(idx_a):
			room_doors[idx_a] = []
		room_doors[idx_a].append(best_door_a)
		
		if not room_doors.has(idx_b):
			room_doors[idx_b] = []
		room_doors[idx_b].append(best_door_b)
		
		# Extender el camino para perforar los muros de las dos salas
		var full_path: Array[Vector2i] = []
		full_path.append(_get_wall_tile_for_door(best_door_a, room_a))
		full_path.append_array(best_path)
		full_path.append(_get_wall_tile_for_door(best_door_b, room_b))
		
		return _points_to_corridors(full_path)
		
	return []

## Retorna la casilla de pared exacta que corresponde a una puerta exterior
func _get_wall_tile_for_door(door: Vector2i, room: Rect2i) -> Vector2i:
	if door.y == room.position.y - 1:
		return Vector2i(door.x, room.position.y)
	elif door.y == room.end.y:
		return Vector2i(door.x, room.end.y - 1)
	elif door.x == room.position.x - 1:
		return Vector2i(room.position.x, door.y)
	elif door.x == room.end.x:
		return Vector2i(room.end.x - 1, door.y)
	return door

func _get_valid_door_candidates(room: Rect2i, room_idx: int, room_doors: Dictionary) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var existing_doors: Array = room_doors.get(room_idx, [])
	
	var min_x = room.position.x + 1
	var max_x = room.end.x - 2
	var min_y = room.position.y + 1
	var max_y = room.end.y - 2
	
	if min_x > max_x or min_y > max_y:
		return []
		
	for x in range(min_x, max_x + 1):
		var pt_top = Vector2i(x, room.position.y - 1)
		if _is_door_valid(pt_top, existing_doors):
			candidates.append(pt_top)
		var pt_bot = Vector2i(x, room.end.y)
		if _is_door_valid(pt_bot, existing_doors):
			candidates.append(pt_bot)
			
	for y in range(min_y, max_y + 1):
		var pt_left = Vector2i(room.position.x - 1, y)
		if _is_door_valid(pt_left, existing_doors):
			candidates.append(pt_left)
		var pt_right = Vector2i(room.end.x, y)
		if _is_door_valid(pt_right, existing_doors):
			candidates.append(pt_right)
			
	return candidates

func _is_door_valid(door_pt: Vector2i, existing_doors: Array) -> bool:
	for existing in existing_doors:
		if maxi(abs(door_pt.x - existing.x), abs(door_pt.y - existing.y)) < 2:
			return false
	return true

func _generate_line_pts(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var line: Array[Vector2i] = []
	var sx = 1 if b.x >= a.x else -1
	var sy = 1 if b.y >= a.y else -1
	if a.y == b.y:
		for x in range(a.x, b.x + sx, sx):
			line.append(Vector2i(x, a.y))
	elif a.x == b.x:
		for y in range(a.y, b.y + sy, sy):
			line.append(Vector2i(a.x, y))
	return line

func _is_path_strictly_valid(path: Array[Vector2i], idx_a: int, idx_b: int, all_rooms: Array[Rect2i]) -> bool:
	if path.is_empty():
		return false
		
	var door_a = path[0]
	var door_b = path[-1]
	
	for pt in path:
		for r_idx in range(all_rooms.size()):
			var room = all_rooms[r_idx]
			var room_margin = room.grow(1)
			
			if r_idx == idx_a:
				if pt != door_a and room_margin.has_point(pt):
					return false
			elif r_idx == idx_b:
				if pt != door_b and room_margin.has_point(pt):
					return false
			else:
				if room_margin.has_point(pt):
					return false
					
	return true

func _points_to_corridors(pts: Array[Vector2i]) -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	if pts.is_empty():
		return rects
		
	var start_pt = pts[0]
	var prev_pt = pts[0]
	
	for i in range(1, pts.size()):
		var curr = pts[i]
		var is_adjacent = (abs(curr.x - prev_pt.x) + abs(curr.y - prev_pt.y)) == 1
		var same_direction = (curr.x == prev_pt.x and prev_pt.x == start_pt.x) or (curr.y == prev_pt.y and prev_pt.y == start_pt.y)
		
		if is_adjacent and same_direction:
			prev_pt = curr
		else:
			rects.append(_make_rect_from_points(start_pt, prev_pt))
			start_pt = curr
			prev_pt = curr
			
	rects.append(_make_rect_from_points(start_pt, prev_pt))
	return rects

func _make_rect_from_points(p1: Vector2i, p2: Vector2i) -> Rect2i:
	var min_x = mini(p1.x, p2.x)
	var max_x = maxi(p1.x, p2.x)
	var min_y = mini(p1.y, p2.y)
	var max_y = maxi(p1.y, p2.y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _add_extra_loop_connections(
	hallways: Array[Rect2i], 
	all_rooms: Array[Rect2i], 
	connected_pairs: Array[Vector2i], 
	room_doors: Dictionary
) -> void:
	if all_rooms.size() < 3:
		return
		
	var added = 0
	var max_dist_sq = 25.0 * 25.0
	
	var room_indices = range(all_rooms.size())
	room_indices.shuffle()
	
	for i in room_indices:
		if added >= extra_loop_count:
			break
		var room_a = all_rooms[i]
		var center_a = Vector2(room_a.position + room_a.size / 2)
		
		for j in room_indices:
			if i == j or added >= extra_loop_count:
				continue
			var room_b = all_rooms[j]
			var center_b = Vector2(room_b.position + room_b.size / 2)
			
			var dist_sq = center_a.distance_squared_to(center_b)
			if dist_sq < max_dist_sq:
				var new_corridors = _try_connect_rooms(i, j, all_rooms, connected_pairs, room_doors)
				if not new_corridors.is_empty():
					hallways.append_array(new_corridors)
					added += 1
