# tests/test_screen_reveal_refresh.gd
extends GutTest

const DECK := preload("res://scenes/barge_hub/BargeHub.tscn")

func before_each() -> void:
	GameState.credits = 0
	GameState.debt = 0
	GameState.freezer_value = 0
	GameState.freezer_runs = 0
	GameState.pressure_level = 0
	GameState.selected_zone = "district7"

func _make(scene: PackedScene) -> Node:
	var s := scene.instantiate()
	add_child_autofree(s)
	return s

func test_deck_reveal_refreshes_freezer() -> void:
	var deck := _make(DECK)
	await get_tree().process_frame
	GameState.freezer_value = 1400
	deck.on_screen_shown()
	assert_string_contains(deck._freezer_panel._value_label.text, "1,400")

const WORKSHOP := preload("res://scenes/barge_hub/Workshop.tscn")

func test_workshop_reveal_reflects_rod_damage() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	GameState.rod_damaged = false
	var w := _make(WORKSHOP)
	await get_tree().process_frame
	GameState.rod_damaged = true
	w.on_screen_shown()
	assert_string_contains(w.rod_label.text, "[damaged]")

const VENDORS := preload("res://scenes/barge_hub/VendorsLayout.tscn")

func _has_enabled_stock(v: Node) -> bool:
	for c in v.stock_container.get_children():
		if c is Button and not (c as Button).disabled:
			return true
	return false

func test_vendors_reveal_rebuilds_stock_for_credits() -> void:
	GameState.credits = 0
	GameState.lure_inventory = {}
	var v := _make(VENDORS)
	await get_tree().process_frame
	await get_tree().process_frame
	GameState.credits = 999999
	v.on_screen_shown()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(_has_enabled_stock(v), "raising credits should enable at least one item")
