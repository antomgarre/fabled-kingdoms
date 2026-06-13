extends SceneTree

func _init():
	print("=== DIAGNOSTIC: Animation Names ===")
	
	var models = [
		"res://assets/models/UAL1_Standard.glb",
		"res://assets/models/UAL2_Standard.glb",
		"res://assets/models/Superhero_Male_FullBody.glb",
		"res://assets/models/AnimatedEnemy.gltf",
		"res://assets/models/AnimatedKnight.gltf",
		"res://assets/models/AnimatedVillager.gltf",
		"res://assets/animations/EnemyAnimationLibrary.res"
	]
	
	for path in models:
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is AnimationLibrary:
				print("\n--- ", path, " ---")
				print(res.get_animation_list())
			else:
				var scene = res.instantiate()
				var p = _find_anim_player(scene)
				print("\n--- ", path, " ---")
				if p:
					for lib_name in p.get_animation_library_list():
						var lib = p.get_animation_library(lib_name)
						print("Library '", lib_name, "': ", lib.get_animation_list())
				else:
					print("No AnimationPlayer found.")
					
	print("=== END DIAGNOSTIC ===")
	quit()

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var r = _find_anim_player(child)
		if r:
			return r
	return null
