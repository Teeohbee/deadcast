# tests/test_freezer_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/FreezerPanel.tscn")

func before_each() -> void:
	GameState.credits = 0
	GameState.freezer_base = 0
	GameState.freezer_runs = 0

func _make_panel() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_empty_shows_vacant() -> void:
	var p := _make_panel()
	assert_true(p._vacant.visible)
	assert_false(p._strip.visible)
	assert_false(p._sell_btn.visible)

func test_stored_shows_strip_and_sell() -> void:
	GameState.freezer_base = 1400
	var p := _make_panel()
	assert_false(p._vacant.visible)
	assert_true(p._strip.visible)
	assert_true(p._sell_btn.visible)
	assert_string_contains(p._value_label.text, "1,400")

func test_chip_fresh_at_zero_runs() -> void:
	GameState.freezer_base = 500
	var p := _make_panel()
	assert_eq(p.spoil_chip_text(), "FRESH")

func test_chip_counts_down() -> void:
	GameState.freezer_base = 500
	GameState.freezer_runs = 1
	var p := _make_panel()
	assert_eq(p.spoil_chip_text(), "SPOILS IN 2 RUNS")

func test_chip_singular_run() -> void:
	GameState.freezer_base = 500
	GameState.freezer_runs = 2
	var p := _make_panel()
	assert_eq(p.spoil_chip_text(), "SPOILS IN 1 RUN")

func test_stored_count_uses_body_tier() -> void:
	GameState.freezer_base = 1200
	var p := _make_panel()
	assert_eq(p._count_label.get_theme_font_size("font_size"), DeckStyle.SIZE_BODY)

func test_sell_credits_and_clears() -> void:
	GameState.freezer_base = 1400
	GameState.freezer_runs = 2
	var p := _make_panel()
	p._on_sell()
	assert_eq(GameState.credits, 1400)
	assert_eq(GameState.freezer_base, 0)
	assert_eq(GameState.freezer_runs, 0)
	assert_true(p._vacant.visible)

func test_focus_targets_is_sell_button() -> void:
	GameState.freezer_base = 500
	var p := _make_panel()
	assert_eq(p.focus_targets(), [p._sell_btn])
