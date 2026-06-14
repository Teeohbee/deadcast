# tests/test_market_ticker.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/MarketTicker.tscn")

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_title_is_market_ticker() -> void:
	assert_eq(_make().title, "market_ticker")

func test_ticker_text_lists_known_goods() -> void:
	var t: String = _make().ticker_text()
	assert_string_contains(t, "shock_lure")
	assert_string_contains(t, "ghost_line")

func test_ticker_text_has_credit_figures() -> void:
	assert_string_contains(_make().ticker_text(), "cr")
