# scenes/ui/settings_toggles.gd
# The SOUND and CRT switches, shared by the title screen and the system menu so
# both read and behave the same. Each button flips its setting and relabels
# itself; CRT overlays follow via Settings.crt_changed.
class_name SettingsToggles

static func sound_button() -> Button:
	var button := _toggle()
	var relabel := func() -> void:
		button.text = "[ SOUND: %s ]" % ("OFF" if Settings.audio_muted else "ON")
	button.pressed.connect(func() -> void:
		Audio.toggle_mute()
		relabel.call())
	# Mute also lives on M / Back, so relabel whenever the button is shown.
	button.visibility_changed.connect(relabel)
	relabel.call()
	return button

static func crt_button() -> Button:
	var button := _toggle()
	var relabel := func() -> void:
		button.text = "[ CRT: %s ]" % ("ON" if Settings.crt_enabled else "OFF")
	button.pressed.connect(func() -> void:
		Settings.set_crt_enabled(not Settings.crt_enabled)
		relabel.call())
	button.visibility_changed.connect(relabel)
	relabel.call()
	return button

static func _toggle() -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	DeckStyle.apply_action_button(button, DeckStyle.DIM)
	return button
