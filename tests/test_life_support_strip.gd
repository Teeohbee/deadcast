# tests/test_life_support_strip.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/LifeSupportStrip.tscn")

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_title_is_life_support() -> void:
	assert_eq(_make().title, "life_support")

func test_wave_is_slow_and_sky() -> void:
	var p := _make()
	assert_eq(p._wave.line_color, DeckStyle.SKY)
	assert_true(p._wave.speed < 3.0, "vitals trace should drift slower than the sonar")

func test_readout_mentions_resting() -> void:
	var p := _make()
	assert_string_contains(p._readout.text, "resting")
