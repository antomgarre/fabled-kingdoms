@tool
extends SceneTree

func _init():
	for ext in [".fbx", ".glb"]:
		var path = "res://assets/models/ladron_unido" + ext
		if ResourceLoader.exists(path):
			var scene = load(path)
			var node = scene.instantiate()
			print("\n--- ", path, " ---")
			print("Root scale: ", node.scale)
			var meshes = []
			_find_meshes(node, meshes)
			for m in meshes:
				var aabb = m.get_aabb()
				print("Mesh: ", m.name)
				print("  AABB position: ", aabb.position)
				print("  AABB size: ", aabb.size)
				print("  AABB volume: ", aabb.volume())
			node.free()
	quit()

func _find_meshes(node: Node, meshes: Array):
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		_find_meshes(child, meshes)
