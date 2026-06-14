# scenes/barge_hub/panels/tension_gauge.gd
extends TerminalPanel
class_name TensionGauge

var _meter: BarMeter
var _status: Label
var _readout: Label

func _ready() -> void:
	title = "tension_gauge"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 120)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	_status = Label.new()
	DeckStyle.apply_label(_status, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_status)

	var meter_holder := Control.new()
	meter_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meter_holder.custom_minimum_size = Vector2(0, 40)
	root.add_child(meter_holder)

	_meter = BarMeter.new()
	_meter.redline = 0.85
	_meter.set_anchors_and_offsets_preset(Control.PRESET_VCENTER_WIDE)
	_meter.custom_minimum_size = Vector2(0, 22)
	meter_holder.add_child(_meter)

	_readout = Label.new()
	_readout.text = "peak 71T    avg 44T    cycles 1,204"
	DeckStyle.apply_label(_readout, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_readout)

	refresh()

# Pure mapping from rod condition to gauge appearance. Tested directly.
func gauge_state(damaged: bool) -> Dictionary:
	if damaged:
		return {"color": DeckStyle.RED, "label": "load 96%   [DAMAGED]", "load": 0.96}
	return {"color": DeckStyle.GREEN, "label": "load 62%   [OK]", "load": 0.62}

func refresh() -> void:
	var state := gauge_state(GameState.rod_damaged)
	_meter.fill_color = state.color
	_meter.target = state.load
	_status.text = state.label
	DeckStyle.apply_label(_status, state.color, DeckStyle.SIZE_AMBIENT)
