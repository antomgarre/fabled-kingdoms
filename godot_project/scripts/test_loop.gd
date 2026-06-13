extends SceneTree

func _init():
	print("--- TEST LOOP ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	var pivot = enemy.get_node_or_null("Pivot")
	for child in pivot.get_children():
		if child.name != "CollisionShape3D":
			child.queue_free()
			
	var model = load("res://assets/models/AnimatedEnemy.gltf").instantiate()
	pivot.add_child(model)
	
	var root = Node.new()
	root.add_child(enemy)
	enemy._ready()
	
	var ap = enemy.animation_player
	if ap:
		var anim = ap.get_animation("Idle")
		print("Idle Loop Mode: ", anim.loop_mode)
		var anim_w = ap.get_animation("Walk")
		print("Walk Loop Mode: ", anim_w.loop_mode)
	
	print("--- END TEST LOOP ---")
	quit()
