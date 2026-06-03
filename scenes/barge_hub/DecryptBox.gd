# scenes/barge_hub/DecryptBox.gd
extends Control

const LOAD_AMOUNT: int = 1000

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var message_label: Label = $VBoxContainer/MessageLabel

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	for btn in [load_button]:
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)

	$VBoxContainer/TitleLabel.text = "┌── [ DECRYPT BOX ] ───────────────────────────────────────────"
	UIStyle.apply_label($VBoxContainer/TitleLabel, UIStyle.COL_DIM)
	UIStyle.apply_label(status_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(message_label, UIStyle.COL_DIM)

	load_button.pressed.connect(_on_load_pressed)
	_refresh()
	load_button.grab_focus()

func _refresh() -> void:
	var decrypting = GameState.decrypt_box_runs > 0

	if GameState.decrypt_box_queue == 0:
		status_label.text = "box is empty.\nload credits to decrypt at 4x after %d runs." % GameState.DECRYPT_THRESHOLD
	else:
		var runs_left = GameState.DECRYPT_THRESHOLD - GameState.decrypt_box_runs
		status_label.text = "queued: %dcr\ndecrypts in %d run%s → %dcr" % [
			GameState.decrypt_box_queue,
			runs_left,
			"s" if runs_left != 1 else "",
			GameState.decrypt_box_queue * GameState.DECRYPT_MULTIPLIER
		]

	if decrypting:
		load_button.text = "decryption in progress"
		load_button.disabled = true
	else:
		load_button.text = "load %dcr of data" % LOAD_AMOUNT
		load_button.disabled = GameState.credits < LOAD_AMOUNT

func _on_load_pressed() -> void:
	if GameState.spend_credits(LOAD_AMOUNT):
		GameState.decrypt_box_queue += LOAD_AMOUNT
		if GameState.decrypt_box_queue == LOAD_AMOUNT:
			GameState.decrypt_box_runs = 0
		GameState.save()
		message_label.text = "%dcr loaded into decrypt queue." % LOAD_AMOUNT
		_refresh()
	else:
		message_label.text = "not enough credits."
