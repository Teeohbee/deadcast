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

func test_refresh_damaged_tints_wave_red() -> void:
	var p := _make()
	GameState.rod_damaged = true
	p.refresh()
	assert_eq(p._wave.line_color, DeckStyle.RED)
