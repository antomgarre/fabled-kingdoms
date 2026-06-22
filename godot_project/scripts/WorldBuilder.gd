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
			
	_spawn_town_campfire()
			
	print("WorldBuilder: Region assembly complete!")

func _spawn_town_campfire():
	var campfire = Node3D.new()
	add_child(campfire)
	
	var terrain = get_node("../TerrainGenerator")
	var y_pos = 0.0
	if terrain and terrain.has_method("get_height"):
		y_pos = terrain.get_height(25.0, -25.0)
	campfire.global_position = Vector3(25.0, y_pos + 0.5, -25.0)
	
	# Light
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.omni_range = 25.0
	light.light_energy = 2.0
	light.shadow_enabled = true
	campfire.add_child(light)
	
	# Fire Particles
	var particles = GPUParticles3D.new()
	particles.amount = 30
	particles.lifetime = 1.0
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.0)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	mesh.radial_segments = 4
	mesh.rings = 4
	mesh.material = mat
	particles.draw_pass_1 = mesh
	
	var proc = ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = 0.4
	proc.direction = Vector3(0, 1, 0)
	proc.spread = 15.0
	proc.initial_velocity_min = 1.0
	proc.initial_velocity_max = 2.0
	proc.gravity = Vector3(0, 0, 0)
	
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	var curve_tex = CurveTexture.new()
	curve_tex.curve = curve
	proc.scale_curve = curve_tex
	
	particles.process_material = proc
	campfire.add_child(particles)
	
	# Simple flicker script
	var script = GDScript.new()
	script.source_code = "extends OmniLight3D\nvar time=0.0\nfunc _process(delta):\n\ttime+=delta*15.0\n\tlight_energy = 2.0 + sin(time)*0.3 + cos(time*1.7)*0.2\n"
	script.reload()
	light.set_script(script)
	light.set_process(true)

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
