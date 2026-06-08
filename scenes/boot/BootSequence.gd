# scenes/boot/BootSequence.gd
extends Control

const SYSTEM_DELAY := 0.3
const NARRATIVE_DELAY := 0.5

@onready var output_label: RichTextLabel = $MarginContainer/OutputLabel

var _groups: Array[Dictionary] = []
var _finished := false
var _waiting_for_key := false

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_background(self)
	output_label.add_theme_color_override("default_color", UIStyle.COL_DIM)

	_groups = [
		{"lines": "DEADCAST_OS v2.1.4\nBOOT SEQUENCE INITIATED...", "delay": SYSTEM_DELAY, "cue": "power_on"},
		{"lines": "> SCANNING HARDWARE...\n  VESSEL:      THE MERIDIAN (deep-sea data trawler, class IV)\n  MOORING:     DISTRICT 7 DOCKS, THE SUMP\n  OPERATOR:    [NOT REGISTERED]\n  ROD SYSTEM:  SCRAP ROD Mk.I (salvage-grade, low depth)\n  HULL STATUS: pressure-rated to 200m. last survey: OVERDUE", "delay": SYSTEM_DELAY, "cue": "scan_blip"},
		{"lines": "> CHECKING NETWORK...\n  ENCRYPTED CHANNEL DETECTED: MARTA VOSS [F5]", "delay": SYSTEM_DELAY, "cue": "scan_blip"},
		{"lines": "  OUTSTANDING DEBT: 80,000cr\n  TERMS: 10,000cr every 5 runs. miss a payment and the terms change.", "delay": SYSTEM_DELAY, "cue": "warning"},
		{"lines": "  VENDOR CHANNEL: OKEKE [F6]", "delay": SYSTEM_DELAY, "cue": ""},
		{"lines": "> LOADING DIVE PROTOCOLS...\n  the sump was a city once. district 7, the exchange,\n  axiom tower. flooded forty years ago. nobody came back\n  for what was left.", "delay": NARRATIVE_DELAY, "cue": "scan_blip"},
		{"lines": "  each dive deploys a trawl line into the ruins.\n  whatever surfaces - data, bio-matter, machines, ghosts -\n  you decide what to do with it.", "delay": NARRATIVE_DELAY, "cue": ""},
		{"lines": "  tension accumulates with every catch. push too hard\n  and the line snaps. lose everything.", "delay": NARRATIVE_DELAY, "cue": ""},
		{"lines": "> SYSTEM READY.\n  pay the debt. keep the rig. don't think too hard\n  about what you're pulling up.", "delay": NARRATIVE_DELAY, "cue": "system_ready"},
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
		output_label.text += group.lines

		if _finished:
			return
		await get_tree().create_timer(group.delay).timeout

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
	if not event.is_pressed() or event.is_echo():
		return
	if _waiting_for_key:
		_transition_to_game()
	elif not _finished:
		_skip_to_end()
