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

func test_link_follows_active_vendor() -> void:
	var s := _make()
	await get_tree().process_frame
	s._select("okeke")
	assert_string_contains(s._vendor_link._body.text, "okeke")
