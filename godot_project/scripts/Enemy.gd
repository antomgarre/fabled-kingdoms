extends CharacterBody3D

const SPEED = 2.0
const CHASE_SPEED = 4.0
const ATTACK_RANGE = 2.0
const AGGRO_RANGE = 15.0
const DAMAGE = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

enum State { IDLE, WANDER, CHASE, ATTACK, HURT }
var current_state = State.IDLE
var target_player: Node3D = null
var wander_target: Vector3 = Vector3.ZERO
var state_timer = 0.0
var hp = 50.0

@onready var pivot = $Pivot
var animation_player: AnimationPlayer
var hit_sound: AudioStreamPlayer3D
var death_sound: AudioStreamPlayer3D
var aggro_sound: AudioStreamPlayer3D
var is_dead = false
var health_bar: ProgressBar
var health_bar_container: SubViewport
var attack_dealt = false

func take_damage(amount: float):
	if is_dead: return
	hp -= amount
	
	if hit_sound:
		hit_sound.play()
	
	# Update floating health bar
	if health_bar:
		health_bar.value = hp
		health_bar.get_parent().get_parent().visible = true # Show bar when hit
	
	if target_player:
		var push_dir = target_player.global_position.direction_to(global_position)
		push_dir.y = 0
		velocity += push_dir.normalized() * 10.0
		
	var tween = create_tween()
	tween.tween_property($Pivot, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property($Pivot, "scale", Vector3(1, 1, 1), 0.1)
	
	if hp <= 0:
		_die()
	else:
		current_state = State.HURT
		state_timer = 0.5
		_play_anim("HitRecieve")

func _die():
	is_dead = true
	current_state = State.HURT
	_play_anim("Death")
	
	# Hide health bar
	for child in get_children():
		if child is SubViewportContainer:
			child.visible = false
	
	$CollisionShape3D.set_deferred("disabled", true)
	
	if death_sound and not death_sound.playing:
		death_sound.play()
	
	var loot_script = load("res://scripts/LootDrop.gd")
	if loot_script:
		var area = Area3D.new()
		area.set_script(loot_script)
		get_tree().current_scene.add_child(area)
		area.global_position = global_position + Vector3(0, 1, 0)
	
	await get_tree().create_timer(2.0).timeout
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 2.0, 2.0)
	await tween.finished
	queue_free()

func _ready():
	add_to_group("enemies")
	
	hit_sound = AudioStreamPlayer3D.new()
	if ResourceLoader.exists("res://assets/sounds/impactPunch_heavy_000.ogg"):
		hit_sound.stream = load("res://assets/sounds/impactPunch_heavy_000.ogg")
	add_child(hit_sound)
	
	death_sound = AudioStreamPlayer3D.new()
	if ResourceLoader.exists("res://assets/sounds/dramatic-death-collapse.mp3"):
		death_sound.stream = load("res://assets/sounds/dramatic-death-collapse.mp3")
	add_child(death_sound)
	
	aggro_sound = AudioStreamPlayer3D.new()
	if ResourceLoader.exists("res://assets/sounds/voice-attack-grunt.mp3"):
		aggro_sound.stream = load("res://assets/sounds/voice-attack-grunt.mp3")
	add_child(aggro_sound)
	
	# Floating health bar above the enemy
	_create_health_bar()
					
	# Find Player
	var tree = get_tree()
	if tree.has_group("player"):
		target_player = tree.get_nodes_in_group("player")[0]
	else:
		# Fallback to finding by name in root
		var root = get_node_or_null("/root/Main")
		if root and root.has_node("Player"):
			target_player = root.get_node("Player")

func initialize(data: Dictionary):
	if data.has("stats"):
		hp = data["stats"].get("hp", 50.0)
		
	var type = data.get("type", "AnimatedEnemy")
	var model_path = "res://assets/models/" + type + ".gltf"
	if not ResourceLoader.exists(model_path):
		model_path = "res://assets/models/" + type + ".glb"
		if not ResourceLoader.exists(model_path):
			model_path = "res://assets/models/" + type + ".fbx"
			
	if ResourceLoader.exists(model_path):
		for child in pivot.get_children():
			child.queue_free()
		
		var model = load(model_path).instantiate()
		pivot.add_child(model)
		
		animation_player = _find_animation_player(model)
		if animation_player:
			for anim_name in animation_player.get_animation_list():
				var lower_name = anim_name.to_lower()
				if "idle" in lower_name or "walk" in lower_name or "run" in lower_name:
					var anim = animation_player.get_animation(anim_name)
					if anim:
						anim.loop_mode = Animation.LOOP_LINEAR

func _physics_process(delta):
	if is_dead:
		return
		
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)

	move_and_slide()
	
	if current_state != State.ATTACK and current_state != State.HURT:
		_check_aggro()

func _process_hurt(delta):
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.CHASE

func _process_idle(delta):
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)
	_play_anim("Idle")
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.WANDER
		state_timer = randf_range(2.0, 5.0)
		var rand_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		wander_target = global_position + Vector3(rand_dir.x, 0, rand_dir.y) * 5.0

func _process_wander(delta):
	var dir = global_position.direction_to(wander_target)
	dir.y = 0
	dir = dir.normalized()
	
	if global_position.distance_to(wander_target) < 1.0:
		current_state = State.IDLE
		state_timer = randf_range(1.0, 3.0)
		return
		
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	_rotate_towards(dir, delta)
	_play_anim("Walk")
	
	state_timer -= delta
	if state_timer <= 0:
		current_state = State.IDLE
		state_timer = randf_range(1.0, 3.0)

func _process_chase(delta):
	if not target_player:
		current_state = State.IDLE
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	if dist > AGGRO_RANGE * 1.5:
		current_state = State.IDLE
		return
		
	if dist < ATTACK_RANGE:
		current_state = State.ATTACK
		state_timer = 1.0 # Attack cooldown
		return
		
	var dir = global_position.direction_to(target_player.global_position)
	dir.y = 0
	dir = dir.normalized()
	
	velocity.x = dir.x * CHASE_SPEED
	velocity.z = dir.z * CHASE_SPEED
	_rotate_towards(dir, delta)
	_play_anim("Run")

func _process_attack(delta):
	velocity.x = move_toward(velocity.x, 0, SPEED)
	velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if target_player:
		var dir = global_position.direction_to(target_player.global_position)
		_rotate_towards(dir, delta * 2.0)
	
	if not attack_dealt:
		attack_dealt = true
		_play_anim("Sword_Slash")
		
		# Deal damage after a short wind-up delay
		await get_tree().create_timer(0.3).timeout
		if hp > 0 and target_player and current_state == State.ATTACK:
			var dist = global_position.distance_to(target_player.global_position)
			if dist < ATTACK_RANGE * 1.5:
				if target_player.has_method("take_damage"):
					target_player.take_damage(DAMAGE)
		
	state_timer -= delta
	if state_timer <= 0:
		attack_dealt = false
		current_state = State.CHASE

func _check_aggro():
	if not target_player: return
	if global_position.distance_to(target_player.global_position) < AGGRO_RANGE:
		if current_state != State.CHASE and current_state != State.ATTACK:
			if aggro_sound and not aggro_sound.playing:
				aggro_sound.play()
		current_state = State.CHASE

func _rotate_towards(dir: Vector3, delta: float):
	if dir.length_squared() > 0.001:
		var target_y = atan2(dir.x, dir.z)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, target_y, 10.0 * delta)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null

func _play_anim(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

func _create_health_bar():
	# Use a simple Sprite3D + SubViewport for the floating bar
	var bar_root = Node3D.new()
	bar_root.name = "HealthBarRoot"
	bar_root.position = Vector3(0, 2.5, 0) # Above head
	bar_root.visible = false # Hidden until first hit
	add_child(bar_root)
	
	var svp_container = SubViewportContainer.new()
	svp_container.stretch = true
	
	var svp = SubViewport.new()
	svp.size = Vector2(200, 20)
	svp.transparent_bg = true
	svp_container.add_child(svp)
	
	health_bar = ProgressBar.new()
	health_bar.max_value = hp
	health_bar.value = hp
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(200, 20)
	health_bar.size = Vector2(200, 20)
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.15, 0.1)
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.1, 0.1, 0.8)
	bg.corner_radius_top_left = 2
	bg.corner_radius_top_right = 2
	bg.corner_radius_bottom_left = 2
	bg.corner_radius_bottom_right = 2
	health_bar.add_theme_stylebox_override("background", bg)
	
	svp.add_child(health_bar)
	
	# Use a Sprite3D to show the viewport as a billboard
	var sprite = Sprite3D.new()
	sprite.texture = svp.get_texture()
	sprite.pixel_size = 0.005
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	bar_root.add_child(sprite)
	bar_root.add_child(svp_container)
	svp_container.visible = false # Hide the container, sprite shows it
