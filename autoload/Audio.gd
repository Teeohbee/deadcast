# autoload/Audio.gd
extends Node

const MIX_RATE := 44100.0
const HUM_VOLUME_DB := -16.0
const CLICK_VOLUME_DB := -6.0
const CROSSFADE_DURATION := 1.5

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

# Audio nodes
var _hum_player: AudioStreamPlayer
var _hum_gen: AudioStreamGenerator
var _hum_playback: AudioStreamGeneratorPlayback

var _click_player: AudioStreamPlayer
var _click_gen: AudioStreamGenerator
var _click_playback: AudioStreamGeneratorPlayback

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

	_next_crackle_in = _rand_crackle_interval()

	UIController.screen_changed.connect(_on_screen_changed)
	UIController.dive_state_changed.connect(_on_dive_state_changed)
	get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
	_fill_hum(delta)
	_fill_click()

func _fill_hum(delta: float) -> void:
	if _hum_playback == null:
		return
	var frames := _hum_playback.get_frames_available()
	for _i in frames:
		_hum_playback.push_frame(Vector2.ZERO)

func _fill_click() -> void:
	if _click_playback == null:
		return
	var frames := _click_playback.get_frames_available()
	for _i in frames:
		_click_playback.push_frame(Vector2.ZERO)

func play_click() -> void:
	pass  # implemented in Task 5

func stop_hum() -> void:
	_hum_active = false

func _on_screen_changed(_id: String) -> void:
	_hum_active = true

func _on_dive_state_changed(is_dive: bool) -> void:
	_target_blend = 1.0 if is_dive else 0.0

func _on_node_added(node: Node) -> void:
	if node is Button:
		node.pressed.connect(play_click)

func _rand_crackle_interval() -> float:
	return randf_range(5.0, 15.0)
