extends Node

## MusicManager.gd
## Procedurally synthesises two adaptive music themes using AudioStreamGenerator:
##   - Exploration: slow, calm, medieval flute-like melody over Am–F–C–G chords.
##   - Combat:      same progression, faster tempo, percussive noise bursts, bass drone.
## Switch themes via set_combat_mode(bool); crossfade is 2 s.
## mix_rate = 22050 Hz throughout to keep CPU load minimal.

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const MIX_RATE        := 22050          # Hz — matches AudioStreamGenerator mix_rate
const TWO_PI          := TAU            # convenience

# ---- Pentatonic A-minor note frequencies (A3–A4) ----
const SCALE_FREQS := [
	220.00,   # A3
	246.94,   # B3
	261.63,   # C4
	293.66,   # D4
	329.63,   # E4
	392.00,   # G4
	440.00,   # A4
]

# ---- Chord roots (in scale-index space, for colour) ----
# Am=0(A), F=2(C), C=2(C), G=5(G)  — we emphasise the root by weighting note picks
const CHORD_ROOTS_IDX := [0, 2, 2, 5]      # Am, F, C, G
const CHORD_BEATS     := 8                  # each chord lasts this many beats

# ---- Exploration melody (scale indices, loops automatically) ----
const MELODY_EXPL := [0, 2, 3, 4, 3, 2, 4, 5, 4, 3, 2, 0, 2, 4, 5, 6]

# ---- Combat melody (same notes, reordered for urgency) ----
const MELODY_CMBT := [4, 3, 2, 0, 4, 5, 4, 2, 6, 5, 4, 3, 2, 4, 3, 0]

# ---- ADSR parameters (in seconds / linear) ----
const ATTACK_S        := 0.02
const DECAY_S         := 0.10
const SUSTAIN_LEVEL   := 0.70
const RELEASE_S       := 0.30

# ---- Snare noise burst length (samples) ----
const SNARE_SAMPLES   := int(MIX_RATE * 0.008)   # 8 ms

# ---- Crossfade duration ----
const FADE_TIME       := 2.0   # seconds

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _expl_player  : AudioStreamPlayer
var _cmbt_player  : AudioStreamPlayer
var _expl_pb                                   # AudioStreamGeneratorPlayback
var _cmbt_pb                                   # AudioStreamGeneratorPlayback

var _is_combat    := false

# Per-player synthesis state (exploration)
var _expl_phase   := 0.0         # oscillator phase accumulator
var _expl_beat    := 0.0         # time within current beat (seconds)
var _expl_beat_idx := 0          # which beat we're on (for melody & chord)
var _expl_note_phase := 0.0      # where we are within the note's ADSR (seconds)
var _expl_note_dur  := 0.0       # total note duration (seconds)
var _expl_note_freq := 0.0       # current note frequency

# Per-player synthesis state (combat)
var _cmbt_phase     := 0.0
var _cmbt_beat      := 0.0
var _cmbt_beat_idx  := 0
var _cmbt_note_phase := 0.0
var _cmbt_note_dur   := 0.0
var _cmbt_note_freq  := 0.0
var _cmbt_bass_phase := 0.0      # low drone oscillator
var _cmbt_snare_buf  := []       # pre-baked snare burst (float samples)
var _cmbt_snare_pos  := -1       # playback position in snare (-1 = silent)

# Tempo (beats per second)
var _expl_bps     := 0.0
var _cmbt_bps     := 0.0

# Crossfade tween reference (we cancel old tween when called again)
var _fade_tween   : Tween

# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------

func _ready() -> void:
	_expl_bps = 1.0 / 0.55    # ~109 bpm (calm)
	_cmbt_bps = 1.0 / 0.28    # ~214 bpm (urgent — twice the speed)

	_setup_player("ExplorationPlayer", false)
	_setup_player("CombatPlayer",      true)

	# Start both; combat begins silent
	_expl_player.volume_db = 0.0
	_cmbt_player.volume_db = -80.0

	_expl_player.play()
	_cmbt_player.play()

	# Cache playback objects (available right after play())
	_expl_pb = _expl_player.get_stream_playback()
	_cmbt_pb = _cmbt_player.get_stream_playback()

	# Bake snare buffer once
	_bake_snare()

	# Prime first notes
	_next_expl_note()
	_next_cmbt_note()


func _setup_player(node_name: String, is_combat: bool) -> void:
	var gen  := AudioStreamGenerator.new()
	gen.mix_rate    = MIX_RATE
	gen.buffer_length = 0.2    # 200 ms lookahead — low latency, light RAM

	var player := AudioStreamPlayer.new()
	player.name   = node_name
	player.stream = gen
	add_child(player)

	if is_combat:
		_cmbt_player = player
	else:
		_expl_player = player


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Switch between exploration (false) and combat (true) themes.
func set_combat_mode(combat: bool) -> void:
	if _is_combat == combat:
		return
	_is_combat = combat

	# Kill any running crossfade
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()

	if combat:
		# Exploration fades out, Combat fades in
		_fade_tween.tween_property(_expl_player, "volume_db", -80.0, FADE_TIME)
		_fade_tween.parallel().tween_property(_cmbt_player, "volume_db", 0.0, FADE_TIME)
	else:
		# Combat fades out, Exploration fades in
		_fade_tween.tween_property(_cmbt_player, "volume_db", -80.0, FADE_TIME)
		_fade_tween.parallel().tween_property(_expl_player, "volume_db", 0.0, FADE_TIME)


# ---------------------------------------------------------------------------
# _process  — fill audio buffers every frame
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	_fill_exploration()
	_fill_combat()


# ---------------------------------------------------------------------------
# Buffer filling — Exploration
# ---------------------------------------------------------------------------

func _fill_exploration() -> void:
	if not _expl_pb:
		return
	var frames_avail : int = _expl_pb.get_frames_available()
	if frames_avail <= 0:
		return

	var dt := 1.0 / float(MIX_RATE)    # time per sample

	for _i in range(frames_avail):
		# ---- Advance beat clock ----
		_expl_beat += dt * _expl_bps
		if _expl_beat >= 1.0:
			_expl_beat -= 1.0
			_expl_beat_idx += 1
			_next_expl_note()

		# ---- ADSR envelope ----
		_expl_note_phase += dt
		var env := _adsr(_expl_note_phase, _expl_note_dur)

		# ---- Flute oscillator: sine + subtle 3rd harmonic (airy tone) ----
		_expl_phase += TWO_PI * _expl_note_freq * dt
		if _expl_phase > TWO_PI:
			_expl_phase -= TWO_PI
		var osc := sin(_expl_phase) * 0.85 + sin(_expl_phase * 3.0) * 0.10

		var sample := osc * env * 0.35     # master gain — preserves headroom
		_expl_pb.push_frame(Vector2(sample, sample))


# ---------------------------------------------------------------------------
# Buffer filling — Combat
# ---------------------------------------------------------------------------

func _fill_combat() -> void:
	if not _cmbt_pb:
		return
	var frames_avail : int = _cmbt_pb.get_frames_available()
	if frames_avail <= 0:
		return

	var dt := 1.0 / float(MIX_RATE)

	for _i in range(frames_avail):
		# ---- Beat clock ----
		_cmbt_beat += dt * _cmbt_bps
		if _cmbt_beat >= 1.0:
			_cmbt_beat -= 1.0
			_cmbt_beat_idx += 1
			_next_cmbt_note()
			# Snare on beat 2 and 4 (0-indexed: position 1 and 3 within each bar of 4)
			var beat_in_bar := _cmbt_beat_idx % 4
			if beat_in_bar == 1 or beat_in_bar == 3:
				_cmbt_snare_pos = 0

		# ---- Melody ADSR ----
		_cmbt_note_phase += dt
		var env := _adsr(_cmbt_note_phase, _cmbt_note_dur)

		# ---- Melody oscillator: sawtooth for urgency ----
		_cmbt_phase += TWO_PI * _cmbt_note_freq * dt
		if _cmbt_phase > TWO_PI:
			_cmbt_phase -= TWO_PI
		var melody := ((_cmbt_phase / TWO_PI) * 2.0 - 1.0) * env * 0.22

		# ---- Bass drone: low sine one octave below current chord root ----
		var chord_slot  := (_cmbt_beat_idx / CHORD_BEATS) % 4
		var bass_freq   := SCALE_FREQS[CHORD_ROOTS_IDX[chord_slot]] * 0.5
		_cmbt_bass_phase += TWO_PI * bass_freq * dt
		if _cmbt_bass_phase > TWO_PI:
			_cmbt_bass_phase -= TWO_PI
		var bass := sin(_cmbt_bass_phase) * 0.25

		# ---- Snare burst ----
		var snare_smp := 0.0
		if _cmbt_snare_pos >= 0 and _cmbt_snare_pos < _cmbt_snare_buf.size():
			snare_smp = _cmbt_snare_buf[_cmbt_snare_pos]
			_cmbt_snare_pos += 1
			if _cmbt_snare_pos >= _cmbt_snare_buf.size():
				_cmbt_snare_pos = -1

		var sample := clampf(melody + bass + snare_smp, -1.0, 1.0)
		_cmbt_pb.push_frame(Vector2(sample, sample))


# ---------------------------------------------------------------------------
# Note sequencing helpers
# ---------------------------------------------------------------------------

func _next_expl_note() -> void:
	var melody_idx    := _expl_beat_idx % MELODY_EXPL.size()
	_expl_note_freq   = SCALE_FREQS[MELODY_EXPL[melody_idx]]
	_expl_note_dur    = 1.0 / _expl_bps      # one full beat in seconds
	_expl_note_phase  = 0.0


func _next_cmbt_note() -> void:
	var melody_idx    := _cmbt_beat_idx % MELODY_CMBT.size()
	_cmbt_note_freq   = SCALE_FREQS[MELODY_CMBT[melody_idx]]
	_cmbt_note_dur    = 1.0 / _cmbt_bps
	_cmbt_note_phase  = 0.0


# ---------------------------------------------------------------------------
# ADSR envelope — returns amplitude in [0..1]
#   t   : time elapsed since note-on (seconds)
#   dur : total scheduled note duration (seconds)
# ---------------------------------------------------------------------------

func _adsr(t: float, dur: float) -> float:
	if t < 0.0:
		return 0.0

	# Attack phase
	if t < ATTACK_S:
		return t / ATTACK_S

	# Decay → Sustain
	var after_attack := t - ATTACK_S
	if after_attack < DECAY_S:
		return lerpf(1.0, SUSTAIN_LEVEL, after_attack / DECAY_S)

	# Sustain (hold until release begins)
	var release_start := dur - RELEASE_S
	if t < release_start:
		return SUSTAIN_LEVEL

	# Release
	var rel_t := t - release_start
	if rel_t < RELEASE_S:
		return lerpf(SUSTAIN_LEVEL, 0.0, rel_t / RELEASE_S)

	return 0.0


# ---------------------------------------------------------------------------
# _bake_snare: pre-compute a short hi-passed white-noise burst.
# Stored as Array of floats, played back via _cmbt_snare_pos index.
# ---------------------------------------------------------------------------

func _bake_snare() -> void:
	_cmbt_snare_buf.resize(SNARE_SAMPLES)
	var prev := 0.0
	for i in range(SNARE_SAMPLES):
		# Raw white noise sample
		var noise := randf_range(-1.0, 1.0)
		# One-pole highpass: removes low rumble, emphasises mid-range crack
		var hp := noise - prev * 0.5
		prev = noise
		# Exponential amplitude decay over the burst window
		var env := pow(1.0 - float(i) / float(SNARE_SAMPLES), 2.0)
		_cmbt_snare_buf[i] = hp * env * 0.35
