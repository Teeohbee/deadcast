# autoload/Audio.gd
extends Node

# All game sound goes through here. Cues are named sounds with a few sample
# variations; play_cue picks one at random with a little pitch jitter so
# repeats don't sound mechanical. Screens never play sounds directly: UI clicks
# hook into the viewport globally and dive sounds listen to EventBus.
#
# Samples are Kenney CC0 packs; the title music is "Pyro" from OpenGameArt
# (CC0). See README credits.

const INTERFACE := "res://audio/kenney_interface/"
const SCI_FI := "res://audio/kenney_sci_fi/"
const IMPACT := "res://audio/kenney_impact/"
const RPG := "res://audio/kenney_rpg/"
const MUSIC := "res://audio/music/"

const CUES := {
	# UI
	"ui_focus": {
		"files": [INTERFACE + "tick_001.ogg", INTERFACE + "tick_002.ogg", INTERFACE + "tick_004.ogg"],
		"bus": "UI", "volume_db": -16.0, "pitch": 1.0, "pitch_variation": 0.08,
	},
	"ui_confirm": {
		"files": [INTERFACE + "select_001.ogg", INTERFACE + "select_002.ogg",
			INTERFACE + "select_003.ogg", INTERFACE + "select_004.ogg"],
		"bus": "UI", "volume_db": -10.0, "pitch": 1.0, "pitch_variation": 0.05,
	},
	"ui_screen": {
		"files": [INTERFACE + "switch_001.ogg", INTERFACE + "switch_002.ogg",
			INTERFACE + "switch_003.ogg", INTERFACE + "switch_004.ogg"],
		"bus": "UI", "volume_db": -12.0, "pitch": 0.9, "pitch_variation": 0.05,
	},
	# Dive
	"dive_cast": {
		"files": [SCI_FI + "doorOpen_000.ogg", SCI_FI + "doorOpen_001.ogg", SCI_FI + "doorOpen_002.ogg"],
		"bus": "Events", "volume_db": -6.0, "pitch": 0.7, "pitch_variation": 0.05,
	},
	"contact_ping": {
		"files": [INTERFACE + "maximize_001.ogg", INTERFACE + "maximize_002.ogg",
			INTERFACE + "maximize_003.ogg", INTERFACE + "maximize_004.ogg"],
		"bus": "Events", "volume_db": -8.0, "pitch": 0.8, "pitch_variation": 0.06,
	},
	"contact_entity": {
		"files": [SCI_FI + "forceField_000.ogg", SCI_FI + "forceField_001.ogg", SCI_FI + "forceField_002.ogg"],
		"bus": "Events", "volume_db": -4.0, "pitch": 0.45, "pitch_variation": 0.04,
	},
	"line_strain": {
		"files": [RPG + "creak1.ogg", RPG + "creak2.ogg", RPG + "creak3.ogg"],
		"bus": "Events", "volume_db": -8.0, "pitch": 0.8, "pitch_variation": 0.1,
	},
	"signal_glitch": {
		"files": [INTERFACE + "glitch_001.ogg", INTERFACE + "glitch_002.ogg",
			INTERFACE + "glitch_003.ogg", INTERFACE + "glitch_004.ogg"],
		"bus": "Events", "volume_db": -10.0, "pitch": 1.0, "pitch_variation": 0.2,
	},
	"line_snap": {
		"files": [IMPACT + "impactMetal_heavy_000.ogg", IMPACT + "impactMetal_heavy_001.ogg",
			IMPACT + "impactMetal_heavy_002.ogg"],
		"bus": "Events", "volume_db": 0.0, "pitch": 0.9, "pitch_variation": 0.05,
	},
	"signal_lost": {
		"files": [SCI_FI + "lowFrequency_explosion_000.ogg", SCI_FI + "lowFrequency_explosion_001.ogg"],
		"bus": "Events", "volume_db": -2.0, "pitch": 0.8, "pitch_variation": 0.03,
	},
	"checkpoint": {
		"files": [INTERFACE + "bong_001.ogg"],
		"bus": "Events", "volume_db": -6.0, "pitch": 0.7, "pitch_variation": 0.0,
	},
	"lure_fire": {
		"files": [SCI_FI + "laserRetro_000.ogg", SCI_FI + "laserRetro_001.ogg", SCI_FI + "laserRetro_002.ogg"],
		"bus": "Events", "volume_db": -8.0, "pitch": 0.8, "pitch_variation": 0.05,
	},
	"haul_banked": {
		"files": [RPG + "handleCoins.ogg", RPG + "handleCoins2.ogg"],
		"bus": "Events", "volume_db": -4.0, "pitch": 1.0, "pitch_variation": 0.05,
	},
}

# Looping beds under everything. Kenney's engine loops are 5s; pitched down
# they read as barge machinery (hub) and water pressure on the hull (dive).
# The title plays music instead, and it carries on into the terminal title
# until the first deck screen switches to the hub bed.
const AMBIENCES := {
	"title": {"file": MUSIC + "pyro.mp3", "volume_db": -8.0, "pitch": 1.0},
	"hub":  {"file": SCI_FI + "spaceEngineLow_000.ogg", "volume_db": -24.0, "pitch": 0.6},
	"dive": {"file": SCI_FI + "engineCircular_000.ogg", "volume_db": -20.0, "pitch": 0.4},
}

const BUS_NAMES: Array[String] = ["Ambient", "UI", "Events"]
const AMBIENCE_FADE_SECONDS := 1.2
const SILENT_DB := -60.0
# Ignore a repeat of the same cue inside this window: screen changes grab focus
# programmatically, which would otherwise stack a tick on top of the swoosh.
const MINIMUM_SECONDS_BETWEEN_REPEATS := 0.06
# Small tension bumps happen constantly; only creak for a real pull.
const MINIMUM_TENSION_RISE_TO_CREAK := 5.0
const MINIMUM_CORRUPTION_RISE_TO_GLITCH := 5.0
const CUE_HISTORY_LIMIT := 32
const CUE_PLAYER_COUNT := 8

# Most recent cues first-to-last, for tests and debugging.
var cue_history: Array[String] = []
var current_ambience: String = ""

var _cue_players: Array[AudioStreamPlayer] = []
var _next_cue_player_index := 0
var _last_played_seconds_by_cue: Dictionary = {}
var _ambience_player_a: AudioStreamPlayer
var _ambience_player_b: AudioStreamPlayer
var _active_ambience_player: AudioStreamPlayer
var _last_tension := 0.0
var _last_corruption := 0.0
var _fade_by_ambience_player: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_buses()
	_create_players()
	apply_mute_setting()
	_connect_ui_sounds()
	_connect_game_events()
	set_ambience("hub")

# --- Public ---

func play_cue(cue_name: String) -> void:
	if not CUES.has(cue_name):
		push_warning("Audio: unknown cue '%s'" % cue_name)
		return
	if _played_too_recently(cue_name):
		return
	var cue: Dictionary = CUES[cue_name]
	var player := _take_next_cue_player()
	player.stream = load(cue.files.pick_random())
	player.bus = cue.bus
	player.volume_db = cue.volume_db
	player.pitch_scale = cue.pitch + randf_range(-cue.pitch_variation, cue.pitch_variation)
	player.play()
	_remember_cue(cue_name)

func set_ambience(ambience_name: String) -> void:
	if ambience_name == current_ambience:
		return
	current_ambience = ambience_name
	var outgoing_player := _active_ambience_player
	var incoming_player := _ambience_player_b if outgoing_player == _ambience_player_a else _ambience_player_a
	_fade_out(outgoing_player)
	if AMBIENCES.has(ambience_name):
		_fade_in(incoming_player, AMBIENCES[ambience_name])
	_active_ambience_player = incoming_player

func toggle_mute() -> void:
	Settings.set_audio_muted(not Settings.audio_muted)
	apply_mute_setting()
	EventBus.deck_log.emit("AUDIO: %s." % ("muted" if Settings.audio_muted else "restored"))

func apply_mute_setting() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), Settings.audio_muted)

func clear_cue_history() -> void:
	cue_history.clear()
	_last_played_seconds_by_cue.clear()

# M on keyboard, Back on a pad, from any screen.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mute"):
		toggle_mute()
		get_viewport().set_input_as_handled()

# --- Setup ---

func _create_buses() -> void:
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var new_bus_index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(new_bus_index, bus_name)
		AudioServer.set_bus_send(new_bus_index, "Master")

func _create_players() -> void:
	for player_number in CUE_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_cue_players.append(player)
	_ambience_player_a = _make_ambience_player()
	_ambience_player_b = _make_ambience_player()
	_active_ambience_player = _ambience_player_a

func _make_ambience_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "Ambient"
	player.volume_db = SILENT_DB
	add_child(player)
	return player

func _connect_ui_sounds() -> void:
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	get_tree().node_added.connect(_on_node_added)
	UIController.screen_changed.connect(_on_screen_changed)

func _connect_game_events() -> void:
	EventBus.dive_cast.connect(func() -> void: play_cue("dive_cast"))
	EventBus.checkpoint_reached.connect(func() -> void: play_cue("checkpoint"))
	EventBus.line_snapped.connect(_on_line_snapped)
	EventBus.contact_presented.connect(_on_contact_presented)
	EventBus.tension_changed.connect(_on_tension_changed)
	EventBus.corruption_changed.connect(_on_corruption_changed)
	EventBus.lure_stock_changed.connect(func(_lure_id: String, _remaining: int) -> void: play_cue("lure_fire"))
	EventBus.run_ended.connect(_on_run_ended)

# --- Event handlers ---

func _on_focus_changed(_control: Control) -> void:
	play_cue("ui_focus")

# Every Button anywhere in the game clicks when pressed, so screens built in
# code (vendor stock, dive choices) get sound without knowing about Audio.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(func() -> void: play_cue("ui_confirm"))

func _on_screen_changed(screen_id: String) -> void:
	play_cue("ui_screen")
	if screen_id == "dive":
		set_ambience("dive")
	else:
		set_ambience("hub")

func _on_line_snapped() -> void:
	play_cue("line_snap")
	play_cue("signal_lost")

func _on_contact_presented(catch_data: CatchData) -> void:
	if catch_data.catch_type == CatchData.CatchType.ENTITY:
		play_cue("contact_entity")
	else:
		play_cue("contact_ping")

func _on_tension_changed(tension: float) -> void:
	var tension_rise := tension - _last_tension
	_last_tension = tension
	if tension_rise >= MINIMUM_TENSION_RISE_TO_CREAK:
		play_cue("line_strain")

# Corruption rises from 0 as the run disturbs the signal (SIG shows 100 - corruption).
func _on_corruption_changed(corruption: float) -> void:
	var corruption_rise := corruption - _last_corruption
	_last_corruption = corruption
	if corruption_rise >= MINIMUM_CORRUPTION_RISE_TO_GLITCH:
		play_cue("signal_glitch")

func _on_run_ended(result: Dictionary) -> void:
	var run_was_snapped: bool = result.get("snapped", false)
	if not run_was_snapped:
		play_cue("haul_banked")

# --- Helpers ---

func _played_too_recently(cue_name: String) -> bool:
	var now_seconds := Time.get_ticks_msec() / 1000.0
	var last_played_seconds: float = _last_played_seconds_by_cue.get(cue_name, -1000.0)
	return now_seconds - last_played_seconds < MINIMUM_SECONDS_BETWEEN_REPEATS

func _remember_cue(cue_name: String) -> void:
	_last_played_seconds_by_cue[cue_name] = Time.get_ticks_msec() / 1000.0
	cue_history.append(cue_name)
	if cue_history.size() > CUE_HISTORY_LIMIT:
		cue_history.remove_at(0)

func _take_next_cue_player() -> AudioStreamPlayer:
	var player := _cue_players[_next_cue_player_index]
	_next_cue_player_index = (_next_cue_player_index + 1) % _cue_players.size()
	return player

func _fade_in(player: AudioStreamPlayer, ambience: Dictionary) -> void:
	# Both AudioStreamOggVorbis and AudioStreamMP3 loop through a "loop" property.
	var looping_stream: AudioStream = load(ambience.file).duplicate()
	looping_stream.set("loop", true)
	player.stream = looping_stream
	player.pitch_scale = ambience.pitch
	player.volume_db = SILENT_DB
	player.play()
	var fade := _start_fade(player)
	fade.tween_property(player, "volume_db", ambience.volume_db, AMBIENCE_FADE_SECONDS)

func _fade_out(player: AudioStreamPlayer) -> void:
	if not player.playing:
		return
	var fade := _start_fade(player)
	fade.tween_property(player, "volume_db", SILENT_DB, AMBIENCE_FADE_SECONDS)
	fade.tween_callback(player.stop)

# One fade per player: a quick hub -> dive -> hub switch must cancel the old
# fade-out, or its stop() would cut off the ambience that just faded back in.
func _start_fade(player: AudioStreamPlayer) -> Tween:
	var previous_fade: Tween = _fade_by_ambience_player.get(player)
	if previous_fade != null and previous_fade.is_valid():
		previous_fade.kill()
	var fade := create_tween()
	_fade_by_ambience_player[player] = fade
	return fade
