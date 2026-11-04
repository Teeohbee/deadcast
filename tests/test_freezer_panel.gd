# tests/test_freezer_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/FreezerPanel.tscn")

func before_each() -> void:
	GameState.credits = 0
	GameState.freezer_base = 0
	GameState.freezer_runs = 0
	GameState.freezer_multiplier = 1.0

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
	GameState.freezer_multiplier = 1.0
	var p := _make_panel()
	assert_false(p._vacant.visible)
	assert_true(p._strip.visible)
	assert_true(p._sell_btn.visible)
	assert_string_contains(p._value_label.text, "1,400")

func test_value_label_reflects_multiplier() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_multiplier = 1.5
	var p := _make_panel()
	assert_string_contains(p._value_label.text, "1,500")

func test_market_chip_hidden_when_empty() -> void:
	var p := _make_panel()
	assert_false(p._market_chip.visible)

func test_market_chip_shown_when_stored() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_multiplier = 1.2
	var p := _make_panel()
	assert_true(p._market_chip.visible)
	assert_string_contains(p._market_chip.text, "1.2")

func test_sell_credits_sale_value_and_clears() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_multiplier = 1.5
	GameState.freezer_runs = 2
	var p := _make_panel()
	p._on_sell()
	assert_eq(GameState.credits, 1500)
	assert_eq(GameState.freezer_base, 0)
	assert_eq(GameState.freezer_runs, 0)
	assert_almost_eq(GameState.freezer_multiplier, 1.0, 0.001)
	assert_true(p._vacant.visible)

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

func test_count_label_shows_stored_base_not_sale() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_multiplier = 1.5
	var p := _make_panel()
	assert_string_contains(p._count_label.text, "1,000")
	assert_string_contains(p._value_label.text, "1,500")

func test_focus_targets_is_sell_button() -> void:
	GameState.freezer_base = 500
	var p := _make_panel()
	assert_eq(p.focus_targets(), [p._sell_btn])

func test_base_and_sale_values_are_labelled_as_different_numbers() -> void:
	GameState.freezer_base = 350
	GameState.freezer_multiplier = 1.32
	var p := _make_panel()
	assert_eq(p._count_label.text, "BASE 350 cr")
	assert_eq(p._value_label.text, "SELLS FOR 462 cr")
