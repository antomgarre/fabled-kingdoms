extends SceneTree

func _init():
	var scene = load("res://assets/models/Female_Ranger.gltf")
	if not scene:
		print("Failed to load Female_Peasant.gltf")
		quit()
		return
		
	var node = scene.instantiate()
	print("--- Female_Peasant.gltf Nodes ---")
	_print_tree(node, "")
	quit()

func _print_tree(n: Node, indent: String):
	print(indent + n.name + " [" + n.get_class() + "]")
	if n is MeshInstance3D:
		var mesh = n.mesh
		if mesh:
			print(indent + "  Mesh surfaces: ", mesh.get_surface_count())
	for c in n.get_children():
		_print_tree(c, indent + "  ")
