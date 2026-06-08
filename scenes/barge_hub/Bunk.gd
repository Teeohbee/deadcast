# scenes/barge_hub/Bunk.gd
extends Control

enum Mode { JOURNAL, MANUAL }

@onready var content_label: RichTextLabel = $VBoxContainer/ScrollContainer/JournalLabel
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var page_up_btn: Button = $VBoxContainer/PageButtons/PageUpButton
@onready var page_down_btn: Button = $VBoxContainer/PageButtons/PageDownButton
@onready var journal_toggle: Button = $VBoxContainer/ToggleRow/JournalToggle
@onready var manual_toggle: Button = $VBoxContainer/ToggleRow/ManualToggle

var _mode: Mode = Mode.JOURNAL

func _ready() -> void:
	self.theme = UIStyle.get_theme()

	$VBoxContainer/TitleLabel.text = "┌── [ THE BUNK ] ──────────────────────────────────────────────"
	UIStyle.apply_label($VBoxContainer/TitleLabel, UIStyle.COL_DIM)

	for btn in [page_up_btn, page_down_btn, journal_toggle, manual_toggle]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIStyle.apply_button(btn)

	page_up_btn.pressed.connect(_on_page_up)
	page_down_btn.pressed.connect(_on_page_down)
	journal_toggle.pressed.connect(func() -> void: _set_mode(Mode.JOURNAL))
	manual_toggle.pressed.connect(func() -> void: _set_mode(Mode.MANUAL))

	if GameState.journal_entries.is_empty():
		_set_mode(Mode.MANUAL)
	else:
		_set_mode(Mode.JOURNAL)

	await get_tree().process_frame
	page_down_btn.grab_focus()

func _set_mode(mode: Mode) -> void:
	_mode = mode
	scroll_container.scroll_vertical = 0
	_refresh_toggles()
	_refresh_content()

func _refresh_toggles() -> void:
	var journal_col: Color = UIStyle.COL_ACCENT if _mode == Mode.JOURNAL else UIStyle.COL_DIM
	var manual_col: Color = UIStyle.COL_ACCENT if _mode == Mode.MANUAL else UIStyle.COL_DIM
	journal_toggle.add_theme_color_override("font_color", journal_col)
	journal_toggle.add_theme_color_override("font_hover_color", journal_col)
	journal_toggle.add_theme_color_override("font_focus_color", journal_col)
	manual_toggle.add_theme_color_override("font_color", manual_col)
	manual_toggle.add_theme_color_override("font_hover_color", manual_col)
	manual_toggle.add_theme_color_override("font_focus_color", manual_col)

func _refresh_content() -> void:
	match _mode:
		Mode.JOURNAL:
			if GameState.journal_entries.is_empty():
				content_label.text = "run %d.\n\nnothing written yet.\nthe sump takes everything down eventually." % GameState.run_count
			else:
				var reversed_entries = GameState.journal_entries.duplicate()
				reversed_entries.reverse()
				content_label.text = "\n\n---\n\n".join(reversed_entries)
		Mode.MANUAL:
			content_label.text = ManualContent.format_full_manual()

func _on_page_up() -> void:
	scroll_container.scroll_vertical -= int(scroll_container.size.y)

func _on_page_down() -> void:
	scroll_container.scroll_vertical += int(scroll_container.size.y)
