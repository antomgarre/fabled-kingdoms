extends Node

# AIManager.gd
# Simulates a connection to an LLM like Gemini for generating dynamic entities.

var use_live_api = false # Set to true once an API key is provided

func _ready():
	randomize()
	
	var bgm_player = AudioStreamPlayer.new()
	var bgm_stream = load("res://assets/sounds/music/background.mp3")
	if bgm_stream:
		bgm_stream.loop = true
		bgm_player.stream = bgm_stream
		bgm_player.volume_db = -12.0 # Not too loud
		bgm_player.autoplay = true
		add_child(bgm_player)
	else:
		push_warning("Could not load background music")

# Generates a JSON payload for a new NPC or Enemy
func request_npc_generation(location_context: String, callback: Callable):
	print("AIManager: Buscando mundo pre-compilado para la region: ", location_context)
	
	var file_path = "res://../generated_worlds/dark_forest_compiled.json"
	if not FileAccess.file_exists(file_path):
		push_error("No se encontró el mundo compilado en " + file_path)
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var world_data = json.data
		callback.call(world_data)
	else:
		push_error("Error parseando el JSON compilado: " + json.get_error_message())
