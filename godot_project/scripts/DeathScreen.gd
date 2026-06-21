extends CanvasLayer

## Death Screen - Shows "Has Caído" with a retry button
## Resets player position, HP, and respawns enemies.

var overlay: ColorRect
var panel: PanelContainer
var title_label: Label
var subtitle_label: Label
var btn_retry: Button
var is_showing: bool = false

const COLOR_GOLD = Color(0.79, 0.66, 0.43)
const COLOR_BG_DARK = Color(0.05, 0.02, 0.08, 0.92)
const COLOR_RED = Color(0.85, 0.15, 0.1)
const COLOR_TEXT = Color(0.93, 0.91, 0.87)

func _ready():
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_visible(false)

func _build_ui():
	# === Full-screen dark overlay ===
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	# === Centered panel ===
	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -130
	panel.offset_bottom = 130
	
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
	panel_style.border_color = COLOR_RED
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel_style.shadow_color = Color(0.3, 0, 0, 0.4)
	panel_style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# === Inner VBox ===
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)
	
	# --- Death title ---
	title_label = Label.new()
	title_label.text = "Has Caído"
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", COLOR_RED)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# --- Subtitle ---
	subtitle_label = Label.new()
	subtitle_label.text = "La oscuridad te ha consumido..."
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 0.8))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_label)
	
	# --- Separator ---
	var sep = ColorRect.new()
	sep.color = Color(COLOR_RED.r, COLOR_RED.g, COLOR_RED.b, 0.3)
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)
	
	# --- Retry button ---
	btn_retry = Button.new()
	btn_retry.text = "Reintentar"
	btn_retry.custom_minimum_size = Vector2(220, 50)
	btn_retry.add_theme_font_size_override("font_size", 22)
	btn_retry.add_theme_color_override("font_color", COLOR_TEXT)
	btn_retry.add_theme_color_override("font_hover_color", COLOR_GOLD)
	btn_retry.add_theme_color_override("font_pressed_color", COLOR_GOLD)
	
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.15, 0.08, 0.08, 1.0)
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = COLOR_GOLD
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10
	btn_retry.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(0.22, 0.12, 0.12, 1.0)
	btn_hover.border_color = Color(0.92, 0.8, 0.55)
	btn_retry.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.08, 0.04, 0.04, 1.0)
	btn_retry.add_theme_stylebox_override("pressed", btn_pressed)
	
	var btn_focus = btn_hover.duplicate()
	btn_retry.add_theme_stylebox_override("focus", btn_focus)
	
	# Center the button
	var center_h = HBoxContainer.new()
	center_h.alignment = BoxContainer.ALIGNMENT_CENTER
	center_h.add_child(btn_retry)
	vbox.add_child(center_h)
	
	btn_retry.pressed.connect(_on_retry)

func _set_visible(show: bool):
	overlay.visible = show
	panel.visible = show
	is_showing = show

func show_death_screen():
	if is_showing:
		return
	
	is_showing = true
	_set_visible(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	
	# Fade in
	overlay.modulate = Color(1, 1, 1, 0)
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.7, 0.7)
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.8).set_delay(0.3)
	tween.parallel().tween_property(panel, "scale", Vector2(1, 1), 0.6).set_delay(0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Pulse the title
	var pulse = create_tween().set_loops()
	pulse.tween_property(title_label, "modulate", Color(1.3, 0.8, 0.8, 1), 1.5).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 1.5).set_ease(Tween.EASE_IN_OUT)

func _on_retry():
	is_showing = false
	get_tree().paused = false
	_set_visible(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Reset player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector3(0, 5, 0)
		player.velocity = Vector3.ZERO
		player.current_hp = player.max_hp
		player.is_dead = false
		player.is_attacking = false
		player.is_dodging = false
		
		# Update HUD
		var hud = get_node_or_null("/root/Main/HUD")
		if hud and hud.has_method("update_player_hp"):
			hud.update_player_hp(player.current_hp, player.max_hp)
	
	# Respawn enemies by reloading WorldBuilder's enemies
	_respawn_enemies()

func _respawn_enemies():
	# Remove existing dead enemies (all current enemies)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	
	# Re-trigger world builder to spawn enemies
	var world_builder = get_node_or_null("/root/Main/WorldBuilder")
	if world_builder:
		# Load the region data and respawn only enemies
		var file = FileAccess.open("res://data/dark_forest_compiled.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var result = json.parse(file.get_as_text())
			file.close()
			if result == OK:
				var data = json.data
				if data.has("enemies"):
					for enemy_data in data["enemies"]:
						if world_builder.has_method("_spawn_enemy"):
							world_builder._spawn_enemy(enemy_data)
