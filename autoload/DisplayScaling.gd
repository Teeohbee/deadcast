# autoload/DisplayScaling.gd
# One build has to look right on two screens: the Steam Deck (1280x800, 16:10)
# and the Steam Machine on a 4K 16:9 TV.
#
# Exported builds start fullscreen, so the window is the screen's real size and
# canvas_items stretch redraws the terminal text crisply at that size. Editor
# runs stay windowed.
#
# Full-resolution 3D at 4K is about 8x the Deck's pixels, which the
# Compatibility renderer won't keep smooth, so the 3D (the skyline title) is
# drawn at no more than 1440 lines and scaled up. Text and UI are 2D and are
# not affected.
extends Node

const MAXIMUM_3D_RENDER_HEIGHT := 1440

func _ready() -> void:
	if _is_exported_desktop_build():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_viewport().size_changed.connect(_apply_3d_render_scale)
	_apply_3d_render_scale()

# The fraction of the window's resolution to draw 3D at: full resolution up to
# MAXIMUM_3D_RENDER_HEIGHT lines, scaled down to that height above it.
static func render_scale_3d_for_window_height(window_height: int) -> float:
	if window_height <= MAXIMUM_3D_RENDER_HEIGHT:
		return 1.0
	return float(MAXIMUM_3D_RENDER_HEIGHT) / float(window_height)

func _apply_3d_render_scale() -> void:
	var root_viewport := get_viewport()
	var window_height := DisplayServer.window_get_size().y
	root_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root_viewport.scaling_3d_scale = render_scale_3d_for_window_height(window_height)

func _is_exported_desktop_build() -> bool:
	return OS.has_feature("template") and not OS.has_feature("web")
