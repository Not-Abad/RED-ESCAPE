extends CharacterBody2D

## Se emite cada vez que cambia la vida (sirve para una barra de vida).
signal vida_cambiada(vida_actual: int, vida_maxima: int)
## Se emite cuando la vida llega a cero.
signal murio

@export var vida_maxima: int = 3

var vida: int = 0

func _ready() -> void:
	vida = vida_maxima

# Las balas llaman a esta función cuando golpean al enemigo
func recibir_dano(cantidad: int) -> void:
	if vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	vida_cambiada.emit(vida, vida_maxima)
	_parpadear()
	if vida == 0:
		murio.emit()
		queue_free()

# Se pone rojizo un momento para notar el golpe
func _parpadear() -> void:
	modulate = Color(1.0, 0.4, 0.4)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
