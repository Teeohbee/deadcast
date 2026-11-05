# scenes/barge_hub/Workshop.gd
extends Control

# The vendor's rod order doubles as the wireframe variant index.
const VENDORS := preload("res://scenes/barge_hub/VendorsLayout.gd")

@onready var rod_label: Label = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/RodLabel
@onready var repair_button: Button = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/RepairButton
@onready var winch_button: Button = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/WinchButton
@onready var message_label: Label = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/MessageLabel
@onready var _tension_gauge: TensionGauge = $MarginContainer/HBox/RightColumn/TensionGauge
@onready var _maintenance_log: MaintenanceLogPanel = $MarginContainer/HBox/RightColumn/MaintenanceLogPanel
@onready var _schematic: ItemSchematic = $MarginContainer/HBox/LeftColumn/ItemSchematic

func _ready() -> void:
	for btn in [repair_button, winch_button]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_action_button(btn)

	DeckStyle.apply_label(rod_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	DeckStyle.apply_label(message_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)

	repair_button.pressed.connect(_on_repair_pressed)
	winch_button.pressed.connect(_on_winch_pressed)

	_refresh()

	await get_tree().process_frame
	repair_button.grab_focus()
	DeckNav.chain_vertical([repair_button, winch_button])

func on_screen_shown() -> void:
	_refresh()
	_tension_gauge.refresh()
	default_focus().grab_focus()

func default_focus() -> Control:
	return repair_button

func _refresh() -> void:
	var rod = GameState.current_rod
	if rod == null:
		rod_label.text = "no rod equipped."
		repair_button.disabled = true
		_schematic.clear()
		return

	var status = " [damaged]" if GameState.rod_damaged else " [ok]"
	_schematic.show_item("rod", _rod_variant(rod), rod.rod_name + status, rod.description)
	rod_label.text = "%s%s  ·  cap: %dT  ·  depth: %dft" % [
		rod.rod_name.to_lower(), status, rod.tension_cap, GameState.line_rating_ft()]

	var repair_cost := GameState.vendor_price(rod.repair_cost)
	repair_button.text = "repair %s (%dcr%s)" % [rod.rod_name.to_lower(), repair_cost, GameState.vendor_markup_suffix()]
	repair_button.disabled = not GameState.rod_damaged or GameState.credits < repair_cost

	if GameState.deep_winch_fitted:
		winch_button.text = "deep winch fitted · reaches the deep layer (%dft)" % GameState.DEEP_WINCH_RATING_FT
		winch_button.disabled = true
	else:
		winch_button.text = "fit deep winch · reach the deep layer (%dcr%s)" % [
			_winch_cost(), GameState.vendor_markup_suffix()]
		winch_button.disabled = GameState.credits < _winch_cost()

func _on_repair_pressed() -> void:
	var rod = GameState.current_rod
	if GameState.spend_credits(GameState.vendor_price(rod.repair_cost)):
		GameState.rod_damaged = false
		GameState.save()
		message_label.text = "%s repaired." % rod.rod_name.to_lower()
		message_label.add_theme_color_override("font_color", DeckStyle.GREEN)
		_maintenance_log.append_line("REPAIR: %s serviced. Micro-fractures sealed." % rod.rod_name.to_lower())
		_tension_gauge.refresh()
		_refresh()
	else:
		message_label.text = "not enough credits."
		message_label.add_theme_color_override("font_color", DeckStyle.RED)

func _on_winch_pressed() -> void:
	if GameState.fit_deep_winch(_winch_cost()):
		message_label.text = "deep winch fitted. the deep layer is in reach."
		message_label.add_theme_color_override("font_color", DeckStyle.GREEN)
		_maintenance_log.append_line("WINCH: Deep cable spooled. New ceiling: %dft." % GameState.line_rating_ft())
		_tension_gauge.refresh()
		_refresh()
	else:
		message_label.text = "not enough credits."
		message_label.add_theme_color_override("font_color", DeckStyle.RED)

# Match on name, so any duplicated rod still finds its wireframe.
func _rod_variant(rod: RodData) -> int:
	for index in VENDORS.ROD_PATHS.size():
		var stock_rod: RodData = load(VENDORS.ROD_PATHS[index])
		if stock_rod.rod_name == rod.rod_name:
			return index
	return 0

func _winch_cost() -> int:
	return GameState.vendor_price(GameState.DEEP_WINCH_COST)
