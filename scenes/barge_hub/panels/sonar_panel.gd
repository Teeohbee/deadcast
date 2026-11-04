# scenes/barge_hub/panels/sonar_panel.gd
extends TerminalPanel

const ZONE_PARAMS: Dictionary = {
	"district7": {"amp": 15.0, "freq": 0.02, "sig": "LOW", "sig_tier": 0},
	"exchange":  {"amp": 25.0, "freq": 0.02, "sig": "MEDIUM", "sig_tier": 1},
	"axiom":     {"amp": 35.0, "freq": 0.04, "sig": "CRITICAL", "sig_tier": 2},
}

var _wave: SonarWave
var _sig_label: Label
var _legend: VBoxContainer

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

	# The wave and its legend share a row so the legend never sits on the wave.
	var wave_row := HBoxContainer.new()
	wave_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wave_row.add_theme_constant_override("separation", 12)
	root.add_child(wave_row)

	var wave_holder := Control.new()
	wave_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wave_row.add_child(wave_holder)

	_wave = SonarWave.new()
	_wave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wave_holder.add_child(_wave)

	_legend = VBoxContainer.new()
	_legend.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Fixed width, so the wave doesn't jump when GHOST-SIG changes length.
	_legend.custom_minimum_size = Vector2(210, 0)
	_sig_label = Label.new()
	DeckStyle.apply_label(_sig_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	_legend.add_child(_sig_label)
	var thermo := Label.new()
	thermo.text = "█ THERMOCLINE: 4.1°C"
	DeckStyle.apply_label(thermo, DeckStyle.SKY, DeckStyle.SIZE_AMBIENT)
	_legend.add_child(thermo)
	wave_row.add_child(_legend)

func params_for(zone_id: String) -> Dictionary:
	return ZONE_PARAMS.get(zone_id, ZONE_PARAMS["district7"])

func _on_zone_changed(zone_id: String) -> void:
	var params := params_for(zone_id)
	_wave.amplitude = params["amp"]
	_wave.frequency = params["freq"]
	_sig_label.text = "█ GHOST-SIG: %s" % params["sig"]
	DeckStyle.apply_label(_sig_label, DeckStyle.tier_color(params["sig_tier"]), DeckStyle.SIZE_BODY)
