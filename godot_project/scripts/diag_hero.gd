extends SceneTree

func _init():
	var scene = load("res://assets/models/Superhero_Male_FullBody.gltf")
	if not scene: quit()
	var node = scene.instantiate()
	print("--- Superhero Nodes ---")
	_print_tree(node, "")
	quit()

func _print_tree(n: Node, indent: String):
	print(indent + n.name + " [" + n.get_class() + "]")
	for c in n.get_children():
		_print_tree(c, indent + "  ")
