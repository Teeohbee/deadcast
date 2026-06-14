# scenes/barge_hub/panels/life_support_strip.gd
extends TerminalPanel
class_name LifeSupportStrip

var _wave: SonarWave
var _readout: Label

func _ready() -> void:
	title = "life_support"
	custom_minimum_size = Vector2(0, 64)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var resp := Label.new()
	resp.text = "RESP"
	resp.custom_minimum_size.x = 44
	DeckStyle.apply_label(resp, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(resp)

	var wave_holder := Control.new()
	wave_holder.custom_minimum_size = Vector2(160, 0)
	wave_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(wave_holder)

	_wave = SonarWave.new()
	_wave.amplitude = 6.0
	_wave.frequency = 0.05
	_wave.line_color = DeckStyle.SKY
	_wave.speed = 0.8
	_wave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wave_holder.add_child(_wave)

	_readout = Label.new()
	_readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_readout.text = "6/min    O2 MIX 21%    HULL -4200m    BAY 18.4°C    STATE: resting"
	DeckStyle.apply_label(_readout, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_readout)
