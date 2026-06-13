extends SceneTree

func _init():
	var scene = load("res://assets/models/Superhero_Male_FullBody.gltf").instantiate()
	var ap = AnimationPlayer.new()
	scene.add_child(ap)
	
	var lib = load("res://assets/animations/VillagerLibrary.res")
	ap.add_animation_library("", lib)
	
	# Try to play Idle
	if ap.has_animation("Idle"):
		print("Has Idle")
	quit()
