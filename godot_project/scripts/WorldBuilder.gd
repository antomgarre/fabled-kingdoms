extends Node3D

func _ready():
	# In a full game, the region name would depend on where the player is.
	AIManager.request_npc_generation("Dark Forest", _on_region_loaded)

func _on_region_loaded(region_data: Dictionary):
	print("WorldBuilder: Assembling region '", region_data["region_name"], "'...")
	
	if region_data.has("terrain"):
		var terrain = get_node("../TerrainGenerator")
		if terrain and terrain.has_method("generate"):
			terrain.generate(region_data["terrain"])
			
	if region_data.has("npcs"):
		for npc_data in region_data["npcs"]:
			_spawn_npc(npc_data)
			
	if region_data.has("enemies"):
		for enemy_data in region_data["enemies"]:
			_spawn_enemy(enemy_data)
			
	if region_data.has("environment_props"):
		for prop_data in region_data["environment_props"]:
			_spawn_prop(prop_data)
			
	print("WorldBuilder: Region assembly complete!")

func _spawn_npc(data: Dictionary):
	var npc_scene = load("res://scenes/NPC.tscn")
	var npc = npc_scene.instantiate()
	add_child(npc)
	
	if data.has("position"):
		var pos = data["position"]
		var terrain = get_node("../TerrainGenerator")
		var y_pos = pos["y"]
		if terrain and terrain.has_method("get_height"):
			var h = terrain.get_height(pos["x"], pos["z"])
			# Never place NPCs underwater
			if h < terrain.water_level:
				h = terrain.water_level + 1.0
			y_pos = h
		npc.global_position = Vector3(pos["x"], y_pos, pos["z"])
		
	# Initialize the NPC with its lore/stats
	npc.initialize(data)

func _spawn_enemy(data: Dictionary):
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	if data.has("position"):
		var pos = data["position"]
		var terrain = get_node("../TerrainGenerator")
		var y_pos = pos["y"]
		if terrain and terrain.has_method("get_height"):
			var h = terrain.get_height(pos["x"], pos["z"])
			if h < terrain.water_level:
				h = terrain.water_level + 1.0
			y_pos = h
		
		add_child(enemy)
		enemy.global_position = Vector3(pos["x"], y_pos, pos["z"])
	else:
		add_child(enemy)
		
	if enemy.has_method("initialize"):
		enemy.initialize(data)

func _spawn_prop(data: Dictionary):
	var type = data["type"]
	var model_path = "res://assets/models/" + type + ".gltf"
	
	if ResourceLoader.exists(model_path):
		var packed_scene = load(model_path)
		var prop = packed_scene.instantiate()
		
		if data.has("position"):
			var pos = data["position"]
			var terrain = get_node("../TerrainGenerator")
			var y_pos = pos["y"]
			var is_underwater = false
			
			if terrain and terrain.has_method("get_height"):
				var h = terrain.get_height(pos["x"], pos["z"])
				if h < terrain.water_level:
					is_underwater = true
				y_pos = h
			
			# Don't plant trees underwater!
			if is_underwater and (type.contains("Tree") or type.contains("Pine")):
				prop.free()
				return
				
			add_child(prop)
			prop.global_position = Vector3(pos["x"], y_pos, pos["z"])
			
		else:
			add_child(prop)
			
		if data.has("rotation"):
			var rot = data["rotation"]
			prop.rotation = Vector3(0, rot["y"], 0)
			
		# Make sure they cast shadows
		for child in prop.get_children():
			if child is MeshInstance3D:
				child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		push_error("WorldBuilder: Missing prop model -> " + model_path)
