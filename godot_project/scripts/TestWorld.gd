extends Node3D

## TestWorld.gd — Diagnostic Sandbox.
## Added rigorous debug information to diagnose the tunneling issue instead of guessing.

var is_setup_complete: bool = false

func _ready() -> void:
	
	var world_builder = get_node_or_null("WorldBuilder")
	if world_builder:
		if not world_builder.get("is_generation_complete"):
			print("[DEBUG] TestWorld: Awaiting WorldBuilder generation...")
			await world_builder.generation_complete
		print("[DEBUG] TestWorld: WorldBuilder generation complete!")
	
	# 1. Setup Base Coordinates (Moved to 25, -25 which is the town plateau)
	var base_x = 25.0
	var base_z = -25.0
	
	var terrain = get_node_or_null("Terrain3D")
	if terrain:
		# Disable any debug grids that might cause lines on the ground
		if "debug_show_region_grid" in terrain:
			terrain.set("debug_show_region_grid", false)
		if "debug_show_grid" in terrain:
			terrain.set("debug_show_grid", false)
		if "show_grid" in terrain:
			terrain.set("show_grid", false)
		if terrain.material:
			if "show_region_grid" in terrain.material:
				terrain.material.set("show_region_grid", false)
			if "show_grid" in terrain.material:
				terrain.material.set("show_grid", false)
			
	_setup_world()

func _get_terrain_height(x: float, z: float) -> float:
	var fallback_y = 150.0
	var terrain = get_node_or_null("Terrain3D")
	if terrain and terrain.data:
		var h = terrain.data.get_height(Vector3(x, 0.0, z))
		if not is_nan(h):
			return h
	return fallback_y

func _snap_to_ground(node: Node3D, offset: float = 0.0) -> void:
	# A bulletproof method to snap any node to the terrain using a physics raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(node.global_position.x, 1000.0, node.global_position.z),
		Vector3(node.global_position.x, -1000.0, node.global_position.z)
	)
	if node is CollisionObject3D:
		query.exclude = [node.get_rid()]
	var result = space_state.intersect_ray(query)
	if result:
		node.global_position.y = result.position.y + offset
	else:
		var h = _get_terrain_height(node.global_position.x, node.global_position.z)
		node.global_position.y = h + offset

func _setup_world() -> void:
	print("\n=======================================================")
	print("[DEBUG] SETTING UP WORLD...")
	
	var terrain = get_node_or_null("Terrain3D")
	
	# Action 1: New center spawn safely at the dead center of Region (0,0) to completely hide edges
	var base_x = 512.0
	var base_z = 512.0
	var spawn_x = 505.0
	var spawn_z = 505.0
	
	# Action 5: Spawn Dialogue UI so NPCs can talk
	var dialogue_scene = load("res://scenes/DialogueUI.tscn")
	if dialogue_scene:
		var dialogue_ui = dialogue_scene.instantiate()
		dialogue_ui.name = "DialogueUI"
		add_child(dialogue_ui)
		print("[DEBUG] DialogueUI spawned.")

	# 2. Spawn HUD and DeathScreen
	var hud_scene = load("res://scenes/HUD.tscn")
	if hud_scene:
		var hud = hud_scene.instantiate()
		hud.name = "HUD"
		add_child(hud)
		print("[DEBUG] HUD spawned.")
		
	var death_scene = load("res://scenes/DeathScreen.tscn")
	if death_scene:
		var death_ui = death_scene.instantiate()
		death_ui.name = "DeathScreen"
		add_child(death_ui)
		print("[DEBUG] DeathScreen spawned.")
		
	var map_scene = load("res://scenes/WorldMap.tscn")
	if map_scene:
		var map_ui = map_scene.instantiate()
		map_ui.name = "WorldMap"
		add_child(map_ui)
		print("[DEBUG] WorldMap spawned.")
		
	if not get_node_or_null("/root/PauseMenu"):
		var pause_scene = load("res://scenes/PauseMenu.tscn")
		if pause_scene:
			var pause_ui = pause_scene.instantiate()
			pause_ui.name = "PauseMenu"
			add_child(pause_ui)
			print("[DEBUG] PauseMenu spawned locally.")
	
	# 3. Spawn Player at new center
	var player_scene = load("res://scenes/Player.tscn")
	var player = player_scene.instantiate()
	var spawn_y = _get_terrain_height(spawn_x, spawn_z)
	player.position = Vector3(spawn_x, spawn_y + 1.0, spawn_z)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(player)
	
	var camera = player.find_child("Camera3D", true, false)
	if camera and terrain and terrain.has_method("set_camera"):
		terrain.set_camera(camera)
	
	var spring_arm = player.get_node_or_null("SpringArm3D")
	if spring_arm:
		spring_arm.collision_mask = 0
		
	print("[DEBUG] Player spawned at (-300, -300), initial Y=%.2f" % player.position.y)
	
	for f in range(5):
		await get_tree().process_frame

	var actual_player_y = _get_terrain_height(base_x, base_z)
	player.global_position.y = actual_player_y + 1.0
	
	var world_builder_exists = get_node_or_null("WorldBuilder") != null
	if not world_builder_exists:
		# Action 4: Spawn NPCs
		var npc_scene = load("res://scenes/NPC.tscn")
		if npc_scene:
			# Guard
			var npc1 = npc_scene.instantiate()
			npc1.position = Vector3(base_x + 10.0, _get_terrain_height(base_x+10.0, base_z-10.0) + 1.0, base_z - 10.0)
			add_child(npc1)
			npc1.initialize({
				"name": "Guard Aldric",
				"visuals": {"base_body": "AnimatedKnight"},
				"dialogue_opening": "Stay alert. The forest grows darker."
			})
			
			# Peasant (Using fully assembled AnimatedVillager)
			var npc2 = npc_scene.instantiate()
			npc2.position = Vector3(base_x - 8.0, _get_terrain_height(base_x-8.0, base_z-5.0) + 1.0, base_z - 5.0)
			add_child(npc2)
			npc2.initialize({
				"name": "Viejo Granjero",
				"visuals": {
					"base_body": "AnimatedVillager"
				},
				"dialogue_opening": "Tiempos terribles... las cosechas se están muriendo."
			})

			# Ranger (Using fully assembled AnimatedKnight)
			var npc3 = npc_scene.instantiate()
			npc3.position = Vector3(base_x + 5.0, _get_terrain_height(base_x+5.0, base_z+12.0) + 1.0, base_z + 12.0)
			add_child(npc3)
			npc3.initialize({
				"name": "Exploradora Lyra",
				"visuals": {
					"base_body": "AnimatedKnight"
				},
				"dialogue_opening": "Vi a un enorme ladrón merodeando hacia el este."
			})
			print("[DEBUG] NPCs spawned.")

		# 5. Spawn Enemies
		var enemy_scene = load("res://scenes/Enemy.tscn")
		if enemy_scene:
			var enemy_positions = [
				Vector3(base_x - 15.0, 0.0, base_z - 15.0),
				Vector3(base_x + 15.0, 0.0, base_z + 15.0),
				Vector3(base_x - 25.0, 0.0, base_z + 25.0)
			]
			for pos in enemy_positions:
				var enemy = enemy_scene.instantiate()
				var ey = _get_terrain_height(pos.x, pos.z)
				enemy.position = Vector3(pos.x, ey + 1.0, pos.z)
				add_child(enemy)
				enemy.initialize({"id": "test_enemy", "visuals": {"base_body": "ladron_unido", "texture": "res://assets/models/ladron_unido_Color_5db537b7-96b5-441d-a5ac-d1be5831c58c.jpg", "animation_library": "res://assets/animations/EnemyAnimationLibrary.res"}, "stats": {"hp": 50, "damage": 10}})
			
			# Action 3: Spawn Thief Boss
			var boss = enemy_scene.instantiate()
			var bx = base_x + 10.0
			var bz = base_z - 5.0
			var by = _get_terrain_height(bx, bz)
			boss.position = Vector3(bx, by + 1.0, bz)
			add_child(boss)
			boss.initialize({
				"id": "thief_boss",
				"type": "ladron_unido", # Logic type
				"visuals": {
					"base_body": "ladron_unido",
					"texture": "res://assets/models/ladron_unido_Color_5db537b7-96b5-441d-a5ac-d1be5831c58c.jpg",
					"animation_library": "res://assets/animations/EnemyAnimationLibrary.res"
				},
				"stats": {"hp": 500, "damage": 40}
			})
			print("[DEBUG] Thief Boss spawned at X=%.2f, Z=%.2f." % [bx, bz])

		# 6. Spawn Campfire
		_spawn_campfire(base_x + 5.0, base_z + 5.0)
		print("[DEBUG] Campfire spawned.")
		
	# Spawn Water Plane (always spawn this)
	var water = MeshInstance3D.new()
	water.name = "WaterPlane"
	var plane = BoxMesh.new()
	plane.size = Vector3(2048, 10.0, 2048)
	water.mesh = plane
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.1, 0.6, 0.9, 0.85) # Brighter, more opaque blue
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.cull_mode = BaseMaterial3D.CULL_DISABLED # Ensure visible from both sides
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.0, 0.3, 0.6)
	water_mat.roughness = 0.05
	water_mat.metallic = 0.1
	water.material_override = water_mat
	
	var water_y = _get_terrain_height(512.0, 512.0)
	water.position = Vector3(0, water_y - 6.5, 0) # Top surface is at water_y - 1.5. Center is 5m down.
	add_child(water)
	print("[DEBUG] Water plane spawned.")
	
	# 7. Spawn Forest
	_generate_forest()
	
	# 8. Spawn Animals
	_generate_animals()
	
	# 9. Spawn Creatures (Bugs, Rats, etc)
	_generate_creatures()
	
	# Disable physics for everyone so they don't fall through the floor while Terrain3D loads
	for child in get_children():
		if child is CharacterBody3D:
			child.process_mode = Node.PROCESS_MODE_DISABLED
			
	# Wait for Terrain3D async physics collision generation to fully initialize
	print("[DEBUG] Waiting for Terrain3D collision to build...")
	await get_tree().create_timer(3.0).timeout
	
	_snap_all_recursive(self)
	
	# Re-enable physics for everyone
	for child in get_children():
		if child is CharacterBody3D:
			child.process_mode = Node.PROCESS_MODE_INHERIT
			
	print("[DEBUG] WORLD SETUP COMPLETE. Everyone snapped to ground.")
	print("=======================================================\n")
	is_setup_complete = true

func _snap_all_recursive(node: Node) -> void:
	# --- Group-based snap: all spawnable WorldBuilder objects register themselves ---
	# in the "snappable" group. We iterate the group and snap using Terrain3D math.
	var terrain = get_node_or_null("Terrain3D")
	
	for snap_node in get_tree().get_nodes_in_group("snappable"):
		if not is_instance_valid(snap_node):
			continue
		if not snap_node is Node3D:
			continue
		var pos = snap_node.global_position
		var ground_y: float = 0.0
		if terrain and terrain.data:
			var h = terrain.data.get_height(Vector3(pos.x, 0.0, pos.z))
			if not is_nan(h):
				ground_y = h
			else:
				ground_y = _get_terrain_height(pos.x, pos.z)
		else:
			ground_y = _get_terrain_height(pos.x, pos.z)
		
		# CharacterBody3D: snap and let physics take over
		if snap_node is CharacterBody3D:
			snap_node.global_position.y = ground_y + 0.1
		else:
			# Props / houses / trees — sit exactly on the ground
			snap_node.global_position.y = ground_y
	
	# Also snap trees/campfires spawned directly under TestWorld (not in WorldBuilder)
	for child in get_children():
		if child.name.begins_with("PineTree") or child.name.begins_with("Tree") or child.name.begins_with("Campfire_TW"):
			if child is Node3D:
				_snap_to_ground(child, 0.0)

func _spawn_campfire(pos_x: float, pos_z: float) -> void:
	var campfire = Node3D.new()
	campfire.name = "Campfire"
	add_child(campfire)
	
	var y_pos = _get_terrain_height(pos_x, pos_z)
	campfire.global_position = Vector3(pos_x, y_pos, pos_z)
	
	# Materials
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
	
	# Light
	var light = OmniLight3D.new()
	light.name = "OmniLight3D"
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
	
	# Particles
	var particles = GPUParticles3D.new()
	particles.name = "GPUParticles3D"
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
	
	# Wood pile
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
	
	# Rock ring
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
		rock.position = Vector3(sin(ang) * 1.5, 0.05, cos(ang) * 1.5)
		campfire.add_child(rock)
	print("[DEBUG] Programmatic Campfire spawned at (5.0, %.2f, 5.0)" % y_pos)

func _generate_forest() -> void:
	print("[DEBUG] Generating forest...")
	
	var tree_paths = [
		"res://assets/models/nature/Pine_1.gltf",
		"res://assets/models/nature/Pine_2.gltf",
		"res://assets/models/nature/CommonTree_1.gltf",
		"res://assets/models/nature/CommonTree_2.gltf",
		"res://assets/models/nature2/BirchTree_1.gltf"
	]
	
	var prop_paths = [
		"res://assets/models/nature/Rock_Medium_1.gltf",
		"res://assets/models/nature/Rock_Medium_2.gltf",
		"res://assets/models/nature2/Bush_Large.gltf"
	]
	
	var tree_scenes = []
	var prop_scenes = []
	
	for path in tree_paths:
		if ResourceLoader.exists(path):
			tree_scenes.append(load(path))
			
	for path in prop_paths:
		if ResourceLoader.exists(path):
			prop_scenes.append(load(path))
			
	if tree_scenes.size() == 0:
		print("[DEBUG] No high-quality tree models found!")
		return
		
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var forest_node = Node3D.new()
	forest_node.name = "Forest"
	add_child(forest_node)
	
	# Generate 300 trees (reduced for FPS)
	for i in range(300):
		var rx = rng.randf_range(0.0, 1000.0)
		var rz = rng.randf_range(0.0, 1000.0)
		
		if Vector2(rx, rz).distance_to(Vector2(512.0, 512.0)) < 40.0:
			continue
			
		var tree = tree_scenes[rng.randi() % tree_scenes.size()].instantiate()
		var ty = _get_terrain_height(rx, rz)
		if ty < 0.5:
			continue # Don't spawn in water
		tree.position = Vector3(rx, ty, rz)
		
		var scale_val = rng.randf_range(0.8, 1.5)
		tree.scale = Vector3(scale_val, scale_val, scale_val)
		tree.rotation.y = rng.randf_range(0, 2*PI)
		
		_enable_shadows(tree)
		forest_node.add_child(tree)
		
	# Generate 100 rocks/bushes (reduced for FPS)
	for i in range(100):
		var rx = rng.randf_range(0.0, 1000.0)
		var rz = rng.randf_range(0.0, 1000.0)
		
		if Vector2(rx, rz).distance_to(Vector2(512.0, 512.0)) < 25.0:
			continue
			
		var prop = prop_scenes[rng.randi() % prop_scenes.size()].instantiate()
		var ty = _get_terrain_height(rx, rz)
		if ty < 0.5:
			continue # Don't spawn in water
		prop.position = Vector3(rx, ty, rz)
		
		var scale_val = rng.randf_range(0.8, 2.0)
		prop.scale = Vector3(scale_val, scale_val, scale_val)
		prop.rotation.y = rng.randf_range(0, 2*PI)
		
		# No shadows for small props to save FPS
		forest_node.add_child(prop)
		
	print("[DEBUG] Planted 300 trees and 100 nature props.")

func _generate_animals() -> void:
	print("[DEBUG] Spawning animals...")
	
	var animal_models = [
		"Deer", "Stag", "Fox", "Wolf", "Cow", "Horse"
	]
	var animal_scenes = []
	for name in animal_models:
		var path = "res://assets/models/animals/" + name + ".gltf"
		if ResourceLoader.exists(path):
			animal_scenes.append(load(path))
			
	if animal_scenes.size() == 0:
		print("[DEBUG] No animal models found.")
		return
		
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var animals_node = Node3D.new()
	animals_node.name = "Animals"
	add_child(animals_node)
	
	for i in range(15):
		var rx = rng.randf_range(50.0, 950.0)
		var rz = rng.randf_range(50.0, 950.0)
		
		# Keep away from town center
		if Vector2(rx, rz).distance_to(Vector2(512.0, 512.0)) < 60.0:
			continue
			
		var animal = animal_scenes[rng.randi() % animal_scenes.size()].instantiate()
		var ty = _get_terrain_height(rx, rz)
		if ty < 0.5:
			continue # Don't spawn in water
		animal.position = Vector3(rx, ty, rz)
		animal.rotation.y = rng.randf_range(0, 2*PI)
		
		# No shadows for animals to improve FPS
		
		# Adding them to the snappable group so they stay on the ground
		animal.add_to_group("snappable")
		animals_node.add_child(animal)
		
	print("[DEBUG] Spawned 15 ambient animals.")

func _generate_creatures() -> void:
	print("[DEBUG] Spawning creatures...")
	
	var creature_models = [
		"Rat", "Spider", "Snake", "Frog"
	]
	var creature_scenes = []
	for name in creature_models:
		var path = "res://assets/models/creatures/" + name + ".fbx"
		if ResourceLoader.exists(path):
			creature_scenes.append(load(path))
			
	if creature_scenes.size() == 0:
		print("[DEBUG] No creature models found.")
		return
		
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var creatures_node = Node3D.new()
	creatures_node.name = "Creatures"
	add_child(creatures_node)
	
	for i in range(20):
		var rx = rng.randf_range(50.0, 950.0)
		var rz = rng.randf_range(50.0, 950.0)
		
		var creature = creature_scenes[rng.randi() % creature_scenes.size()].instantiate()
		var ty = _get_terrain_height(rx, rz)
		if ty < 0.5:
			continue # Don't spawn in water
		creature.position = Vector3(rx, ty, rz)
		creature.rotation.y = rng.randf_range(0, 2*PI)
		
		# Scale down bugs and rats
		var scale_val = rng.randf_range(0.3, 0.6)
		creature.scale = Vector3(scale_val, scale_val, scale_val)
		
		# No shadows for small creatures to improve FPS
		creature.add_to_group("snappable")
		creatures_node.add_child(creature)
		
	print("[DEBUG] Spawned 20 ambient creatures.")

func _enable_shadows(node: Node) -> void:
	if node is MeshInstance3D:
		# Use OFF or SHADOW_CASTING_SETTING_ON. Since this kills FPS on HTML5, let's turn off for most things, or keep it light.
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Add collision so you can't walk through trees
		if "tree" in node.get_parent().name.to_lower() or "pine" in node.get_parent().name.to_lower():
			node.create_trimesh_collision()
	for child in node.get_children():
		_enable_shadows(child)

func _perform_raycast_diagnostics(player: CharacterBody3D) -> void:
	var space_state = get_world_3d().direct_space_state
	# Cast a ray from high in the sky (Y=100) down to deep underground (Y=-100)
	var query = PhysicsRayQueryParameters3D.create(
		Vector3(0, 100, 0), 
		Vector3(0, -100, 0)
	)
	# Use the player's exact collision mask
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result["collider"]
		print("[DEBUG-RAYCAST] Raycast hit object: ", collider.name, " (", collider.get_class(), ") at Y=%.2f" % result["position"].y)
	else:
		print("[DEBUG-RAYCAST] Raycast hit NOTHING. Physics engine sees NO ground at XZ=50,50 on mask ", player.collision_mask)

func _process(delta: float) -> void:
	if InputMap.has_action("p2_join") and Input.is_action_just_pressed("p2_join"):
		_spawn_invader()

func _spawn_invader():
	var player = get_node_or_null("Player")
	if not player:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_dist = 30.0 # Max range to possess
	
	for e in enemies:
		if e.get("is_dead") or e.get("is_invader"):
			continue
			
		var dist = player.global_position.distance_to(e.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = e
			
	if closest_enemy:
		if closest_enemy.has_method("become_invader"):
			closest_enemy.become_invader(1) # device_id 1 (Gamepad 1)
			
			var hud = get_node_or_null("HUD")
			if hud and hud.has_method("show_message"):
				hud.show_message("¡UN INVASOR HA TOMADO EL CONTROL!", 4.0)
			else:
				# Spawn a giant floating text
				var label = Label3D.new()
				label.text = "¡UN INVASOR HA TOMADO EL CONTROL!"
				label.modulate = Color(1.0, 0.0, 0.0)
				label.font_size = 64
				label.outline_size = 4
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.no_depth_test = true
				add_child(label)
				label.global_position = player.global_position + Vector3(0, 3.0, 0)
				
				var tween = create_tween()
				tween.tween_property(label, "global_position:y", player.global_position.y + 6.0, 4.0)
				tween.parallel().tween_property(label, "modulate:a", 0.0, 4.0)
				tween.tween_callback(label.queue_free)
