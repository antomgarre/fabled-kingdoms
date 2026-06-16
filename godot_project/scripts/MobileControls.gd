extends CanvasLayer
class_name MobileControls

var joystick_active = false
var joystick_touch_id = -1
var joystick_center = Vector2()
var joystick_current = Vector2()
var joystick_vector = Vector2()

var camera_drag_touch_id = -1

# UI Elements
var joy_bg: Panel
var joy_handle: Panel

signal camera_dragged(relative: Vector2)

func _ready():
	# Make sure we only show on mobile/touch
	if not DisplayServer.is_touchscreen_available():
		hide()
		set_process_input(false)
		return
		
	# Setup InputMap actions if not exist (so we can trigger them)
	for action in ["attack", "dodge", "sprint"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
	# --- Joystick Visuals ---
	joy_bg = Panel.new()
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(1, 1, 1, 0.2)
	bg_style.corner_radius_top_left = 125
	bg_style.corner_radius_top_right = 125
	bg_style.corner_radius_bottom_left = 125
	bg_style.corner_radius_bottom_right = 125
	joy_bg.add_theme_stylebox_override("panel", bg_style)
	joy_bg.size = Vector2(250, 250)
	joy_bg.hide()
	add_child(joy_bg)
	
	joy_handle = Panel.new()
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(1, 1, 1, 0.6)
	h_style.corner_radius_top_left = 40
	h_style.corner_radius_top_right = 40
	h_style.corner_radius_bottom_left = 40
	h_style.corner_radius_bottom_right = 40
	joy_handle.add_theme_stylebox_override("panel", h_style)
	joy_handle.size = Vector2(80, 80)
	joy_bg.add_child(joy_handle)
	joy_handle.position = (joy_bg.size / 2.0) - (joy_handle.size / 2.0)
	
	# --- Action Buttons ---
	# Attack
	_create_action_button("Attack", "attack", Vector2(-180, -180), Color(0.8, 0.2, 0.2, 0.5))
	# Jump (ui_accept)
	_create_action_button("Jump", "ui_accept", Vector2(-180, -360), Color(0.2, 0.8, 0.2, 0.5))
	# Dodge
	_create_action_button("Dodge", "dodge", Vector2(-360, -180), Color(0.2, 0.2, 0.8, 0.5))

func _create_action_button(text_label: String, action_name: String, offset: Vector2, color: Color):
	var btn = Button.new()
	btn.text = text_label
	btn.size = Vector2(150, 150)
	btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.position = get_viewport().get_visible_rect().size + offset
	btn.focus_mode = Control.FOCUS_NONE
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 75
	style.corner_radius_top_right = 75
	style.corner_radius_bottom_left = 75
	style.corner_radius_bottom_right = 75
	
	var style_pressed = style.duplicate()
	style_pressed.bg_color = color.lightened(0.5)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("hover", style)
	
	add_child(btn)
	
	# We use pressed/released to simulate input actions so the PlayerController can just read Input.is_action_pressed
	btn.button_down.connect(func(): Input.action_press(action_name))
	btn.button_up.connect(func(): Input.action_release(action_name))
	
	# Keep position relative to bottom right on resize
	get_viewport().size_changed.connect(func(): 
		btn.position = get_viewport().get_visible_rect().size + offset
	)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Left half of screen -> Joystick
			if event.position.x < get_viewport().size.x / 2.0:
				if not joystick_active:
					joystick_active = true
					joystick_touch_id = event.index
					joystick_center = event.position
					joystick_current = event.position
					
					joy_bg.position = joystick_center - (joy_bg.size / 2.0)
					joy_handle.position = (joy_bg.size / 2.0) - (joy_handle.size / 2.0)
					joy_bg.show()
			else:
				# Right half -> Camera drag (only if not hitting a button, Button consumes input first!)
				if camera_drag_touch_id == -1:
					camera_drag_touch_id = event.index
		else:
			# Touch released
			if event.index == joystick_touch_id:
				joystick_active = false
				joystick_touch_id = -1
				joystick_vector = Vector2.ZERO
				joy_bg.hide()
			elif event.index == camera_drag_touch_id:
				camera_drag_touch_id = -1
				
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_id:
			joystick_current = event.position
			var dir = joystick_current - joystick_center
			var max_dist = joy_bg.size.x / 2.0
			
			if dir.length() > max_dist:
				dir = dir.normalized() * max_dist
				
			joystick_vector = dir / max_dist
			joy_handle.position = (joy_bg.size / 2.0) - (joy_handle.size / 2.0) + dir
			
		elif event.index == camera_drag_touch_id:
			# Send relative motion to the game
			camera_dragged.emit(event.relative)
