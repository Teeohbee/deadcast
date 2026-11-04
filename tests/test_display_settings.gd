# tests/test_display_settings.gd
# The Steam Machine drives a 4K TV. "viewport" stretch renders at 1280x800 and
# upscales the bitmap, which blurs text; canvas_items redraws at full size.
extends GutTest

func test_ui_redraws_at_output_resolution() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")

func test_wider_screens_get_more_room_not_bars() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")

func test_steam_deck_draws_3d_at_full_resolution() -> void:
	assert_eq(DisplayScaling.render_scale_3d_for_window_height(800), 1.0)

func test_1440p_draws_3d_at_full_resolution() -> void:
	assert_eq(DisplayScaling.render_scale_3d_for_window_height(1440), 1.0)

func test_4k_tv_draws_3d_at_1440_lines() -> void:
	assert_almost_eq(DisplayScaling.render_scale_3d_for_window_height(2160), 1440.0 / 2160.0, 0.0001)

func test_3d_edges_get_2x_msaa() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"), Viewport.MSAA_2X)
