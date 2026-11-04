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
func _all_boot_lines(boot: Control) -> PackedStringArray:
	var lines := PackedStringArray()
	for group in boot._groups:
		lines.append_array((group.lines as String).split("\n"))
	return lines

func test_boot_text_names_no_keyboard_keys() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	boot._finished = true
	var regex := RegEx.new()
	regex.compile("\\[F\\d+\\]")
	for line in _all_boot_lines(boot):
		assert_null(regex.search(line), line)

func test_every_boot_line_fits_the_base_viewport() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	boot._finished = true
	var font: Font = boot.output_label.get_theme_font("normal_font", "RichTextLabel")
	var font_size: int = boot.output_label.get_theme_font_size("normal_font_size", "RichTextLabel")
	var base_width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var usable_width := base_width - 48  # panel margins and border
	for line in _all_boot_lines(boot):
		var width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		assert_lt(width, float(usable_width), line)
