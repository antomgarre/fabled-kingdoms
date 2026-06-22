extends CharacterBody3D

const SPEED = 2.0
const CHASE_SPEED = 4.0
const ATTACK_RANGE = 2.0
const AGGRO_RANGE = 15.0
const DAMAGE = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

enum State { IDLE, PATROL, ALERT, WANDER, CHASE, ATTACK, HURT }
## Start in PATROL so the enemy is never just standing still at game start.
var current_state = State.PATROL
var target_player: Node3D = null
var wander_target: Vector3 = Vector3.ZERO
var state_timer = 0.0
var hp = 50.0

# ---------------------------------------------------------------------------
# Patrol state
# ---------------------------------------------------------------------------
## Three waypoints generated around the spawn position at _ready().
var patrol_points: Array[Vector3] = []
## Index of the waypoint currently being walked toward.
var patrol_index: int = 0
## Countdown while the enemy stands still between waypoints.
var patrol_wait_timer: float = 0.0

# ---------------------------------------------------------------------------
# Alert state
# ---------------------------------------------------------------------------
## Radius for sound-triggered alerts (player attack heard but not seen).
const ALERT_SOUND_RANGE: float = 15.0
## Total time spent in ALERT before returning to PATROL.
const ALERT_DURATION: float = 4.0
## How many seconds each 45-degree head-sweep takes.
const ALERT_SWEEP_TIME: float = 1.0
## Accumulated time inside ALERT.
var alert_timer: float = 0.0
## Used to drive the look-left / look-right oscillation.
var alert_sweep_elapsed: float = 0.0
## Baseline Y rotation captured when we first enter ALERT.
var alert_base_yaw: float = 0.0

# --- Hit Flash ---
var _is_flashing: bool = false
var _flash_mesh: MeshInstance3D = null
var _original_material: Material = null

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
	
	_flash_white()
	
	if hp <= 0:
		_die()
	else:
		current_state = State.HURT
		state_timer = 0.5
		_play_anim("HitRecieve")

## Recursively finds the first MeshInstance3D in the subtree.
func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null

## Briefly overrides all surface materials with a bright white emissive material,
## then restores the originals after 80 ms. Skips if already flashing.
func _flash_white() -> void:
	if _is_flashing:
		return
	_is_flashing = true
	
	# Locate the mesh on first hit (cached for subsequent hits)
	if _flash_mesh == null:
		_flash_mesh = _find_mesh_instance(self)
	if _flash_mesh == null:
		_is_flashing = false
		return
	
	# Store the original material from surface 0 (representative)
	_original_material = _flash_mesh.get_surface_override_material(0)
	
	# Build the white hot emissive material
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color.WHITE
	white_mat.emission_enabled = true
	white_mat.emission = Color.WHITE
	white_mat.emission_energy_multiplier = 2.0
	white_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Override every surface so skinned meshes with multiple materials flash fully
	var surf_count = _flash_mesh.get_surface_override_material_count()
	# Ensure count matches mesh surfaces
	if _flash_mesh.mesh:
		surf_count = max(surf_count, _flash_mesh.mesh.get_surface_count())
	for i in range(surf_count):
		_flash_mesh.set_surface_override_material(i, white_mat)
	
	# Wait 80 ms then restore
	await get_tree().create_timer(0.08).timeout
	
	for i in range(surf_count):
		_flash_mesh.set_surface_override_material(i, _original_material)
	
	_is_flashing = false

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
	
	# --- Generate patrol waypoints around spawn position ---
	# We keep Y at spawn height so the enemy doesn't try to walk into the air.
	var spawn_pos: Vector3 = global_position
	for i in 3:
		var offset := Vector3(
			randf_range(-8.0, 8.0),
			0.0,
			randf_range(-8.0, 8.0)
		)
		patrol_points.append(spawn_pos + offset)
	# Shuffle so the order feels less predictable between instances.
	patrol_points.shuffle()
	patrol_index = 0
	
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
		State.PATROL:
			_process_patrol(delta)
		State.ALERT:
			_process_alert(delta)
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

# ---------------------------------------------------------------------------
# PATROL – walk a short circuit between pre-generated waypoints.
# ---------------------------------------------------------------------------
func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		# Safety: fall back to IDLE if waypoints weren't built yet.
		current_state = State.IDLE
		state_timer = 1.0
		return

	# --- Waiting at current waypoint ---
	if patrol_wait_timer > 0.0:
		patrol_wait_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		_play_anim("Idle")
		return

	# --- Walking toward current waypoint ---
	var dest: Vector3 = patrol_points[patrol_index]
	var dist: float = global_position.distance_to(dest)

	if dist < 1.5:
		# Arrived – pause before moving on.
		patrol_wait_timer = randf_range(1.5, 2.5)
		patrol_index = (patrol_index + 1) % patrol_points.size()
		return

	var dir: Vector3 = global_position.direction_to(dest)
	dir.y = 0.0
	dir = dir.normalized()

	# Patrol speed is 30 % of normal chase speed for a leisurely walk.
	var patrol_speed: float = SPEED * 0.6
	velocity.x = dir.x * patrol_speed
	velocity.z = dir.z * patrol_speed
	_rotate_towards(dir, delta)
	_play_anim("Walk")

# ---------------------------------------------------------------------------
# ALERT – enemy stopped moving, performs two slow 45-degree head sweeps.
# Transitions:
#   • Player enters AGGRO_RANGE → CHASE  (handled in _check_aggro)
#   • Timer expires              → PATROL
# ---------------------------------------------------------------------------
func _process_alert(delta: float) -> void:
	# Stand still.
	velocity.x = move_toward(velocity.x, 0.0, SPEED)
	velocity.z = move_toward(velocity.z, 0.0, SPEED)
	_play_anim("Idle")

	alert_timer += delta
	alert_sweep_elapsed += delta

	# Oscillate ±45° (PI/4) around the baseline yaw.
	# Full period = 2 × ALERT_SWEEP_TIME, so we use a sine wave.
	var sweep_angle: float = deg_to_rad(45.0) * sin((alert_sweep_elapsed / ALERT_SWEEP_TIME) * PI)
	pivot.rotation.y = alert_base_yaw + sweep_angle

	if alert_timer >= ALERT_DURATION:
		# Two full sweeps done – back to patrol.
		current_state = State.PATROL
		alert_timer = 0.0
		alert_sweep_elapsed = 0.0

# Helper: enter ALERT and capture the baseline facing direction.
func _enter_alert() -> void:
	current_state = State.ALERT
	alert_timer = 0.0
	alert_sweep_elapsed = 0.0
	alert_base_yaw = pivot.rotation.y

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
					target_player.take_damage(DAMAGE, self)
		
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
			# Notify MusicManager that combat has started
			var mm = get_node_or_null("/root/Main/MusicManager")
			if mm:
				mm.set_combat_mode(true)
			# Also reset the player's combat timer so music stays up while chasing
			if target_player.has_method("_trigger_combat_music"):
				target_player._trigger_combat_music()
		current_state = State.CHASE
		return

	# --- Sound detection: player is attacking nearby but NOT in direct line of sight → ALERT ---
	# We check if the player has just attacked by reading a flag exposed on the player node.
	# The flag is optional – we degrade gracefully if it doesn't exist.
	var dist_to_player: float = global_position.distance_to(target_player.global_position)
	var player_is_attacking: bool = false
	if target_player.has_method("is_attacking"):
		player_is_attacking = target_player.is_attacking()
	elif "is_attacking" in target_player:
		player_is_attacking = target_player.is_attacking

	if player_is_attacking and dist_to_player < ALERT_SOUND_RANGE:
		# Dot-product sight check: if the player is broadly in front of the
		# enemy (dot > 0.5, roughly ±60°) we consider them visible and jump
		# straight to CHASE instead of ALERT.
		var to_player: Vector3 = global_position.direction_to(target_player.global_position)
		to_player.y = 0.0
		var facing: Vector3 = -pivot.global_transform.basis.z  # forward vector
		facing.y = 0.0
		var dot: float = facing.normalized().dot(to_player.normalized())
		if dot > 0.5:
			# Visible – escalate directly to chase.
			if current_state != State.CHASE and current_state != State.ATTACK:
				if aggro_sound and not aggro_sound.playing:
					aggro_sound.play()
			current_state = State.CHASE
		else:
			# Heard but not seen – trigger ALERT (only if not already alert/chasing).
			if current_state == State.PATROL or current_state == State.IDLE or current_state == State.WANDER:
				_enter_alert()

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
