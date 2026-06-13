extends CanvasLayer

var hp_bar: ProgressBar
var hp_label: Label
var enemy_bars = {}

func _ready():
	# === Player HP Bar ===
	var panel = PanelContainer.new()
	panel.name = "HPPanel"
	panel.position = Vector2(20, 20)
	panel.size = Vector2(250, 50)
	
	# Dark background style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.65, 0.2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	# HP Label
	hp_label = Label.new()
	hp_label.text = "HP"
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	vbox.add_child(hp_label)
	
	# HP Bar
	hp_bar = ProgressBar.new()
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(220, 18)
	
	# Bar fill style (red gradient)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.15, 0.1)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Bar background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.1, 0.1)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	hp_bar.add_theme_stylebox_override("background", bg_style)
	
	vbox.add_child(hp_bar)
	
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
		
		# Smooth HP bar animation
		var tween = create_tween()
		tween.tween_property(hp_bar, "value", current, 0.3).set_ease(Tween.EASE_OUT)
		
		hp_label.text = "HP  " + str(int(current)) + " / " + str(int(maximum))
		
		# Flash red when taking damage
		if current < hp_bar.value:
			var flash = create_tween()
			flash.tween_property(hp_label, "modulate", Color(1, 0.3, 0.3), 0.1)
			flash.tween_property(hp_label, "modulate", Color(1, 1, 1), 0.3)
