extends CanvasLayer

func _ready():
	# Procedurally create background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Procedurally create label
	var label = Label.new()
	label.text = "Cargando..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 48)
	add_child(label)
	
	# Start threaded load
	var err = ResourceLoader.load_threaded_request("res://scenes/Main.tscn")
	if err != OK:
		push_error("Failed to start loading Main.tscn: " + str(err))

func _process(_delta):
	var status = ResourceLoader.load_threaded_get_status("res://scenes/Main.tscn")
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://scenes/Main.tscn"))
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		push_error("Error loading Main.tscn")
		set_process(false)
