extends Area3D

var time_passed = 0.0
var mesh_instance: MeshInstance3D

func _ready():
	# 1. CollisionShape3D
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.5
	collision.shape = shape
	add_child(collision)
	
	# 2. MeshInstance3D
	mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3
	sphere_mesh.height = 0.6
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.84, 0.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.84, 0.0)
	material.emission_energy_multiplier = 2.0
	sphere_mesh.material = material
	
	mesh_instance.mesh = sphere_mesh
	add_child(mesh_instance)
	
	# 3. Light3D
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.2)
	light.light_energy = 0.5
	light.omni_range = 5.0
	add_child(light)
	
	# Connect signal
	body_entered.connect(_on_body_entered)

func _process(delta):
	time_passed += delta
	if mesh_instance:
		mesh_instance.position.y = sin(time_passed * 3.0) * 0.2
		mesh_instance.rotation.y += delta * 2.0

func _on_body_entered(body):
	if body.name == "Player":
		# 1. Play sound
		var audio = AudioStreamPlayer.new()
		audio.stream = load("res://assets/sounds/handleCoins.ogg")
		get_tree().current_scene.add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
		
		# 2. Floating text
		var label = Label3D.new()
		label.text = "+10 XP"
		label.pixel_size = 0.02
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(1, 0.84, 0)
		label.global_position = global_position + Vector3(0, 1, 0)
		get_tree().current_scene.add_child(label)
		
		var tween = label.create_tween()
		tween.tween_property(label, "global_position:y", label.global_position.y + 2.0, 1.5)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
		tween.parallel().tween_property(label, "outline_modulate:a", 0.0, 1.5)
		tween.tween_callback(label.queue_free)
		
		# 3. Add progress
		var qm = get_node_or_null("/root/Main/QuestManager")
		if qm == null and get_tree().current_scene.has_node("QuestManager"):
			qm = get_tree().current_scene.get_node("QuestManager")
		if qm:
			qm.add_progress("kill_goblins", 1)
			
		# 4. Free drop
		queue_free()
