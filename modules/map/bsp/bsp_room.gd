class_name BSPRoom extends Resource

enum ShapeType {
	RECTANGLE,         ## Caja estándar
	CHAMFERED,         ## Esquinas recortadas/biseladas
	H_SHAPE,           ## Muros proyectados hacia el centro en forma de H
	TWO_ROWS_PILLARS,  ## Dos filas paralelas de pilares
	CENTER_ALTAR,      ## Estructura o pedestal central
	STEPPED_WALLS      ## Bordes dentados o escalonados
}

enum RoomType {
	DEFAULT,
	SPAWN,
	CHEST,
	BOSS,
	SHOP
}

var bounds: Rect2i
var room_type: RoomType = RoomType.DEFAULT
var shape_type: ShapeType = ShapeType.RECTANGLE

## Listas de coordenadas globales en la cuadrícula
var floor_positions: Array[Vector2i] = []
var wall_positions: Array[Vector2i] = []     ## Paredes perimetrales e internas
var obstacle_positions: Array[Vector2i] = [] ## Pilares / Columnas

func _init(_bounds: Rect2i = Rect2i(), _type: RoomType = RoomType.DEFAULT) -> void:
	bounds = _bounds
	room_type = _type

func get_center() -> Vector2i:
	return bounds.position + bounds.size / 2
