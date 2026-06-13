@tool
extends SceneTree

func _init():
	print("Triggering asset import...")
	
	# Wait for import to finish
	var ninja_path = "res://assets/animations/mixamo/Ninja Idle.fbx"
	var rumba_path = "res://assets/animations/mixamo/Rumba Dancing.fbx"
	
	if not ResourceLoader.exists(ninja_path) or not ResourceLoader.exists(rumba_path):
		print("Waiting for Godot to recognize files...")
		
	# Load the library
	var lib_path = "res://assets/animations/EnemyAnimationLibrary.res"
	var lib = load(lib_path)
	if not lib:
		push_error("Could not load library")
		quit()
		return
		
	# Extract animations
	var files = {
		"Ninja_Idle": ninja_path,
		"Rumba_Dancing": rumba_path
	}
	
	for anim_name in files:
		var scene = load(files[anim_name])
		if scene:
			var node = scene.instantiate()
			var p = _find_ap(node)
			if p:
				var a = p.get_animation("mixamo_com")
				if a:
					a.loop_mode = Animation.LOOP_LINEAR
					lib.add_animation(anim_name, a.duplicate())
					print("Added ", anim_name)
			node.free()
			
	var err = ResourceSaver.save(lib, lib_path)
	print("Saved library: ", err == OK)
	quit()

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var r = _find_ap(c)
		if r: return r
	return null
