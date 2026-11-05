extends GutTest

var _saved_loadout: Array[String]
var _saved_inventory: Dictionary

func before_each() -> void:
	_saved_loadout = GameState.loadout.duplicate()
	_saved_inventory = GameState.lure_inventory.duplicate()

func after_each() -> void:
	GameState.loadout = _saved_loadout
	GameState.lure_inventory = _saved_inventory

func test_event_bus_has_new_signals() -> void:
	assert_true(EventBus.has_signal("haul_changed"))
	assert_true(EventBus.has_signal("slot_revealed"))
	assert_true(EventBus.has_signal("lure_stock_changed"))

func test_consume_lure_emits_stock_changed() -> void:
	GameState.lure_inventory["shock_lure"] = 2
	watch_signals(EventBus)
	GameState.consume_lure("shock_lure")
	assert_signal_emitted_with_parameters(EventBus, "lure_stock_changed", ["shock_lure", 1])

func test_consume_an_empty_lure_does_not_emit() -> void:
	GameState.lure_inventory["shock_lure"] = 0
	watch_signals(EventBus)
	GameState.consume_lure("shock_lure")
	assert_signal_not_emitted(EventBus, "lure_stock_changed")

func test_starting_a_dive_signals_the_cast_and_first_contact() -> void:
	GameState.selected_zone = "district7"
	watch_signals(EventBus)
	var dive: Node = load("res://scenes/dive_run/DiveRun.tscn").instantiate()
	add_child_autofree(dive)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_signal_emitted(EventBus, "dive_cast")
	assert_signal_emitted(EventBus, "contact_presented")

func _start_dive_with_scrap_rod(damaged: bool) -> Node:
	GameState.selected_zone = "district7"
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	GameState.rod_damaged = damaged
	var dive: Node = load("res://scenes/dive_run/DiveRun.tscn").instantiate()
	add_child_autofree(dive)
	await get_tree().process_frame
	return dive

func test_dive_rail_shows_tension_against_the_rod_cap() -> void:
	var saved_rod := GameState.current_rod
	var saved_damaged := GameState.rod_damaged
	var dive: Node = await _start_dive_with_scrap_rod(false)
	assert_eq(dive.line_tension._readout.text, "TENSION 0 / 80")
	GameState.current_rod = saved_rod
	GameState.rod_damaged = saved_damaged

func test_dive_rail_shows_the_reduced_cap_on_a_damaged_rod() -> void:
	var saved_rod := GameState.current_rod
	var saved_damaged := GameState.rod_damaged
	var dive: Node = await _start_dive_with_scrap_rod(true)
	assert_eq(dive.line_tension._readout.text, "TENSION 0 / 55")
	GameState.current_rod = saved_rod
	GameState.rod_damaged = saved_damaged
