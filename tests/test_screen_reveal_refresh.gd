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
