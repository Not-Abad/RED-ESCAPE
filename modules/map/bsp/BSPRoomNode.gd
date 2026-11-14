class_name BSPRoomNode extends Resource

@export var area: Rect2i
@export var room: Rect2i
@export var left: BSPRoomNode
@export var right: BSPRoomNode

func _init(_area: Rect2i = Rect2i()) -> void:
	area = _area
	left = null
	right = null

func is_leaf() -> bool:
	return left == null and right == null

## Devuelve todas las celdas hojas (habitaciones finales)
func get_leaves() -> Array[BSPRoomNode]:
	if is_leaf():
		return [self]
	var leaves: Array[BSPRoomNode] = []
	if left:
		leaves.append_array(left.get_leaves())
	if right:
		leaves.append_array(right.get_leaves())
	return leaves

## Obtiene el centro de una sala accesible dentro de este sub-árbol
func get_room_center() -> Vector2i:
	if is_leaf():
		return room.position + room.size / 2
	
	if left and right:
		return left.get_room_center() if randf() < 0.5 else right.get_room_center()
	elif left:
		return left.get_room_center()
	elif right:
		return right.get_room_center()
	
	return Vector2i.ZERO
	
## Obtiene una habitación (Rect2i) aleatoria dentro de este subárbol
func get_random_room() -> Rect2i:
	if is_leaf():
		return room
	if left and right:
		return left.get_random_room() if randf() < 0.5 else right.get_random_room()
	elif left:
		return left.get_random_room()
	elif right:
		return right.get_random_room()
	return room
