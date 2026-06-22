extends Node3D

func _ready():
	_build_house()

func _build_house():
	# Load models
	var wall_scene = load("res://assets/models/Wall_Plaster_Straight.gltf")
	var door_wall_scene = load("res://assets/models/Wall_Plaster_Door_Flat.gltf")
	var roof_scene = load("res://assets/models/Roof_Wooden_2x1.gltf")
	
	if not wall_scene or not door_wall_scene or not roof_scene:
		print("ModularHouse: Error loading assets")
		return
		
	# Instantiate one wall to get dimensions
	var temp_wall = wall_scene.instantiate()
	add_child(temp_wall)
	var aabb = _get_combined_aabb(temp_wall)
	
	# The size of the wall along its main axis
	var L = aabb.size.x
	var H = aabb.size.y
	temp_wall.queue_free()
	
	# Wall 1: North (Straight)
	var wall1 = wall_scene.instantiate()
	add_child(wall1)
	wall1.position = Vector3(0, 0, -L/2.0)
	
	# Wall 2: South (Straight)
	var wall2 = wall_scene.instantiate()
	add_child(wall2)
	wall2.position = Vector3(0, 0, L/2.0)
	wall2.rotation.y = PI
	
	# Wall 3: East (Straight)
	var wall3 = wall_scene.instantiate()
	add_child(wall3)
	wall3.position = Vector3(L/2.0, 0, 0)
	wall3.rotation.y = PI / 2.0
	
	# Wall 4: West (Door)
	var wall4 = door_wall_scene.instantiate()
	add_child(wall4)
	wall4.position = Vector3(-L/2.0, 0, 0)
	wall4.rotation.y = -PI / 2.0
	
	# Roof
	var roof = roof_scene.instantiate()
	add_child(roof)
	# Center the roof at the top
	roof.position = Vector3(0, H, 0)
	
	# Get roof size to scale it properly
	var roof_aabb = _get_combined_aabb(roof)
	if roof_aabb.size.x > 0 and roof_aabb.size.z > 0:
		# Add 20% overhang
		var scale_x = (L * 1.2) / roof_aabb.size.x
		var scale_z = (L * 1.2) / roof_aabb.size.z
		roof.scale = Vector3(scale_x, 1.0, scale_z)
	
	# Add a door inside the door frame
	var door_scene = load("res://assets/models/Door_1_Flat.gltf")
	if door_scene:
		var door = door_scene.instantiate()
		wall4.add_child(door)
		# The origin of the door wall might be center, so we place door at zero or slightly offset
		door.position = Vector3(0, 0, 0) 
		
	# Add a floor
	var floor_scene = load("res://assets/models/Floor_WoodDark.gltf")
	if floor_scene:
		var f = floor_scene.instantiate()
		add_child(f)
		f.position = Vector3(0, 0.05, 0)
		var f_aabb = _get_combined_aabb(f)
		if f_aabb.size.x > 0:
			var fs = L / f_aabb.size.x
			f.scale = Vector3(fs, 1.0, fs)
			
	# Generate collision for all children
	_generate_collisions(self)

func _get_combined_aabb(node: Node) -> AABB:
	var aabb = AABB()
	var first = true
	
	var meshes = []
	_find_meshes(node, meshes)
	
	for m in meshes:
		if first:
			aabb = m.get_aabb()
			first = false
		else:
			aabb = aabb.merge(m.get_aabb())
			
	return aabb

func _find_meshes(node: Node, result: Array):
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_find_meshes(child, result)

func _generate_collisions(node: Node):
	if node is MeshInstance3D:
		node.create_trimesh_collision()
	for child in node.get_children():
		_generate_collisions(child)
