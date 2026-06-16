extends Node3D
class_name TerrainGenerator

var noise = FastNoiseLite.new()
const CHUNK_SIZE = 300
const RESOLUTION = 0.5 # Lower resolution for WebGL 16-bit limits

var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D

var height_multiplier: float = 5.0
var water_level: float = -0.5

func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	static_body = StaticBody3D.new()
	add_child(static_body)
	
	collision_shape = CollisionShape3D.new()
	static_body.add_child(collision_shape)
	
	# HeightMapShape3D defaults to 1 unit per vertex. We need to scale it down to match RESOLUTION
	static_body.scale = Vector3(1.0 / RESOLUTION, 1.0, 1.0 / RESOLUTION)

func generate(terrain_data: Dictionary):
	if terrain_data.has("seed"):
		noise.seed = terrain_data["seed"]
	if terrain_data.has("noise_scale"):
		noise.frequency = terrain_data["noise_scale"]
	if terrain_data.has("height_multiplier"):
		height_multiplier = terrain_data["height_multiplier"]
	if terrain_data.has("water_level"):
		water_level = terrain_data["water_level"]
		
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	_create_mesh()

func get_height(x: float, z: float) -> float:
	var h = noise.get_noise_2d(x, z) * height_multiplier
	
	# Force a dry plateau for the town at x=25, z=-25
	var town_center = Vector2(25.0, -25.0)
	var dist = Vector2(x, z).distance_to(town_center)
	if dist < 40.0:
		# Smoothly blend from plateau height (2.0) to natural noise height
		var blend = smoothstep(15.0, 40.0, dist)
		h = lerp(2.0, h, blend)
		
	return h

func _create_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var verts_per_row = int(CHUNK_SIZE * RESOLUTION)
	var step = 1.0 / RESOLUTION
	var offset = CHUNK_SIZE / 2.0
	
	var heights = PackedFloat32Array()
	heights.resize(verts_per_row * verts_per_row)
	
	for z in range(verts_per_row):
		for x in range(verts_per_row):
			var world_x = (x * step) - offset
			var world_z = (z * step) - offset
			
			var y = get_height(world_x, world_z)
			
			# Flatten the ground slightly if it goes below water level to make lakes flat
			if y < water_level:
				y = water_level - 0.2
			
			heights[z * verts_per_row + x] = y
			
			# Add UV and Vertex
			st.set_uv(Vector2(x, z) / float(verts_per_row))
			st.set_normal(Vector3.UP) # Will calculate normals later
			st.add_vertex(Vector3(world_x, y, world_z))
			
	for z in range(verts_per_row - 1):
		for x in range(verts_per_row - 1):
			var i = z * verts_per_row + x
			
			# Triangle 1
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + verts_per_row)
			
			# Triangle 2
			st.add_index(i + 1)
			st.add_index(i + verts_per_row + 1)
			st.add_index(i + verts_per_row)
			
	st.generate_normals()
	mesh_instance.mesh = st.commit()
	
	# Create procedural grass shader material
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Simple procedural noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),
			   mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);
}

void fragment() {
	float n1 = noise(world_pos.xz * 2.0);
	float n2 = noise(world_pos.xz * 10.0);
	
	vec3 color1 = vec3(0.18, 0.38, 0.13); // Darker green
	vec3 color2 = vec3(0.25, 0.45, 0.18); // Lighter green
	vec3 dirt_color = vec3(0.35, 0.28, 0.2); // Dirt
	
	vec3 albedo = mix(color1, color2, n1 * 0.7 + n2 * 0.3);
	
	// Add dirt on slopes
	float slope = 1.0 - NORMAL.y;
	albedo = mix(albedo, dirt_color, smoothstep(0.15, 0.4, slope));
	
	ALBEDO = albedo;
	ROUGHNESS = 0.9;
}
"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mesh_instance.material_override = mat
	
	# Create Collision
	var shape = HeightMapShape3D.new()
	shape.map_width = verts_per_row
	shape.map_depth = verts_per_row
	shape.map_data = heights
	collision_shape.shape = shape
