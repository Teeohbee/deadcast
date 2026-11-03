extends GutTest

var _saved_lure: LureData
var _saved_inventory: Dictionary

func before_each() -> void:
	_saved_lure = GameState.current_lure
	_saved_inventory = GameState.lure_inventory.duplicate()

func after_each() -> void:
	GameState.current_lure = _saved_lure
	GameState.lure_inventory = _saved_inventory

func test_event_bus_has_new_signals() -> void:
	assert_true(EventBus.has_signal("haul_changed"))
	assert_true(EventBus.has_signal("slot_revealed"))
	assert_true(EventBus.has_signal("lure_stock_changed"))

func test_consume_lure_use_emits_stock_changed() -> void:
	GameState.current_lure = load("res://resources/lures/shock_lure.tres")
	GameState.lure_inventory["shock_lure"] = 2
	watch_signals(EventBus)
	GameState.consume_lure_use()
	assert_signal_emitted_with_parameters(EventBus, "lure_stock_changed", ["shock_lure", 1])

func test_consume_infinite_lure_does_not_emit() -> void:
	GameState.current_lure = load("res://resources/lures/basic_hook.tres")
	GameState.lure_inventory["basic_hook"] = GameState.INFINITE_STOCK
	watch_signals(EventBus)
	GameState.consume_lure_use()
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
