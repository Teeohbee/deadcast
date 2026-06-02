# scenes/barge_hub/DecryptBox.gd
extends Control

const LOAD_AMOUNT: int = 1000

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	for btn in [load_button, back_button]:
		btn.focus_mode = Control.FOCUS_ALL
	load_button.pressed.connect(_on_load_pressed)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))
	_refresh()
	back_button.grab_focus()

func _refresh() -> void:
	if GameState.decrypt_box_queue == 0:
		status_label.text = "Box is empty.\nLoad credits to decrypt at 4x after %d runs." % GameState.DECRYPT_THRESHOLD
	else:
		var runs_left = GameState.DECRYPT_THRESHOLD - GameState.decrypt_box_runs
		status_label.text = "Queued: %dcr\nDecrypts in %d run%s → %dcr" % [
			GameState.decrypt_box_queue,
			runs_left,
			"s" if runs_left != 1 else "",
			GameState.decrypt_box_queue * GameState.DECRYPT_MULTIPLIER
		]
	load_button.text = "Load %dcr of data" % LOAD_AMOUNT
	load_button.disabled = GameState.credits < LOAD_AMOUNT

func _on_load_pressed() -> void:
	if GameState.spend_credits(LOAD_AMOUNT):
		GameState.decrypt_box_queue += LOAD_AMOUNT
		if GameState.decrypt_box_queue == LOAD_AMOUNT:
			GameState.decrypt_box_runs = 0  # reset timer on first load
		GameState.save()
		message_label.text = "%dcr loaded into decrypt queue." % LOAD_AMOUNT
		_refresh()
	else:
		message_label.text = "Not enough credits."
