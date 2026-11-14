
extends CanvasLayer

# ===== RUTAS =====
const MAIN_MENU = "res://modules/ui/MainMenu.tscn"
const OPTIONS_MENU = "res://modules/ui/options_menu.tscn"
const UI = "res://assets/ui/"

var menu_opciones: Control = null
var elementos_pausa: Array[CanvasItem] = []
var boton_reanudar: BaseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	crear_interfaz()
	visible = false


# ===== TECLA ESC =====
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if event is InputEventKey and event.echo:
		return

	get_viewport().set_input_as_handled()

	# No cerrar la pausa mientras Opciones esta abierto.
	if is_instance_valid(menu_opciones):
		return

	if visible:
		reanudar_juego()
	else:
		pausar_juego()


# ===== CREAR INTERFAZ =====
func crear_interfaz() -> void:
	# Ocultar los nodos anteriores sin eliminarlos.
	for hijo in get_children():
		if hijo is CanvasItem:
			hijo.hide()

	# ===== FONDO OSCURO =====
	var fondo := ColorRect.new()
	fondo.name = "FondoOscuroPixel"
	fondo.color = Color(0, 0, 0, 0.45)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	elementos_pausa.append(fondo)

	# ===== CONTENEDOR CENTRAL =====
	var centro := CenterContainer.new()
	centro.name = "Centro"
	add_child(centro)
	centro.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	elementos_pausa.append(centro)

	# ===== PANEL PRINCIPAL =====
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 520)
	centro.add_child(panel)

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#53060F")
	estilo.border_color = Color("#FA742D")
	estilo.set_border_width_all(6)
	estilo.shadow_color = Color(0, 0, 0, 0.7)
	estilo.shadow_size = 12
	estilo.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", estilo)

	# ===== CONTENEDOR VERTICAL =====
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	panel.add_child(caja)

	# ===== TITULO PIXEL ART =====
	var ruta_titulo := UI + "titulo_pausa.png"

	if ResourceLoader.exists(ruta_titulo):
		var titulo := TextureRect.new()
		titulo.texture = load(ruta_titulo)
		titulo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		titulo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		titulo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		titulo.custom_minimum_size = Vector2(480, 100)
		titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(titulo)
	else:
		var titulo := Label.new()
		titulo.text = "PAUSA"
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		titulo.custom_minimum_size = Vector2(480, 90)
		titulo.add_theme_font_size_override("font_size", 42)
		titulo.add_theme_color_override(
			"font_color", Color("#FFF3D6")
		)
		caja.add_child(titulo)

	# ===== BOTON REANUDAR =====
	boton_reanudar = crear_boton_pixel(
		"reanudar", "REANUDAR"
	)
	caja.add_child(boton_reanudar)
	boton_reanudar.pressed.connect(reanudar_juego)

	# ===== BOTON OPCIONES =====
	var opciones := crear_boton_pixel(
		"opciones", "OPCIONES"
	)
	caja.add_child(opciones)
	opciones.pressed.connect(abrir_opciones)

	# ===== BOTON SALIR =====
	var salir := crear_boton_pixel("salir", "SALIR")
	caja.add_child(salir)
	salir.pressed.connect(salir_al_menu)


# ===== BOTONES PIXEL ART =====
func crear_boton_pixel(
	nombre: String,
	texto_respaldo: String
) -> BaseButton:

	var normal := UI + nombre + "_normal.png"
	var hover := UI + nombre + "_hover.png"
	var pressed := UI + nombre + "_pressed.png"

	if ResourceLoader.exists(normal):
		var boton := TextureButton.new()
		boton.name = nombre.capitalize()
		boton.texture_normal = load(normal)

		if ResourceLoader.exists(hover):
			boton.texture_hover = load(hover)

		if ResourceLoader.exists(pressed):
			boton.texture_pressed = load(pressed)

		boton.texture_focused = boton.texture_hover
		boton.ignore_texture_size = true
		boton.custom_minimum_size = Vector2(480, 92)
		boton.stretch_mode = TextureButton.STRETCH_SCALE
		boton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		boton.focus_mode = Control.FOCUS_ALL
		return boton

	# Boton de respaldo si falta una imagen.
	var boton := Button.new()
	boton.name = nombre.capitalize()
	boton.text = texto_respaldo
	boton.custom_minimum_size = Vector2(480, 88)
	boton.add_theme_font_size_override("font_size", 24)
	boton.add_theme_color_override(
		"font_color", Color("#FFF3D6")
	)

	boton.add_theme_stylebox_override(
		"normal",
		crear_estilo_boton("#922018", "#E5642E")
	)

	boton.add_theme_stylebox_override(
		"hover",
		crear_estilo_boton("#D86A31", "#FFD08A")
	)

	boton.add_theme_stylebox_override(
		"pressed",
		crear_estilo_boton("#B53A1D", "#FF9F42")
	)

	return boton


func crear_estilo_boton(
	color_fondo: String,
	color_borde: String
) -> StyleBoxFlat:

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(color_fondo)
	estilo.border_color = Color(color_borde)
	estilo.set_border_width_all(4)
	estilo.shadow_color = Color(0, 0, 0, 0.55)
	estilo.shadow_size = 5
	return estilo


# ===== PAUSAR JUEGO =====
func pausar_juego() -> void:
	for elemento in elementos_pausa:
		elemento.show()

	visible = true
	get_tree().paused = true

	if is_instance_valid(boton_reanudar):
		boton_reanudar.grab_focus()


# ===== REANUDAR JUEGO =====
func reanudar_juego() -> void:
	if is_instance_valid(menu_opciones):
		menu_opciones.queue_free()
		menu_opciones = null

	visible = false
	get_tree().paused = false


# ===== ABRIR OPCIONES =====
func abrir_opciones() -> void:
	if is_instance_valid(menu_opciones):
		return

	if not ResourceLoader.exists(OPTIONS_MENU):
		push_error(
			"No se encontro OptionsMenu: " + OPTIONS_MENU
		)
		return

	var escena := load(OPTIONS_MENU) as PackedScene

	if escena == null:
		push_error("No se pudo cargar OptionsMenu.")
		return

	menu_opciones = escena.instantiate() as Control

	if menu_opciones == null:
		push_error(
			"OptionsMenu necesita un nodo raiz Control."
		)
		return

	# Mantener la partida pausada.
	get_tree().paused = true

	# Ocultar solamente los elementos de pausa.
	for elemento in elementos_pausa:
		elemento.hide()

	# Crear Opciones dentro de este CanvasLayer.
	add_child(menu_opciones)
	menu_opciones.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_opciones.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Al pulsar VOLVER, recuperar el menu de pausa.
	menu_opciones.tree_exited.connect(
		_restaurar_menu_pausa
	)


# ===== REGRESAR DE OPCIONES =====
func _restaurar_menu_pausa() -> void:
	menu_opciones = null

	if not is_inside_tree():
		return

	for elemento in elementos_pausa:
		if is_instance_valid(elemento):
			elemento.show()

	visible = true
	get_tree().paused = true

	if is_instance_valid(boton_reanudar):
		boton_reanudar.grab_focus()


# ===== SALIR AL MENU PRINCIPAL =====
func salir_al_menu() -> void:
	get_tree().paused = false

	if not ResourceLoader.exists(MAIN_MENU):
		push_error(
			"No se encontro MainMenu: " + MAIN_MENU
		)
		return

	get_tree().change_scene_to_file(MAIN_MENU)
