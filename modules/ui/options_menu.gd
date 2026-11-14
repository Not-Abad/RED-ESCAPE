
extends Control

const REBIND_SCRIPT = preload(
	"res://modules/ui/scripts/InputRebind.gd"
)

const UI = "res://assets/ui/"
const CREMA = Color("#FFF3D6")
const NARANJA = Color("#F08A3E")

var vista_general: VBoxContainer
var vista_controles: Control
var boton_general: TextureButton
var boton_controles: TextureButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	crear_interfaz()


func textura(nombre: String) -> Texture2D:
	var ruta = UI + nombre + ".png"

	if ResourceLoader.exists(ruta):
		return load(ruta)

	push_warning("Falta la textura: " + ruta)
	return null


func crear_imagen(
	nombre: String,
	ancho: float,
	alto: float
) -> TextureRect:
	var imagen = TextureRect.new()
	imagen.texture = textura(nombre)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagen.custom_minimum_size = Vector2(ancho, alto)
	imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return imagen


func crear_boton(
	nombre: String,
	ancho: float,
	alto: float
) -> TextureButton:
	var boton = TextureButton.new()
	boton.texture_normal = textura(nombre + "_normal")
	boton.texture_hover = textura(nombre + "_hover")
	boton.texture_pressed = textura(nombre + "_pressed")
	boton.texture_focused = boton.texture_hover
	boton.ignore_texture_size = true
	boton.stretch_mode = TextureButton.STRETCH_SCALE
	boton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boton.custom_minimum_size = Vector2(ancho, alto)
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.focus_mode = Control.FOCUS_ALL
	return boton


func crear_interfaz() -> void:
	# ===== FONDO OSCURO =====
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ===== CENTRAR EL MENU =====
	var centro = CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ===== PANEL =====
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(550, 600)
	centro.add_child(panel)

	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color("#3A090F")
	estilo.border_color = NARANJA
	estilo.set_border_width_all(6)
	estilo.set_content_margin_all(18)
	estilo.shadow_color = Color(0, 0, 0, 0.65)
	estilo.shadow_size = 10
	panel.add_theme_stylebox_override("panel", estilo)

	# ===== ORGANIZACION VERTICAL =====
	var caja = VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	panel.add_child(caja)

	# ===== TITULO PIXEL ART =====
	var titulo = crear_imagen(
		"titulo_opciones", 480, 90
	)
	caja.add_child(titulo)

	# ===== PESTAÑAS =====
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)

	boton_general = crear_boton("general", 210, 56)
	fila.add_child(boton_general)

	boton_controles = crear_boton("controles", 210, 56)
	fila.add_child(boton_controles)

	boton_general.pressed.connect(
		func(): cambiar_pestana(true)
	)
	boton_controles.pressed.connect(
		func(): cambiar_pestana(false)
	)

	# ===== AREA DE CONTENIDO =====
	var contenido = PanelContainer.new()
	contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.add_child(contenido)

	var estilo_contenido = StyleBoxFlat.new()
	estilo_contenido.bg_color = Color("#290C11")
	estilo_contenido.border_color = Color("#9B321F")
	estilo_contenido.set_border_width_all(3)
	estilo_contenido.set_content_margin_all(12)

	contenido.add_theme_stylebox_override(
		"panel", estilo_contenido
	)

	var contenido_root = Control.new()
	contenido_root.custom_minimum_size = Vector2(0, 310)
	contenido_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenido.add_child(contenido_root)

	# ===== GENERAL =====
	vista_general = VBoxContainer.new()
	contenido_root.add_child(vista_general)
	vista_general.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	vista_general.add_theme_constant_override(
		"separation", 16
	)
	crear_general()

	# ===== CONTROLES =====
	vista_controles = Control.new()
	vista_controles.set_script(REBIND_SCRIPT)
	contenido_root.add_child(vista_controles)
	vista_controles.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# ===== BOTON VOLVER =====
	var volver = crear_boton("volver", 480, 75)
	caja.add_child(volver)
	volver.pressed.connect(cerrar_opciones)

	cambiar_pestana(true)


func cambiar_pestana(es_general: bool) -> void:
	vista_general.visible = es_general
	vista_controles.visible = not es_general

	# Resaltar visualmente la pestaña activa.
	if es_general:
		boton_general.texture_normal = textura("general_pressed")
		boton_controles.texture_normal = textura("controles_normal")
	else:
		boton_general.texture_normal = textura("general_normal")
		boton_controles.texture_normal = textura("controles_pressed")


func crear_general() -> void:
	# ===== ENCABEZADO =====
	vista_general.add_child(
		crear_imagen("label_general", 450, 55)
	)

	# ===== VOLUMEN MASTER =====
	vista_general.add_child(
		crear_imagen("label_volumen", 330, 43)
	)

	var volumen = crear_slider(0, 100)
	vista_general.add_child(volumen)

	var bus = AudioServer.get_bus_index("Master")

	if bus >= 0:
		if AudioServer.is_bus_mute(bus):
			volumen.value = 0
		else:
			var db = AudioServer.get_bus_volume_db(bus)
			volumen.value = clampf(
				db_to_linear(db) * 100.0,
				0.0, 100.0
			)

	volumen.value_changed.connect(cambiar_volumen)

	# ===== BRILLO =====
	vista_general.add_child(
		crear_imagen("label_brillo", 220, 43)
	)

	var brillo = crear_slider(50, 100)
	vista_general.add_child(brillo)

	var capa = obtener_capa_brillo()

	if capa != null:
		brillo.value = clampf(
			100.0 - capa.color.a * 100.0,
			50.0, 100.0
		)
	else:
		brillo.value = 100

	brillo.value_changed.connect(cambiar_brillo)


func crear_slider(minimo: float, maximo: float) -> HSlider:
	var slider = HSlider.new()
	slider.min_value = minimo
	slider.max_value = maximo
	slider.step = 1
	slider.custom_minimum_size.y = 42
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var fondo = StyleBoxFlat.new()
	fondo.bg_color = Color("#401317")
	fondo.border_color = NARANJA
	fondo.set_border_width_all(2)
	fondo.set_content_margin_all(5)

	var relleno = StyleBoxFlat.new()
	relleno.bg_color = Color("#F08A3E")
	relleno.set_content_margin_all(5)

	slider.add_theme_stylebox_override("slider", fondo)
	slider.add_theme_stylebox_override(
		"grabber_area", relleno
	)
	slider.add_theme_stylebox_override(
		"grabber_area_highlight", relleno
	)

	var imagen = Image.create(
		18, 18, false, Image.FORMAT_RGBA8
	)
	imagen.fill(Color("#3A0F14"))

	for x in range(2, 16):
		for y in range(2, 16):
			imagen.set_pixel(x, y, NARANJA)

	var agarre = ImageTexture.create_from_image(imagen)

	slider.add_theme_icon_override("grabber", agarre)
	slider.add_theme_icon_override(
		"grabber_highlight", agarre
	)

	return slider


func cambiar_volumen(valor: float) -> void:
	var bus = AudioServer.get_bus_index("Master")

	if bus < 0:
		return

	if valor <= 0:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(
			bus, linear_to_db(valor / 100.0)
		)


func obtener_capa_brillo() -> ColorRect:
	return get_tree().root.get_node_or_null(
		"BrilloGlobal/CapaOscura"
	) as ColorRect


func cambiar_brillo(valor: float) -> void:
	var raiz = get_tree().root
	var capa_global = raiz.get_node_or_null("BrilloGlobal")

	if capa_global == null:
		capa_global = CanvasLayer.new()
		capa_global.name = "BrilloGlobal"
		capa_global.layer = 90
		raiz.add_child(capa_global)

		var capa = ColorRect.new()
		capa.name = "CapaOscura"
		capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		capa_global.add_child(capa)
		capa.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)

	var capa = obtener_capa_brillo()

	if capa != null:
		capa.color = Color(
			0, 0, 0, (100.0 - valor) / 100.0
		)


func cerrar_opciones() -> void:
	queue_free()
