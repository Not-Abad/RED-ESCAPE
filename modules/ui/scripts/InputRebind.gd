
extends Control

const UI = "res://assets/ui/"
const CREMA = Color("#FFF3D6")
const NARANJA = Color("#F08A3E")

var lista: VBoxContainer
var accion_pendiente: StringName = &""
var fuente_pixel: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var ruta = "res://assets/fonts/PressStart2P-Regular.ttf"
	if ResourceLoader.exists(ruta):
		fuente_pixel = load(ruta)

	crear_interfaz()
	mostrar_acciones()


func aplicar_fuente(nodo: Control, tamano: int = 10) -> void:
	nodo.add_theme_font_size_override("font_size", tamano)

	if fuente_pixel != null:
		nodo.add_theme_font_override("font", fuente_pixel)


func crear_interfaz() -> void:
	var caja = VBoxContainer.new()
	add_child(caja)
	caja.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	caja.add_theme_constant_override("separation", 10)

	# ===== TITULO =====
	var titulo = TextureRect.new()
	var ruta = UI + "label_controles.png"

	if ResourceLoader.exists(ruta):
		titulo.texture = load(ruta)

	titulo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	titulo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	titulo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	titulo.custom_minimum_size.y = 48
	caja.add_child(titulo)

	# ===== LISTA DESPLAZABLE =====
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.add_child(scroll)

	lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 8)
	scroll.add_child(lista)

	# ===== RESTABLECER PIXEL ART =====
	var restablecer = TextureButton.new()
	restablecer.texture_normal = cargar("restablecer_normal")
	restablecer.texture_hover = cargar("restablecer_hover")
	restablecer.texture_pressed = cargar("restablecer_pressed")
	restablecer.texture_focused = restablecer.texture_hover
	restablecer.ignore_texture_size = true
	restablecer.stretch_mode = TextureButton.STRETCH_SCALE
	restablecer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	restablecer.custom_minimum_size.y = 62

	caja.add_child(restablecer)
	restablecer.pressed.connect(restablecer_controles)


func cargar(nombre: String) -> Texture2D:
	var ruta = UI + nombre + ".png"

	if ResourceLoader.exists(ruta):
		return load(ruta)

	push_warning("No se encontro: " + ruta)
	return null


func obtener_acciones() -> Array[StringName]:
	var acciones: Array[StringName] = []

	for nombre in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		if InputMap.has_action(nombre):
			acciones.append(StringName(nombre))

	for accion in InputMap.get_actions():
		if String(accion).begins_with("ui_"):
			continue

		if not acciones.has(accion):
			acciones.append(accion)

	return acciones


func mostrar_acciones() -> void:
	for hijo in lista.get_children():
		lista.remove_child(hijo)
		hijo.queue_free()

	for accion in obtener_acciones():
		var fila = HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		lista.add_child(fila)

		var nombre = Label.new()
		nombre.text = nombre_visible(accion)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.add_theme_color_override("font_color", CREMA)
		aplicar_fuente(nombre, 9)
		fila.add_child(nombre)

		var boton = Button.new()
		boton.text = obtener_tecla(accion)
		boton.custom_minimum_size = Vector2(165, 43)
		configurar_boton(boton)
		fila.add_child(boton)

		boton.pressed.connect(
			iniciar_captura.bind(accion, boton)
		)


func configurar_boton(boton: Button) -> void:
	aplicar_fuente(boton, 9)

	for estado in [
		"font_color",
		"font_hover_color",
		"font_pressed_color"
	]:
		boton.add_theme_color_override(estado, CREMA)

	boton.add_theme_stylebox_override(
		"normal", estilo(Color("#79251D"))
	)
	boton.add_theme_stylebox_override(
		"hover", estilo(Color("#D96A32"))
	)
	boton.add_theme_stylebox_override(
		"pressed", estilo(Color("#A83D22"))
	)


func estilo(color: Color) -> StyleBoxFlat:
	var caja = StyleBoxFlat.new()
	caja.bg_color = color
	caja.border_color = NARANJA
	caja.set_border_width_all(3)
	caja.set_corner_radius_all(0)
	caja.set_content_margin_all(6)
	return caja


func nombre_visible(accion: StringName) -> String:
	match String(accion):
		"ui_up": return "MOVER ARRIBA"
		"ui_down": return "MOVER ABAJO"
		"ui_left": return "MOVER IZQ."
		"ui_right": return "MOVER DER."
		"dodge": return "ESQUIVAR"
		"aim_up": return "APUNTAR ARRIBA"
		"aim_down": return "APUNTAR ABAJO"
		"aim_left": return "APUNTAR IZQ."
		"aim_right": return "APUNTAR DER."
		_:
			return String(accion).replace("_", " ").to_upper()


func obtener_tecla(accion: StringName) -> String:
	var teclas: Array[String] = []

	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey:
			teclas.append(evento.as_text())

	if teclas.is_empty():
		return "ASIGNAR"

	return ", ".join(teclas)


func iniciar_captura(
	accion: StringName,
	boton: Button
) -> void:
	accion_pendiente = accion
	boton.text = "PULSA TECLA"
	boton.release_focus()


func _input(event: InputEvent) -> void:
	if accion_pendiente.is_empty():
		return

	if not (event is InputEventKey):
		return

	var tecla = event as InputEventKey

	if not tecla.pressed or tecla.echo:
		return

	get_viewport().set_input_as_handled()

	if tecla.keycode == KEY_ESCAPE:
		accion_pendiente = &""
		mostrar_acciones()
		return

	var nuevo = InputEventKey.new()

	if tecla.physical_keycode != KEY_NONE:
		nuevo.physical_keycode = tecla.physical_keycode
	else:
		nuevo.keycode = tecla.keycode

	var conservados: Array[InputEvent] = []

	for anterior in InputMap.action_get_events(accion_pendiente):
		if not (anterior is InputEventKey):
			conservados.append(anterior)

	InputMap.action_erase_events(accion_pendiente)

	for anterior in conservados:
		InputMap.action_add_event(
			accion_pendiente, anterior
		)

	InputMap.action_add_event(accion_pendiente, nuevo)

	accion_pendiente = &""
	mostrar_acciones()


func restablecer_controles() -> void:
	accion_pendiente = &""
	InputMap.load_from_project_settings()
	mostrar_acciones()
