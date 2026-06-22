extends CanvasLayer

var hp_bar: ProgressBar
var hp_ghost_bar: ProgressBar
var hp_label: Label
var xp_label: Label
var total_xp: int = 0
var enemy_bars = {}

func _ready():
	# === HUD Container ===
	var panel = PanelContainer.new()
	panel.name = "HPPanel"
	panel.position = Vector2(20, 20)
	panel.size = Vector2(260, 70)
	
	# Dark background style with golden glowing border
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.65, 0.2, 0.8)
	
	# Add subtle glow
	style.shadow_color = Color(0.8, 0.65, 0.2, 0.3)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	# HP Label
	hp_label = Label.new()
	hp_label.text = "❤️ HP"
	hp_label.add_theme_font_size_override("font_size", 16)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	vbox.add_child(hp_label)
	
	# HP Bars Container (Overlay)
	var bar_container = MarginContainer.new()
	bar_container.custom_minimum_size = Vector2(230, 20)
	vbox.add_child(bar_container)
	
	# Ghost Bar (Background, updates slowly)
	hp_ghost_bar = ProgressBar.new()
	hp_ghost_bar.max_value = 100
	hp_ghost_bar.value = 100
	hp_ghost_bar.show_percentage = false
	hp_ghost_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var ghost_fill = StyleBoxFlat.new()
	ghost_fill.bg_color = Color(0.6, 0.1, 0.1) # Dark red
	ghost_fill.corner_radius_top_left = 4
	ghost_fill.corner_radius_top_right = 4
	ghost_fill.corner_radius_bottom_left = 4
	ghost_fill.corner_radius_bottom_right = 4
	hp_ghost_bar.add_theme_stylebox_override("fill", ghost_fill)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.05, 0.05)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	hp_ghost_bar.add_theme_stylebox_override("background", bg_style)
	bar_container.add_child(hp_ghost_bar)
	
	# Main HP Bar (Foreground, transparent background, updates instantly)
	hp_bar = ProgressBar.new()
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var main_fill = StyleBoxFlat.new()
	main_fill.bg_color = Color(0.2, 0.8, 0.2) # Starts green
	main_fill.corner_radius_top_left = 4
	main_fill.corner_radius_top_right = 4
	main_fill.corner_radius_bottom_left = 4
	main_fill.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", main_fill)
	
	var trans_bg = StyleBoxEmpty.new()
	hp_bar.add_theme_stylebox_override("background", trans_bg)
	bar_container.add_child(hp_bar)
	
	# XP Label
	xp_label = Label.new()
	xp_label.text = "✦ XP: 0"
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(xp_label)
	
	# === Crosshair (subtle center dot) ===
	var crosshair = Label.new()
	crosshair.text = "·"
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.anchors_preset = Control.PRESET_CENTER
	crosshair.position = Vector2(-10, -16)
	add_child(crosshair)

func update_player_hp(current: float, maximum: float):
	if hp_bar:
		hp_bar.max_value = maximum
		hp_ghost_bar.max_value = maximum
		
		# Update color based on percentage
		var pct = current / maximum
		var fill_style = hp_bar.get_theme_stylebox("fill").duplicate()
		if pct > 0.5:
			fill_style.bg_color = Color(0.2, 0.8, 0.2) # Green
		elif pct > 0.25:
			fill_style.bg_color = Color(0.9, 0.6, 0.1) # Orange
		else:
			fill_style.bg_color = Color(0.9, 0.1, 0.1) # Bright Red
		hp_bar.add_theme_stylebox_override("fill", fill_style)
		
		var damage_taken = current < hp_bar.value
		
		# Main bar updates instantly
		hp_bar.value = current
		
		hp_label.text = "❤️ HP  " + str(int(current)) + " / " + str(int(maximum))
		
		if damage_taken:
			# Flash label
			var flash = create_tween()
			flash.tween_property(hp_label, "modulate", Color(1, 0.3, 0.3), 0.1)
			flash.tween_property(hp_label, "modulate", Color(1, 1, 1), 0.3)
			
			# Tween ghost bar down with a delay to show the "damage chunk"
			var tween = create_tween()
			tween.tween_interval(0.3)
			tween.tween_property(hp_ghost_bar, "value", current, 0.4).set_ease(Tween.EASE_OUT)
		else:
			# If healing, update ghost instantly too
			hp_ghost_bar.value = current

func add_xp(amount: int):
	total_xp += amount
	if xp_label:
		xp_label.text = "✦ XP: " + str(total_xp)
		
		# Pulse animation for XP gain
		var tween = create_tween()
		tween.tween_property(xp_label, "modulate", Color(2.0, 2.0, 2.0), 0.1)
		tween.tween_property(xp_label, "modulate", Color(1.0, 1.0, 1.0), 0.3)

func create_enemy_hp_bar(enemy_id: int):
	pass

func update_enemy_hp(enemy_id: int, current: float, maximum: float, screen_pos: Vector2):
	pass

func remove_enemy_hp_bar(enemy_id: int):
	pass
