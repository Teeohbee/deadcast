# scenes/barge_hub/panels/sonar_panel.gd
extends TerminalPanel

const ZONE_PARAMS: Dictionary = {
	"district7": {"amp": 15.0, "freq": 0.02, "sig": "LOW", "sig_tier": 0},
	"exchange":  {"amp": 25.0, "freq": 0.02, "sig": "MEDIUM", "sig_tier": 1},
	"axiom":     {"amp": 35.0, "freq": 0.04, "sig": "CRITICAL", "sig_tier": 2},
}

var _wave: SonarWave
var _sig_label: Label

func _ready() -> void:
	title = "sonar_hydro-scan"
	custom_minimum_size = Vector2(0, 160)
	_build()
	EventBus.zone_changed.connect(_on_zone_changed)
	_on_zone_changed(GameState.selected_zone)

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	var header := HBoxContainer.new()
	for text in ["SCAN RATE: 1000ms", "SENSITIVITY: +4.5dB", "DIVER DEPTH VARIATION"]:
		var l := Label.new()
		l.text = text
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		DeckStyle.apply_label(l, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
		header.add_child(l)
	(header.get_child(2) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(header)

	var wave_holder := Control.new()
	wave_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(wave_holder)

	_wave = SonarWave.new()
	_wave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wave_holder.add_child(_wave)

	var legend := VBoxContainer.new()
	legend.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	legend.offset_left = -210
	legend.offset_top = 6
	legend.offset_right = -6
	_sig_label = Label.new()
	DeckStyle.apply_label(_sig_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	legend.add_child(_sig_label)
	var thermo := Label.new()
	thermo.text = "█ THERMOCLINE: 4.1°C"
	DeckStyle.apply_label(thermo, DeckStyle.SKY, DeckStyle.SIZE_AMBIENT)
	legend.add_child(thermo)
	wave_holder.add_child(legend)

func params_for(zone_id: String) -> Dictionary:
	return ZONE_PARAMS.get(zone_id, ZONE_PARAMS["district7"])

func _on_zone_changed(zone_id: String) -> void:
	var params := params_for(zone_id)
	_wave.amplitude = params["amp"]
	_wave.frequency = params["freq"]
	_sig_label.text = "█ GHOST-SIG: %s" % params["sig"]
	DeckStyle.apply_label(_sig_label, DeckStyle.tier_color(params["sig_tier"]), DeckStyle.SIZE_BODY)
