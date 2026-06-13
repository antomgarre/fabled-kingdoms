extends CharacterBody3D

@onready var pivot = $Pivot

var npc_data: Dictionary = {}
var animation_player: AnimationPlayer

var current_state = "idle"
var speed: float = 2.0
var max_health = 100
var current_health = 100

var player: Node3D

func _ready():
	# Find player for distance checking
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func initialize(data: Dictionary):
	npc_data = data
	print("NPC Spawning: ", data["name"], " the ", data["role"])
	
	speed = data["stats"]["speed"]
	max_health = data["stats"]["health"]
	current_health = max_health
	
	_assemble_visuals(data["visuals"])

func _assemble_visuals(visuals: Dictionary):
	var base_name = visuals["base_body"]
	
	# Try loading: .gltf first, then .fbx, then .glb
	var base_scene = null
	var loaded_ext = ""
	for ext in [".gltf", ".fbx", ".glb"]:
		var path = "res://assets/models/" + base_name + ext
		if ResourceLoader.exists(path):
			base_scene = load(path)
			if base_scene:
				loaded_ext = ext
				print("  NPC model loaded: ", path)
				break
	
	if not base_scene:
		push_error("NPC Base body not found for: " + base_name)
		return
		
	# Remove old baked-in models like the mannequin
	for child in pivot.get_children():
		child.queue_free()
		
	var base_model = base_scene.instantiate()
	pivot.add_child(base_model)
	
	# The Mixamo FBX imports with mesh data at 1cm scale (0.01). 
	# We need to scale it up 100x to make it human-sized (1 meter = 1 unit).
	if base_name == "ladron_unido":
		base_model.scale = Vector3(200.0, 200.0, 200.0)
		print("  Scaled ladron_unido up by 200x")
	else:
		print("  Model scale: ", base_model.scale, " ext: ", loaded_ext)
	
	# Find the built-in AnimationPlayer
	animation_player = _find_animation_player(base_model)
	if not animation_player:
		animation_player = AnimationPlayer.new()
		base_model.add_child(animation_player)
	
	print("  AnimationPlayer available: ", animation_player != null)
	
	if animation_player:
		for anim_name in animation_player.get_animation_list():
			var lower_name = anim_name.to_lower()
			if "idle" in lower_name or "walk" in lower_name or "run" in lower_name:
				var anim = animation_player.get_animation(anim_name)
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
	
	# For Mixamo-rigged models (like ladron_unido), load the animation library
	if visuals.has("animation_library") and visuals["animation_library"] != "":
		var lib_path = visuals["animation_library"]
		if ResourceLoader.exists(lib_path):
			var lib = load(lib_path)
			if lib and animation_player:
				# Replace the default library with our custom one
				if animation_player.has_animation_library(""):
					animation_player.remove_animation_library("")
				animation_player.add_animation_library("", lib)
				print("  Animation library loaded with ", lib.get_animation_list().size(), " anims")
	
	# Apply custom texture if specified
	if visuals.has("texture") and visuals["texture"] != "":
		var tex_path = visuals["texture"]
		if ResourceLoader.exists(tex_path):
			var tex = load(tex_path)
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = tex
			mat.roughness = 0.8
			var meshes = []
			_find_meshes(base_model, meshes)
			for m in meshes:
				for i in range(m.mesh.get_surface_count()):
					m.set_surface_override_material(i, mat)
			print("  Custom texture applied: ", tex_path)
	
	# Pick initial idle animation
	var idle_anim = "Idle"
	if visuals.has("idle_animation") and visuals["idle_animation"] != "":
		idle_anim = visuals["idle_animation"]
	elif visuals.has("idle_animations") and visuals["idle_animations"].size() > 0:
		idle_anim = visuals["idle_animations"][0]
		
	# Many standard GLB models have animations ending in _Loop that godot renames,
	# but some don't. Try common names if "Idle" fails.
	if animation_player:
		if animation_player.has_animation(idle_anim):
			animation_player.play(idle_anim)
		elif animation_player.has_animation("Idle_Loop"):
			animation_player.play("Idle_Loop")
		elif animation_player.has_animation("Idle"):
			animation_player.play("Idle")
			
	# Face the center of the town (approx 26, 0, -25)
	var town_center = Vector3(26.0, global_position.y, -25.0)
	var dir = global_position.direction_to(town_center)
	dir.y = 0
	if dir.length_squared() > 0.001:
		rotation.y = atan2(dir.x, dir.z)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null

func _find_meshes(node: Node, meshes: Array):
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		_find_meshes(child, meshes)

var idle_timer = 0.0
var idle_state = 0 # 0 = basic idle, 1 = special idle
var current_special_anim = ""

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	if npc_data.is_empty():
		return # Still loading
		
	if animation_player:
		var horizontal_vel = Vector2(velocity.x, velocity.z)
		if horizontal_vel.length() > 0.1:
			if animation_player.has_animation("Walk"):
				animation_player.play("Walk")
			idle_timer = 0.0
		else:
			idle_timer += delta
			
			var has_anim_array = npc_data.has("visuals") and npc_data["visuals"].has("idle_animations")
			
			# Cycle every 6 seconds
			if idle_timer > 6.0:
				idle_timer = 0.0
				idle_state = 1 - idle_state # Toggle between basic (0) and special (1)
				
				# If we just switched to special state and have an array of animations, pick one at random
				if idle_state == 1:
					var anim_array = ["Idle_Talking", "Idle_FoldArms", "Idle_No", "Yes", "Sitting_Idle"]
					if has_anim_array:
						anim_array = npc_data["visuals"]["idle_animations"]
					var random_idx = randi() % anim_array.size()
					current_special_anim = anim_array[random_idx]
				
			var target_anim = "Idle"
			if not animation_player.has_animation("Idle") and animation_player.has_animation("Idle_Loop"):
				target_anim = "Idle_Loop" # Fallback for some models
				
			if idle_state == 1:
				if current_special_anim != "" and animation_player.has_animation(current_special_anim):
					target_anim = current_special_anim
				elif npc_data.has("visuals") and npc_data["visuals"].has("idle_animation") and npc_data["visuals"]["idle_animation"] != "":
					var special_anim = npc_data["visuals"]["idle_animation"]
					if animation_player.has_animation(special_anim):
						target_anim = special_anim
				
			if animation_player.current_animation != target_anim and animation_player.has_animation(target_anim):
				animation_player.play(target_anim)
				
	move_and_slide()
