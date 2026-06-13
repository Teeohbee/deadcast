# scenes/barge_hub/Bunk.gd
extends Control

enum Mode { JOURNAL, MANUAL, LOG }

@onready var content_label: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/JournalLabel
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var page_up_btn: Button = $MarginContainer/VBoxContainer/PageButtons/PageUpButton
@onready var page_down_btn: Button = $MarginContainer/VBoxContainer/PageButtons/PageDownButton
@onready var journal_toggle: Button = $MarginContainer/VBoxContainer/ToggleRow/JournalToggle
@onready var manual_toggle: Button = $MarginContainer/VBoxContainer/ToggleRow/ManualToggle
@onready var log_toggle: Button = $MarginContainer/VBoxContainer/ToggleRow/RunLogToggle

var _mode: Mode = Mode.JOURNAL

func _ready() -> void:
	for btn in [journal_toggle, manual_toggle, log_toggle]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_function_key(btn)

	for btn in [page_up_btn, page_down_btn]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_action_button(btn)

	content_label.add_theme_color_override("default_color", DeckStyle.TEXT)
	content_label.add_theme_font_size_override("normal_font_size", DeckStyle.SIZE_BODY)

	page_up_btn.pressed.connect(_on_page_up)
	page_down_btn.pressed.connect(_on_page_down)
	journal_toggle.pressed.connect(func() -> void: _set_mode(Mode.JOURNAL))
	manual_toggle.pressed.connect(func() -> void: _set_mode(Mode.MANUAL))
	log_toggle.pressed.connect(func() -> void: _set_mode(Mode.LOG))

	if GameState.journal_entries.is_empty():
		_set_mode(Mode.MANUAL)
	else:
		_set_mode(Mode.JOURNAL)

	await get_tree().process_frame
	page_down_btn.grab_focus()
	_wire_focus_graph()

func _wire_focus_graph() -> void:
	DeckNav.link(journal_toggle, manual_toggle, SIDE_RIGHT)
	DeckNav.link(manual_toggle, journal_toggle, SIDE_LEFT)
	DeckNav.link(manual_toggle, log_toggle, SIDE_RIGHT)
	DeckNav.link(log_toggle, manual_toggle, SIDE_LEFT)
	DeckNav.link(page_up_btn, page_down_btn, SIDE_RIGHT)
	DeckNav.link(page_down_btn, page_up_btn, SIDE_LEFT)
	DeckNav.link(journal_toggle, page_down_btn, SIDE_BOTTOM)
	DeckNav.link(manual_toggle, page_down_btn, SIDE_BOTTOM)
	DeckNav.link(log_toggle, page_down_btn, SIDE_BOTTOM)
	DeckNav.link(page_up_btn, journal_toggle, SIDE_TOP)
	DeckNav.link(page_down_btn, journal_toggle, SIDE_TOP)

func _set_mode(mode: Mode) -> void:
	_mode = mode
	scroll_container.scroll_vertical = 0
	_refresh_toggles()
	_refresh_content()

func _refresh_toggles() -> void:
	var cols := {
		Mode.JOURNAL: DeckStyle.GREEN if _mode == Mode.JOURNAL else DeckStyle.DIM,
		Mode.MANUAL: DeckStyle.GREEN if _mode == Mode.MANUAL else DeckStyle.DIM,
		Mode.LOG: DeckStyle.GREEN if _mode == Mode.LOG else DeckStyle.DIM,
	}
	for pair in [[journal_toggle, cols[Mode.JOURNAL]], [manual_toggle, cols[Mode.MANUAL]], [log_toggle, cols[Mode.LOG]]]:
		var btn := pair[0] as Button
		var col := pair[1] as Color
		btn.add_theme_color_override("font_color", col)
		btn.add_theme_color_override("font_focus_color", col)

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
		Mode.LOG:
			if GameState.run_logs.is_empty():
				content_label.text = "no archived runs.\nthe record begins with your next dive."
			else:
				var reversed_logs := GameState.run_logs.duplicate()
				reversed_logs.reverse()
				var texts: Array[String] = []
				for rec: Dictionary in reversed_logs:
					texts.append(DiveFormat.run_log_text(rec))
				content_label.text = "\n\n".join(texts)

func _on_page_up() -> void:
	scroll_container.scroll_vertical -= int(scroll_container.size.y)

func _on_page_down() -> void:
	scroll_container.scroll_vertical += int(scroll_container.size.y)
