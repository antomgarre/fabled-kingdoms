extends Node

var quests = {}

var ui_layer: CanvasLayer
var quest_list_container: VBoxContainer
var popup_label: Label
var success_sound_player: AudioStreamPlayer

func _ready():
	# Initialize quest
	quests["kill_goblins"] = {
		"id": "kill_goblins",
		"title": "Caza de Goblins",
		"desc": "Elimina 3 goblins del bosque.",
		"type": "kill_enemies",
		"target": 3,
		"progress": 0,
		"completed": false
	}
	
	_setup_ui()
	_update_ui()

func _setup_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Quest list on the right
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ui_layer.add_child(margin)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_color = Color(0.8, 0.7, 0.2, 1.0)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)
	
	quest_list_container = VBoxContainer.new()
	panel.add_child(quest_list_container)
	
	# Popup notification
	popup_label = Label.new()
	popup_label.text = "Misión Completada"
	popup_label.set_anchors_preset(Control.PRESET_CENTER)
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.add_theme_font_size_override("font_size", 32)
	popup_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	popup_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup_label.add_theme_constant_override("outline_size", 8)
	popup_label.modulate.a = 0
	ui_layer.add_child(popup_label)
	
	# Audio player
	success_sound_player = AudioStreamPlayer.new()
	success_sound_player.stream = load("res://assets/sounds/handleCoins.ogg")
	add_child(success_sound_player)

func _update_ui():
	for child in quest_list_container.get_children():
		child.queue_free()
		
	var title_label = Label.new()
	title_label.text = "Misiones Activas:"
	title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	title_label.add_theme_font_size_override("font_size", 18)
	quest_list_container.add_child(title_label)
	
	for q in quests.values():
		if not q.completed:
			var q_label = Label.new()
			q_label.text = "- " + q.title + " (" + str(q.progress) + "/" + str(q.target) + ")"
			quest_list_container.add_child(q_label)

func add_progress(quest_id: String, amount: int):
	if quests.has(quest_id):
		var q = quests[quest_id]
		if not q.completed:
			q.progress += amount
			if q.progress >= q.target:
				q.progress = q.target
				q.completed = true
				_on_quest_completed()
			_update_ui()

func _on_quest_completed():
	success_sound_player.play()
	
	# Reset popup state
	popup_label.modulate.a = 0
	popup_label.scale = Vector2(0.5, 0.5)
	
	# Tween animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup_label, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup_label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	tween.chain().tween_property(popup_label, "modulate:a", 0.0, 1.0).set_delay(2.0)
