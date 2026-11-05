# autoload/InputGlyphs.gd
# Diegetic, device-aware input prompts. On a keyboard, glyphs are the terminal
# OS's own bracket keycaps (e.g. [ENTER], [Q]). On a pad, icon() hands back a
# Steam Deck button texture (Kenney, CC0) that callers tint to the deck palette;
# glyph() still returns the bracket text as the fallback.
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
	"haul":     {Mode.PAD: "[A]",     Mode.KEY: "[SPACE]"},
}

# Pad icons, by the Steam Deck file name under _ICON_DIR.
const _ICON_DIR := "res://resources/glyphs/steam/steamdeck_%s.svg"
const _ICONS := {
	"accept":     "button_a",
	"cancel":     "button_b",
	"prev":       "button_l1",
	"next":       "button_r1",
	"navigate":   "dpad_vertical",
	"cycle_lure": "button_x",
	"haul":       "button_a",
}

const MOUSE_WAKE_PX := 8.0

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
	elif event is InputEventMouseMotion:
		# A deliberate move, not a bumped desk, brings the cursor back.
		if (event as InputEventMouseMotion).relative.length() >= MOUSE_WAKE_PX:
			new_mode = Mode.KEY
	if new_mode != mode:
		mode = new_mode
		Input.mouse_mode = mouse_mode_for(mode)
		device_changed.emit(mode)

# The cursor is noise on a pad, so it hides until the mouse moves again.
static func mouse_mode_for(p_mode: int) -> Input.MouseMode:
	return Input.MOUSE_MODE_HIDDEN if p_mode == Mode.PAD else Input.MOUSE_MODE_VISIBLE

func glyph(action: String) -> String:
	return _GLYPHS.get(action, {}).get(mode, "")

# The pad button texture for an action, or null on a keyboard (use glyph()).
func icon(action: String) -> Texture2D:
	if mode != Mode.PAD or not _ICONS.has(action):
		return null
	return load(_ICON_DIR % _ICONS[action]) as Texture2D

func actions() -> Array:
	return _GLYPHS.keys()
