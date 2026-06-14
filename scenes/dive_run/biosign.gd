# scenes/dive_run/biosign.gd
# Rail widget: the diver's heartbeat as an ECG trace. BPM rises with line tension,
# the trace goes arrhythmic under heavy load, and flatlines on snap. Reskins
# EventBus.tension_changed (+ run_ended for the flatline). No new information.
class_name BiosignPanel
extends TerminalPanel

const BPM_REST := 60
const BPM_MAX := 130

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

func setup(max_tension: int) -> void:
	_max_tension = max_tension

func _ready() -> void:
	title = "biosign"
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
	EventBus.run_ended.connect(_on_run_ended)
	_update_readout(0)

func _process(delta: float) -> void:
	_scroll += delta * (1.0 + _load * 2.0)
	_trace.queue_redraw()

func _on_tension_changed(value: float) -> void:
	if _max_tension <= 0:
		_load = 0.0
	else:
		_load = clampf(value / float(_max_tension), 0.0, 1.0)
	_update_readout(int(value))

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
	var bpm := bpm_for(tension, _max_tension)
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
