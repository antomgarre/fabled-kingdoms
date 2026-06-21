extends CanvasLayer

## Pause Menu - Toggles with ESC, pauses the game tree
## Layer 10 so it renders above everything.

var is_paused: bool = false

# UI Elements
var overlay: ColorRect
var panel: PanelContainer
var title_label: Label
var btn_continue: Button
var btn_fullscreen: Button
var btn_quit: Button

# Colors
const COLOR_BG_DARK = Color(0.1, 0.1, 0.18, 1.0)
const COLOR_GOLD = Color(0.79, 0.66, 0.43)
const COLOR_GOLD_BRIGHT = Color(0.92, 0.8, 0.55)
const COLOR_TEXT = Color(0.93, 0.91, 0.87)
const COLOR_BTN_BG = Color(0.13, 0.13, 0.22, 1.0)
const COLOR_BTN_HOVER = Color(0.18, 0.18, 0.3, 1.0)
const COLOR_BTN_PRESSED = Color(0.08, 0.08, 0.14, 1.0)

func _ready():
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_visible(false)

func _build_ui():
	# === Dark overlay ===
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks through
	add_child(overlay)
	
	# === Centered panel ===
	panel = PanelContainer.new()
	panel.anchors_preset = Control.PRESET_CENTER
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -180
	panel.offset_right = 180
	panel.offset_top = -160
	panel.offset_bottom = 160
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_DARK
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = COLOR_GOLD
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# === Inner VBox ===
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	# --- Title ---
	title_label = Label.new()
	title_label.text = "PAUSA"
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", COLOR_GOLD)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# --- Decorative separator ---
	var sep = ColorRect.new()
	sep.color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.5)
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)
	
	# --- Buttons ---
	btn_continue = _create_button("Continuar")
	vbox.add_child(btn_continue)
	btn_continue.pressed.connect(_on_continue)
	
	btn_fullscreen = _create_button("Pantalla Completa")
	vbox.add_child(btn_fullscreen)
	btn_fullscreen.pressed.connect(_on_fullscreen)
	
	btn_quit = _create_button("Salir")
	vbox.add_child(btn_quit)
	btn_quit.pressed.connect(_on_quit)

func _create_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 48)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
	btn.add_theme_color_override("font_pressed_color", COLOR_GOLD)
	btn.add_theme_color_override("font_focus_color", COLOR_TEXT)
	
	# Normal style
	var normal = StyleBoxFlat.new()
	normal.bg_color = COLOR_BTN_BG
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = COLOR_GOLD
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", normal)
	
	# Hover style
	var hover = normal.duplicate()
	hover.bg_color = COLOR_BTN_HOVER
	hover.border_color = COLOR_GOLD_BRIGHT
	btn.add_theme_stylebox_override("hover", hover)
	
	# Pressed style
	var pressed = normal.duplicate()
	pressed.bg_color = COLOR_BTN_PRESSED
	pressed.border_color = COLOR_GOLD
	btn.add_theme_stylebox_override("pressed", pressed)
	
	# Focus style (same as hover)
	var focus = hover.duplicate()
	btn.add_theme_stylebox_override("focus", focus)
	
	return btn

func _set_visible(show: bool):
	overlay.visible = show
	panel.visible = show

func toggle_pause():
	if is_paused:
		_unpause()
	else:
		_pause()

func _pause():
	is_paused = true
	get_tree().paused = true
	_set_visible(true)
	
	# Animate panel scale
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.3)
	tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.2)
	
	# Show cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unpause():
	is_paused = false
	
	# Animate out
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_callback(func():
		_set_visible(false)
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		# Check if dialogue is open - don't steal ESC from it
		var dialogue_ui = get_node_or_null("/root/Main/DialogueUI")
		if dialogue_ui and dialogue_ui.is_open:
			return
		
		toggle_pause()
		get_viewport().set_input_as_handled()

# === Button callbacks ===

func _on_continue():
	_unpause()

func _on_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		btn_fullscreen.text = "Pantalla Completa"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		btn_fullscreen.text = "Modo Ventana"

func _on_quit():
	_unpause()
	# Reload the current scene (effectively restarting)
	get_tree().reload_current_scene()
