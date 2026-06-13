# scenes/barge_hub/GameOver.gd
extends Control

@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var return_button: Button = $VBoxContainer/ReturnButton

func _ready() -> void:
	DeckStyle.apply_label(message_label, DeckStyle.RED)
	return_button.focus_mode = Control.FOCUS_ALL
	return_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	DeckStyle.apply_action_button(return_button)
	return_button.text = "return to title"
	return_button.pressed.connect(_on_return_pressed)
	message_label.text = "forced surrender\n\nmarta's people came for the meridian.\nyou made it %d runs." % GameState.run_count
	return_button.grab_focus()

func _on_return_pressed() -> void:
	UIController.navigate_to_title()
