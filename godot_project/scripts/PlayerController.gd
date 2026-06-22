extends CharacterBody3D

# === MOVEMENT ===
const WALK_SPEED = 4.0
const SPRINT_SPEED = 7.0
const JUMP_VELOCITY = 5.5
const MOUSE_SENSITIVITY = 0.002
const ACCELERATION = 12.0
const DECELERATION = 18.0
const ROTATION_SPEED = 12.0

# === COMBAT ===
const ATTACK_DURATION = 0.45     # How long the attack "locks" you
const ATTACK_MOVE_PENALTY = 0.3  # Movement at 30% during attack
const COMBO_WINDOW = 0.2         # Last 0.2s of attack allow combo input
const DODGE_SPEED = 8.0
const DODGE_DURATION = 0.4

# === COYOTE TIME ===
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.1

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var pivot = $Pivot
@onready var spring_arm = $SpringArm3D
@onready var camera = $SpringArm3D/Camera3D
var animation_player: AnimationPlayer

var camera_shake_intensity = 0.0

# --- Core State ---
var is_attacking = false
var is_dodging = false
var is_invulnerable = false
var attack_timer = 0.0
var combo_queued = false
var combo_count = 0
var dodge_timer = 0.0

# Dialogue / Death blocking
var dialogue_active: bool = false
var is_dead: bool = false
var death_handled: bool = false

var mobile_controls = null
var dodge_direction = Vector3.ZERO
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var was_on_floor = true
var is_jumping = false

# Health
var max_hp = 100.0
var current_hp = 100.0

var sfx_attack: AudioStreamPlayer
var sfx_footstep: AudioStreamPlayer
var sfx_dodge: AudioStreamPlayer
var sfx_hurt: AudioStreamPlayer
var footsteps_grass = []
var footsteps_dirt = []
var attack_sounds = []
var step_timer = 0.0

# Camera shake
var shake_amount = 0.0
var shake_decay = 8.0

# --- Damage Direction Indicator ---
var _dmg_canvas: CanvasLayer = null
var _dmg_top: ColorRect = null
var _dmg_bottom: ColorRect = null
var _dmg_left: ColorRect = null
var _dmg_right: ColorRect = null

# Animation map (resolved at load time)
var anim_map = {}
var footstep_particles: GPUParticles3D

# === UTILITY FUNCTIONS ===

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = find_skeleton(child)
		if result:
			return result
	return null

func find_meshes(node: Node, meshes: Array):
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		find_meshes(child, meshes)

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = find_animation_player(child)
		if result:
			return result
	return null

# === READY ===

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	
	if DisplayServer.is_touchscreen_available():
		var mobile_controls_script = load("res://scripts/MobileControls.gd")
		if mobile_controls_script:
			mobile_controls = mobile_controls_script.new()
			add_child(mobile_controls)
			mobile_controls.camera_dragged.connect(_on_camera_dragged)
	
	# Register movement InputMap actions
	for action_data in [
		["move_forward", KEY_W],
		["move_back", KEY_S],
		["move_left", KEY_A],
		["move_right", KEY_D],
		["sprint", KEY_SHIFT],
		["jump", KEY_SPACE]
	]:
		if not InputMap.has_action(action_data[0]):
			InputMap.add_action(action_data[0])
			var ev = InputEventKey.new()
			ev.keycode = action_data[1]
			InputMap.action_add_event(action_data[0], ev)
	
	_setup_audio()
	_setup_character()
	_setup_particles()
	_setup_damage_indicator()
	
	# Connect to dialogue signals
	call_deferred("_connect_dialogue_signals")

func _connect_dialogue_signals():
	var dialogue_ui = get_node_or_null("/root/Main/DialogueUI")
	if dialogue_ui:
		dialogue_ui.dialogue_opened.connect(func(): dialogue_active = true)
		dialogue_ui.dialogue_closed.connect(func(): dialogue_active = false)

## Creates a CanvasLayer (layer 5) with four semi-transparent red edge panels
## used to communicate the direction an attack came from.
func _setup_damage_indicator() -> void:
	_dmg_canvas = CanvasLayer.new()
	_dmg_canvas.layer = 5
	add_child(_dmg_canvas)
	
	var vp_size = get_viewport().get_visible_rect().size
	var edge_thick = 60.0  # px
	var base_color = Color(1.0, 0.0, 0.0, 0.0)  # start fully transparent
	
	# Top strip
	_dmg_top = ColorRect.new()
	_dmg_top.color = base_color
	_dmg_top.size = Vector2(vp_size.x, edge_thick)
	_dmg_top.position = Vector2.ZERO
	_dmg_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dmg_canvas.add_child(_dmg_top)
	
	# Bottom strip
	_dmg_bottom = ColorRect.new()
	_dmg_bottom.color = base_color
	_dmg_bottom.size = Vector2(vp_size.x, edge_thick)
	_dmg_bottom.position = Vector2(0.0, vp_size.y - edge_thick)
	_dmg_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dmg_canvas.add_child(_dmg_bottom)
	
	# Left strip
	_dmg_left = ColorRect.new()
	_dmg_left.color = base_color
	_dmg_left.size = Vector2(edge_thick, vp_size.y)
	_dmg_left.position = Vector2.ZERO
	_dmg_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dmg_canvas.add_child(_dmg_left)
	
	# Right strip
	_dmg_right = ColorRect.new()
	_dmg_right.color = base_color
	_dmg_right.size = Vector2(edge_thick, vp_size.y)
	_dmg_right.position = Vector2(vp_size.x - edge_thick, 0.0)
	_dmg_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dmg_canvas.add_child(_dmg_right)

## Determines which screen edge the attacker is on (in camera-relative space)
## and pulses that panel from alpha 0.6 → 0.0 over 0.8 seconds.
func show_damage_direction(attacker_global_pos: Vector3) -> void:
	if _dmg_canvas == null:
		return
	
	# World-space direction from player → attacker, flattened to XZ plane
	var to_attacker = attacker_global_pos - global_position
	to_attacker.y = 0.0
	if to_attacker.length_squared() < 0.001:
		return
	to_attacker = to_attacker.normalized()
	
	# Camera forward on XZ plane (spring_arm looks where the camera faces)
	var cam_fwd = -spring_arm.global_transform.basis.z
	cam_fwd.y = 0.0
	if cam_fwd.length_squared() < 0.001:
		cam_fwd = Vector3(0, 0, -1)
	else:
		cam_fwd = cam_fwd.normalized()
	
	var cam_right = spring_arm.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()
	
	# Project attacker direction onto camera axes to get a 2-D screen-space angle
	var dot_fwd   = to_attacker.dot(cam_fwd)    # +1 = ahead,  -1 = behind
	var dot_right = to_attacker.dot(cam_right)  # +1 = right,  -1 = left
	var angle_deg = rad_to_deg(atan2(dot_right, dot_fwd))  # 0° = front, 90° = right
	
	# Determine which quadrant the hit came from and pick the panel
	var panel: ColorRect = null
	if angle_deg >= -45.0 and angle_deg < 45.0:
		panel = _dmg_top      # attacker is in front → top flash
	elif angle_deg >= 45.0 and angle_deg < 135.0:
		panel = _dmg_right    # attacker is to the right
	elif angle_deg >= -135.0 and angle_deg < -45.0:
		panel = _dmg_left     # attacker is to the left
	else:
		panel = _dmg_bottom   # attacker is behind → bottom flash
	
	if panel == null:
		return
	
	# Snap the panel to peak alpha, then tween to transparent
	panel.color = Color(1.0, 0.0, 0.0, 0.6)
	var tween = create_tween()
	tween.tween_property(panel, "color", Color(1.0, 0.0, 0.0, 0.0), 0.8)

func _setup_audio():
	# Attack sounds (varied for combo)
	sfx_attack = AudioStreamPlayer.new()
	add_child(sfx_attack)
	for fname in ["drawKnife1.ogg", "knifeSlice.ogg", "chop.ogg"]:
		var path = "res://assets/sounds/" + fname
		if ResourceLoader.exists(path):
			attack_sounds.append(load(path))
	if attack_sounds.size() > 0:
		sfx_attack.stream = attack_sounds[0]
	
	# Footsteps
	sfx_footstep = AudioStreamPlayer.new()
	sfx_footstep.volume_db = -10.0
	add_child(sfx_footstep)
	for i in range(5):
		var path = "res://assets/sounds/footstep_grass_00" + str(i) + ".ogg"
		if ResourceLoader.exists(path):
			footsteps_grass.append(load(path))
	for i in range(10):
		var path = "res://assets/sounds/footstep0" + str(i) + ".ogg"
		if ResourceLoader.exists(path):
			footsteps_dirt.append(load(path))
	
	# Dodge sound
	sfx_dodge = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/sounds/cloth1.ogg"):
		sfx_dodge.stream = load("res://assets/sounds/cloth1.ogg")
	add_child(sfx_dodge)
	
	# Hurt sound
	sfx_hurt = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/sounds/player_hit.mp3"):
		sfx_hurt.stream = load("res://assets/sounds/player_hit.mp3")
	add_child(sfx_hurt)

func _setup_character():
	var character_model = $Pivot/BaseCharacter
	if not character_model:
		return
	
	var skeleton = find_skeleton(character_model)
	if not skeleton:
		return
		
	# 1. Setup Animation on Base Character
	animation_player = AnimationPlayer.new()
	character_model.add_child(animation_player)
	animation_player.root_node = animation_player.get_path_to(skeleton)
	
	var merged_library = AnimationLibrary.new()
	
	# Load UAL 1 (Basic Locomotion)
	var ual1_scene = load("res://assets/models/UAL1_Standard.glb")
	if ual1_scene:
		var ual1 = ual1_scene.instantiate()
		var p1 = find_animation_player(ual1)
		if p1:
			for lib_name in p1.get_animation_library_list():
				var lib = p1.get_animation_library(lib_name)
				for anim_name in lib.get_animation_list():
					var anim = lib.get_animation(anim_name).duplicate()
					for i in range(anim.get_track_count()):
						var path = anim.track_get_path(i)
						var new_path = "."
						for j in range(path.get_subname_count()):
							new_path += ":" + path.get_subname(j)
						anim.track_set_path(i, NodePath(new_path))
					merged_library.add_animation(anim_name, anim)

	# Load UAL 2 (Expansions, Zombies, Jobs)
	var ual2_scene = load("res://assets/models/UAL2_Standard.glb")
	if ual2_scene:
		var ual2 = ual2_scene.instantiate()
		var p2 = find_animation_player(ual2)
		if p2:
			for lib_name in p2.get_animation_library_list():
				var lib = p2.get_animation_library(lib_name)
				for anim_name in lib.get_animation_list():
					var anim = lib.get_animation(anim_name).duplicate()
					for i in range(anim.get_track_count()):
						var path = anim.track_get_path(i)
						var new_path = "."
						for j in range(path.get_subname_count()):
							new_path += ":" + path.get_subname(j)
						anim.track_set_path(i, NodePath(new_path))
					merged_library.add_animation(anim_name, anim)
					
	animation_player.add_animation_library("", merged_library)
	
	# Build animation map by scanning all loaded animations
	# NOTE: Godot strips "_Loop" suffix when importing GLB animations!
	# e.g. "Sprint_Loop" in the GLB becomes just "Sprint" in Godot
	var all_anims = animation_player.get_animation_list()
	
	# Map roles to animations using keyword search on actual Godot names
	for a in all_anims:
		var lower = a.to_lower()
		# Idle
		if lower == "idle" and "idle" not in anim_map:
			anim_map["idle"] = a
		# Walk
		if lower == "walk" and "walk" not in anim_map:
			anim_map["walk"] = a
		# Sprint
		if lower == "sprint" and "sprint" not in anim_map:
			anim_map["sprint"] = a
		# Jog
		if ("jog" in lower) and "jog" not in anim_map:
			anim_map["jog"] = a
		# Jump
		if lower == "jump_start" and "jump_start" not in anim_map:
			anim_map["jump_start"] = a
		if lower == "jump" and "jump_loop" not in anim_map:
			anim_map["jump_loop"] = a
		if lower == "jump_land" and "jump_land" not in anim_map:
			anim_map["jump_land"] = a
		# Roll
		if lower == "roll" and "roll" not in anim_map:
			anim_map["roll"] = a
		# Death
		if "death" in lower and "death" not in anim_map:
			anim_map["death"] = a
		# Hurt
		if "hit_chest" in lower and "hurt" not in anim_map:
			anim_map["hurt"] = a
		if "hit_knockback" == lower and "knockback" not in anim_map:
			anim_map["knockback"] = a
		# Attacks
		if "sword_regular_a" == lower and "attack1" not in anim_map:
			anim_map["attack1"] = a
		if "sword_regular_b" == lower and "attack2" not in anim_map:
			anim_map["attack2"] = a
		if "sword_regular_c" == lower and "attack3" not in anim_map:
			anim_map["attack3"] = a
		if "sword_regular_combo" == lower and "combo" not in anim_map:
			anim_map["combo"] = a
		if "sword_attack" == lower and "sword_attack" not in anim_map:
			anim_map["sword_attack"] = a
		if "punch_jab" == lower and "punch" not in anim_map:
			anim_map["punch"] = a
		if "sword_block" == lower and "block" not in anim_map:
			anim_map["block"] = a
	
	# Fallbacks
	if "sprint" not in anim_map and "jog" in anim_map:
		anim_map["sprint"] = anim_map["jog"]
	if "attack1" not in anim_map and "sword_attack" in anim_map:
		anim_map["attack1"] = anim_map["sword_attack"]
	if "attack2" not in anim_map and "attack1" in anim_map:
		anim_map["attack2"] = anim_map["attack1"]
	


	# 2. Setup Modular Outfit (Male_Ranger)
	var outfit_scene = load("res://assets/models/Male_Ranger.gltf")
	if outfit_scene:
		var outfit = outfit_scene.instantiate()
		character_model.add_child(outfit)
		
		var meshes = []
		find_meshes(outfit, meshes)
		for mesh in meshes:
			mesh.skeleton = mesh.get_path_to(skeleton)

	# 3. Equip Sword
	var right_hand = ""
	for i in range(skeleton.get_bone_count()):
		var bname = skeleton.get_bone_name(i).to_lower()
		if ("hand" in bname and "right" in bname) or ("r_hand" in bname) or ("hand_r" in bname):
			right_hand = skeleton.get_bone_name(i)
			break
	
	if right_hand != "":
		var attachment = BoneAttachment3D.new()
		attachment.bone_name = right_hand
		skeleton.add_child(attachment)
		
		var sword_mesh = load("res://assets/models/Sword.obj")
		if sword_mesh:
			var mi = MeshInstance3D.new()
			mi.mesh = sword_mesh
			mi.rotation_degrees = Vector3(0, 90, 90)
			mi.position = Vector3(0, 0.1, 0)
			mi.scale = Vector3(0.15, 0.15, 0.15)
			
			# Add Hitbox
			var area = Area3D.new()
			area.name = "SwordHitbox"
			area.collision_layer = 0
			area.collision_mask = 2 # Enemy layer
			area.body_entered.connect(_on_sword_body_entered)
			
			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(0.2, 1.5, 0.2)
			col.shape = box
			col.position = Vector3(0, 0.75, 0)
			area.add_child(col)
			mi.add_child(area)
			
			attachment.add_child(mi)
	else:
		push_error("Could not find right hand bone!")

# === COMBAT ===

func _on_sword_body_entered(body):
	if is_attacking and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			var damage = 20 if combo_count == 0 else 30 # Combo hit = more damage
			body.take_damage(damage)
			
			# Spawn sparks
			_spawn_combat_sparks(body.global_position + Vector3(0, 1.5, 0))
			
			# Spawn floating damage number
			_spawn_damage_number(body.global_position + Vector3(0, 2.5, 0), damage)

func _attack():
	if is_dodging: return
	if not animation_player: return
	
	if is_attacking:
		# Queue combo if in the combo window
		if attack_timer < COMBO_WINDOW:
			combo_queued = true
		return
	
	_execute_attack()

func _execute_attack():
	is_attacking = true
	attack_timer = ATTACK_DURATION
	
	# Pick animation from cached map
	var anim_name = ""
	if combo_count == 0:
		anim_name = anim_map.get("attack1", anim_map.get("punch", ""))
	else:
		anim_name = anim_map.get("attack2", anim_map.get("attack1", ""))
	
	# Play attack sound (varied)
	if attack_sounds.size() > 0:
		var idx = combo_count % attack_sounds.size()
		sfx_attack.stream = attack_sounds[idx]
		sfx_attack.play()
	
	if anim_name != "":
		animation_player.play(anim_name)

func _find_first_anim(names: Array) -> String:
	for n in names:
		if animation_player.has_animation(n):
			return n
	return ""

func _dodge():
	if is_dodging or not is_on_floor(): return
	
	is_dodging = true
	is_invulnerable = true
	dodge_timer = DODGE_DURATION
	
	# Direction: movement direction or backwards
	var input_dir = _get_input_direction()
	if input_dir.length() > 0.1:
		dodge_direction = input_dir
	else:
		# Dodge forward relative to where the character faces
		dodge_direction = pivot.transform.basis.z
		dodge_direction.y = 0
		dodge_direction = dodge_direction.normalized()
	
	if sfx_dodge and sfx_dodge.stream:
		sfx_dodge.play()
	
	if "roll" in anim_map:
		animation_player.play(anim_map["roll"])

func take_damage(amount: float, attacker = null):
	if is_dead:
		return
	
	current_hp -= amount
	current_hp = max(current_hp, 0)
	camera_shake(0.2)
	
	if sfx_hurt and sfx_hurt.stream:
		sfx_hurt.play()
	
	# Show directional damage indicator when attacker is known
	if attacker != null and attacker is Node3D:
		show_damage_direction(attacker.global_position)
	
	# Update HUD
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("update_player_hp"):
		hud.update_player_hp(current_hp, max_hp)
	
	# Check for death
	if current_hp <= 0 and not is_dead:
		_handle_death()

func _handle_death():
	is_dead = true
	is_attacking = false
	is_dodging = false
	
	# Play death animation if available
	if animation_player and "death" in anim_map:
		animation_player.play(anim_map["death"])
	
	# After 1.5 seconds, show death screen
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(_show_death_screen)

func _show_death_screen():
	var death_screen = get_node_or_null("/root/Main/DeathScreen")
	if death_screen and death_screen.has_method("show_death_screen"):
		death_screen.show_death_screen()

func camera_shake(intensity: float):
	shake_amount = intensity

func _spawn_damage_number(pos: Vector3, damage: int):
	var label = Label3D.new()
	label.text = "-" + str(damage)
	label.font_size = 48
	label.outline_size = 8
	label.modulate = Color(1, 0.2, 0.1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.global_position = pos
	label.no_depth_test = true
	get_tree().root.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", pos.y + 1.5, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _setup_particles():
	footstep_particles = GPUParticles3D.new()
	footstep_particles.amount = 15
	footstep_particles.lifetime = 0.5
	footstep_particles.emitting = false
	
	var dust_mat = StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.45, 0.35, 0.25, 0.5)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var dust_mesh = SphereMesh.new()
	dust_mesh.radius = 0.05
	dust_mesh.height = 0.1
	dust_mesh.radial_segments = 8
	dust_mesh.rings = 4
	dust_mesh.material = dust_mat
	footstep_particles.draw_pass_1 = dust_mesh
	
	var dust_proc = ParticleProcessMaterial.new()
	dust_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dust_proc.emission_box_extents = Vector3(0.2, 0.05, 0.2)
	dust_proc.direction = Vector3(0, 1, 0)
	dust_proc.spread = 30.0
	dust_proc.initial_velocity_min = 0.5
	dust_proc.initial_velocity_max = 1.0
	dust_proc.gravity = Vector3(0, -0.5, 0)
	
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	var curve_tex = CurveTexture.new()
	curve_tex.curve = curve
	dust_proc.scale_curve = curve_tex
	
	footstep_particles.process_material = dust_proc
	
	add_child(footstep_particles)
	footstep_particles.position = Vector3(0, 0.1, 0)

func _spawn_combat_sparks(pos: Vector3):
	Engine.time_scale = 0.1
	var timer = get_tree().create_timer(0.05, true, false, true)
	timer.timeout.connect(func(): Engine.time_scale = 1.0)
	
	camera_shake_intensity = 0.3
	
	var sparks = GPUParticles3D.new()
	sparks.amount = 15
	sparks.lifetime = 0.3
	sparks.one_shot = true
	sparks.explosiveness = 0.9
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1)
	mat.emission_energy_multiplier = 4.0
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.02, 0.2, 0.02)
	mesh.material = mat
	sparks.draw_pass_1 = mesh
	
	var proc = ParticleProcessMaterial.new()
	proc.particle_flag_align_y = true
	proc.direction = Vector3(0, 1, 0)
	proc.spread = 180.0
	proc.initial_velocity_min = 2.0
	proc.initial_velocity_max = 4.0
	proc.gravity = Vector3(0, -5.0, 0)
	
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	var curve_tex = CurveTexture.new()
	curve_tex.curve = curve
	proc.scale_curve = curve_tex
	
	sparks.process_material = proc
	
	get_tree().root.add_child(sparks)
	sparks.global_position = pos
	sparks.emitting = true
	
	var cleanup_timer = get_tree().create_timer(1.0)
	cleanup_timer.timeout.connect(sparks.queue_free)

# === INPUT ===

func _unhandled_input(event):
	# Block all input during dialogue or death
	if dialogue_active or is_dead:
		return
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		spring_arm.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)
	
	# ESC is now handled by PauseMenu
			
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_attack()
	elif event.is_action_pressed("attack"):
		_attack()

func _on_camera_dragged(relative: Vector2):
	spring_arm.rotation.y -= relative.x * MOUSE_SENSITIVITY
	spring_arm.rotation.x -= relative.y * MOUSE_SENSITIVITY
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func _get_input_direction() -> Vector3:
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y -= 1
	if Input.is_action_pressed("move_back"): input_dir.y += 1
	if Input.is_action_pressed("move_left"): input_dir.x -= 1
	if Input.is_action_pressed("move_right"): input_dir.x += 1
	
	if mobile_controls and mobile_controls.joystick_active:
		input_dir += mobile_controls.joystick_vector
		
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
		
	return (spring_arm.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

# === PHYSICS (MAIN GAME LOOP) ===

func _process(delta):
	if camera_shake_intensity > 0:
		camera.h_offset = randf_range(-camera_shake_intensity, camera_shake_intensity)
		camera.v_offset = randf_range(-camera_shake_intensity, camera_shake_intensity)
		camera_shake_intensity -= delta * 5.0
		if camera_shake_intensity <= 0:
			camera_shake_intensity = 0.0
			camera.h_offset = 0.0
			camera.v_offset = 0.0

func _physics_process(delta):
	# Block all processing during dialogue or death
	if dialogue_active or is_dead:
		if is_dead:
			# Still apply gravity when dead so body doesn't float
			if not is_on_floor():
				velocity.y -= gravity * delta
			velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
			velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)
			move_and_slide()
		return
	
	var on_floor = is_on_floor()
	
	# --- Coyote Time ---
	if on_floor:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
	
	# --- Jump Buffer ---
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta
	
	# --- Gravity ---
	if not on_floor:
		velocity.y -= gravity * delta
	
	# --- Jump ---
	var can_jump = coyote_timer > 0 and jump_buffer_timer > 0
	if can_jump and not is_dodging:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0
		jump_buffer_timer = 0
		is_jumping = true
		
		if "jump_start" in anim_map:
			animation_player.play(anim_map["jump_start"])
	
	# --- Landing detection ---
	if on_floor and not was_on_floor:
		is_jumping = false
		# Play landing sound
		var active_footsteps = footsteps_dirt if get_floor_normal().y < 0.85 else footsteps_grass
		if active_footsteps.size() > 0:
			sfx_footstep.stream = active_footsteps[randi() % active_footsteps.size()]
			sfx_footstep.pitch_scale = randf_range(0.9, 1.1)
			sfx_footstep.volume_db = randf_range(-14.0, -10.0)
			sfx_footstep.play()
	was_on_floor = on_floor
	
	# --- Dodge (Q key) ---
	if (Input.is_key_pressed(KEY_Q) or Input.is_action_pressed("dodge")) and not is_dodging and not is_attacking and on_floor:
		_dodge()
	
	if is_dodging:
		dodge_timer -= delta
		velocity.x = dodge_direction.x * DODGE_SPEED
		velocity.z = dodge_direction.z * DODGE_SPEED
		if dodge_timer <= 0:
			is_dodging = false
			is_invulnerable = false
		move_and_slide()
		return
	
	# --- Attack timer ---
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			if combo_queued:
				combo_queued = false
				combo_count += 1
				_execute_attack()
			else:
				is_attacking = false
				combo_count = 0
	
	# --- Movement ---
	var direction = _get_input_direction()
	
	var current_speed = WALK_SPEED
	var is_sprinting = Input.is_action_pressed("sprint")
	if is_sprinting:
		current_speed = SPRINT_SPEED
	
	# Emit footsteps particles
	if footstep_particles:
		if on_floor and velocity.length() > 0.5 and not is_jumping:
			footstep_particles.emitting = true
		else:
			footstep_particles.emitting = false
	
	# Reduce speed during attack (but don't freeze!)
	if is_attacking:
		current_speed *= ATTACK_MOVE_PENALTY
		
	if direction.length() > 0.1:
		# Smooth acceleration
		var target_vx = direction.x * current_speed
		var target_vz = direction.z * current_speed
		velocity.x = lerp(velocity.x, target_vx, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_vz, ACCELERATION * delta)
		
		# Smooth rotation
		var target_y = atan2(direction.x, direction.z)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, target_y, ROTATION_SPEED * delta)
		
		# Animation from cached map
		if animation_player and not is_attacking and on_floor and not is_jumping:
			var target_anim: String = ""
			if is_sprinting:
				target_anim = anim_map.get("sprint", "")
				if target_anim == anim_map.get("walk", ""):
					animation_player.speed_scale = 2.0
				else:
					animation_player.speed_scale = 1.2
			else:
				target_anim = anim_map.get("walk", "")
				animation_player.speed_scale = 1.0
			if target_anim != "":
				if animation_player.current_animation != target_anim:
					animation_player.play(target_anim)
		else:
			if not on_floor:
				pass # in air
			elif is_jumping:
				pass # jumping
				
		# Footstep sounds
		if on_floor and not is_attacking:
			step_timer -= delta
			if step_timer <= 0:
				step_timer = 0.3 if current_speed == SPRINT_SPEED else 0.5
				var active_footsteps = footsteps_dirt if get_floor_normal().y < 0.85 else footsteps_grass
				if active_footsteps.size() > 0:
					sfx_footstep.stream = active_footsteps[randi() % active_footsteps.size()]
					sfx_footstep.pitch_scale = randf_range(0.9, 1.1)
					sfx_footstep.volume_db = randf_range(-14.0, -10.0) 
					sfx_footstep.play()
	else:
		# Smooth deceleration
		velocity.x = lerp(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = lerp(velocity.z, 0.0, DECELERATION * delta)
		
		if animation_player and on_floor and not is_attacking and not is_jumping:
			var idle_anim = anim_map.get("idle", "")
			if idle_anim != "" and animation_player.current_animation != idle_anim:
				animation_player.play(idle_anim)
				animation_player.speed_scale = 1.0
	
	# --- In-air animation ---
	if not on_floor and not is_dodging:
		if velocity.y < -1.0 and animation_player:
			var fall_anim = anim_map.get("jump_loop", "")
			if fall_anim != "":
				var cur = animation_player.current_animation
				if cur != fall_anim and cur != anim_map.get("jump_start", ""):
					animation_player.play(fall_anim)
	
	# --- Camera shake ---
	if shake_amount > 0:
		spring_arm.position = Vector3(
			randf_range(-shake_amount, shake_amount),
			1.5 + randf_range(-shake_amount, shake_amount),
			0
		)
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
		if shake_amount < 0.01:
			shake_amount = 0.0
			spring_arm.position = Vector3(0, 1.5, 0)
	
	move_and_slide()
