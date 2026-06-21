extends Node

var wind_player: AudioStreamPlayer
var water_player: AudioStreamPlayer3D
var wind_bus_idx: int
var water_bus_idx: int

func _ready():
	# Create audio streams
	var wind_stream = _create_noise_stream()
	var water_stream = _create_noise_stream()
	
	# Setup Buses
	wind_bus_idx = AudioServer.bus_count
	AudioServer.add_bus(wind_bus_idx)
	AudioServer.set_bus_name(wind_bus_idx, "WindBus")
	
	water_bus_idx = AudioServer.bus_count
	AudioServer.add_bus(water_bus_idx)
	AudioServer.set_bus_name(water_bus_idx, "WaterBus")
	
	# Wind Effects (Low frequency, gentle rumble)
	var wind_lpf = AudioEffectLowPassFilter.new()
	wind_lpf.cutoff_hz = 400.0
	wind_lpf.resonance = 0.2
	AudioServer.add_bus_effect(wind_bus_idx, wind_lpf)
	
	var wind_chorus = AudioEffectChorus.new()
	wind_chorus.voice_count = 2
	wind_chorus.set_voice_rate_hz(0, 0.5)
	wind_chorus.set_voice_depth_ms(0, 2.0)
	AudioServer.add_bus_effect(wind_bus_idx, wind_chorus)

	# Water Effects (Mid-high frequency, dynamic)
	var water_bpf = AudioEffectBandPassFilter.new()
	water_bpf.cutoff_hz = 1200.0
	water_bpf.resonance = 0.5
	AudioServer.add_bus_effect(water_bus_idx, water_bpf)
	
	var water_phaser = AudioEffectPhaser.new()
	water_phaser.rate_hz = 0.5
	water_phaser.depth = 1.0
	AudioServer.add_bus_effect(water_bus_idx, water_phaser)

	# Setup Players
	wind_player = AudioStreamPlayer.new()
	wind_player.stream = wind_stream
	wind_player.bus = "WindBus"
	wind_player.volume_db = -10.0
	add_child(wind_player)
	wind_player.play()
	
	water_player = AudioStreamPlayer3D.new()
	water_player.stream = water_stream
	water_player.bus = "WaterBus"
	# Position near the water level in the center
	water_player.position = Vector3(0, -0.6, 0)
	water_player.unit_size = 5.0
	water_player.max_distance = 30.0
	water_player.volume_db = -5.0
	add_child(water_player)
	water_player.play()

func _create_noise_stream() -> AudioStreamWAV:
	var mix_rate = 22050
	var length = 2.0
	var total_samples = int(mix_rate * length)
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	# Generate white noise and apply a simple moving average to soften it slightly
	var last_val = 0
	for i in range(total_samples):
		var noise = randi() % 65536 - 32768
		# Simple 1-pole lowpass to avoid harsh highs before bus effects
		var val = int(lerp(float(last_val), float(noise), 0.5))
		last_val = val
		
		# 16-bit little endian
		data.encode_s16(i * 2, val)
		
	stream.data = data
	return stream

func _process(delta):
	# Slightly modulate wind cutoff for dynamic weather feel
	var time = Time.get_ticks_msec() / 1000.0
	var modulation = (sin(time * 0.3) + sin(time * 0.7) * 0.5) * 0.5 # -0.75 to +0.75
	
	var lpf = AudioServer.get_bus_effect(wind_bus_idx, 0) as AudioEffectLowPassFilter
	if lpf:
		lpf.cutoff_hz = 400.0 + modulation * 150.0 # 250 to 550 Hz
