# scenes/dive_run/biosign.gd
# Rail widget: the diver's heartbeat as an ECG trace. BPM rises with line tension,
# the trace goes arrhythmic under heavy load, and flatlines on snap. Reskins
# EventBus.tension_changed (+ run_ended for the flatline). No new information.
class_name BiosignPanel
extends TerminalPanel

const BPM_REST := 60
const BPM_MAX := 130
# From 50 corruption the readout can't be trusted: it wanders around the true
# value and keeps re-reading even when tension hasn't changed.
const CORRUPT_READOUT_FROM := 50.0
const CORRUPT_BPM_JITTER := 8
const CORRUPT_REREAD_SECONDS := 0.4
const TENSION_PULSE_MIN_RISE := 5.0
const TENSION_PULSE_SECONDS := 0.35

static func displayed_bpm(true_bpm: int, corruption: float, rng: RandomNumberGenerator) -> int:
	if corruption < CORRUPT_READOUT_FROM:
		return true_bpm
	return true_bpm + rng.randi_range(-CORRUPT_BPM_JITTER, CORRUPT_BPM_JITTER)

static func bpm_for(tension: int, max_tension: int) -> int:
	if max_tension <= 0:
		return BPM_REST
	var ratio := clampf(float(tension) / float(max_tension), 0.0, 1.0)
	return int(round(lerpf(BPM_REST, BPM_MAX, ratio)))

static func load_state(load_ratio: float) -> String:
	if load_ratio >= 0.85:
		return "CRITICAL"
	if load_ratio >= 0.7:
		return "ELEVATED"
	return "NOMINAL"

var _trace: Control
var _readout: Label
var _max_tension: int = 80
var _load: float = 0.0
var _flatline: bool = false
var _scroll: float = 0.0
var _tension: float = 0.0
var _corruption: float = 0.0
var _seconds_since_reread: float = 0.0
var _readout_rng := RandomNumberGenerator.new()

func setup(max_tension: int) -> void:
	_max_tension = max_tension

func _ready() -> void:
	title = "biosign"
	ambient = true
	custom_minimum_size = Vector2(0, 72)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	add_child(root)

	_readout = Label.new()
	DeckStyle.apply_label(_readout, DeckStyle.TEXT, DeckStyle.SIZE_AMBIENT)
	root.add_child(_readout)

	_trace = Control.new()
	_trace.custom_minimum_size = Vector2(0, 40)
	_trace.clip_contents = true
	_trace.draw.connect(_draw_trace)
	root.add_child(_trace)

	EventBus.tension_changed.connect(_on_tension_changed)
	EventBus.corruption_changed.connect(_on_corruption_changed)
	EventBus.run_ended.connect(_on_run_ended)
	_update_readout(0)

func _process(delta: float) -> void:
	_scroll += delta * (1.0 + _load * 2.0)
	_trace.queue_redraw()
	if _corruption >= CORRUPT_READOUT_FROM:
		_seconds_since_reread += delta
		if _seconds_since_reread >= CORRUPT_REREAD_SECONDS:
			_seconds_since_reread = 0.0
			_update_readout(int(_tension))

func _on_tension_changed(value: float) -> void:
	if value - _tension >= TENSION_PULSE_MIN_RISE:
		_pulse()
	_tension = value
	if _max_tension <= 0:
		_load = 0.0
	else:
		_load = clampf(value / float(_max_tension), 0.0, 1.0)
	_update_readout(int(value))

func _on_corruption_changed(value: float) -> void:
	_corruption = value

# A real pull on the line: the panel flares red and settles.
func _pulse() -> void:
	modulate = Color(1.8, 0.6, 0.6, resting_modulate().a)
	create_tween().tween_property(self, "modulate", resting_modulate(), TENSION_PULSE_SECONDS)

func _on_run_ended(result: Dictionary) -> void:
	if not result.get("snapped", false) or _flatline:
		return
	_flatline = true
	set_process(false)
	_trace.queue_redraw()
	_readout.text = "FLATLINE  ·  0 BPM"
	DeckStyle.apply_label(_readout, DeckStyle.RED, DeckStyle.SIZE_AMBIENT)

func _update_readout(tension: int) -> void:
	if _flatline:
		return
	var bpm := displayed_bpm(bpm_for(tension, _max_tension), _corruption, _readout_rng)
	var state := load_state(_load)
	_readout.text = "%d BPM  ·  [%s]" % [bpm, state]
	var col := DeckStyle.TEXT.lerp(DeckStyle.RED, _load)
	DeckStyle.apply_label(_readout, col, DeckStyle.SIZE_AMBIENT)

func _draw_trace() -> void:
	var w := _trace.size.x
	var h := _trace.size.y
	if w < 2.0 or h < 2.0:
		return
	var mid := h / 2.0
	var col := DeckStyle.TEXT.lerp(DeckStyle.RED, _load)
	if _flatline:
		_trace.draw_line(Vector2(0, mid), Vector2(w, mid), DeckStyle.RED, 1.5)
		return
	var pts := PackedVector2Array()
	for x in int(w):
		# Baseline with a periodic QRS spike; jitter grows with load (arrhythmia).
		var phase := fmod((x + _scroll * 30.0), 60.0)
		var y := mid
		if phase > 52.0 and phase < 56.0:
			y = mid - h * 0.42 * (1.0 + randf() * _load * 0.6)
		elif phase >= 56.0 and phase < 58.0:
			y = mid + h * 0.18
		pts.append(Vector2(x, y))
	if pts.size() >= 2:
		_trace.draw_polyline(pts, col, 1.5, true)
