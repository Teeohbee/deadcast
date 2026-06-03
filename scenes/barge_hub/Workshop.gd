# scenes/barge_hub/Workshop.gd
extends Control

const DEPTH_UPGRADE_COST: int = 2000
const DEPTH_UPGRADE_AMOUNT: int = 50

@onready var rod_label: Label = $VBoxContainer/RodLabel
@onready var repair_button: Button = $VBoxContainer/RepairButton
@onready var depth_upgrade_button: Button = $VBoxContainer/DepthUpgradeButton
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	for btn in [repair_button, depth_upgrade_button, back_button]:
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)

	$VBoxContainer/TitleLabel.text = "// workshop"
	UIStyle.apply_label($VBoxContainer/TitleLabel, UIStyle.COL_DIM)
	UIStyle.apply_label(rod_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(message_label, UIStyle.COL_DIM)

	repair_button.text = "repair rod"
	depth_upgrade_button.text = "depth upgrade"
	back_button.text = "return to deck"

	repair_button.pressed.connect(_on_repair_pressed)
	depth_upgrade_button.pressed.connect(_on_depth_upgrade_pressed)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))

	_refresh()
	back_button.grab_focus()

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

	depth_upgrade_button.text = "depth upgrade +%dft (%dcr)" % [DEPTH_UPGRADE_AMOUNT, DEPTH_UPGRADE_COST]
	depth_upgrade_button.disabled = GameState.credits < DEPTH_UPGRADE_COST

func _on_repair_pressed() -> void:
	var rod = GameState.current_rod
	if GameState.spend_credits(rod.repair_cost):
		GameState.rod_damaged = false
		GameState.save()
		message_label.text = "%s repaired." % rod.rod_name.to_lower()
		_refresh()
	else:
		message_label.text = "not enough credits."

func _on_depth_upgrade_pressed() -> void:
	if GameState.spend_credits(DEPTH_UPGRADE_COST):
		GameState.max_depth_bonus += DEPTH_UPGRADE_AMOUNT
		var rod = GameState.current_rod.duplicate()
		rod.max_depth += DEPTH_UPGRADE_AMOUNT
		GameState.current_rod = rod
		GameState.save()
		message_label.text = "depth increased to %dft." % rod.max_depth
		_refresh()
	else:
		message_label.text = "not enough credits."
