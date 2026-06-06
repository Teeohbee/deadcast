# autoload/Audio.gd
extends Node

const MIX_RATE := 44100.0
const HUM_VOLUME_DB := -16.0
const CLICK_VOLUME_DB := -6.0
const CROSSFADE_DURATION := 1.5
const FOCUS_VOLUME_DB := -18.0
const FOCUS_DURATION := 0.01
const FOCUS_COOLDOWN := 0.08

# Hum state
var _hum_active := false
var _hum_blend := 0.0       # 0.0 = barge, 1.0 = dive
var _target_blend := 0.0
var _sample_pos := 0        # cumulative sample counter

# Crackle state
var _crackle_timer := 0.0
var _crackle_remaining := 0.0
var _next_crackle_in := 0.0

# Click state
var _click_buffer: PackedFloat32Array
var _click_pos := 0
var _click_active := false

# Focus state
var _focus_buffer: PackedFloat32Array
var _focus_pos := 0
var _focus_active := false
var _focus_cooldown := 0.0

# Audio nodes
var _hum_player: AudioStreamPlayer
var _hum_gen: AudioStreamGenerator
var _hum_playback: AudioStreamGeneratorPlayback

var _click_player: AudioStreamPlayer
var _click_gen: AudioStreamGenerator
var _click_playback: AudioStreamGeneratorPlayback

var _focus_player: AudioStreamPlayer
var _focus_gen: AudioStreamGenerator
var _focus_playback: AudioStreamGeneratorPlayback

func _ready() -> void:
	_hum_gen = AudioStreamGenerator.new()
	_hum_gen.mix_rate = MIX_RATE
	_hum_gen.buffer_length = 0.1
	_hum_player = AudioStreamPlayer.new()
	_hum_player.stream = _hum_gen
	_hum_player.volume_db = HUM_VOLUME_DB
	add_child(_hum_player)

	_click_gen = AudioStreamGenerator.new()
	_click_gen.mix_rate = MIX_RATE
	_click_gen.buffer_length = 0.1
	_click_player = AudioStreamPlayer.new()
	_click_player.stream = _click_gen
	_click_player.volume_db = CLICK_VOLUME_DB
	add_child(_click_player)

	_hum_player.play()
	_hum_playback = _hum_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_click_player.play()
	_click_playback = _click_player.get_stream_playback() as AudioStreamGeneratorPlayback

	_focus_gen = AudioStreamGenerator.new()
	_focus_gen.mix_rate = MIX_RATE
	_focus_gen.buffer_length = 0.1
	_focus_player = AudioStreamPlayer.new()
	_focus_player.stream = _focus_gen
	_focus_player.volume_db = FOCUS_VOLUME_DB
	add_child(_focus_player)
	_focus_player.play()
	_focus_playback = _focus_player.get_stream_playback() as AudioStreamGeneratorPlayback

	_next_crackle_in = _rand_crackle_interval()

	UIController.screen_changed.connect(_on_screen_changed)
	UIController.dive_state_changed.connect(_on_dive_state_changed)
	get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
	_fill_hum(delta)
	_fill_click()
	_fill_focus(delta)

func _fill_hum(delta: float) -> void:
	if _hum_playback == null:
		return
	var frames := _hum_playback.get_frames_available()

	if not _hum_active:
		for _i in frames:
			_hum_playback.push_frame(Vector2.ZERO)
		return

	_hum_blend = move_toward(_hum_blend, _target_blend, delta / CROSSFADE_DURATION)

	_crackle_timer += delta
	if _crackle_remaining <= 0.0 and _crackle_timer >= _next_crackle_in:
		_crackle_remaining = 0.02
		_crackle_timer = 0.0
		_next_crackle_in = _rand_crackle_interval()
	if _crackle_remaining > 0.0:
		_crackle_remaining -= delta

	var base_freq: float = lerp(60.0, 40.0, _hum_blend)
	var h3_amp: float = lerp(0.2, 0.0, _hum_blend)

	for _i in frames:
		var t := float(_sample_pos) / MIX_RATE
		var lfo := 1.0 + 0.06 * sin(TAU * 0.1 * t)
		var sample := sin(TAU * base_freq * t)
		sample += sin(TAU * base_freq * 2.0 * t) * 0.4
		sample += sin(TAU * base_freq * 3.0 * t) * h3_amp
		sample *= lfo * 0.3
		if _crackle_remaining > 0.0:
			sample += randf_range(-0.25, 0.25)
		_hum_playback.push_frame(Vector2(sample, sample))
		_sample_pos += 1

func _fill_click() -> void:
	if _click_playback == null:
		return
	var frames := _click_playback.get_frames_available()
	for _i in frames:
		if not _click_active or _click_pos >= _click_buffer.size():
			_click_playback.push_frame(Vector2.ZERO)
		else:
			var s := _click_buffer[_click_pos]
			_click_playback.push_frame(Vector2(s, s))
			_click_pos += 1
			if _click_pos >= _click_buffer.size():
				_click_active = false

func play_focus() -> void:
	if _focus_cooldown > 0.0:
		return
	var samples := int(MIX_RATE * FOCUS_DURATION)
	_focus_buffer.resize(samples)
	for i in samples:
		var t := float(i) / MIX_RATE
		var env := exp(-6.0 * t / FOCUS_DURATION)
		var noise := randf_range(-0.15, 0.15) * env
		_focus_buffer[i] = sin(TAU * 2000.0 * t) * env * 0.4 + noise
	_focus_pos = 0
	_focus_active = true
	_focus_cooldown = FOCUS_COOLDOWN

func _fill_focus(delta: float) -> void:
	_focus_cooldown = maxf(_focus_cooldown - delta, 0.0)
	if _focus_playback == null:
		return
	var frames := _focus_playback.get_frames_available()
	for _i in frames:
		if not _focus_active or _focus_pos >= _focus_buffer.size():
			_focus_playback.push_frame(Vector2.ZERO)
		else:
			var s := _focus_buffer[_focus_pos]
			_focus_playback.push_frame(Vector2(s, s))
			_focus_pos += 1
			if _focus_pos >= _focus_buffer.size():
				_focus_active = false

func play_click() -> void:
	var pitch := 1.0 + randf_range(-0.08, 0.08)
	var samples := int(MIX_RATE * 0.015)  # 15ms
	_click_buffer.resize(samples)
	for i in samples:
		var t := float(i) / MIX_RATE
		var noise_env := exp(-8.0 * t / 0.015)
		var noise := randf_range(-1.0, 1.0) * noise_env * 0.6
		var thunk_env := exp(-5.0 * t / 0.015)
		var thunk := sin(TAU * 150.0 * pitch * t) * thunk_env * 0.8
		_click_buffer[i] = clamp(noise + thunk, -0.9, 0.9)
	_click_pos = 0
	_click_active = true

func stop_hum() -> void:
	_hum_active = false

func _on_screen_changed(_id: String) -> void:
	_hum_active = true

func _on_dive_state_changed(is_dive: bool) -> void:
	_target_blend = 1.0 if is_dive else 0.0

func _on_node_added(node: Node) -> void:
	if node is Button:
		node.pressed.connect(play_click)
		node.focus_entered.connect(play_focus)

func _rand_crackle_interval() -> float:
	return randf_range(5.0, 15.0)
