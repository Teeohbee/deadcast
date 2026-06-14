# tests/test_tension_gauge.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/TensionGauge.tscn")

func before_each() -> void:
	GameState.rod_damaged = false

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_title_is_tension_gauge() -> void:
	assert_eq(_make().title, "tension_gauge")

func test_ok_state_is_green() -> void:
	assert_eq(_make().gauge_state(false).color, DeckStyle.GREEN)

func test_damaged_state_is_red() -> void:
	assert_eq(_make().gauge_state(true).color, DeckStyle.RED)

func test_damaged_state_drives_load_past_redline() -> void:
	assert_gt(_make().gauge_state(true).load, 0.85)

func test_refresh_damaged_tints_meter_red() -> void:
	var p := _make()
	GameState.rod_damaged = true
	p.refresh()
	assert_eq(p._meter.fill_color, DeckStyle.RED)
	assert_almost_eq(p._meter.target, 0.96, 0.001)

func test_meter_has_drawable_size() -> void:
	var p := _make()
	await get_tree().process_frame
	await get_tree().process_frame
	# Regression: the meter must be full-width and 22px tall so BarMeter._draw
	# actually paints (a zero-size meter renders nothing).
	assert_gt(p._meter.size.x, 0.0, "meter should span the panel width")
	assert_almost_eq(p._meter.size.y, 22.0, 0.001)
