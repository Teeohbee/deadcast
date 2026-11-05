# scenes/relay/RelayTab.gd
# The RELAY tab: the record of everything said over the relay. Contacts on the
# left, the selected contact's thread in the middle, the active job and the
# Axiom Credit account on the right. Replaces the old MARTA tab.
#
# Marta's job offer for this run arrives here as a text exchange with replies
# (take it / pass / say nothing); the answer is filed in her thread.
class_name RelayTab
extends Control

const CONTACT_ORDER: Array[String] = [
	RelayScripts.CONTACT_MARTA, RelayScripts.CONTACT_AXIOM_CREDIT, RelayScripts.CONTACT_OKEKE]
const NAME_COLUMN_WIDTH := 7
const INSTALMENT_EVERY_RUNS := 5

var selected_contact := RelayScripts.CONTACT_MARTA
var _job_offer_runner: RelayRunner = null

var _contact_list: VBoxContainer
var _contact_buttons: Dictionary = {} # contact -> Button
var _thread_panel: TerminalPanel
var _thread: RichTextLabel
var _reply_block: VBoxContainer
var _case_rows: VBoxContainer
var _account_rows: VBoxContainer

func _ready() -> void:
	_build_layout()
	_refresh()

func on_screen_shown() -> void:
	var newest_unread := _newest_unread_contact()
	if newest_unread != "":
		selected_contact = newest_unread
	_refresh()
	var target := default_focus()
	if target != null:
		target.grab_focus()

# A pending reply to Marta first, otherwise the contact being read.
func default_focus() -> Control:
	for child in _reply_block.get_children():
		if not child.is_queued_for_deletion():
			return child as Control
	return _contact_buttons.get(selected_contact)

func _refresh() -> void:
	_open_job_offer_if_due()
	_build_contact_list()
	_show_thread(selected_contact)
	_fill_case_file()
	_fill_account()

# --- contacts and thread ---

# Marta and Axiom Credit are always listed; anyone else once they've been in touch.
func listed_contacts() -> Array[String]:
	var listed: Array[String] = []
	for contact in CONTACT_ORDER:
		var always_listed := contact in [RelayScripts.CONTACT_MARTA, RelayScripts.CONTACT_AXIOM_CREDIT]
		if always_listed or not GameState.relay_entries_for(contact).is_empty():
			listed.append(contact)
	return listed

func select_contact(contact: String) -> void:
	selected_contact = contact
	_build_contact_list()
	_show_thread(contact)

func _show_thread(contact: String) -> void:
	GameState.relay_mark_read(contact)
	var display: Dictionary = RelayScripts.CONTACT_DISPLAY.get(contact, {})
	_thread_panel.title = "relay_7 · %s" % display.get("caller_id", contact).to_lower()
	_thread.text = render_thread(contact)
	_show_job_offer_replies()

func render_thread(contact: String) -> String:
	var rendered: Array[String] = []
	for entry in GameState.relay_entries_for(contact):
		rendered.append(_colored("── %s ──" % entry_heading(entry), DeckStyle.DIM))
		for line in entry.lines:
			rendered.append(_render_line(line))
	if contact == RelayScripts.CONTACT_MARTA and _job_offer_runner != null:
		rendered.append(_colored("── run %d ──" % GameState.run_count, DeckStyle.DIM))
		for line in _job_offer_runner.transcript:
			rendered.append(_render_line(line))
	if rendered.is_empty():
		return _colored("no transmissions.", DeckStyle.DIM)
	return "\n".join(rendered)

static func entry_heading(entry: Dictionary) -> String:
	match entry.kind:
		GameState.RELAY_ENTRY_CALL:
			return "call · run %d" % entry.run
		GameState.RELAY_ENTRY_MISSED_CALL:
			return "missed call · run %d" % entry.run
		GameState.RELAY_ENTRY_DIVE_LINE:
			return "dive %d · on the line" % (entry.run + 1)
	return "run %d" % entry.run

func _render_line(line: Dictionary) -> String:
	var who: String = line.who
	var display: Dictionary = RelayScripts.CONTACT_DISPLAY.get(who, {})
	var speaker: String = display.get("speaker", who)
	var name_color := DeckStyle.GREEN if who == RelayRunner.PLAYER else _contact_color(who)
	var text_color := DeckStyle.GREEN if who == RelayRunner.PLAYER else DeckStyle.TEXT
	if line.get("attachment", false):
		text_color = DeckStyle.AMBER
	var name_column: String = (speaker + " ›").rpad(NAME_COLUMN_WIDTH + 2)
	return _colored(name_column, name_color) + _colored(line.text, text_color)

func _newest_unread_contact() -> String:
	for index in range(GameState.relay_entries.size() - 1, -1, -1):
		var entry: Dictionary = GameState.relay_entries[index]
		if not entry.read:
			return entry.contact
	return ""

func _build_contact_list() -> void:
	# Rebuilding frees the focused button, so carry pad focus over to the
	# newly selected one when it was in the list.
	var owner := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var refocus := owner != null and _contact_list.is_ancestor_of(owner)
	_contact_buttons.clear()
	for child in _contact_list.get_children():
		_contact_list.remove_child(child)
		child.queue_free()
	var buttons: Array[Control] = []
	for contact in listed_contacts():
		var display: Dictionary = RelayScripts.CONTACT_DISPLAY.get(contact, {})
		var unread := GameState.relay_unread_count(contact)
		var selected := contact == selected_contact
		var button := Button.new()
		button.text = "%s%s%s" % ["> " if selected else "  ", display.get("caller_id", contact).to_lower(),
			"  ·  %d new" % unread if unread > 0 else ""]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		DeckStyle.apply_card(button, selected)
		button.add_theme_color_override("font_color", _contact_color(contact))
		button.add_theme_font_size_override("font_size", DeckStyle.SIZE_BODY)
		var contact_id := contact
		button.pressed.connect(func() -> void: select_contact(contact_id))
		_contact_list.add_child(button)
		buttons.append(button)
		_contact_buttons[contact] = button
	DeckNav.chain_vertical(buttons)
	if refocus and _contact_buttons.has(selected_contact):
		(_contact_buttons[selected_contact] as Button).grab_focus()

func contact_button_labels() -> Array[String]:
	var labels: Array[String] = []
	for child in _contact_list.get_children():
		labels.append((child as Button).text)
	return labels

# --- job offers ---

func _open_job_offer_if_due() -> void:
	if not GameState.job_offer_open():
		_job_offer_runner = null
		return
	var offer := MartaJobs.offer_for(GameState.run_count)
	if offer == null:
		return
	var offer_script := RelayScripts.job_offer_script(offer.id)
	if offer_script.is_empty():
		return
	if _job_offer_runner != null and _job_offer_runner.script_id == offer_script.id:
		return
	_job_offer_runner = RelayRunner.new(offer_script)
	_advance_job_offer()

# Plays the offer up to its replies (or to the end, once answered).
func _advance_job_offer() -> void:
	while _job_offer_runner != null:
		var event := _job_offer_runner.next_event()
		match event.kind:
			RelayRunner.EVENT_REPLIES:
				return
			RelayRunner.EVENT_DO:
				RelayActions.apply(event.action)
			RelayRunner.EVENT_END:
				GameState.relay_file_entry(RelayScripts.CONTACT_MARTA, GameState.RELAY_ENTRY_TEXT,
					_job_offer_runner.script_id, _job_offer_runner.transcript)
				GameState.relay_mark_read(RelayScripts.CONTACT_MARTA)
				GameState.save()
				_job_offer_runner = null
				return

func job_offer_options() -> Array[String]:
	var labels: Array[String] = []
	for child in _reply_block.get_children():
		labels.append((child as Button).text)
	return labels

func answer_job_offer(option_index: int) -> void:
	if _job_offer_runner == null or not _job_offer_runner.is_waiting_for_reply():
		return
	_job_offer_runner.choose(option_index)
	_advance_job_offer()
	_refresh()

func _show_job_offer_replies() -> void:
	for child in _reply_block.get_children():
		_reply_block.remove_child(child)
		child.queue_free()
	var waiting := _job_offer_runner != null and _job_offer_runner.is_waiting_for_reply() \
		and selected_contact == RelayScripts.CONTACT_MARTA
	if not waiting:
		return
	var options: Array = _job_offer_runner.next_event().options
	for index in options.size():
		var button := Button.new()
		button.text = "[%d] %s" % [index + 1, options[index]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		DeckStyle.apply_action_button(button)
		var option_index := index
		button.pressed.connect(func() -> void: answer_job_offer(option_index))
		_reply_block.add_child(button)
	# Weak, so a tab freed before the deferred call doesn't leave a dangling capture.
	var first_reply: WeakRef = weakref(_reply_block.get_child(0))
	(func() -> void:
		var button := first_reply.get_ref() as Button
		if button != null and button.is_inside_tree():
			button.grab_focus()).call_deferred()

# --- right column ---

func _fill_case_file() -> void:
	_clear(_case_rows)
	var active := MartaJobs.find(GameState.active_job_id)
	if active != null:
		_case_rows.add_child(_label(active.title.to_upper(), DeckStyle.TEXT, DeckStyle.SIZE_VALUE))
		_case_rows.add_child(_wrapped_label(RelayScripts.job_condition_text(active.id), DeckStyle.TEXT, DeckStyle.SIZE_BODY))
		_case_rows.add_child(_row("PAYS:", "%s cr off axiom" % LedgerPanel.format_thousands(active.debt_relief), DeckStyle.GREEN))
		_case_rows.add_child(_row("CUT:", "marta 30%", DeckStyle.DIM))
		return
	_case_rows.add_child(_label("NO ACTIVE JOB", DeckStyle.DIM, DeckStyle.SIZE_BODY))
	var hint := "check back after your next dive."
	if GameState.victory:
		hint = "no more jobs. you don't owe anyone anything."
	elif _job_offer_runner != null:
		hint = "marta has work, if you want it."
	elif GameState.run_count == 0:
		hint = "first dive's on marta. no client."
	_case_rows.add_child(_wrapped_label(hint, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT))

func _fill_account() -> void:
	_clear(_account_rows)
	if GameState.victory:
		_account_rows.add_child(_row("BALANCE:", "0 cr", DeckStyle.GREEN))
		_account_rows.add_child(_label("ACCOUNT CLOSED", DeckStyle.GREEN, DeckStyle.SIZE_BODY))
		return
	var dives_left := INSTALMENT_EVERY_RUNS - GameState.runs_since_payment
	_account_rows.add_child(_row("BALANCE:", "%s cr" % LedgerPanel.format_thousands(GameState.debt), DeckStyle.RED))
	_account_rows.add_child(_row("NEXT INSTALMENT:", "%s cr" % LedgerPanel.format_thousands(LedgerPanel.next_payment_amount()), DeckStyle.AMBER))
	_account_rows.add_child(_row("DUE:", "in %d dive%s" % [dives_left, "" if dives_left == 1 else "s"], DeckStyle.AMBER))
	_account_rows.add_child(_row("MISSED:", "%d / 5" % GameState.pressure_level,
		DeckStyle.RED if GameState.pressure_level > 0 else DeckStyle.DIM))

func account_text() -> String:
	return _text_of(_account_rows)

func case_file_text() -> String:
	return _text_of(_case_rows)

# --- layout ---

func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var contacts_panel := _panel("relay_contacts")
	contacts_panel.custom_minimum_size = Vector2(260, 0)
	row.add_child(contacts_panel)
	var contacts_column := VBoxContainer.new()
	contacts_column.add_theme_constant_override("separation", 8)
	contacts_panel.add_child(contacts_column)
	_contact_list = VBoxContainer.new()
	_contact_list.add_theme_constant_override("separation", 6)
	_contact_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contacts_column.add_child(_contact_list)
	contacts_column.add_child(_label("%s SELECT CONTACT" % InputGlyphs.glyph("navigate"), DeckStyle.DIM, DeckStyle.SIZE_AMBIENT))
	contacts_column.add_child(_label("SRC meridian_relay · ENC aes-256", DeckStyle.DIM, DeckStyle.SIZE_AMBIENT))

	_thread_panel = _panel("relay_7")
	_thread_panel.active = true
	_thread_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_thread_panel)
	var thread_column := VBoxContainer.new()
	thread_column.add_theme_constant_override("separation", 8)
	_thread_panel.add_child(thread_column)
	_thread = RichTextLabel.new()
	_thread.bbcode_enabled = true
	_thread.scroll_following = true
	_thread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_thread.add_theme_constant_override("line_separation", 6)
	var thread_margin := MarginContainer.new()
	thread_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	thread_margin.add_theme_constant_override("margin_left", 12)
	thread_margin.add_theme_constant_override("margin_right", 12)
	thread_margin.add_child(_thread)
	thread_column.add_child(thread_margin)
	_reply_block = VBoxContainer.new()
	_reply_block.add_theme_constant_override("separation", 6)
	var reply_margin := MarginContainer.new()
	reply_margin.add_theme_constant_override("margin_left", 12)
	reply_margin.add_theme_constant_override("margin_right", 12)
	reply_margin.add_child(_reply_block)
	thread_column.add_child(reply_margin)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(332, 0)
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	var case_panel := _panel("case_file")
	right.add_child(case_panel)
	_case_rows = VBoxContainer.new()
	_case_rows.add_theme_constant_override("separation", 6)
	case_panel.add_child(_case_rows)
	var account_panel := _panel("axiom_credit")
	account_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(account_panel)
	_account_rows = VBoxContainer.new()
	_account_rows.add_theme_constant_override("separation", 6)
	account_panel.add_child(_account_rows)

func _panel(title: String) -> TerminalPanel:
	var panel := TerminalPanel.new()
	panel.title = title
	return panel

func _label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	DeckStyle.apply_label(label, color, font_size)
	return label

func _wrapped_label(text: String, color: Color, font_size: int) -> Label:
	var label := _label(text, color, font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _row(caption: String, value: String, value_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var caption_label := _label(caption, DeckStyle.DIM, DeckStyle.SIZE_BODY)
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption_label)
	row.add_child(_label(value, value_color, DeckStyle.SIZE_VALUE))
	return row

func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _text_of(container: Container) -> String:
	var parts: Array[String] = []
	for node in container.find_children("*", "Label", true, false):
		parts.append((node as Label).text)
	return " ".join(parts)

func _contact_color(contact: String) -> Color:
	match RelayScripts.CONTACT_DISPLAY.get(contact, {}).get("color", ""):
		"AMBER": return DeckStyle.AMBER
		"RED": return DeckStyle.RED
	return DeckStyle.SKY

func _colored(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text.replace("[", "[lb]")]
