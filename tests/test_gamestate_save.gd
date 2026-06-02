# tests/test_gamestate_save.gd
extends GutTest

func before_each() -> void:
	GameState.credits = 0
	GameState.pressure_level = 0
	GameState.rod_damaged = false
	GameState.lure_inventory = {
		"basic_hook": 99,
		"shock_lure": 3,
		"decoy_swarm": 2,
		"deep_pulse": 2,
		"ghost_bait": 2,
	}

func after_each() -> void:
	# Clean up any save file created during tests
	DirAccess.remove_absolute("user://save_test.cfg")

func test_save_and_load_credits() -> void:
	GameState.credits = 5000
	GameState._save_to("user://save_test.cfg")
	GameState.credits = 0
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.credits, 5000)

func test_save_and_load_pressure_level() -> void:
	GameState.pressure_level = 3
	GameState._save_to("user://save_test.cfg")
	GameState.pressure_level = 0
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.pressure_level, 3)

func test_load_missing_file_uses_defaults() -> void:
	GameState.credits = 999
	GameState._load_from("user://nonexistent_save.cfg")
	assert_eq(GameState.credits, 999, "Missing file should not change existing state")

func test_save_and_load_lure_inventory() -> void:
	GameState.lure_inventory["shock_lure"] = 7
	GameState._save_to("user://save_test.cfg")
	GameState.lure_inventory["shock_lure"] = 0
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.lure_inventory.get("shock_lure", 0), 7)

func test_save_and_load_rod_damaged() -> void:
	GameState.rod_damaged = true
	GameState._save_to("user://save_test.cfg")
	GameState.rod_damaged = false
	GameState._load_from("user://save_test.cfg")
	assert_true(GameState.rod_damaged)
