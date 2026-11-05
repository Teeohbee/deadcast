# tests/test_input_map.gd
extends GutTest

func _joypad_event(action: String) -> InputEventJoypadButton:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton:
			return e
	return null

func _key_event(action: String) -> InputEventKey:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return e
	return null

func test_tab_next_bound_to_right_shoulder_all_devices() -> void:
	var e := _joypad_event("tab_next")
	assert_not_null(e)
	assert_eq(e.button_index, JOY_BUTTON_RIGHT_SHOULDER)
	assert_eq(e.device, -1)

func test_tab_prev_bound_to_left_shoulder_all_devices() -> void:
	var e := _joypad_event("tab_prev")
	assert_not_null(e)
	assert_eq(e.button_index, JOY_BUTTON_LEFT_SHOULDER)
	assert_eq(e.device, -1)

func test_cycle_lure_bound_to_x_button_all_devices() -> void:
	var e := _joypad_event("cycle_lure")
	assert_not_null(e)
	assert_eq(e.button_index, JOY_BUTTON_X)
	assert_eq(e.device, -1)

func test_cycle_lure_bound_to_tab_key() -> void:
	var e := _key_event("cycle_lure")
	assert_not_null(e)
	assert_eq(e.physical_keycode, KEY_TAB)

# The pad must drive the UI on its own: Godot's defaults leave pad A and B off
# ui_accept and ui_cancel, so the project adds them.
func _has_pad_button(action: String, button: JoyButton) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			return true
	return false

func _has_key(action: String, key: Key) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and ((e as InputEventKey).physical_keycode == key or (e as InputEventKey).keycode == key):
			return true
	return false

func test_pad_a_accepts() -> void:
	assert_true(_has_pad_button("ui_accept", JOY_BUTTON_A))

func test_keyboard_still_accepts() -> void:
	assert_true(_has_key("ui_accept", KEY_ENTER))
	assert_true(_has_key("ui_accept", KEY_KP_ENTER))
	assert_true(_has_key("ui_accept", KEY_SPACE))

func test_pad_b_and_escape_cancel() -> void:
	assert_true(_has_pad_button("ui_cancel", JOY_BUTTON_B))
	assert_true(_has_key("ui_cancel", KEY_ESCAPE))

func test_left_stick_and_dpad_navigate() -> void:
	assert_true(_has_pad_button("ui_up", JOY_BUTTON_DPAD_UP))
	var has_stick := false
	for e in InputMap.action_get_events("ui_up"):
		has_stick = has_stick or e is InputEventJoypadMotion
	assert_true(has_stick)

func test_unused_dive_bindings_are_gone() -> void:
	assert_false(InputMap.has_action("action_slack"))
	assert_false(InputMap.has_action("action_dive"))

func test_right_stick_and_page_keys_scroll() -> void:
	var stick := false
	for e in InputMap.action_get_events("scroll_down"):
		stick = stick or (e is InputEventJoypadMotion and (e as InputEventJoypadMotion).axis == JOY_AXIS_RIGHT_Y)
	assert_true(stick)
	assert_true(_has_key("scroll_down", KEY_PAGEDOWN))
	assert_true(_has_key("scroll_up", KEY_PAGEUP))
