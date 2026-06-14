# tests/test_bar_meter.gd
extends GutTest

func _make() -> BarMeter:
	var m := BarMeter.new()
	add_child_autofree(m)
	return m

func test_default_fill_is_green() -> void:
	assert_eq(_make().fill_color, DeckStyle.GREEN)

func test_zero_lights_no_segments() -> void:
	assert_eq(_make().lit_segments(0.0), 0)

func test_full_lights_all_segments() -> void:
	var m := _make()
	assert_eq(m.lit_segments(1.0), BarMeter.SEGMENTS)

func test_lit_segments_clamps_overflow() -> void:
	var m := _make()
	assert_eq(m.lit_segments(2.5), BarMeter.SEGMENTS)
	assert_eq(m.lit_segments(-1.0), 0)
