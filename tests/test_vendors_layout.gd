# tests/test_vendors_layout.gd
extends GutTest

const SCREEN := preload("res://scenes/barge_hub/VendorsLayout.tscn")

func before_each() -> void:
	GameState.credits = 50000
	GameState.pressure_level = 0

func _make() -> Node:
	var s := SCREEN.instantiate()
	add_child_autofree(s)
	return s

func test_screen_has_ticker_and_link() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_not_null(s._ticker)
	assert_not_null(s._vendor_link)

func test_link_shows_okeke() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s._vendor_link._body.text, "okeke")

func test_okeke_sells_rods_and_lures() -> void:
	var s := _make()
	await get_tree().process_frame
	await get_tree().process_frame
	var stock := ""
	for child in s.stock_container.get_children():
		if child is Button:
			stock += child.text + "\n"
	assert_string_contains(stock, "scrap rod")
	assert_string_contains(stock, "shock lure")

func test_focus_lands_on_buyable_item_on_load() -> void:
	var s := _make()
	await get_tree().process_frame
	await get_tree().process_frame
	var focused := s.get_viewport().gui_get_focus_owner()
	assert_true(focused is Button, "a stock button should hold focus on load")
	assert_false((focused as Button).disabled, "focused item should be buyable")
