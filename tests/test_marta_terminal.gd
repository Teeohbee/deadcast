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

# --- transmission history ---

func test_no_beats_before_first_run() -> void:
	var s := _make()
	assert_eq(s.beat_history(0).size(), 0)

func test_beat_history_is_newest_first() -> void:
	var s := _make()
	var history: Array = s.beat_history(8)
	assert_eq(history.size(), 5)
	assert_string_contains(history[0], "transponder")
	assert_string_contains(history[4], "80,000")

func test_history_panel_lists_earlier_beats_not_the_current_one() -> void:
	GameState.run_count = 8
	var s := _make()
	await get_tree().process_frame
	var text: String = s._history_label.text
	assert_string_contains(text, "shard")
	assert_string_contains(text, "80,000")
	assert_false(text.contains("transponder"), "current beat belongs in the marta panel")

func test_history_panel_says_when_empty() -> void:
	GameState.run_count = 1
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s._history_label.text, "no earlier transmissions")
