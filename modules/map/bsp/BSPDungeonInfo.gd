class_name BSPDungeonInfo extends Resource

@export var root: BSPRoomNode
@export var rooms: Array[BSPRoom] = []
@export var hallways: Array[Rect2i] = []

## Retorna los rectángulos de bounds de todas las salas (para compatibilidad con pasillos)
func get_room_rects() -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	for r in rooms:
		rects.append(r.bounds)
	return rects
