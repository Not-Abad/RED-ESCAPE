
extends Control

# ===== RUTAS DE LAS ESCENAS =====
const GAME_SCENE = "res://modules/map/bsp/dungeon_builder.tscn"
const OPTIONS_SCENE = "res://modules/ui/options_menu.tscn"

# ===== RUTAS DE LAS IMAGENES =====
const FONDO = "res://assets/fondo_menu.png"
const UI = "res://assets/ui/"

var menu_opciones: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	crear_interfaz()


# ===== CREAR MENU PRINCIPAL =====
func crear_interfaz() -> void:

	# Ocultar fondo anterior
	var fondo_viejo = get_node_or_null("Fondo")
	if fondo_viejo:
		fondo_viejo.hide()

	# ===== FONDO DE MARTE =====
	var fondo = TextureRect.new()
	fondo.name = "FondoMarte"

	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	if ResourceLoader.exists(FONDO):
		fondo.texture = load(FONDO)
	else:
		push_warning("No se encontro fondo_menu.png")

	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_child(fondo, 0)

	# ===== CAPA OSCURA =====
	var sombra = ColorRect.new()
	sombra.name = "SombraFondo"

	add_child(sombra)
	sombra.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	sombra.color = Color(0, 0, 0, 0.24)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ===== CENTRO =====
	var centro = CenterContainer.new()
	centro.name = "Centro"

	add_child(centro)
	centro.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# ===== PANEL =====
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 350)
	centro.add_child(panel)

	var estilo_panel = StyleBoxFlat.new()
	estilo_panel.bg_color = Color("#3A090F")
	estilo_panel.border_color = Color("#FA742D")
	estilo_panel.set_border_width_all(6)
	estilo_panel.shadow_color = Color(0, 0, 0, 0.7)
	estilo_panel.shadow_size = 12
	estilo_panel.set_content_margin_all(23)

	panel.add_theme_stylebox_override(
		"panel", estilo_panel
	)

	# ===== CONTENEDOR VERTICAL =====
	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 13)
	panel.add_child(caja)

	# ===== TITULO PIXEL ART =====
	var titulo = TextureRect.new()

	var ruta_titulo = UI + "titulo_red_escape.png"

	if ResourceLoader.exists(ruta_titulo):
		titulo.texture = load(ruta_titulo)

	titulo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	titulo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	titulo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	titulo.custom_minimum_size = Vector2(480, 110)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	caja.add_child(titulo)

	# ===== BOTON INICIAR =====
	var iniciar = crear_boton("iniciar")
	caja.add_child(iniciar)
	iniciar.pressed.connect(iniciar_juego)

	# ===== BOTON OPCIONES =====
	var opciones = crear_boton("opciones")
	caja.add_child(opciones)
	opciones.pressed.connect(abrir_opciones)


# ===== CREAR BOTONES CON TEXTURAS =====
func crear_boton(nombre: String) -> TextureButton:
	var boton = TextureButton.new()

	boton.name = nombre.capitalize()

	var normal = UI + nombre + "_normal.png"
	var hover = UI + nombre + "_hover.png"
	var pressed = UI + nombre + "_pressed.png"

	if ResourceLoader.exists(normal):
		boton.texture_normal = load(normal)

	if ResourceLoader.exists(hover):
		boton.texture_hover = load(hover)

	if ResourceLoader.exists(pressed):
		boton.texture_pressed = load(pressed)

	boton.texture_focused = boton.texture_hover
	boton.ignore_texture_size = true
	boton.custom_minimum_size = Vector2(480, 100)
	boton.stretch_mode = TextureButton.STRETCH_SCALE
	boton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boton.focus_mode = Control.FOCUS_ALL

	return boton


# ===== INICIAR VIDEOJUEGO =====
func iniciar_juego() -> void:

	if not ResourceLoader.exists(GAME_SCENE):
		push_error(
			"No se encontro la escena del juego: " + GAME_SCENE
		)
		return

	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


# ===== ABRIR MENU DE OPCIONES =====
func abrir_opciones() -> void:

	# Evitar abrir varias ventanas
	if is_instance_valid(menu_opciones):
		return

	if not ResourceLoader.exists(OPTIONS_SCENE):
		push_error(
			"No se encontro OptionsMenu: " + OPTIONS_SCENE
		)
		return

	var escena = load(OPTIONS_SCENE)

	menu_opciones = escena.instantiate() as Control

	if menu_opciones == null:
		push_error(
			"OptionsMenu debe tener un nodo raiz Control."
		)
		return

	menu_opciones.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(menu_opciones)

	menu_opciones.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
