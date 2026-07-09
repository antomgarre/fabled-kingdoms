extends CanvasLayer

var hp_bar: ProgressBar
var hp_ghost_bar: ProgressBar
var hp_label: Label
var stamina_bar: ProgressBar
var mana_bar: ProgressBar
var xp_label: Label
var total_xp: int = 0
var enemy_bars = {}

# === Minimap variables ===
var minimap_panel: PanelContainer
var minimap_texture_rect: TextureRect
var minimap_overlay: Control
var terrain_node: Node
var player_node: Node3D
var map_bounds: Rect2
var is_minimap_initialized: bool = false

# === Steam Lobby UI ===
var lobby_id_label: Label

func _ready():
	# === HP/Stamina HUD Container ===
	var panel = PanelContainer.new()
	panel.name = "HPPanel"
	panel.position = Vector2(20, 20)
	panel.size = Vector2(260, 95)
	
	# Dark background style with golden glowing border
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.65, 0.2, 0.8)
	
	# Add subtle glow
	style.shadow_color = Color(0.8, 0.65, 0.2, 0.3)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	# HP Label
	hp_label = Label.new()
	hp_label.text = "❤️ HP"
	hp_label.add_theme_font_size_override("font_size", 16)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	vbox.add_child(hp_label)
	
	# HP Bars Container (Overlay)
	var bar_container = MarginContainer.new()
	bar_container.custom_minimum_size = Vector2(230, 20)
	vbox.add_child(bar_container)
	
	# Ghost Bar (Background, updates slowly)
	hp_ghost_bar = ProgressBar.new()
	hp_ghost_bar.max_value = 100
	hp_ghost_bar.value = 100
	hp_ghost_bar.show_percentage = false
	hp_ghost_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var ghost_fill = StyleBoxFlat.new()
	ghost_fill.bg_color = Color(0.6, 0.1, 0.1) # Dark red
	ghost_fill.corner_radius_top_left = 4
	ghost_fill.corner_radius_top_right = 4
	ghost_fill.corner_radius_bottom_left = 4
	ghost_fill.corner_radius_bottom_right = 4
	hp_ghost_bar.add_theme_stylebox_override("fill", ghost_fill)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.05, 0.05)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	hp_ghost_bar.add_theme_stylebox_override("background", bg_style)
	bar_container.add_child(hp_ghost_bar)
	
	# Main HP Bar (Foreground, transparent background, updates instantly)
	hp_bar = ProgressBar.new()
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var main_fill = StyleBoxFlat.new()
	main_fill.bg_color = Color(0.2, 0.8, 0.2) # Starts green
	main_fill.corner_radius_top_left = 4
	main_fill.corner_radius_top_right = 4
	main_fill.corner_radius_bottom_left = 4
	main_fill.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", main_fill)
	
	var trans_bg = StyleBoxEmpty.new()
	hp_bar.add_theme_stylebox_override("background", trans_bg)
	bar_container.add_child(hp_bar)
	
	# Stamina Bar
	stamina_bar = ProgressBar.new()
	stamina_bar.max_value = 200
	stamina_bar.value = 200
	stamina_bar.show_percentage = false
	stamina_bar.custom_minimum_size = Vector2(230, 8)
	
	var stamina_fill = StyleBoxFlat.new()
	stamina_fill.bg_color = Color(0.2, 0.6, 1.0) # Blue
	stamina_fill.corner_radius_top_left = 2
	stamina_fill.corner_radius_top_right = 2
	stamina_fill.corner_radius_bottom_left = 2
	stamina_fill.corner_radius_bottom_right = 2
	stamina_bar.add_theme_stylebox_override("fill", stamina_fill)
	
	var stamina_bg = StyleBoxFlat.new()
	stamina_bg.bg_color = Color(0.05, 0.1, 0.2)
	stamina_bg.corner_radius_top_left = 2
	stamina_bg.corner_radius_top_right = 2
	stamina_bg.corner_radius_bottom_left = 2
	stamina_bg.corner_radius_bottom_right = 2
	stamina_bar.add_theme_stylebox_override("background", stamina_bg)
	vbox.add_child(stamina_bar)
	
	# Mana Bar
	mana_bar = ProgressBar.new()
	mana_bar.max_value = 100
	mana_bar.value = 100
	mana_bar.show_percentage = false
	mana_bar.custom_minimum_size = Vector2(230, 8)
	
	var mana_fill = StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.6, 0.2, 0.8) # Purple
	mana_fill.corner_radius_top_left = 2
	mana_fill.corner_radius_top_right = 2
	mana_fill.corner_radius_bottom_left = 2
	mana_fill.corner_radius_bottom_right = 2
	mana_bar.add_theme_stylebox_override("fill", mana_fill)
	
	var mana_bg = StyleBoxFlat.new()
	mana_bg.bg_color = Color(0.1, 0.05, 0.2) # Dark purple/black
	mana_bg.corner_radius_top_left = 2
	mana_bg.corner_radius_top_right = 2
	mana_bg.corner_radius_bottom_left = 2
	mana_bg.corner_radius_bottom_right = 2
	mana_bar.add_theme_stylebox_override("background", mana_bg)
	vbox.add_child(mana_bar)
	
	# XP Label
	xp_label = Label.new()
	xp_label.text = "✦ XP: 0"
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(xp_label)
	
	# === Crosshair (subtle center dot) ===
	var crosshair = Label.new()
	crosshair.text = "·"
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.anchors_preset = Control.PRESET_CENTER
	crosshair.position = Vector2(-10, -16)
	add_child(crosshair)
	
	# === Steam Lobby Label ===
	lobby_id_label = Label.new()
	lobby_id_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	lobby_id_label.position = Vector2(20, -50)
	lobby_id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lobby_id_label.add_theme_font_size_override("font_size", 16)
	lobby_id_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))
	add_child(lobby_id_label)
	
	# === Minimap Setup ===
	# Wait a frame or two to make sure nodes are added to tree
	call_deferred("_setup_minimap")

func _process(_delta: float):
	# Update Steam Lobby ID
	if lobby_id_label:
		var sm = get_node_or_null("/root/SteamManager")
		if sm and sm.get("current_lobby_id") != null and sm.current_lobby_id > 0:
			lobby_id_label.text = "Código Sala: " + sm.get_lobby_code()
		else:
			lobby_id_label.text = ""

	if is_minimap_initialized:
		if not is_instance_valid(player_node):
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				player_node = players[0]
				
		if minimap_overlay:
			minimap_overlay.queue_redraw()
			
		# Update Minimap Centering (4x Zoom)
		if is_instance_valid(player_node) and is_instance_valid(minimap_texture_rect):
			var pos_2d = Vector2(player_node.global_position.x, player_node.global_position.z)
			var norm = (pos_2d - map_bounds.position) / map_bounds.size
			norm.x = clamp(norm.x, 0.0, 1.0)
			norm.y = clamp(norm.y, 0.0, 1.0)
			var center_offset = Vector2(96, 96) # Half of the 192x192 clip container
			var map_px = minimap_texture_rect.size
			minimap_texture_rect.position = center_offset - (norm * map_px)

func _setup_minimap() -> void:
	# 1. Locate Terrain3D Node in active scene
	terrain_node = get_tree().root.find_child("Terrain3D", true, false) if get_tree() else null
		
	if not terrain_node or not terrain_node.data:
		push_error("Minimap HUD: Terrain3D or Terrain3DData not found in scene tree!")
		return
		
	# 2. Determine Map Walkable Boundaries
	map_bounds = _calculate_map_bounds()
	
	# 3. Create Minimap Panel Container
	minimap_panel = PanelContainer.new()
	minimap_panel.name = "MinimapPanel"
	
	# Anchor to bottom right with 20px margins
	minimap_panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	minimap_panel.anchor_left = 1.0
	minimap_panel.anchor_right = 1.0
	minimap_panel.anchor_top = 1.0
	minimap_panel.anchor_bottom = 1.0
	minimap_panel.offset_left = -220
	minimap_panel.offset_right = -20
	minimap_panel.offset_top = -220
	minimap_panel.offset_bottom = -20
	
	# Same styling as HPPanel (golden glowing border)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.65, 0.2, 0.8)
	style.shadow_color = Color(0.8, 0.65, 0.2, 0.3)
	style.shadow_size = 8
	minimap_panel.add_theme_stylebox_override("panel", style)
	add_child(minimap_panel)
	
	# Margin container inside panel
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	minimap_panel.add_child(margin)
	
	# 4. Generate and display 2D static representation of terrain
	var terrain_texture = _generate_terrain_texture()
	
	var clip_control = Control.new()
	clip_control.clip_contents = true
	clip_control.custom_minimum_size = Vector2(192, 192)
	clip_control.size = Vector2(192, 192)
	margin.add_child(clip_control)
	
	minimap_texture_rect = TextureRect.new()
	minimap_texture_rect.name = "MinimapTexture"
	minimap_texture_rect.texture = terrain_texture
	minimap_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	minimap_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	var zoom_size = 192 * 4.0 # 4x Zoom
	minimap_texture_rect.custom_minimum_size = Vector2(zoom_size, zoom_size)
	minimap_texture_rect.size = Vector2(zoom_size, zoom_size)
	clip_control.add_child(minimap_texture_rect)
	
	# 5. Add overlay for drawing markers
	minimap_overlay = Control.new()
	minimap_overlay.name = "MinimapOverlay"
	minimap_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	minimap_overlay.draw.connect(_on_overlay_draw)
	minimap_texture_rect.add_child(minimap_overlay)
	
	is_minimap_initialized = true
	print("[DEBUG] Minimap HUD successfully initialized. Bounds: ", map_bounds)

func _calculate_map_bounds() -> Rect2:
  	# Look for WorldBoundaries in active scene
	var boundaries = get_tree().root.find_child("WorldBoundaries", true, false) if get_tree() else null
	print("[DEBUG] Map bounds calculation. Found boundaries: ", boundaries)
		
	if boundaries:
		var east = boundaries.get_node_or_null("CollisionShape3D_East")
		var west = boundaries.get_node_or_null("CollisionShape3D_West")
		var north = boundaries.get_node_or_null("CollisionShape3D_North")
		var south = boundaries.get_node_or_null("CollisionShape3D_South")
		print("[DEBUG] Map bounds walls: East: ", east, ", West: ", west, ", North: ", north, ", South: ", south)
		
		if east and west and north and south:
			var east_size = east.shape.size if east.shape else Vector3.ZERO
			var west_size = west.shape.size if west.shape else Vector3.ZERO
			var north_size = north.shape.size if north.shape else Vector3.ZERO
			var south_size = south.shape.size if south.shape else Vector3.ZERO
			
			var min_x = west.global_position.x + (west_size.x / 2.0)
			var max_x = east.global_position.x - (east_size.x / 2.0)
			var min_z = north.global_position.z + (north_size.z / 2.0)
			var max_z = south.global_position.z - (south_size.z / 2.0)
			
			return Rect2(min_x, min_z, max_x - min_x, max_z - min_z)
			
	# Fallback: Calculate bounds from Terrain3D region locations
	if terrain_node and terrain_node.data:
		var locations = terrain_node.data.get_region_locations()
		if not locations.is_empty():
			var region_size = terrain_node.region_size
			var spacing = terrain_node.vertex_spacing
			var r_world = float(region_size) * spacing
			
			var min_x = INF
			var min_z = INF
			var max_x = -INF
			var max_z = -INF
			for loc in locations:
				var rx = loc.x * r_world
				var rz = loc.y * r_world
				min_x = min(min_x, rx)
				min_z = min(min_z, rz)
				max_x = max(max_x, rx + r_world)
				max_z = max(max_z, rz + r_world)
			return Rect2(min_x, min_z, max_x - min_x, max_z - min_z)
			
	# Hardcoded default fallback
	return Rect2(-500, -500, 1000, 1000)

func _generate_terrain_texture() -> ImageTexture:
	var img_size = 256
	var img = Image.create(img_size, img_size, false, Image.FORMAT_RGBA8)
	
	var data = terrain_node.data
	var height_range = data.get_height_range()
	var min_h = height_range.x
	var max_h = height_range.y
	if max_h == min_h:
		max_h += 1.0
		
	# Shading setup
	var light_dir = Vector3(0.5, 1.0, 0.5).normalized()
	
	# Sample grid
	for y in range(img_size):
		for x in range(img_size):
			# Map pixel position to 3D world coordinates
			var px = map_bounds.position.x + (float(x) / img_size) * map_bounds.size.x
			var pz = map_bounds.position.y + (float(y) / img_size) * map_bounds.size.y
			var world_pos = Vector3(px, 0.0, pz)
			
			var h = data.get_height(world_pos)
			var pixel_color = Color(0.1, 0.1, 0.1, 1.0) # Dark gray for out of bounds
			
			if not is_nan(h):
				var normal = data.get_normal(world_pos)
				var slope = 1.0 - normal.y # 0 is flat, 1 is vertical cliff
				
				# Get painted color tint if any
				var tint = data.get_color(world_pos)
				if is_nan(tint.r):
					tint = Color.WHITE
					
				# Base color based on slope and height (reproducing dynamic biome coloring)
				var base_color = Color(0.25, 0.45, 0.18) # Lush grass green
				
				if h < 2.7: # Deep water (matches global water plane at ~2.68)
					base_color = Color(0.1, 0.25, 0.55)
				elif h < 5.0: # Beach/sand
					base_color = Color(0.76, 0.70, 0.50)
				elif slope > 0.3: # Cliff
					base_color = Color(0.45, 0.40, 0.36)
				elif h > 300.0: # Snow cap
					base_color = Color(0.95, 0.95, 0.95)
					
				# Calculate hillshading (lighting)
				var shade = normal.dot(light_dir)
				shade = clamp((shade + 1.0) * 0.5, 0.4, 1.1)
				
				pixel_color = base_color * tint * shade
				pixel_color.a = 1.0
				
			img.set_pixel(x, y, pixel_color)
			
	return ImageTexture.create_from_image(img)

func _on_overlay_draw() -> void:
	if not is_minimap_initialized or not is_instance_valid(minimap_texture_rect) or not get_tree() or not get_tree().current_scene:
		return
		
	var overlay_size = minimap_overlay.size
	
	# Helper: map 3D world coordinate to 2D overlay coordinate
	var to_minimap_space = func(world_pos: Vector3) -> Vector2:
		var pos_2d = Vector2(world_pos.x, world_pos.z)
		var norm = (pos_2d - map_bounds.position) / map_bounds.size
		norm.x = clamp(norm.x, 0.0, 1.0)
		norm.y = clamp(norm.y, 0.0, 1.0)
		return norm * overlay_size
		
	# 1. Draw NPCs (Green circles)
	var npcs = []
	if get_tree():
		_find_npcs(get_tree().root, npcs)
	for npc in npcs:
		if is_instance_valid(npc):
			var draw_pos = to_minimap_space.call(npc.global_position)
			minimap_overlay.draw_circle(draw_pos, 4.0, Color.GREEN)
			minimap_overlay.draw_arc(draw_pos, 4.0, 0, PI * 2, 8, Color.BLACK, 1.0)
			
	# 2. Draw Enemies (Red circles)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			var draw_pos = to_minimap_space.call(enemy.global_position)
			minimap_overlay.draw_circle(draw_pos, 4.0, Color.RED)
			minimap_overlay.draw_arc(draw_pos, 4.0, 0, PI * 2, 8, Color.BLACK, 1.0)
			
	# 3. Draw Campfire (Orange circle)
	var campfire = get_tree().root.find_child("Campfire", true, false) if get_tree() else null
	if campfire and is_instance_valid(campfire):
		var draw_pos = to_minimap_space.call(campfire.global_position)
		minimap_overlay.draw_circle(draw_pos, 5.0, Color(1.0, 0.5, 0.0))
		minimap_overlay.draw_arc(draw_pos, 5.0, 0, PI * 2, 8, Color.BLACK, 1.0)
		
	# 4. Draw Player (Gold rotated chevron)
	if is_instance_valid(player_node):
		var draw_pos = to_minimap_space.call(player_node.global_position)
		var rot = 0.0
		if player_node.has_node("Pivot"):
			rot = -player_node.get_node("Pivot").global_rotation.y + PI
		else:
			rot = -player_node.global_rotation.y + PI
		
		var chevron_points = PackedVector2Array([
			Vector2(0, -9),  # Tip
			Vector2(-7, 7),  # Bottom-left
			Vector2(0, 3),   # Indent
			Vector2(7, 7)    # Bottom-right
		])
		
		# Rotate and translate chevron vertices
		var rotated_points = PackedVector2Array()
		for pt in chevron_points:
			rotated_points.append(pt.rotated(rot) + draw_pos)
			
		minimap_overlay.draw_colored_polygon(rotated_points, Color(1.0, 0.84, 0.0)) # Gold
		
		# Outline for chevron
		var outline = PackedVector2Array([
			rotated_points[0],
			rotated_points[1],
			rotated_points[2],
			rotated_points[3],
			rotated_points[0]
		])
		minimap_overlay.draw_polyline(outline, Color.BLACK, 1.5)

func _find_npcs(node: Node, npcs: Array) -> void:
	if node.get_script():
		var path = node.get_script().resource_path
		if "NPC.gd" in path:
			npcs.append(node)
	for child in node.get_children():
		_find_npcs(child, npcs)

# === Existing player stats HUD update methods ===
func update_player_hp(current: float, maximum: float):
	if hp_bar:
		hp_bar.max_value = maximum
		hp_ghost_bar.max_value = maximum
		
		# Update color based on percentage
		var pct = current / maximum
		var fill_style = hp_bar.get_theme_stylebox("fill").duplicate()
		if pct > 0.5:
			fill_style.bg_color = Color(0.2, 0.8, 0.2) # Green
		elif pct > 0.25:
			fill_style.bg_color = Color(0.9, 0.6, 0.1) # Orange
		else:
			fill_style.bg_color = Color(0.9, 0.1, 0.1) # Bright Red
		hp_bar.add_theme_stylebox_override("fill", fill_style)
		
		var damage_taken = current < hp_bar.value
		
		# Main bar updates instantly
		hp_bar.value = current
		
		hp_label.text = "❤️ HP  " + str(int(current)) + " / " + str(int(maximum))
		
		if damage_taken:
			# Flash label
			var flash = create_tween()
			flash.tween_property(hp_label, "modulate", Color(1, 0.3, 0.3), 0.1)
			flash.tween_property(hp_label, "modulate", Color(1, 1, 1), 0.3)
			
			# Tween ghost bar down with a delay to show the "damage chunk"
			var tween = create_tween()
			tween.tween_interval(0.3)
			tween.tween_property(hp_ghost_bar, "value", current, 0.5).set_ease(Tween.EASE_OUT)
		else:
			# If healing, update ghost instantly too
			hp_ghost_bar.value = current

func update_stamina(current: float, maximum: float):
	if stamina_bar:
		stamina_bar.max_value = maximum
		stamina_bar.value = current

func update_mana(current: float, maximum: float):
	if mana_bar:
		mana_bar.max_value = maximum
		mana_bar.value = current

func update_xp(level: int, current: int, maximum: int):
	if xp_label:
		xp_label.text = "✦ Lvl " + str(level) + " (" + str(current) + "/" + str(maximum) + " XP)"

func pulse_xp():
	if xp_label:
		var tween = create_tween()
		tween.tween_property(xp_label, "modulate", Color(2.0, 2.0, 2.0), 0.1)
		tween.tween_property(xp_label, "modulate", Color(1.0, 1.0, 1.0), 0.3)

func create_enemy_hp_bar(_enemy_id: int):
	pass

func update_enemy_hp(_enemy_id: int, _current: int, _maximum: int, _screen_pos: Vector2):
	pass

func remove_enemy_hp_bar(_enemy_id: int):
	pass
