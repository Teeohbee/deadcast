# tests/test_vendors_layout.gd
extends GutTest

const SCREEN := preload("res://scenes/barge_hub/VendorsLayout.tscn")

func before_each() -> void:
	GameState.credits = 50000
	GameState.pressure_level = 0

func after_each() -> void:
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

func test_reveal_in_same_frame_as_ready_builds_stock_once() -> void:
	# UIController adds a screen and calls on_screen_shown in the same frame,
	# so _ready's build and the reveal's build overlap.
	var s := _make()
	s.on_screen_shown()
	await get_tree().process_frame
	await get_tree().process_frame
	var rod_headers := 0
	for child in s.stock_container.get_children():
		if child is Label and not child.is_queued_for_deletion() and child.text.begins_with("── rods"):
			rod_headers += 1
	assert_eq(rod_headers, 1, "stock should be built exactly once")

# --- axiom pressure (shop economy plan, PR B1) ---

func _stock_text(s: Node) -> String:
	var text := ""
	for child in s.stock_container.get_children():
		if not child.is_queued_for_deletion() and (child is Button or child is Label):
			text += child.text + "\n"
	return text

func test_prices_are_base_without_pressure() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(_stock_text(s), "2500cr")

func test_pressure_two_marks_prices_up_a_fifth() -> void:
	GameState.pressure_level = 2
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(_stock_text(s), "3000cr (+20%)")

func test_pressure_three_sells_under_the_counter() -> void:
	GameState.pressure_level = 3
	var s := _make()
	await get_tree().process_frame
	var text := _stock_text(s)
	assert_string_contains(text, "3750cr (+50%)")
	assert_string_contains(text, "under the counter")

func test_buying_charges_the_marked_up_price() -> void:
	GameState.pressure_level = 2
	GameState.credits = 10000
	var lure_count: int = GameState.lure_inventory.get("shock_lure", 0)
	var s := _make()
	await get_tree().process_frame
	for child in s.stock_container.get_children():
		if child is Button and child.text.begins_with("shock lure"):
			child.pressed.emit()
			break
	assert_eq(GameState.credits, 10000 - 480)
	GameState.lure_inventory["shock_lure"] = lure_count

func test_rods_show_their_trait() -> void:
	var s := _make()
	await get_tree().process_frame
	var text := _stock_text(s)
	assert_string_contains(text, "monocarbon rig — 100T cap · BRAKE")
	assert_string_contains(text, "ghost line — 110T cap · QUIET")
