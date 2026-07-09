extends Node

# NetworkManager.gd
const DEFAULT_PORT = 7777
var host_ip = "127.0.0.1"

var player_ref: Node3D = null
var invader_ref: Node3D = null

var is_host = false
var is_client = false
var connected_client_id = 0

signal client_connected
signal client_disconnected
signal connected_to_server
signal connection_failed
signal server_disconnected

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Listen to SteamManager
	var sm = get_node_or_null("/root/SteamManager")
	if sm:
		sm.on_lobby_created.connect(_on_steam_lobby_created)
		sm.on_lobby_joined.connect(_on_steam_lobby_joined)

func host_game() -> bool:
	var sm = get_node_or_null("/root/SteamManager")
	if sm:
		sm.host_lobby()
	return true

func _on_steam_lobby_created(lobby_id: int):
	var peer = SteamMultiplayerPeer.new()
	var err = peer.create_host(0) # 0 = default virtual port
	if err != OK:
		print("[NETWORK] Error creating Steam host: ", err)
		return
		
	multiplayer.multiplayer_peer = peer
	is_host = true
	is_client = false
	print("[NETWORK] Hosting Steam P2P session.")

func _on_steam_lobby_joined(lobby_id: int):
	var owner_id = Steam.getLobbyOwner(lobby_id)
	
	# If we are the owner, we already created the host socket in _on_steam_lobby_created
	if owner_id == Steam.getSteamID():
		return
		
	var peer = SteamMultiplayerPeer.new()
	var err = peer.create_client(owner_id, 0) # 0 = default virtual port
	if err != OK:
		print("[NETWORK] Error creating Steam client: ", err)
		return
		
	multiplayer.multiplayer_peer = peer
	is_host = false
	is_client = true
	print("[NETWORK] Joined Steam P2P session.")

func leave_game():
	multiplayer.multiplayer_peer = null
	is_host = false
	is_client = false
	connected_client_id = 0
	invader_ref = null
	player_ref = null

# --- Callbacks ---

func _on_peer_connected(id: int):
	print("[NETWORK] Peer connected: ", id)
	if is_host and id != 1:
		connected_client_id = id
		client_connected.emit()
		_spawn_invader_for_client(id)

func _on_peer_disconnected(id: int):
	print("[NETWORK] Peer disconnected: ", id)
	if is_host and id == connected_client_id:
		connected_client_id = 0
		client_disconnected.emit()
		
		# Free the invader or return to AI
		if is_instance_valid(invader_ref):
			invader_ref.is_invader = false
			invader_ref = null

func _on_connected_to_server():
	print("[NETWORK] Successfully connected to server!")
	connected_to_server.emit()

func _on_connection_failed():
	print("[NETWORK] Connection failed.")
	connection_failed.emit()
	leave_game()

func _on_server_disconnected():
	print("[NETWORK] Server disconnected.")
	server_disconnected.emit()
	leave_game()

# --- Logic ---

func _spawn_invader_for_client(client_id: int):
	# Wait for TestWorld to be ready
	await get_tree().create_timer(1.0).timeout
	
	player_ref = get_tree().root.find_child("Player", true, false)
	if not player_ref:
		print("[NETWORK] Player not found for invader!")
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_dist = 1000.0
	
	for e in enemies:
		if e.get("is_dead") or e.get("is_invader"):
			continue
			
		var dist = player_ref.global_position.distance_to(e.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = e
			
	if closest_enemy:
		print("[NETWORK] Possessing enemy: ", closest_enemy.name)
		closest_enemy.become_invader(0) # 0 means Network Input, not Joypad
		invader_ref = closest_enemy
		
		# Tell client who they are
		rpc("setup_client_refs", player_ref.get_path(), invader_ref.get_path())

@rpc("authority", "call_local", "reliable")
func setup_client_refs(p_path: NodePath, i_path: NodePath):
	print("[NETWORK] Client received refs!")
	player_ref = get_node_or_null(p_path)
	invader_ref = get_node_or_null(i_path)
	
	if invader_ref and is_client:
		# Disable standard camera
		if player_ref:
			var p_cam = player_ref.find_child("Camera3D", true, false)
			if p_cam: p_cam.current = false
			
		# Add a camera to the invader
		var cam_pivot = Node3D.new()
		var cam = Camera3D.new()
		cam.current = true
		cam.position = Vector3(0, 3, 5)
		cam.rotation_degrees = Vector3(-15, 0, 0)
		cam_pivot.add_child(cam)
		invader_ref.add_child(cam_pivot)
		
		# Disable Enemy AI completely on the client side
		invader_ref.is_invader = true
		invader_ref.set_process(false)
		invader_ref.set_physics_process(false)
		
		if player_ref:
			player_ref.set_process(false)
			player_ref.set_physics_process(false)

# --- Synchronization ---

func _physics_process(delta):
	# Host sends state to client
	if is_host and connected_client_id != 0 and is_instance_valid(player_ref) and is_instance_valid(invader_ref):
		var p_anim = ""
		if player_ref.get("animation_player"): p_anim = player_ref.animation_player.current_animation
		var i_anim = ""
		if invader_ref.get("animation_player"): i_anim = invader_ref.animation_player.current_animation
		
		rpc("sync_state", 
			player_ref.global_position, player_ref.rotation, p_anim,
			invader_ref.global_position, invader_ref.rotation, i_anim
		)
		
	# Client reads input and sends to Host
	if is_client and is_instance_valid(invader_ref):
		var dx = Input.get_axis("p2_move_left", "p2_move_right")
		if dx == 0.0: dx = Input.get_axis("move_left", "move_right") # Fallback to WASD for testing
		
		var dy = Input.get_axis("p2_move_forward", "p2_move_back")
		if dy == 0.0: dy = Input.get_axis("move_forward", "move_back")
		
		var attack = Input.is_action_just_pressed("p2_attack") or Input.is_action_just_pressed("attack")
		
		rpc_id(1, "send_invader_input", dx, dy, attack)

@rpc("authority", "call_remote", "unreliable_ordered")
func sync_state(p_pos: Vector3, p_rot: Vector3, p_anim: String, i_pos: Vector3, i_rot: Vector3, i_anim: String):
	if not is_client: return
	
	if is_instance_valid(player_ref):
		player_ref.global_position = p_pos
		player_ref.rotation = p_rot
		if p_anim != "" and player_ref.get("animation_player") and player_ref.animation_player.current_animation != p_anim:
			player_ref.animation_player.play(p_anim)
			
	if is_instance_valid(invader_ref):
		invader_ref.global_position = i_pos
		invader_ref.rotation = i_rot
		if i_anim != "" and invader_ref.get("animation_player") and invader_ref.animation_player.current_animation != i_anim:
			invader_ref.animation_player.play(i_anim)

@rpc("any_peer", "call_remote", "unreliable")
func send_invader_input(dx: float, dy: float, attack: bool):
	if not is_host: return
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != connected_client_id: return
	
	if is_instance_valid(invader_ref):
		invader_ref.set("net_dx", dx)
		invader_ref.set("net_dy", dy)
		if attack:
			invader_ref.set("net_attack", true)
