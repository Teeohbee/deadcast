# scenes/ui/PostRun.gd
extends Control

@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var run_credits_label: Label = $VBoxContainer/RunCreditsLabel
@onready var total_credits_label: Label = $VBoxContainer/TotalCreditsLabel
@onready var return_button: Button = $VBoxContainer/ReturnButton

func _ready() -> void:
	return_button.pressed.connect(_on_return_pressed)
	return_button.focus_mode = Control.FOCUS_ALL
	return_button.grab_focus()
	var result = GameState.last_run_result
	var snapped = result.get("snapped", false)
	var earned = result.get("credits", 0)
	result_label.text = "LINE SNAPPED" if snapped else "RUN COMPLETE"
	run_credits_label.text = "EARNED: %d CR" % earned
	total_credits_label.text = "TOTAL: %d CR" % GameState.credits

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn")
