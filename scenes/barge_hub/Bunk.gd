# scenes/barge_hub/Bunk.gd
extends Control

@onready var journal_label: RichTextLabel = $VBoxContainer/JournalLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	back_button.focus_mode = Control.FOCUS_ALL
	UIStyle.apply_button(back_button)
	back_button.text = "return to deck"
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))
	back_button.grab_focus()

	$VBoxContainer/TitleLabel.text = "// the bunk"
	UIStyle.apply_label($VBoxContainer/TitleLabel, UIStyle.COL_DIM)

	if GameState.journal_entries.is_empty():
		journal_label.text = "run %d.\n\nnothing written yet.\nthe sump takes everything down eventually." % GameState.run_count
	else:
		var reversed_entries = GameState.journal_entries.duplicate()
		reversed_entries.reverse()
		journal_label.text = "\n\n---\n\n".join(reversed_entries)
