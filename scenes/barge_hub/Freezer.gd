# scenes/barge_hub/Freezer.gd
extends Control

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var sell_button: Button = $VBoxContainer/SellButton
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	for btn in [sell_button, back_button]:
		btn.focus_mode = Control.FOCUS_ALL
	sell_button.pressed.connect(_on_sell_pressed)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))
	_refresh()
	back_button.grab_focus()

func _refresh() -> void:
	if GameState.freezer_value == 0:
		status_label.text = "Freezer is empty.\nBiological catches are stored here automatically."
		sell_button.disabled = true
		return

	var spoiled = GameState.freezer_runs >= GameState.FREEZER_SPOIL_RUNS
	if spoiled:
		status_label.text = "SPOILED — Value: %dcr (50%% loss)\nSell quickly." % GameState.freezer_value
	else:
		var runs_until_spoil = GameState.FREEZER_SPOIL_RUNS - GameState.freezer_runs
		status_label.text = "Stored: %dcr\nSpoils in %d run%s." % [
			GameState.freezer_value, runs_until_spoil, "s" if runs_until_spoil != 1 else ""]

	sell_button.text = "Sell All (%dcr)" % GameState.freezer_value
	sell_button.disabled = false

func _on_sell_pressed() -> void:
	var value = GameState.freezer_value
	GameState.add_credits(value)
	GameState.freezer_value = 0
	GameState.freezer_runs = 0
	GameState.save()
	message_label.text = "Sold for %dcr." % value
	_refresh()
