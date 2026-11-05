# scenes/relay/CallScreen.gd
# A relay call, laid out like a dive: caller, voice trace and link telemetry on
# the rail, the call itself in a feed on the right, and replies as option
# buttons at the bottom of the feed. Plays UIController.pending_call through a
# RelayRunner, files the transcript in the RELAY thread, and hands back to
# UIController.finish_call() when the player hangs up.
#
# A forced call (the first call) can only be answered, and nothing on this
# screen backs out of it. If the game quits mid-call the script isn't marked
# played, so RelayDirector rings it again on Continue.
class_name CallScreen
extends Control

signal call_over
signal _reply_chosen(index: int)

const NAME_COLUMN_WIDTH := 7
# Word-by-word delivery: a base delay per word, more for long words, a pause at
# punctuation, and a breath between lines.
const SECONDS_PER_WORD := 0.09
const SECONDS_PER_LETTER := 0.02
const SECONDS_AT_PUNCTUATION := 0.22
const SECONDS_BETWEEN_LINES := 0.45
const SECONDS_AFTER_CONNECTING := 0.5
# Weak signal: now and then a longer word arrives scrambled and resolves.
const SCRAMBLE_CHANCE := 0.12
const SCRAMBLE_MIN_WORD_LENGTH := 4
const SCRAMBLE_AMOUNT := 0.6
const SCRAMBLE_SECONDS_MIN := 0.35
const SCRAMBLE_SECONDS_MAX := 0.85

# Test seam: skips every wait, so tests can drive a whole call in one frame.
var instant := false

var _relay_script: Dictionary = {}
var _runner: RelayRunner
var _contact_display: Dictionary = {}
# Each line is {"who", "color", "words": [{"text", "scrambled"}]}.
var _feed_lines: Array[Dictionary] = []
var _skip_current_line := false
var _speaking := false
var _call_started_msec := 0
var _random := RandomNumberGenerator.new()

var _feed: RichTextLabel
var _live_block: VBoxContainer
var _voice_trace: VoiceTrace
var _duration_value: Label

func _ready() -> void:
	_build_layout()

func on_screen_shown() -> void:
	start(UIController.pending_call)

# The first reply on offer, if the call is waiting on one.
func default_focus() -> Control:
	for child in _live_block.get_children():
		if not child.is_queued_for_deletion():
			return child as Control
	return null

func _process(_delta: float) -> void:
	if _call_started_msec > 0 and _duration_value != null:
		_duration_value.text = format_duration((Time.get_ticks_msec() - _call_started_msec) / 1000)

func _unhandled_input(event: InputEvent) -> void:
	if _speaking and event.is_action_pressed("ui_accept"):
		_skip_current_line = true
		get_viewport().set_input_as_handled()

# --- the call ---

func start(call_request: Dictionary) -> void:
	_relay_script = RelayScripts.find(call_request.get("script_id", ""))
	if _relay_script.is_empty():
		push_error("CallScreen: no relay script %s" % call_request)
		_finish()
		return
	_contact_display = RelayScripts.CONTACT_DISPLAY.get(_relay_script.contact, {})
	_fill_caller_panel()
	var last_dive_snapped: bool = GameState.last_run_result.get("snapped", false)
	_runner = RelayRunner.new(_relay_script, {RelayScripts.FLAG_LAST_DIVE_SNAPPED: last_dive_snapped})

	var answered: bool = call_request.get("answered", false)
	if not answered:
		answered = await _ring()
	if not answered:
		await _file_missed_call()
		return
	await _play_call()

func _ring() -> bool:
	_log_system("> incoming: %s · %s · encrypted" % [
		_contact_display.get("caller_id", "").to_lower(), _contact_display.get("route", "")], DeckStyle.TEXT)
	var options: Array[String] = ["answer"]
	if not RelayScripts.is_forced(_relay_script):
		options.append("let it ring")
	var index := await _present_options(options)
	return index == 0

func _file_missed_call() -> void:
	_runner.run_to_end_without_replies()
	_apply_actions(_runner.actions_taken)
	GameState.relay_file_entry(_relay_script.contact, GameState.RELAY_ENTRY_MISSED_CALL, _relay_script.id, _runner.transcript)
	GameState.relay_mark_played(_relay_script.id)
	GameState.save()
	_log_system("│  missed call. filed to RELAY.", DeckStyle.DIM)
	await _wait(SECONDS_BETWEEN_LINES)
	_finish()

func _play_call() -> void:
	_call_started_msec = maxi(1, Time.get_ticks_msec())
	_log_system("│  connected.", DeckStyle.DIM)
	await _wait(SECONDS_AFTER_CONNECTING)
	while true:
		var event := _runner.next_event()
		match event.kind:
			RelayRunner.EVENT_SAY:
				await _speak(event.who, event.text)
				await _wait(SECONDS_BETWEEN_LINES)
			RelayRunner.EVENT_ATTACH:
				_log_system("│  %s" % event.text, DeckStyle.AMBER)
			RelayRunner.EVENT_REPLIES:
				var index := await _present_options(event.options)
				var reply: String = event.options[index]
				if reply == RelayRunner.SAY_NOTHING:
					reply = RelayRunner.SILENCE_IN_TRANSCRIPT
				_add_line(RelayRunner.PLAYER, reply, DeckStyle.GREEN)
				_runner.choose(index)
				await _wait(SECONDS_BETWEEN_LINES)
			RelayRunner.EVENT_DO:
				_apply_actions([event.action])
			RelayRunner.EVENT_END:
				break
	var seconds := (Time.get_ticks_msec() - _call_started_msec) / 1000
	_call_started_msec = 0
	GameState.relay_file_entry(_relay_script.contact, GameState.RELAY_ENTRY_CALL, _relay_script.id, _runner.transcript)
	GameState.relay_mark_played(_relay_script.id)
	GameState.save()
	_log_system("> call ended · %s · transcript saved to RELAY" % format_duration(seconds), DeckStyle.DIM)
	await _present_options(["hang up"])
	_finish()

func _apply_actions(actions: Array) -> void:
	for action in actions:
		RelayActions.apply(action)

func _finish() -> void:
	call_over.emit()
	if not instant:
		UIController.finish_call()

# --- feed ---

func _speak(who: String, text: String) -> void:
	var display_name: String = _contact_display.get("speaker", who) if who == _relay_script.contact \
		else RelayScripts.CONTACT_DISPLAY.get(who, {}).get("speaker", who)
	var line := {"who": display_name, "color": _speaker_color(who), "words": []}
	_feed_lines.append(line)
	_skip_current_line = false
	_speaking = true
	_voice_trace.speaking = true
	for word in text.split(" "):
		var entry := {"text": word, "scrambled": false}
		if word.length() >= SCRAMBLE_MIN_WORD_LENGTH and _random.randf() < SCRAMBLE_CHANCE and not instant:
			entry.scrambled = true
			_resolve_scramble_later(entry)
		line.words.append(entry)
		_render_feed()
		if not _skip_current_line:
			await _wait(_seconds_for_word(word))
	_speaking = false
	_voice_trace.speaking = false

func _resolve_scramble_later(entry: Dictionary) -> void:
	await get_tree().create_timer(_random.randf_range(SCRAMBLE_SECONDS_MIN, SCRAMBLE_SECONDS_MAX)).timeout
	entry.scrambled = false
	if is_instance_valid(self):
		_render_feed()

func _add_line(who: String, text: String, color: Color) -> void:
	var words: Array = []
	for word in text.split(" "):
		words.append({"text": word, "scrambled": false})
	_feed_lines.append({"who": who, "color": color, "words": words})
	_render_feed()

func _log_system(text: String, color: Color) -> void:
	_feed_lines.append({"who": "", "color": color, "words": [{"text": text, "scrambled": false}]})
	_render_feed()

func _render_feed() -> void:
	var newest_spoken_index := -1
	for index in _feed_lines.size():
		if _feed_lines[index].who != "" and _feed_lines[index].who != RelayRunner.PLAYER:
			newest_spoken_index = index
	var rendered: Array[String] = []
	for index in _feed_lines.size():
		rendered.append(_render_line(_feed_lines[index], index == newest_spoken_index))
	_feed.text = "\n".join(rendered)

# Older lines from the caller dim so the newest one reads first.
func _render_line(line: Dictionary, is_newest_spoken: bool) -> String:
	var words: Array[String] = []
	for word in line.words:
		if word.scrambled:
			words.append(_colored(TextFX.corrupt(word.text, SCRAMBLE_AMOUNT), DeckStyle.SKY))
		else:
			words.append(_escape(word.text))
	var body := " ".join(words)
	if line.who == "":
		return _colored_raw(body, line.color)
	var name_column: String = (line.who + " ›").rpad(NAME_COLUMN_WIDTH + 2)
	var text_color: Color = line.color if line.who == RelayRunner.PLAYER else (DeckStyle.TEXT if is_newest_spoken else DeckStyle.DIM)
	return "%s%s" % [_colored(name_column, line.color), _colored_raw(body, text_color)]

func _colored(text: String, color: Color) -> String:
	return _colored_raw(_escape(text), color)

func _colored_raw(bbcode_body: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), bbcode_body]

func _escape(text: String) -> String:
	return text.replace("[", "[lb]")

func _speaker_color(who: String) -> Color:
	var color_name: String = RelayScripts.CONTACT_DISPLAY.get(who, {}).get("color", "SKY")
	match color_name:
		"AMBER": return DeckStyle.AMBER
		"RED": return DeckStyle.RED
		"GREEN": return DeckStyle.GREEN
	return DeckStyle.SKY

# --- options ---

# Shows "[n] option" buttons in the dive-choice style and waits for one.
func _present_options(options: Array[String]) -> int:
	_clear_live_block()
	for index in options.size():
		var button := Button.new()
		button.text = "[%d] %s" % [index + 1, options[index]]
		button.focus_mode = Control.FOCUS_ALL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_action_button(button)
		var option_index := index
		button.pressed.connect(func() -> void: _reply_chosen.emit(option_index))
		_live_block.add_child(button)
	(_live_block.get_child(0) as Button).grab_focus()
	var chosen: int = await _reply_chosen
	_clear_live_block()
	return chosen

func _clear_live_block() -> void:
	for child in _live_block.get_children():
		_live_block.remove_child(child)
		child.queue_free()

# Test seam: presses the option at index, as the player would.
func choose_option(index: int) -> void:
	_reply_chosen.emit(index)

func visible_options() -> Array[String]:
	var labels: Array[String] = []
	for child in _live_block.get_children():
		labels.append((child as Button).text)
	return labels

func feed_text() -> String:
	return _feed.get_parsed_text()

# --- timing ---

func _seconds_for_word(word: String) -> float:
	var seconds := SECONDS_PER_WORD + word.length() * SECONDS_PER_LETTER
	if word.ends_with(".") or word.ends_with(",") or word.ends_with("?"):
		seconds += SECONDS_AT_PUNCTUATION
	return seconds

func _wait(seconds: float) -> void:
	if instant:
		return
	await get_tree().create_timer(seconds).timeout

static func format_duration(total_seconds: int) -> String:
	return "%d:%02d" % [total_seconds / 60, total_seconds % 60]

# --- layout ---

func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	add_child(margin)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 12)
	margin.add_child(main_row)

	var rail := VBoxContainer.new()
	rail.custom_minimum_size = Vector2(280, 0)
	rail.add_theme_constant_override("separation", 12)
	main_row.add_child(rail)

	var caller_panel := _panel("caller")
	rail.add_child(caller_panel)
	var caller_rows := VBoxContainer.new()
	caller_rows.name = "CallerRows"
	caller_panel.add_child(caller_rows)

	var trace_panel := _panel("voice_trace")
	rail.add_child(trace_panel)
	_voice_trace = VoiceTrace.new()
	trace_panel.add_child(_voice_trace)

	var link_panel := _panel("relay_link")
	link_panel.ambient = true
	link_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.add_child(link_panel)
	var link_rows := VBoxContainer.new()
	link_panel.add_child(link_rows)
	var signal_row := HBoxContainer.new()
	signal_row.add_theme_constant_override("separation", 8)
	link_rows.add_child(signal_row)
	signal_row.add_child(_label("SIGNAL", DeckStyle.DIM, DeckStyle.SIZE_AMBIENT))
	signal_row.add_child(SignalBars.new())
	link_rows.add_child(_label("SRC meridian_relay", DeckStyle.DIM, DeckStyle.SIZE_AMBIENT))
	link_rows.add_child(_label("ENC aes-256 / verified", DeckStyle.DIM, DeckStyle.SIZE_AMBIENT))

	var call_panel := _panel("relay_call")
	call_panel.active = true
	call_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.add_child(call_panel)
	var call_column := VBoxContainer.new()
	call_column.add_theme_constant_override("separation", 6)
	call_panel.add_child(call_column)

	_feed = RichTextLabel.new()
	_feed.bbcode_enabled = true
	_feed.scroll_following = true
	_feed.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_feed.add_theme_constant_override("line_separation", 6)
	var feed_margin := MarginContainer.new()
	feed_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed_margin.add_theme_constant_override("margin_left", 20)
	feed_margin.add_theme_constant_override("margin_right", 20)
	feed_margin.add_theme_constant_override("margin_top", 8)
	feed_margin.add_child(_feed)
	call_column.add_child(feed_margin)

	_live_block = VBoxContainer.new()
	_live_block.add_theme_constant_override("separation", 6)
	var live_margin := MarginContainer.new()
	live_margin.add_theme_constant_override("margin_left", 20)
	live_margin.add_theme_constant_override("margin_right", 20)
	live_margin.add_theme_constant_override("margin_bottom", 12)
	live_margin.add_child(_live_block)
	call_column.add_child(live_margin)

func _fill_caller_panel() -> void:
	var rows: VBoxContainer = find_child("CallerRows", true, false)
	for child in rows.get_children():
		child.queue_free()
	rows.add_child(_caller_row("ID", _contact_display.get("caller_id", ""), _speaker_color(_relay_script.contact)))
	rows.add_child(_caller_row("ROUTE", _contact_display.get("route", ""), DeckStyle.TEXT))
	rows.add_child(_caller_row("ENC", "aes-256 / verified", DeckStyle.TEXT))
	var duration_row := _caller_row("DURATION", "--:--", DeckStyle.TEXT)
	_duration_value = duration_row.get_child(1)
	rows.add_child(duration_row)

func _caller_row(caption: String, value: String, value_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var caption_label := _label(caption, DeckStyle.DIM, DeckStyle.SIZE_BODY)
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption_label)
	row.add_child(_label(value, value_color, DeckStyle.SIZE_BODY))
	return row

func _panel(title: String) -> TerminalPanel:
	var panel := TerminalPanel.new()
	panel.title = title
	return panel

func _label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	DeckStyle.apply_label(label, color, font_size)
	return label
