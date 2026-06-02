# scenes/barge_hub/Freezer.gd
extends Control

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var sell_button: Button = $VBoxContainer/SellButton
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	for btn in [sell_button, back_button]:
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)

	$VBoxContainer/TitleLabel.text = "// freezer"
	UIStyle.apply_label($VBoxContainer/TitleLabel, UIStyle.COL_DIM)
	UIStyle.apply_label(status_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(message_label, UIStyle.COL_DIM)

	sell_button.text = "sell all"
	back_button.text = "return to deck"
	sell_button.pressed.connect(_on_sell_pressed)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))
	_refresh()
	back_button.grab_focus()

func _refresh() -> void:
	if GameState.freezer_value == 0:
		status_label.text = "freezer is empty.\nbiological catches are stored here automatically."
		sell_button.disabled = true
		return

	var spoiled = GameState.freezer_runs >= GameState.FREEZER_SPOIL_RUNS
	if spoiled:
		status_label.text = "spoiled — value: %dcr (50%% loss)\nsell quickly." % GameState.freezer_value
	else:
		var runs_until_spoil = GameState.FREEZER_SPOIL_RUNS - GameState.freezer_runs
		status_label.text = "stored: %dcr\nspoils in %d run%s." % [
			GameState.freezer_value, runs_until_spoil, "s" if runs_until_spoil != 1 else ""]

	sell_button.text = "sell all (%dcr)" % GameState.freezer_value
	sell_button.disabled = false

func _on_sell_pressed() -> void:
	var value = GameState.freezer_value
	GameState.add_credits(value)
	GameState.freezer_value = 0
	GameState.freezer_runs = 0
	GameState.save()
	message_label.text = "sold for %dcr." % value
	_refresh()
