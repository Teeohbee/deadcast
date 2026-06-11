# scenes/boot/BootSequence.gd
extends Control

const SYSTEM_DELAY := 0.5
const NARRATIVE_DELAY := 0.8
const CHAR_DELAY_MIN := 0.010
const CHAR_DELAY_MAX := 0.030

@onready var output_label: RichTextLabel = $MarginContainer/OutputLabel

var _groups: Array[Dictionary] = []
var _finished := false
var _waiting_for_key := false

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_background(self)
	output_label.add_theme_color_override("default_color", UIStyle.COL_COST)

	_groups = [
		{"lines": "DEADCAST_OS %s\nBOOT SEQUENCE INITIATED..." % GameState.OS_VERSION, "delay": SYSTEM_DELAY, "cue": "power_on"},
		{"lines": "> SCANNING HARDWARE...\n  VESSEL:      THE MERIDIAN (deep-sea data trawler, class IV)\n  MOORING:     DISTRICT 7 DOCKS, THE SUMP\n  OPERATOR:    [NOT REGISTERED]\n  ROD SYSTEM:  SCRAP ROD Mk.I (salvage-grade, low depth)\n  HULL STATUS: pressure-rated to 200m. last survey: OVERDUE", "delay": SYSTEM_DELAY, "cue": "scan_blip"},
		{"lines": "> CHECKING NETWORK...\n  ENCRYPTED CHANNEL DETECTED: MARTA VOSS [F5]", "delay": SYSTEM_DELAY, "cue": "scan_blip"},
		{"lines": "  OUTSTANDING DEBT: 80,000cr\n  TERMS: 10,000cr every 5 runs. miss a payment and the terms change.", "delay": SYSTEM_DELAY, "cue": "warning"},
		{"lines": "  VENDOR CHANNEL: OKEKE [F6]", "delay": SYSTEM_DELAY, "cue": ""},
		{"lines": "> LOADING DIVE PROTOCOLS...\n  the sump was a city once. district 7, the exchange, axiom tower.\n  flooded forty years ago. nobody came back for what was left.", "delay": NARRATIVE_DELAY, "cue": "scan_blip"},
		{"lines": "  each dive deploys a trawl line into the ruins. whatever surfaces -\n  data, bio-matter, machines, ghosts - you decide what to do with it.", "delay": NARRATIVE_DELAY, "cue": ""},
		{"lines": "  tension accumulates with every catch. push too hard and the line snaps. lose everything.", "delay": NARRATIVE_DELAY, "cue": ""},
		{"lines": "> SYSTEM READY.\n  pay the debt. keep the rig. don't think too hard about what you're pulling up.", "delay": NARRATIVE_DELAY, "cue": "system_ready"},
	]

	Audio.start_boot_hum()
	_run_sequence()

func _run_sequence() -> void:
	for i in _groups.size():
		var group: Dictionary = _groups[i]

		if _finished:
			return

		if i > 0:
			output_label.text += "\n\n"
		_play_cue(group.cue)
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
	output_label.text += "\n\n"
	output_label.text += "[ PRESS ANY KEY TO BEGIN ]"
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
	output_label.text = ""
	for i in _groups.size():
		if i > 0:
			output_label.text += "\n\n"
		output_label.text += _groups[i].lines
	_show_prompt()

func _typewrite(text: String) -> void:
	for ch in text:
		if _finished:
			return
		output_label.text += ch
		var delay := randf_range(0.08, 0.18) if ch == "\n" else randf_range(CHAR_DELAY_MIN, CHAR_DELAY_MAX)
		await get_tree().create_timer(delay).timeout
		if not is_instance_valid(self):
			return

func _play_cue(cue: String) -> void:
	match cue:
		"power_on": Audio.play_power_on()
		"scan_blip": Audio.play_scan_blip()
		"warning": Audio.play_warning_tone()
		"system_ready": Audio.play_system_ready()

func _transition_to_game() -> void:
	Audio.stop_boot_hum()
	get_tree().change_scene_to_file("res://scenes/AppShell.tscn")

func _unhandled_input(event: InputEvent) -> void:
	var accepted := false
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.is_pressed() and not key.is_echo():
			accepted = key.unicode > 0 or key.physical_keycode in [KEY_ENTER, KEY_ESCAPE]
	elif event is InputEventJoypadButton:
		accepted = (event as InputEventJoypadButton).is_pressed()
	if not accepted:
		return
	if _waiting_for_key:
		_transition_to_game()
	elif not _finished:
		_skip_to_end()
