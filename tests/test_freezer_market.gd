# tests/test_freezer_market.gd
extends GutTest

func before_each() -> void:
	GameState.credits = 0
	GameState.freezer_base = 0
	GameState.freezer_runs = 0
	GameState.freezer_multiplier = 1.0

func test_sale_value_applies_multiplier() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_multiplier = 1.2
	assert_eq(GameState.freezer_sale_value(), 1200)

func test_sale_value_rounds() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_multiplier = 0.755
	assert_eq(GameState.freezer_sale_value(), 755)

func test_sale_value_empty_is_zero() -> void:
	GameState.freezer_base = 0
	GameState.freezer_multiplier = 1.5
	assert_eq(GameState.freezer_sale_value(), 0)
