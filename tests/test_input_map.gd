# tests/test_input_map.gd
extends GutTest

func _joypad_event(action: String) -> InputEventJoypadButton:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton:
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
