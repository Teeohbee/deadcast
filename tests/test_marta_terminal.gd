# tests/test_marta_terminal.gd
extends GutTest

const SCREEN := preload("res://scenes/barge_hub/MartaTerminal.tscn")

func before_each() -> void:
	GameState.run_count = 1
	GameState.pressure_level = 4
	GameState.victory = false
	GameState.debt = 80000

func _make() -> Node:
	var s := SCREEN.instantiate()
	add_child_autofree(s)
	return s

func test_screen_instantiates_with_transmission() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_not_null(s._transmission)

func test_transmission_reflects_pressure() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s._transmission._link_label.text, "TRACED")

func test_dialogue_still_renders() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s.dialogue_label.text, "marta")
