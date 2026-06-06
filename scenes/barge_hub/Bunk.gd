# scenes/barge_hub/Bunk.gd
extends Control

@onready var journal_label: RichTextLabel = $VBoxContainer/ScrollContainer/JournalLabel
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var page_up_btn: Button = $VBoxContainer/PageButtons/PageUpButton
@onready var page_down_btn: Button = $VBoxContainer/PageButtons/PageDownButton

func _ready() -> void:
	self.theme = UIStyle.get_theme()

	$VBoxContainer/TitleLabel.text = "┌── [ THE BUNK ] ──────────────────────────────────────────────"
	UIStyle.apply_label($VBoxContainer/TitleLabel, UIStyle.COL_DIM)

	page_up_btn.focus_mode = Control.FOCUS_ALL
	page_down_btn.focus_mode = Control.FOCUS_ALL
	page_up_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	page_down_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIStyle.apply_button(page_up_btn)
	UIStyle.apply_button(page_down_btn)
	page_up_btn.pressed.connect(_on_page_up)
	page_down_btn.pressed.connect(_on_page_down)

	if GameState.journal_entries.is_empty():
		journal_label.text = "run %d.\n\nnothing written yet.\nthe sump takes everything down eventually." % GameState.run_count
	else:
		var reversed_entries = GameState.journal_entries.duplicate()
		reversed_entries.reverse()
		journal_label.text = "\n\n---\n\n".join(reversed_entries)

	await get_tree().process_frame
	page_down_btn.grab_focus()

func _on_page_up() -> void:
	scroll_container.scroll_vertical -= int(scroll_container.size.y)

func _on_page_down() -> void:
	scroll_container.scroll_vertical += int(scroll_container.size.y)
