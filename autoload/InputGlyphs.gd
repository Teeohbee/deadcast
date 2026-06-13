# autoload/InputGlyphs.gd
# Diegetic, device-aware input prompts. Glyphs are rendered as the terminal OS's
# own bracket keycaps (e.g. [A], [L1]) so they read as part of the fiction.
#
# navigate tokens use ASCII fallbacks ([+] and [UP/DN]) because IBM Plex Mono
# Regular (the deck font) does not cover U+271A (✚), U+25B2 (▲), or U+25BC (▼).
extends Node

signal device_changed(mode: int)

enum Mode { KEY, PAD }

const _GLYPHS := {
	"accept":   {Mode.PAD: "[A]",     Mode.KEY: "[ENTER]"},
	"cancel":   {Mode.PAD: "[B]",     Mode.KEY: "[ESC]"},
	"prev":     {Mode.PAD: "[L1]",    Mode.KEY: "[Q]"},
	"next":     {Mode.PAD: "[R1]",    Mode.KEY: "[E]"},
	"navigate": {Mode.PAD: "[+]",     Mode.KEY: "[UP/DN]"},
	"cycle_lure": {Mode.PAD: "[X]",   Mode.KEY: "[TAB]"},
}

var mode: int = Mode.KEY

func _input(event: InputEvent) -> void:
	update_mode_from_event(event)

func update_mode_from_event(event: InputEvent) -> void:
	var new_mode := mode
	if event is InputEventJoypadButton:
		new_mode = Mode.PAD
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) >= 0.5:
			new_mode = Mode.PAD
	elif event is InputEventKey or event is InputEventMouseButton:
		new_mode = Mode.KEY
	if new_mode != mode:
		mode = new_mode
		device_changed.emit(mode)

func glyph(action: String) -> String:
	return _GLYPHS.get(action, {}).get(mode, "")
