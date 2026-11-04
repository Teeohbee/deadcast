extends GutTest

const BOOT := preload("res://scenes/boot/BootSequence.tscn")

func _instantiate_boot() -> Control:
	var boot := BOOT.instantiate()
	add_child_autofree(boot)
	return boot

func test_crt_overlay_exists() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	assert_not_null(boot.get_node("CRTOverlay"))

func test_crt_disabled_zeroes_scan_alpha() -> void:
	Settings.crt_enabled = false
	var boot := _instantiate_boot()
	await get_tree().process_frame
	var overlay := boot.get_node("CRTOverlay") as ColorRect
	assert_eq(overlay.material.get_shader_parameter("scan_alpha"), 0.0)
	Settings.crt_enabled = true

func test_crt_enabled_keeps_shader_default_scan_alpha() -> void:
	Settings.crt_enabled = true
	var boot := _instantiate_boot()
	await get_tree().process_frame
	var overlay := boot.get_node("CRTOverlay") as ColorRect
	assert_null(overlay.material.get_shader_parameter("scan_alpha"))

func test_rollup_keeps_recent_lines_visible() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	boot._finished = true
	boot._max_visible_lines = 3
	boot._clear_render_buffer()
	boot._append_text("line_a\nline_b\nline_c\nline_d")
	assert_eq(boot.output_label.text.find("line_a"), -1)
	assert_true(boot.output_label.text.find("line_d") != -1)

func test_mouse_click_skips_boot_sequence() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	boot._finished = false
	boot._waiting_for_key = false

	var click := InputEventMouseButton.new()
	click.pressed = true
	boot._input(click)

	assert_true(boot._finished)

func test_screen_touch_skips_boot_sequence() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	boot._finished = false
	boot._waiting_for_key = false

	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	boot._input(touch)

	assert_true(boot._finished)

func test_boot_points_a_new_operator_at_the_manual() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	boot._finished = true
	var last_group: String = boot._groups[boot._groups.size() - 1].lines
	assert_string_contains(last_group, "manual")
	assert_string_contains(last_group, "BUNK")
