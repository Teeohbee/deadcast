# scenes/boot/BootSequence.gd
extends Control

const SYSTEM_DELAY := 0.5
const NARRATIVE_DELAY := 0.8
const CHAR_DELAY_MIN := 0.010
const CHAR_DELAY_MAX := 0.030
const _LEGIBLE_FONT_SIZE := 16

@onready var output_label: RichTextLabel = $MarginContainer/BootPanel/OutputLabel
@onready var _crt_overlay: ColorRect = $CRTOverlay

var _groups: Array[Dictionary] = []
var _finished := false
var _waiting_for_key := false
var _render_lines: Array[String] = [""]
var _max_visible_lines: int = 20

func _ready() -> void:
	self.theme = DeckStyle.get_theme()
	var crt_mat := (_crt_overlay.material as ShaderMaterial).duplicate() as ShaderMaterial
	if not Settings.crt_enabled:
		crt_mat.set_shader_parameter("scan_alpha", 0.0)
	_crt_overlay.material = crt_mat

	output_label.add_theme_color_override("default_color", DeckStyle.GREEN)
	output_label.add_theme_font_size_override("normal_font_size", _LEGIBLE_FONT_SIZE)
	output_label.add_theme_constant_override("line_separation", 4)
	output_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	await get_tree().process_frame
	_max_visible_lines = _estimate_visible_lines()
	_groups = [
		{"lines": "DEADCAST_OS %s\nBOOT SEQUENCE INITIATED..." % GameState.OS_VERSION, "delay": SYSTEM_DELAY},
		{"lines": "> SCANNING HARDWARE...\n  VESSEL:      THE MERIDIAN (deep-sea data trawler, class IV)\n  MOORING:     DISTRICT 7 DOCKS, THE SUMP\n  OPERATOR:    [NOT REGISTERED]\n  ROD SYSTEM:  SCRAP ROD Mk.I (salvage-grade, low depth)\n  HULL STATUS: pressure-rated to 200m. last survey: OVERDUE", "delay": SYSTEM_DELAY},
		{"lines": "> CHECKING NETWORK...\n  ENCRYPTED CHANNEL DETECTED: MARTA VOSS [F5]", "delay": SYSTEM_DELAY},
		{"lines": "  OUTSTANDING DEBT: 80,000cr\n  TERMS: 10,000cr every 5 runs. miss a payment and the terms change.", "delay": SYSTEM_DELAY},
		{"lines": "  VENDOR CHANNEL: OKEKE [F6]", "delay": SYSTEM_DELAY},
		{"lines": "> LOADING DIVE PROTOCOLS...\n  the sump was a city once. district 7, the exchange, axiom tower.\n  flooded forty years ago. nobody came back for what was left.", "delay": NARRATIVE_DELAY},
		{"lines": "  each dive deploys a trawl line into the ruins. whatever surfaces -\n  data, bio-matter, machines, ghosts - you decide what to do with it.", "delay": NARRATIVE_DELAY},
		{"lines": "  tension accumulates with every catch. push too hard and the line snaps. lose everything.", "delay": NARRATIVE_DELAY},
		{"lines": "> SYSTEM READY.\n  pay the debt. keep the rig. don't think too hard about what you're pulling up.", "delay": NARRATIVE_DELAY},
	]

	_run_sequence()

func _run_sequence() -> void:
	for i in _groups.size():
		var group: Dictionary = _groups[i]

		if _finished:
			return

		if i > 0:
			_append_text("\n\n")
		await _typewrite(group.lines)

		if not is_instance_valid(self) or _finished:
			return
		await get_tree().create_timer(group.delay).timeout
		if not is_instance_valid(self):
			return

	if not _finished:
		_show_prompt()

func _show_prompt() -> void:
	_waiting_for_key = true
	_append_text("\n\n")
	_append_text("[ PRESS ANY KEY TO BEGIN ]")
	_blink_prompt()

func _blink_prompt() -> void:
	while _waiting_for_key and is_instance_valid(self):
		await get_tree().create_timer(0.6).timeout
		if not _waiting_for_key or not is_instance_valid(self):
			return
		output_label.visible_characters = output_label.text.length() - 26
		await get_tree().create_timer(0.4).timeout
		if not _waiting_for_key or not is_instance_valid(self):
			return
		output_label.visible_characters = -1

func _skip_to_end() -> void:
	_finished = true
	_clear_render_buffer()
	for i in _groups.size():
		if i > 0:
			_append_text("\n\n")
		_append_text(_groups[i].lines)
	_show_prompt()

func _typewrite(text: String) -> void:
	for ch in text:
		if _finished:
			return
		_append_text(ch)
		var delay := randf_range(0.08, 0.18) if ch == "\n" else randf_range(CHAR_DELAY_MIN, CHAR_DELAY_MAX)
		await get_tree().create_timer(delay).timeout
		if not is_instance_valid(self):
			return

func _estimate_visible_lines() -> int:
	var font := output_label.get_theme_font("normal_font", "RichTextLabel")
	var font_size := output_label.get_theme_font_size("normal_font_size", "RichTextLabel")
	var line_sep := output_label.get_theme_constant("line_separation", "RichTextLabel")
	var line_height := font.get_height(font_size) + float(line_sep)
	return max(8, int(floor(output_label.size.y / max(1.0, line_height))) - 1)

func _append_text(text: String) -> void:
	for ch in text:
		if _render_lines.is_empty():
			_render_lines.append("")
		if ch == "\n":
			_render_lines.append("")
		else:
			_render_lines[_render_lines.size() - 1] += ch
	_trim_render_buffer()
	_render_to_label()

func _trim_render_buffer() -> void:
	while _render_lines.size() > _max_visible_lines:
		_render_lines.remove_at(0)

func _render_to_label() -> void:
	var start: int = max(0, _render_lines.size() - _max_visible_lines)
	output_label.text = "\n".join(_render_lines.slice(start, _render_lines.size()))

func _clear_render_buffer() -> void:
	_render_lines.clear()
	_render_lines.append("")
	_render_to_label()

func _transition_to_game() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(3.0, 3.0, 3.0), 0.04)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/AppShell.tscn")

func _input(event: InputEvent) -> void:
	var accepted := false
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.is_pressed() and not key.is_echo():
			accepted = key.unicode > 0 or key.physical_keycode in [KEY_ENTER, KEY_ESCAPE]
	elif event is InputEventJoypadButton:
		accepted = (event as InputEventJoypadButton).is_pressed()
	elif event is InputEventMouseButton:
		accepted = (event as InputEventMouseButton).is_pressed()
	elif event is InputEventScreenTouch:
		accepted = (event as InputEventScreenTouch).is_pressed()
	if not accepted:
		return
	if _waiting_for_key:
		_transition_to_game()
	elif not _finished:
		_skip_to_end()
