extends SceneTree

func _init():
	print("--- TEST ENEMY ANIM ---")
	var enemy_scene = load("res://scenes/Enemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Emulate WorldBuilder
	var pivot = enemy.get_node_or_null("Pivot")
	for child in pivot.get_children():
		if child.name != "CollisionShape3D":
			child.queue_free()
			
	var model = load("res://assets/models/AnimatedEnemy.gltf").instantiate()
	pivot.add_child(model)
	
	var root = Node.new()
	root.add_child(enemy)
	
	# Call _ready manually if needed, or just let Godot call it
	enemy._ready()
	
	print("Enemy Animation Player: ", enemy.animation_player)
	if enemy.animation_player:
		print("Has Walk: ", enemy.animation_player.has_animation("Walk"))
		enemy._play_anim("Walk")
		print("Current Anim after play: ", enemy.animation_player.current_animation)
	
	print("--- TEST END ---")
	quit()
