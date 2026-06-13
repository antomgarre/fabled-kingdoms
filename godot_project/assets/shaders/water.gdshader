shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

// === Colors ===
uniform vec4 water_color : source_color = vec4(0.05, 0.2, 0.45, 0.85);
uniform vec4 highlight_color : source_color = vec4(0.2, 0.55, 0.75, 0.9);
uniform vec4 foam_color : source_color = vec4(0.85, 0.92, 1.0, 0.9);

// === Waves ===
uniform float wave_speed : hint_range(0.0, 2.0) = 0.35;
uniform float wave_strength : hint_range(0.0, 0.5) = 0.1;
uniform float wave_freq : hint_range(0.0, 10.0) = 3.0;

// === Surface ===
uniform float roughness_val : hint_range(0.0, 1.0) = 0.02;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.4;
uniform float fresnel_power : hint_range(1.0, 10.0) = 4.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p); p *= 2.0; a *= 0.5;
	}
	return v;
}

void vertex() {
	float t = TIME * wave_speed;
	float w = sin(VERTEX.x * wave_freq + t * 1.3) * cos(VERTEX.z * wave_freq * 0.8 + t * 0.9);
	w += sin(VERTEX.x * wave_freq * 0.6 + t * 0.7) * cos(VERTEX.z * wave_freq * 1.1 + t * 1.1) * 0.7;
	w += sin((VERTEX.x + VERTEX.z) * wave_freq * 0.35 + t * 1.5) * 0.4;
	VERTEX.y += w * wave_strength;

	// Approximate normals from wave
	float dx = cos(VERTEX.x * wave_freq + t * 1.3) * wave_freq * wave_strength;
	float dz = -sin(VERTEX.z * wave_freq * 0.8 + t * 0.9) * wave_freq * 0.8 * wave_strength;
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
	float t = TIME * wave_speed * 0.4;

	// Animated surface detail
	vec2 uv1 = UV * 10.0 + vec2(t, t * 0.7);
	vec2 uv2 = UV * 7.0 - vec2(t * 0.6, t * 0.4);
	float n1 = fbm(uv1);
	float n2 = fbm(uv2);

	// Normal map from noise
	NORMAL_MAP = normalize(vec3((n1 - 0.5) * 2.0, 1.0, (n2 - 0.5) * 2.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.5;

	// Fresnel - bright edges when viewed at an angle
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

	// Base color with slight variation
	float color_noise = fbm(UV * 5.0 + vec2(t * 0.1));
	vec3 col = mix(water_color.rgb, highlight_color.rgb, color_noise * 0.4 + fresnel * 0.5);

	// Sun sparkles
	float sparkle = pow(fbm(UV * 40.0 + vec2(t * 0.5, t * 0.3)), 5.0) * 3.0;
	col += vec3(sparkle * 0.2);

	// Foam ribbons
	float foam = fbm(UV * 15.0 + vec2(t * 0.3, -t * 0.2));
	foam = smoothstep(0.55, 0.65, foam);
	col = mix(col, foam_color.rgb, foam * 0.25);

	ALBEDO = col;
	ALPHA = 1.0; // Fully opaque so the green terrain below doesn't tint the water
	ROUGHNESS = roughness_val;
	METALLIC = metallic_val;
	SPECULAR = 0.6;
}
