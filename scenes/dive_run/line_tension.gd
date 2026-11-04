# scenes/dive_run/line_tension.gd
# Rail widget: plain line tension against the rod's cap. Unlike biosign (which
# reskins tension as a heartbeat), this is the one readout that never glitches -
# it is the number the snap rule uses. Driven by EventBus.tension_changed.
class_name LineTensionPanel
extends TerminalPanel

const AMBER_FROM := 0.75
const RED_FROM := 0.9

static func readout_text(tension: int, cap: int) -> String:
	return "TENSION %d / %d" % [tension, cap]

static func load_color(tension: int, cap: int) -> Color:
	if cap <= 0:
		return DeckStyle.GREEN
	var load_ratio := float(tension) / float(cap)
	if load_ratio >= RED_FROM:
		return DeckStyle.RED
	if load_ratio >= AMBER_FROM:
		return DeckStyle.AMBER
	return DeckStyle.GREEN

var _cap: int = 80
var _snapped: bool = false
var _readout: Label
var _meter: BarMeter

func setup(cap: int) -> void:
	_cap = cap
	if _readout:
		_show_tension(0)

func _ready() -> void:
	title = "line_tension"

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	_readout = Label.new()
	root.add_child(_readout)

	_meter = BarMeter.new()
	_meter.redline = RED_FROM
	_meter.custom_minimum_size = Vector2(0, 14)
	root.add_child(_meter)

	EventBus.tension_changed.connect(_on_tension_changed)
	EventBus.run_ended.connect(_on_run_ended)
	_show_tension(0)

func _on_tension_changed(value: float) -> void:
	if _snapped:
		return
	_show_tension(int(value))

func _on_run_ended(result: Dictionary) -> void:
	if not result.get("snapped", false):
		return
	_snapped = true
	_readout.text = "LINE SNAPPED"
	DeckStyle.apply_label(_readout, DeckStyle.RED, DeckStyle.SIZE_VALUE)
	_meter.fill_color = DeckStyle.RED
	_meter.target = 1.0

func _show_tension(tension: int) -> void:
	var color := load_color(tension, _cap)
	_readout.text = readout_text(tension, _cap)
	DeckStyle.apply_label(_readout, color, DeckStyle.SIZE_VALUE)
	_meter.fill_color = color
	_meter.target = clampf(float(tension) / float(_cap), 0.0, 1.0) if _cap > 0 else 0.0
