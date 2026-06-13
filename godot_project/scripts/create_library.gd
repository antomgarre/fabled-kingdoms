extends SceneTree

func _init():
	var scene = load("res://assets/models/AnimatedVillager.gltf").instantiate()
	var ap = _find_ap(scene)
	if ap:
		var lib = ap.get_animation_library("")
		if lib:
			ResourceSaver.save(lib, "res://assets/animations/VillagerLibrary.res")
			print("Saved VillagerLibrary.res!")
		else:
			print("No default library found.")
	else:
		print("No AP found.")
	quit()

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var r = _find_ap(c)
		if r: return r
	return null
