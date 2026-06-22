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
	campfire.name = "Campfire"
	add_child(campfire)
	
	var terrain = get_node("../TerrainGenerator")
	var y_pos = 0.0
	if terrain and terrain.has_method("get_height"):
		y_pos = terrain.get_height(25.0, -25.0)
	campfire.global_position = Vector3(25.0, y_pos, -25.0)
	
	# --- Shared materials ---
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.38, 0.34, 0.30)
	rock_mat.roughness = 1.0
	
	var log_mat = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.28, 0.18, 0.10)
	log_mat.roughness = 1.0
	
	var ember_mat = StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.4, 0.0)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.3, 0.0)
	ember_mat.emission_energy_multiplier = 3.0
	ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# --- Flickering orange light ---
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.omni_range = 30.0
	light.light_energy = 2.0
	light.shadow_enabled = true
	light.position = Vector3(0, 1.0, 0)
	campfire.add_child(light)
	var flicker = GDScript.new()
	flicker.source_code = "extends OmniLight3D\nvar t=0.0\nfunc _process(d):\n\tt+=d*12.0\n\tlight_energy=2.0+sin(t)*0.4+cos(t*1.9)*0.25\n"
	flicker.reload()
	light.set_script(flicker)
	
	# --- Fire particles ---
	var particles = GPUParticles3D.new()
	particles.amount = 25
	particles.lifetime = 1.2
	particles.position = Vector3(0, 0.3, 0)
	var fire_mesh = SphereMesh.new()
	fire_mesh.radius = 0.12
	fire_mesh.height = 0.24
	fire_mesh.radial_segments = 4
	fire_mesh.rings = 3
	fire_mesh.material = ember_mat
	particles.draw_pass_1 = fire_mesh
	var proc = ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = 0.35
	proc.direction = Vector3(0, 1, 0)
	proc.spread = 12.0
	proc.initial_velocity_min = 1.2
	proc.initial_velocity_max = 2.5
	proc.gravity = Vector3(0, 0.2, 0)
	var fcurve = Curve.new()
	fcurve.add_point(Vector2(0, 1))
	fcurve.add_point(Vector2(1, 0))
	var fct = CurveTexture.new()
	fct.curve = fcurve
	proc.scale_curve = fct
	particles.process_material = proc
	campfire.add_child(particles)
	
	# --- Wood pile at center (inside rock ring) ---
	for i in range(2):
		var wood = MeshInstance3D.new()
		var wm = CylinderMesh.new()
		wm.top_radius = 0.08
		wm.bottom_radius = 0.10
		wm.height = 1.3
		wm.material = log_mat
		wood.mesh = wm
		wood.position = Vector3(0, 0.0, 0)
		wood.rotation = Vector3(deg_to_rad(35.0), i * PI * 0.5, 0.0)
		campfire.add_child(wood)
	
	# --- Rock ring at radius 3m ---
	var rock_angles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
	for ang_deg in rock_angles:
		var ang = deg_to_rad(ang_deg)
		var rock = MeshInstance3D.new()
		var rm = SphereMesh.new()
		rm.radius = randf_range(0.20, 0.35)
		rm.height = randf_range(0.25, 0.45)
		rm.radial_segments = 6
		rm.rings = 4
		rm.material = rock_mat
		rock.mesh = rm
		rock.position = Vector3(sin(ang) * 3.0, -0.15, cos(ang) * 3.0)
		campfire.add_child(rock)
	
	# --- Log seats at radius 8m, facing the fire ---
	var seat_angles_deg = [0.0, 120.0, 240.0]
	for ang_deg in seat_angles_deg:
		var ang = deg_to_rad(ang_deg)
		var seat = MeshInstance3D.new()
		var sm = CylinderMesh.new()
		sm.top_radius = 0.25
		sm.bottom_radius = 0.25
		sm.height = 2.0
		sm.material = log_mat
		seat.mesh = sm
		seat.position = Vector3(sin(ang) * 8.0, 0.0, cos(ang) * 8.0)
		# Lie the log down tangentially (like a bench facing fire)
		seat.rotation = Vector3(0, ang + PI * 0.5, PI * 0.5)
		campfire.add_child(seat)

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
	
	var prop: Node3D
	
	if type == "ModularHouse":
		var script = load("res://scripts/ModularHouse.gd")
		prop = Node3D.new()
		prop.set_script(script)
	else:
		var model_path = "res://assets/models/" + type + ".gltf"
		if ResourceLoader.exists(model_path):
			var packed_scene = load(model_path)
			prop = packed_scene.instantiate()
		else:
			push_error("WorldBuilder: Missing prop model -> " + model_path)
			return
			
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
			
			if data.has("scale"):
				var sc = data["scale"]
				prop.scale = Vector3(sc, sc, sc)
			
			_setup_prop_meshes(prop)
	else:
		push_error("WorldBuilder: Missing prop model -> " + model_path)

func _setup_prop_meshes(node: Node):
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# Generate static collision so players can't walk through houses/props
		node.create_trimesh_collision()
	
	for child in node.get_children():
		_setup_prop_meshes(child)
