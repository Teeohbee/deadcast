# scenes/barge_hub/BargeHub.gd
extends Control

@onready var account_label: Label = $VBoxContainer/ContentRow/RightColumn/AccountLabel
@onready var freezer_label: Label = $VBoxContainer/ContentRow/RightColumn/FreezerLabel
@onready var freezer_sell_btn: Button = $VBoxContainer/ContentRow/RightColumn/FreezerSellButton
@onready var dive_button: Button = $VBoxContainer/DiveRow/DiveButton

func _ready() -> void:
	self.theme = UIStyle.get_theme()

	UIStyle.apply_label(account_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(freezer_label, UIStyle.COL_DIM)
	UIStyle.apply_button(dive_button)
	UIStyle.apply_button(freezer_sell_btn)
	dive_button.focus_mode = Control.FOCUS_ALL
	freezer_sell_btn.focus_mode = Control.FOCUS_ALL

	dive_button.pressed.connect(func(): UIController.navigate_to("dive"))
	freezer_sell_btn.pressed.connect(_on_sell_freezer)

	EventBus.credits_changed.connect(_refresh_account)
	_refresh_account()
	_refresh_freezer()

	await get_tree().process_frame
	$VBoxContainer/ContentRow/LeftColumn/ZoneSelector.get_child(1).grab_focus()

func _refresh_account(_ignored: int = 0) -> void:
	var runs_to_pmt := 5 - GameState.runs_since_payment
	var run_str := "in %d run%s" % [runs_to_pmt, "s" if runs_to_pmt != 1 else ""]
	account_label.text = (
		"┌── [ ACCOUNT STATUS ]\n"
		+ "│  WALLET:   %dcr\n" % GameState.credits
		+ "│  DEBT:     %dcr\n" % GameState.debt
		+ "│  PRESSURE: %d/5\n" % GameState.pressure_level
		+ "│  PAYMENT:  %s\n" % run_str
		+ "└──────────────────────"
	)
	var color := UIStyle.COL_DEBT if GameState.pressure_level >= 3 else UIStyle.COL_TEXT
	UIStyle.apply_label(account_label, color)

func _refresh_freezer() -> void:
	if GameState.freezer_value == 0:
		freezer_label.text = "┌── [ FREEZER ]\n│  empty\n└──────────────────────"
		freezer_sell_btn.visible = false
		return

	var spoiled := GameState.freezer_runs >= GameState.FREEZER_SPOIL_RUNS
	var status_line: String
	if spoiled:
		status_line = "│  SPOILED — %dcr (50%% loss)" % GameState.freezer_value
	else:
		var runs_left := GameState.FREEZER_SPOIL_RUNS - GameState.freezer_runs
		status_line = "│  stored: %dcr  ·  spoils in %d run%s" % [
			GameState.freezer_value, runs_left, "s" if runs_left != 1 else ""]

	freezer_label.text = "┌── [ FREEZER ]\n%s\n└──────────────────────" % status_line
	freezer_sell_btn.text = "│  sell all (%dcr)" % GameState.freezer_value
	freezer_sell_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	freezer_sell_btn.visible = true

func _on_sell_freezer() -> void:
	GameState.add_credits(GameState.freezer_value)
	GameState.freezer_value = 0
	GameState.freezer_runs = 0
	GameState.save()
	_refresh_freezer()
	dive_button.grab_focus()
