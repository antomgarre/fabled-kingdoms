@tool
extends SceneTree

func _init():
	var lib = AnimationLibrary.new()
	var anims_to_rename = {
		"mutant idle": "Idle",
		"mutant walking": "Walk",
		"mutant run": "Run",
		"mutant swiping": "Sword_Slash",
		"mutant roaring": "HitRecieve",
		"mutant dying": "Death"
	}
	
	var dir = DirAccess.open("res://assets/animations/mixamo/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".fbx"):
				var path = "res://assets/animations/mixamo/" + file_name
				var scene = load(path)
				if scene:
					var node = scene.instantiate()
					var ap = _find_animation_player(node)
					if ap:
						for anim_name in ap.get_animation_list():
							var anim = ap.get_animation(anim_name).duplicate()
							var base_name = file_name.replace(".fbx", "")
							var final_name = base_name
							if anims_to_rename.has(base_name):
								final_name = anims_to_rename[base_name]
							lib.add_animation(final_name, anim)
							print("Added animation: ", final_name)
					node.queue_free()
			file_name = dir.get_next()
			
	var err = ResourceSaver.save(lib, "res://assets/animations/EnemyAnimationLibrary.res")
	if err == OK:
		print("Successfully saved EnemyAnimationLibrary.res")
	else:
		print("Error saving library: ", err)
	quit()

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null
