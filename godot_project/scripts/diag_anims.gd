extends SceneTree

func _init():
	print("=== DIAGNOSTIC: Animation Names ===")
	
	var ladron = load("res://assets/models/ladron_rigged.glb")
	if ladron:
		var node = ladron.instantiate()
		var skel = node.find_child("Skeleton3D", true, false)
		if skel:
			print("SKELETON BONES:")
			for i in range(min(skel.get_bone_count(), 20)):
				print("Bone ", i, ": ", skel.get_bone_name(i))
		node.queue_free()
	
	print("=== END DIAGNOSTIC ===")
	quit()

func _print_anims(node: Node, label: String):
	var ap = _find_ap(node)
	if not ap:
		print(label, ": No AnimationPlayer found!")
		return
	
	print(label, " libraries: ", ap.get_animation_library_list())
	for lib_name in ap.get_animation_library_list():
		var lib = ap.get_animation_library(lib_name)
		var anims = lib.get_animation_list()
		print(label, " [", lib_name, "] (", anims.size(), " anims): ", anims)

func _find_ap(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_ap(child)
		if result:
			return result
	return null
