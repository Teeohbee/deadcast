# scenes/barge_hub/GameOver.gd
extends Control

@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var return_button: Button = $VBoxContainer/ReturnButton

func _ready() -> void:
	message_label.text = "FORCED SURRENDER\n\nMarta's people came for the Meridian.\nYou made it %d runs." % GameState.run_count
	return_button.focus_mode = Control.FOCUS_ALL
	return_button.pressed.connect(_on_return_pressed)
	return_button.grab_focus()

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen/TitleScreen.tscn")
