# scenes/barge_hub/panels/incoming_transmission.gd
extends TerminalPanel
class_name IncomingTransmission

var _bars: SignalBars
var _link_label: Label
var _wave: SonarWave

func _ready() -> void:
	title = "incoming_transmission"
	custom_minimum_size = Vector2(0, 120)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)

	var sig := Label.new()
	sig.text = "SIGNAL"
	DeckStyle.apply_label(sig, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	top.add_child(sig)

	_bars = SignalBars.new()
	top.add_child(_bars)

	_link_label = Label.new()
	_link_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_link_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_link_label)

	var src := Label.new()
	src.text = "SRC  meridian_relay      ENC  aes-256 / verified"
	DeckStyle.apply_label(src, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(src)

	var wave_holder := Control.new()
	wave_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wave_holder.custom_minimum_size = Vector2(0, 48)
	root.add_child(wave_holder)

	_wave = SonarWave.new()
	_wave.amplitude = 12.0
	_wave.frequency = 0.07
	_wave.line_color = DeckStyle.SKY
	_wave.speed = 2.0
	_wave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wave_holder.add_child(_wave)

	refresh(GameState.pressure_level)

# Pure mapping from debt pressure to a link descriptor. Tested directly.
func link_status(pressure: int) -> Dictionary:
	if pressure >= 4:
		return {"text": "TRACED", "color": DeckStyle.RED}
	if pressure >= 2:
		return {"text": "MONITORED", "color": DeckStyle.AMBER}
	return {"text": "SECURE", "color": DeckStyle.GREEN}

func refresh(pressure: int) -> void:
	var status := link_status(pressure)
	_link_label.text = "LINK  %s" % status.text
	DeckStyle.apply_label(_link_label, status.color, DeckStyle.SIZE_AMBIENT)
