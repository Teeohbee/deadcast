# scenes/barge_hub/Bunk.gd
extends Control

@onready var journal_label: RichTextLabel = $VBoxContainer/JournalLabel

func _ready() -> void:
	self.theme = UIStyle.get_theme()

	$VBoxContainer/TitleLabel.text = "┌── [ THE BUNK ] ──────────────────────────────────────────────"
	UIStyle.apply_label($VBoxContainer/TitleLabel, UIStyle.COL_DIM)

	if GameState.journal_entries.is_empty():
		journal_label.text = "run %d.\n\nnothing written yet.\nthe sump takes everything down eventually." % GameState.run_count
	else:
		var reversed_entries = GameState.journal_entries.duplicate()
		reversed_entries.reverse()
		journal_label.text = "\n\n---\n\n".join(reversed_entries)
