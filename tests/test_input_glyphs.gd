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

func test_icon_is_null_in_key_mode() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY
	assert_null(InputGlyphs.icon("accept"))

func test_every_action_has_a_pad_icon() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	for action in InputGlyphs.actions():
		assert_not_null(InputGlyphs.icon(action), "%s has no pad icon" % action)

func test_icon_for_unknown_action_is_null() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	assert_null(InputGlyphs.icon("nope"))

func test_accept_and_haul_share_the_a_button() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	assert_same(InputGlyphs.icon("accept"), InputGlyphs.icon("haul"))

func test_cursor_hidden_on_a_pad_and_shown_on_a_keyboard() -> void:
	assert_eq(InputGlyphs.mouse_mode_for(InputGlyphs.Mode.PAD), Input.MOUSE_MODE_HIDDEN)
	assert_eq(InputGlyphs.mouse_mode_for(InputGlyphs.Mode.KEY), Input.MOUSE_MODE_VISIBLE)

func test_moving_the_mouse_switches_back_from_pad() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var e := InputEventMouseMotion.new()
	e.relative = Vector2(20, 0)
	InputGlyphs.update_mode_from_event(e)
	assert_eq(InputGlyphs.mode, InputGlyphs.Mode.KEY)

func test_mouse_jitter_does_not_switch_from_pad() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var e := InputEventMouseMotion.new()
	e.relative = Vector2(1, 1)
	InputGlyphs.update_mode_from_event(e)
	assert_eq(InputGlyphs.mode, InputGlyphs.Mode.PAD)

func test_scroll_glyph_per_mode() -> void:
	assert_eq(InputGlyphs.glyph("scroll"), "[PGUP/DN]")
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	assert_not_null(InputGlyphs.icon("scroll"))


func test_menu_and_back_glyphs_per_mode() -> void:
	assert_eq(InputGlyphs.glyph("menu"), "[ESC]")
	assert_eq(InputGlyphs.glyph("cancel"), "[BKSP]")
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	assert_not_null(InputGlyphs.icon("menu"))

# Steam Input layouts can send the pad's A as Return; the haul must still take it.
func test_enter_also_hauls() -> void:
	var enter := InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	assert_true(enter.is_action_pressed("action_reel"))
