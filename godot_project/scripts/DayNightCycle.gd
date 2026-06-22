extends DirectionalLight3D

@export var day_length_seconds: float = 600.0 # 10 minutes
var time: float = 15.0

@onready var world_env: WorldEnvironment = $"../WorldEnvironment"

func _ready():
	# Enable basic fog
	if world_env and world_env.environment:
		var env = world_env.environment
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_density = 0.015

func _process(delta):
	time += delta
	var cycle = fmod(time, day_length_seconds) / day_length_seconds
	
	# Rotate the light
	# 1 full cycle = 360 degrees. Let's make it rotate around the X axis.
	# At cycle = 0, angle is 0 (sunrise)
	# At cycle = 0.25, angle is 90 (noon)
	# At cycle = 0.5, angle is 180 (sunset)
	# At cycle = 0.75, angle is 270 (midnight)
	var angle = cycle * PI * 2.0
	
	# Set rotation
	rotation.x = -angle # Start horizontally? We need -PI/2 to be straight down at noon.
	# Wait, if rotation.x = 0, light is horizontal.
	# If rotation.x = -PI/2 (-90 deg), light is shining straight down.
	# So let's offset it so it makes sense.
	rotation.x = -angle
	
	# Calculate intensity based on sun's angle
	# When sun is above horizon (rotation.x between -180 and 0 loosely), sin(angle) can help.
	# Actually, light direction is -transform.basis.z. The Y component is the vertical direction.
	var light_dir = -transform.basis.z
	var sun_height = light_dir.y # 1 at noon, 0 at horizon, -1 at midnight
	
	# Energy smoothly goes from 0 to 1
	var target_energy = clamp(sun_height * 2.0, 0.0, 1.0)
	light_energy = target_energy
	
	if world_env and world_env.environment:
		var env = world_env.environment
		
		# Change sky and ambient colors based on time
		var day_sky_color = Color(0.18, 0.32, 0.54)
		var night_sky_color = Color(0.05, 0.05, 0.1)
		
		var day_horizon_color = Color(0.85, 0.9, 0.95)
		var sunset_horizon_color = Color(0.8, 0.4, 0.2)
		var night_horizon_color = Color(0.1, 0.1, 0.2)
		
		var t_height = clamp(sun_height, 0.0, 1.0) # 0 to 1 during day
		var t_sunset = clamp(1.0 - abs(sun_height) * 4.0, 0.0, 1.0) # Peaks near horizon
		var t_night = clamp(-sun_height, 0.0, 1.0) # 0 to 1 during night
		
		# Sky top color
		var current_sky_color = day_sky_color.lerp(night_sky_color, t_night)
		
		# Horizon color (mix between day, sunset, night)
		var current_horizon_color = day_horizon_color
		if sun_height < 0.2 and sun_height > -0.2:
			# Blend sunset
			current_horizon_color = day_horizon_color.lerp(sunset_horizon_color, t_sunset)
			if sun_height < 0:
				current_horizon_color = sunset_horizon_color.lerp(night_horizon_color, t_night * 5.0)
		elif sun_height <= -0.2:
			current_horizon_color = night_horizon_color
			
		var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
		if sky_mat:
			sky_mat.sky_top_color = current_sky_color
			sky_mat.sky_horizon_color = current_horizon_color
			# Sync ground color to avoid a sharp horizon
			sky_mat.ground_horizon_color = current_horizon_color
			sky_mat.ground_bottom_color = current_sky_color.darkened(0.5)
			
		env.ambient_light_energy = max(0.1, target_energy * 0.8)
		
		# Sync fog color
		env.fog_light_color = current_horizon_color
