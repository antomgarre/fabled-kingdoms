extends Node3D

func _ready():
	_build_house()

func _build_house():
	var wall_straight = load("res://assets/models/Wall_Plaster_Straight.gltf")
	var wall_door = load("res://assets/models/Wall_Plaster_Door_Flat.gltf")
	var wall_window = load("res://assets/models/Wall_Plaster_Window_Wide_Flat.gltf")
	var roof_scene = load("res://assets/models/Roof_RoundTiles_4x4.gltf")
	var floor_scene = load("res://assets/models/Floor_WoodDark.gltf")
	var door_scene = load("res://assets/models/Door_1_Flat.gltf")
	
	if not wall_straight or not roof_scene:
		push_error("ModularHouse: Missing fundamental assets")
		return

	var H = 3.0 # Height of walls
	
	# === FRONT WALLS (Z = 2.0) ===
	_spawn_piece(wall_door, Vector3(-1.0, 0, 2.0), 0)
	_spawn_piece(wall_window, Vector3(1.0, 0, 2.0), 0)
	
	# Door
	if door_scene:
		_spawn_piece(door_scene, Vector3(-1.0, 0, 2.0), 0)
		
	# === BACK WALLS (Z = -2.0) ===
	_spawn_piece(wall_straight, Vector3(-1.0, 0, -2.0), PI)
	_spawn_piece(wall_straight, Vector3(1.0, 0, -2.0), PI)
	
	# === LEFT WALLS (X = -2.0) ===
	_spawn_piece(wall_straight, Vector3(-2.0, 0, 1.0), -PI/2.0)
	_spawn_piece(wall_straight, Vector3(-2.0, 0, -1.0), -PI/2.0)
	
	# === RIGHT WALLS (X = 2.0) ===
	_spawn_piece(wall_straight, Vector3(2.0, 0, 1.0), PI/2.0)
	_spawn_piece(wall_straight, Vector3(2.0, 0, -1.0), PI/2.0)
	
	# === FLOORS ===
	if floor_scene:
		_spawn_piece(floor_scene, Vector3(-1.0, 0.05, 1.0), 0)
		_spawn_piece(floor_scene, Vector3(1.0, 0.05, 1.0), 0)
		_spawn_piece(floor_scene, Vector3(-1.0, 0.05, -1.0), 0)
		_spawn_piece(floor_scene, Vector3(1.0, 0.05, -1.0), 0)
		
	# === ROOF ===
	if roof_scene:
		# The roof is 4x4 tiles (probably 8x8 meters), or maybe 4x4 meters.
		# Usually roof origin is center bottom.
		var r = roof_scene.instantiate()
		add_child(r)
		r.position = Vector3(0, H, 0)
		# We don't scale it yet, let's see how it fits at scale 1.0
		
	_generate_collisions(self)

func _spawn_piece(scene: PackedScene, pos: Vector3, rot_y: float):
	if not scene: return
	var instance = scene.instantiate()
	add_child(instance)
	instance.position = pos
	instance.rotation.y = rot_y

func _generate_collisions(node: Node):
	if node is MeshInstance3D:
		node.create_trimesh_collision()
	for child in node.get_children():
		_generate_collisions(child)
