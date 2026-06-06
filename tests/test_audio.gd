# tests/test_audio.gd
extends GutTest

func before_each() -> void:
	Audio._hum_active = false
	Audio._target_blend = 0.0
	Audio._hum_blend = 0.0
	Audio._click_active = false
	Audio._click_pos = 0

func test_hum_starts_on_first_screen_changed() -> void:
	Audio._on_screen_changed("deck")
	assert_true(Audio._hum_active)

func test_hum_stays_active_on_subsequent_screen_changed() -> void:
	Audio._on_screen_changed("deck")
	Audio._on_screen_changed("workshop")
	assert_true(Audio._hum_active)

func test_stop_hum_deactivates() -> void:
	Audio._hum_active = true
	Audio.stop_hum()
	assert_false(Audio._hum_active)

func test_dive_state_true_sets_target_blend_1() -> void:
	Audio._on_dive_state_changed(true)
	assert_eq(Audio._target_blend, 1.0)

func test_dive_state_false_sets_target_blend_0() -> void:
	Audio._target_blend = 1.0
	Audio._on_dive_state_changed(false)
	assert_eq(Audio._target_blend, 0.0)

func test_node_added_connects_button_pressed() -> void:
	var btn := Button.new()
	Audio._on_node_added(btn)
	assert_true(btn.pressed.is_connected(Audio.play_click))
	btn.free()

func test_node_added_ignores_non_button() -> void:
	var label := Label.new()
	Audio._on_node_added(label)
	# verifies no crash and no connection attempt
	assert_false(label.has_signal("pressed"))
	label.free()

func test_play_click_activates_click_playing() -> void:
	Audio._click_active = false
	Audio.play_click()
	assert_true(Audio._click_active)

func test_play_click_fills_buffer() -> void:
	Audio.play_click()
	assert_gt(Audio._click_buffer.size(), 0)

func test_play_click_resets_position() -> void:
	Audio._click_pos = 999
	Audio.play_click()
	assert_eq(Audio._click_pos, 0)
