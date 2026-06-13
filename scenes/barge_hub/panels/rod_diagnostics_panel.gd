# scenes/barge_hub/panels/rod_diagnostics_panel.gd
extends TerminalPanel
class_name RodDiagnosticsPanel

var _no_rod_label: Label
var _stat_box: VBoxContainer
var _rod_name_val: Label
var _tension_val: Label
var _depth_val: Label
var _integrity_val: Label
var _upgrades_val: Label

func _ready() -> void:
	title = "rod_diagnostics"
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	_no_rod_label = Label.new()
	_no_rod_label.text = "no rod equipped"
	DeckStyle.apply_label(_no_rod_label, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_no_rod_label)

	_stat_box = VBoxContainer.new()
	_stat_box.add_theme_constant_override("separation", 4)
	root.add_child(_stat_box)

	_rod_name_val  = _add_row("ROD")
	_tension_val   = _add_row("TENSION")
	_depth_val     = _add_row("DEPTH")
	_integrity_val = _add_row("INTEGRITY")
	_upgrades_val  = _add_row("UPGRADES")

	refresh()

func _add_row(field_name: String) -> Label:
	var row := HBoxContainer.new()
	_stat_box.add_child(row)

	var field_label := Label.new()
	field_label.text = field_name
	field_label.custom_minimum_size.x = 90
	DeckStyle.apply_label(field_label, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	row.add_child(field_label)

	var val_label := Label.new()
	val_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DeckStyle.apply_label(val_label, DeckStyle.TEXT, DeckStyle.SIZE_AMBIENT)
	row.add_child(val_label)

	return val_label

func refresh() -> void:
	var rod := GameState.current_rod
	if rod == null:
		_no_rod_label.visible = true
		_stat_box.visible = false
		return

	_no_rod_label.visible = false
	_stat_box.visible = true

	_rod_name_val.text = rod.rod_name.to_lower()
	_tension_val.text  = "%dT cap" % rod.tension_cap
	_depth_val.text    = "%dft ceiling" % rod.max_depth

	if GameState.rod_damaged:
		_integrity_val.text = "[DAMAGED]"
		_integrity_val.add_theme_color_override("font_color", DeckStyle.RED)
	else:
		_integrity_val.text = "[OK]"
		_integrity_val.add_theme_color_override("font_color", DeckStyle.GREEN)

	var maxed := GameState.depth_upgrade_count >= GameState.MAX_DEPTH_UPGRADES
	_upgrades_val.text = "%d / %d%s" % [
		GameState.depth_upgrade_count,
		GameState.MAX_DEPTH_UPGRADES,
		" (max)" if maxed else "",
	]
