# scenes/barge_hub/Workshop.gd
extends Control

const DEPTH_UPGRADE_BASE_COST: int = 2000
const DEPTH_UPGRADE_AMOUNT: int = 50

@onready var rod_label: Label = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/RodLabel
@onready var repair_button: Button = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/RepairButton
@onready var depth_upgrade_button: Button = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/DepthUpgradeButton
@onready var message_label: Label = $MarginContainer/HBox/LeftColumn/ControlPanel/VBox/MessageLabel
@onready var _diagnostics: RodDiagnosticsPanel = $MarginContainer/HBox/RightColumn/RodDiagnosticsPanel
@onready var _maintenance_log: MaintenanceLogPanel = $MarginContainer/HBox/RightColumn/MaintenanceLogPanel

func _ready() -> void:
	for btn in [repair_button, depth_upgrade_button]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_action_button(btn)

	DeckStyle.apply_label(rod_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	DeckStyle.apply_label(message_label, DeckStyle.DIM, DeckStyle.SIZE_BODY)

	repair_button.pressed.connect(_on_repair_pressed)
	depth_upgrade_button.pressed.connect(_on_depth_upgrade_pressed)

	_refresh()

	await get_tree().process_frame
	repair_button.grab_focus()
	DeckNav.chain_vertical([repair_button, depth_upgrade_button])

func _refresh() -> void:
	var rod = GameState.current_rod
	if rod == null:
		rod_label.text = "no rod equipped."
		repair_button.disabled = true
		return

	var status = " [damaged]" if GameState.rod_damaged else " [ok]"
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
		_maintenance_log.append_line("REPAIR: %s serviced. Micro-fractures sealed." % rod.rod_name.to_lower())
		_diagnostics.refresh()
		_refresh()
	else:
		message_label.text = "not enough credits."

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
		_maintenance_log.append_line("DEPTH MOD: Extension coil fitted. New ceiling: %dft." % rod.max_depth)
		_diagnostics.refresh()
		_refresh()
	else:
		message_label.text = "not enough credits."

func _depth_upgrade_cost() -> int:
	return DEPTH_UPGRADE_BASE_COST * (1 << GameState.depth_upgrade_count)
