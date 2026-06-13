# tests/test_input_glyphs.gd
extends GutTest

func before_each() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY

func test_glyph_returns_key_token_in_key_mode() -> void:
	assert_eq(InputGlyphs.glyph("accept"), "[ENTER]")
	assert_eq(InputGlyphs.glyph("next"), "[E]")

func test_glyph_returns_pad_token_in_pad_mode() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	assert_eq(InputGlyphs.glyph("accept"), "[A]")
	assert_eq(InputGlyphs.glyph("next"), "[R1]")

func test_cycle_lure_glyph_per_mode() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	assert_eq(InputGlyphs.glyph("cycle_lure"), "[X]")
	InputGlyphs.mode = InputGlyphs.Mode.KEY
	assert_eq(InputGlyphs.glyph("cycle_lure"), "[TAB]")

func test_unknown_action_returns_empty() -> void:
	assert_eq(InputGlyphs.glyph("nope"), "")

func test_joypad_event_switches_mode_and_emits() -> void:
	watch_signals(InputGlyphs)
	var e := InputEventJoypadButton.new()
	e.button_index = JOY_BUTTON_A
	e.pressed = true
	InputGlyphs.update_mode_from_event(e)
	assert_eq(InputGlyphs.mode, InputGlyphs.Mode.PAD)
	assert_signal_emitted_with_parameters(InputGlyphs, "device_changed", [InputGlyphs.Mode.PAD])

func test_small_stick_drift_does_not_switch() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_LEFT_X
	e.axis_value = 0.1
	InputGlyphs.update_mode_from_event(e)
	assert_eq(InputGlyphs.mode, InputGlyphs.Mode.KEY)
