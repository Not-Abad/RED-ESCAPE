class_name BSPPartitioner extends RefCounted

## Subdivide el nodo raíz recursivamente en un árbol BSP hasta alcanzar max_rooms o min_room_size
func partition(root: BSPRoomNode, max_rooms: int, min_room_size: Vector2i) -> Array[BSPRoomNode]:
	var leaves: Array[BSPRoomNode] = [root]
	
	while leaves.size() < max_rooms:
		var node_to_split: BSPRoomNode = _get_largest_leaf(leaves, min_room_size)
		if node_to_split == null:
			break
			
		if _split_node(node_to_split, min_room_size):
			leaves.erase(node_to_split)
			leaves.append(node_to_split.left)
			leaves.append(node_to_split.right)
			
	return leaves

func _get_largest_leaf(leaves: Array[BSPRoomNode], min_room_size: Vector2i) -> BSPRoomNode:
	var candidate: BSPRoomNode = null
	var max_area := 0
	for leaf in leaves:
		var area_size = leaf.area.size.x * leaf.area.size.y
		if area_size > max_area and _can_split(leaf, min_room_size):
			max_area = area_size
			candidate = leaf
	return candidate

func _can_split(node: BSPRoomNode, min_room_size: Vector2i) -> bool:
	var can_v = node.area.size.x >= (min_room_size.x * 2 + 2)
	var can_h = node.area.size.y >= (min_room_size.y * 2 + 2)
	return can_v or can_h

func _split_node(node: BSPRoomNode, min_room_size: Vector2i) -> bool:
	var area = node.area
	var can_split_v = area.size.x >= (min_room_size.x * 2 + 2)
	var can_split_h = area.size.y >= (min_room_size.y * 2 + 2)
	
	if not can_split_v and not can_split_h:
		return false
		
	var split_v := false
	if can_split_v and can_split_h:
		split_v = area.size.x > area.size.y if area.size.x != area.size.y else (randi() % 2 == 0)
	elif can_split_v:
		split_v = true
		
	if split_v:
		var split_x = randi_range(min_room_size.x + 1, area.size.x - min_room_size.x - 1)
		node.left = BSPRoomNode.new(Rect2i(area.position, Vector2i(split_x, area.size.y)))
		node.right = BSPRoomNode.new(Rect2i(area.position + Vector2i(split_x, 0), Vector2i(area.size.x - split_x, area.size.y)))
	else:
		var split_y = randi_range(min_room_size.y + 1, area.size.y - min_room_size.y - 1)
		node.left = BSPRoomNode.new(Rect2i(area.position, Vector2i(area.size.x, split_y)))
		node.right = BSPRoomNode.new(Rect2i(area.position + Vector2i(0, split_y), Vector2i(area.size.x, area.size.y - split_y)))
		
	return true
