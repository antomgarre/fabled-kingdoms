extends CanvasLayer

## Dialogue UI - Bottom-of-screen panel with typewriter effect
## Shows NPC name + dialogue text. Blocks player movement while open.

signal dialogue_opened
signal dialogue_closed

var is_open: bool = false

# UI Elements
var overlay: ColorRect
var panel_container: PanelContainer
var name_label: Label
var text_label: Label
var hint_label: Label

# Typewriter state
var full_text: String = ""
var visible_chars: int = 0
var chars_per_second: float = 40.0
var typewriter_timer: float = 0.0
var typewriter_done: bool = true

# Animation
var panel_target_y: float = 0.0
var panel_hidden_y: float = 0.0

func _ready():
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_hide_immediate()

func _build_ui():
	# === Semi-transparent overlay (very subtle, just dims slightly) ===
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.3)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	add_child(overlay)
	
	# === Bottom panel container ===
	panel_container = PanelContainer.new()
	panel_container.anchor_left = 0.05
	panel_container.anchor_right = 0.95
	panel_container.anchor_top = 1.0
	panel_container.anchor_bottom = 1.0
	panel_container.offset_top = -200
	panel_container.offset_bottom = -20
	
	# Dark semi-transparent background with golden border
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.18, 0.92)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.79, 0.66, 0.43)  # Golden
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel_container.add_theme_stylebox_override("panel", panel_style)
	add_child(panel_container)
	
	# === Inner layout ===
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel_container.add_child(vbox)
	
	# --- NPC Name (golden, large) ---
	name_label = Label.new()
	name_label.text = ""
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.79, 0.66, 0.43))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(name_label)
	
	# --- Separator line ---
	var separator = ColorRect.new()
	separator.color = Color(0.79, 0.66, 0.43, 0.4)
	separator.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(separator)
	
	# --- Dialogue text (white, larger) ---
	text_label = Label.new()
	text_label.text = ""
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.87))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(0, 60)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(text_label)
	
	# --- Hint at bottom-right ---
	var hint_container = HBoxContainer.new()
	hint_container.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(hint_container)
	
	hint_label = Label.new()
	hint_label.text = "Pulsa E para cerrar"
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 0.8))
	hint_container.add_child(hint_label)

func _hide_immediate():
	panel_container.visible = false
	overlay.visible = false
	is_open = false

func show_dialogue(npc_name: String, text: String):
	if is_open:
		return
	
	is_open = true
	name_label.text = npc_name
	full_text = text
	text_label.text = ""
	visible_chars = 0
	typewriter_done = false
	typewriter_timer = 0.0
	
	# Show elements
	overlay.visible = true
	overlay.modulate = Color(1, 1, 1, 0)
	panel_container.visible = true
	
	# Animate overlay fade in
	var tween_overlay = create_tween()
	tween_overlay.tween_property(overlay, "modulate", Color(1, 1, 1, 1), 0.3).set_ease(Tween.EASE_OUT)
	
	# Slide panel up from bottom
	# Start off-screen (push it down by 250px)
	panel_container.offset_top = 0
	panel_container.offset_bottom = 200
	
	var tween_panel = create_tween()
	tween_panel.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_panel.tween_property(panel_container, "offset_top", -200, 0.4)
	tween_panel.parallel().tween_property(panel_container, "offset_bottom", -20, 0.4)
	
	dialogue_opened.emit()

func hide_dialogue():
	if not is_open:
		return
	
	is_open = false
	
	# Animate overlay fade out
	var tween_overlay = create_tween()
	tween_overlay.tween_property(overlay, "modulate", Color(1, 1, 1, 0), 0.25)
	
	# Slide panel down
	var tween_panel = create_tween()
	tween_panel.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween_panel.tween_property(panel_container, "offset_top", 0, 0.3)
	tween_panel.parallel().tween_property(panel_container, "offset_bottom", 200, 0.3)
	tween_panel.tween_callback(_on_hide_complete)
	
	dialogue_closed.emit()

func _on_hide_complete():
	panel_container.visible = false
	overlay.visible = false

func _process(delta):
	if not is_open:
		return
	
	# Typewriter effect
	if not typewriter_done:
		typewriter_timer += delta
		var chars_to_show = int(typewriter_timer * chars_per_second)
		if chars_to_show > visible_chars:
			visible_chars = chars_to_show
			if visible_chars >= full_text.length():
				visible_chars = full_text.length()
				typewriter_done = true
			text_label.text = full_text.substr(0, visible_chars)

func _unhandled_input(event):
	if not is_open:
		return
	
	# Close on E press
	var close_pressed = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.physical_keycode == KEY_E:
			close_pressed = true
	
	# Also close on screen tap (for mobile)
	if event is InputEventScreenTouch and event.pressed:
		close_pressed = true
	
	if close_pressed:
		if not typewriter_done:
			# First press: skip typewriter, show full text
			visible_chars = full_text.length()
			text_label.text = full_text
			typewriter_done = true
		else:
			# Second press: close
			hide_dialogue()
		get_viewport().set_input_as_handled()
