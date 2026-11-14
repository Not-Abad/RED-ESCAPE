extends Node2D

## Color de las chispas del impacto.
@export var color: Color = Color.DARK_GOLDENROD
## Cuántas chispas salen.
@export var cantidad: int = 8
## Hasta dónde llegan las chispas (en píxeles).
@export var alcance: float = 35.0
## Duración del efecto en segundos.
@export var duracion: float = 0.35

## Dirección de la bala que chocó (las chispas salen hacia el lado contrario).
var direccion: Vector2 = Vector2.RIGHT

var _t: float = 0.0   # progreso del efecto, de 0 a 1
var _angulos: Array[float] = []

func _ready() -> void:
	var base: float = (-direccion).angle()
	for i in cantidad:
		_angulos.append(base + randf_range(-0.9, 0.9))
	var tween: Tween = create_tween()
	tween.tween_property(self, "_t", 1.0, duracion)
	tween.finished.connect(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var tam: float = lerpf(4.0, 1.0, _t)
	var dist: float = alcance * (1.0 - pow(1.0 - _t, 2.0))   # salen rápido y frenan
	var c: Color = color
	c.a = 1.0 - _t
	for a in _angulos:
		var p: Vector2 = Vector2.from_angle(a) * dist
		draw_rect(Rect2(p - Vector2(tam, tam) / 2.0, Vector2(tam, tam)), c)
