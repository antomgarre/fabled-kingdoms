@tool
extends SceneTree

func _init():
	# Test loading ladron_unido with different extensions
	for ext in [".gltf", ".fbx", ".glb"]:
		var path = "res://assets/models/ladron_unido" + ext
		var exists = ResourceLoader.exists(path)
		print(ext, " -> exists=", exists)
		if exists:
			var scene = load(path)
			if scene:
				var node = scene.instantiate()
				print("  Loaded OK. Children: ")
				for child in node.get_children():
					print("    ", child.get_class(), " [", child.name, "]")
					if child is Skeleton3D:
						print("      Bones: ", child.get_bone_count())
					if child is AnimationPlayer:
						print("      Anims: ", child.get_animation_list())
					for sub in child.get_children():
						print("      ", sub.get_class(), " [", sub.name, "]")
						if sub is MeshInstance3D:
							print("        Surfaces: ", sub.mesh.get_surface_count())
				node.free()
			else:
				print("  FAILED to load scene")
	
	# Test the animation library
	var lib_path = "res://assets/animations/EnemyAnimationLibrary.res"
	if ResourceLoader.exists(lib_path):
		var lib = load(lib_path)
		print("\nAnimation Library anims: ", lib.get_animation_list())
	
	quit()
