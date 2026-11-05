# scenes/barge_hub/Workshop.gd
extends Control

const DEPTH_UPGRADE_BASE_COST: int = 2000
const DEPTH_UPGRADE_AMOUNT: int = 50
# The vendor's rod order doubles as the wireframe variant index.
const VENDORS := preload("res://scenes/barge_hub/VendorsLayout.gd")

@onready var rod_label: Label = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/RodLabel
@onready var repair_button: Button = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/RepairButton
@onready var depth_upgrade_button: Button = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/DepthUpgradeButton
@onready var message_label: Label = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/MessageLabel
@onready var _tension_gauge: TensionGauge = $MarginContainer/HBox/RightColumn/TensionGauge
@onready var _maintenance_log: MaintenanceLogPanel = $MarginContainer/HBox/RightColumn/MaintenanceLogPanel
@onready var _schematic: ItemSchematic = $MarginContainer/HBox/LeftColumn/ItemSchematic

func _ready() -> void:
	for btn in [repair_button, depth_upgrade_button]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_action_button(btn)

	DeckStyle.apply_label(rod_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	DeckStyle.apply_label(message_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)

	repair_button.pressed.connect(_on_repair_pressed)
	depth_upgrade_button.pressed.connect(_on_depth_upgrade_pressed)

	_refresh()

	await get_tree().process_frame
	repair_button.grab_focus()
	DeckNav.chain_vertical([repair_button, depth_upgrade_button])

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
		rod.rod_name.to_lower(), status, rod.tension_cap, rod.max_depth]

	repair_button.text = "repair %s (%dcr)" % [rod.rod_name.to_lower(), rod.repair_cost]
	repair_button.disabled = not GameState.rod_damaged or GameState.credits < rod.repair_cost

	var maxed := GameState.depth_upgrade_count >= GameState.MAX_DEPTH_UPGRADES
	var cost := _depth_upgrade_cost()
	if maxed:
		depth_upgrade_button.text = "depth upgrade — max reached"
		depth_upgrade_button.disabled = true
	else:
		depth_upgrade_button.text = "depth upgrade +%dft (%dcr)" % [DEPTH_UPGRADE_AMOUNT, cost]
		depth_upgrade_button.disabled = GameState.credits < cost

func _on_repair_pressed() -> void:
	var rod = GameState.current_rod
	if GameState.spend_credits(rod.repair_cost):
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

func _on_depth_upgrade_pressed() -> void:
	var cost := _depth_upgrade_cost()
	if GameState.spend_credits(cost):
		GameState.max_depth_bonus += DEPTH_UPGRADE_AMOUNT
		GameState.depth_upgrade_count += 1
		var rod = GameState.current_rod.duplicate()
		rod.max_depth += DEPTH_UPGRADE_AMOUNT
		GameState.current_rod = rod
		GameState.save()
		message_label.text = "depth increased to %dft." % rod.max_depth
		message_label.add_theme_color_override("font_color", DeckStyle.GREEN)
		_maintenance_log.append_line("DEPTH MOD: Extension coil fitted. New ceiling: %dft." % rod.max_depth)
		_tension_gauge.refresh()
		_refresh()
	else:
		message_label.text = "not enough credits."
		message_label.add_theme_color_override("font_color", DeckStyle.RED)

# Upgraded rods are duplicates with no resource_path, so match on name.
func _rod_variant(rod: RodData) -> int:
	for index in VENDORS.ROD_PATHS.size():
		var stock_rod: RodData = load(VENDORS.ROD_PATHS[index])
		if stock_rod.rod_name == rod.rod_name:
			return index
	return 0

func _depth_upgrade_cost() -> int:
	return DEPTH_UPGRADE_BASE_COST * (1 << GameState.depth_upgrade_count)
