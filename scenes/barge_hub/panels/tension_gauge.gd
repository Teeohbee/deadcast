# scenes/barge_hub/panels/tension_gauge.gd
extends TerminalPanel
class_name TensionGauge

var _wave: SonarWave
var _status: Label
var _readout: Label

func _ready() -> void:
	title = "tension_gauge"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 120)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	_status = Label.new()
	DeckStyle.apply_label(_status, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_status)

	var wave_holder := Control.new()
	wave_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wave_holder.custom_minimum_size = Vector2(0, 56)
	root.add_child(wave_holder)

	_wave = SonarWave.new()
	_wave.frequency = 0.05
	_wave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wave_holder.add_child(_wave)

	_readout = Label.new()
	_readout.text = "peak 71T    avg 44T    cycles 1,204"
	DeckStyle.apply_label(_readout, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_readout)

	refresh()

# Pure mapping from rod condition to gauge appearance. Tested directly.
func gauge_state(damaged: bool) -> Dictionary:
	if damaged:
		return {"color": DeckStyle.RED, "label": "load 96%   [DAMAGED]", "amp": 30.0}
	return {"color": DeckStyle.GREEN, "label": "load 62%   [OK]", "amp": 16.0}

func refresh() -> void:
	var state := gauge_state(GameState.rod_damaged)
	_wave.line_color = state.color
	_wave.amplitude = state.amp
	_status.text = state.label
	DeckStyle.apply_label(_status, state.color, DeckStyle.SIZE_AMBIENT)
