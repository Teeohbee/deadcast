# scenes/barge_hub/Bunk.gd
extends Control

@onready var journal_label: Label = $VBoxContainer/JournalLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))

	journal_label.text = "Run %d.\n\nNothing written yet.\nThe Sump takes everything down eventually." % GameState.run_count
	back_button.grab_focus()
