# tests/test_display_settings.gd
# The Steam Machine drives a 4K TV. "viewport" stretch renders at 1280x800 and
# upscales the bitmap, which blurs text; canvas_items redraws at full size.
extends GutTest

func test_ui_redraws_at_output_resolution() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")

func test_wider_screens_get_more_room_not_bars() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")
