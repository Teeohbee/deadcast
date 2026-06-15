# tests/test_gamestate_save.gd
extends GutTest

func before_each() -> void:
	GameState.credits = 0
	GameState.pressure_level = 0
	GameState.rod_damaged = false
	GameState.lure_inventory = {
		"basic_hook": GameState.INFINITE_STOCK,
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

func test_load_from_emits_credits_changed() -> void:
	watch_signals(EventBus)
	GameState.credits = 1234
	GameState._save_to("user://save_test.cfg")
	GameState.credits = 0
	GameState._load_from("user://save_test.cfg")
	assert_signal_emitted(EventBus, "credits_changed")
	assert_eq(GameState.credits, 1234)

func test_new_game_starts_with_only_basic_hook() -> void:
	GameState.new_game()
	assert_true(GameState.lure_inventory.has("basic_hook"))
	assert_eq(GameState.lure_inventory.size(), 1)

func test_basic_hook_stock_is_infinite() -> void:
	GameState.new_game()
	assert_eq(GameState.lure_inventory.get("basic_hook"), GameState.INFINITE_STOCK)

func test_has_lure_stock_true_for_infinite() -> void:
	var lure: LureData = load("res://resources/lures/basic_hook.tres")
	GameState.lure_inventory["basic_hook"] = GameState.INFINITE_STOCK
	assert_true(GameState.has_lure_stock(lure))

func test_consume_lure_does_not_decrement_infinite() -> void:
	var lure: LureData = load("res://resources/lures/basic_hook.tres")
	GameState.current_lure = lure
	GameState.lure_inventory["basic_hook"] = GameState.INFINITE_STOCK
	GameState.consume_lure_use()
	assert_eq(GameState.lure_inventory.get("basic_hook"), GameState.INFINITE_STOCK)

func test_save_and_load_selected_zone() -> void:
	GameState.selected_zone = "axiom"
	GameState._save_to("user://save_test.cfg")
	GameState.selected_zone = "district7"
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.selected_zone, "axiom")

func test_save_and_load_depth_upgrade_count() -> void:
	GameState.depth_upgrade_count = 2
	GameState._save_to("user://save_test.cfg")
	GameState.depth_upgrade_count = 0
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.depth_upgrade_count, 2)

func test_depth_upgrade_count_inferred_from_old_save() -> void:
	GameState.max_depth_bonus = 100
	GameState.depth_upgrade_count = 0
	var cfg = ConfigFile.new()
	cfg.set_value("gear", "max_depth_bonus", 100)
	cfg.save("user://save_test.cfg")
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.depth_upgrade_count, 2, "100 bonus / 50 per upgrade = 2")

func test_freezer_base_and_multiplier_round_trip() -> void:
	GameState.freezer_base = 1234
	GameState.freezer_multiplier = 1.35
	GameState.freezer_runs = 2
	GameState._save_to("user://save_test.cfg")
	GameState.freezer_base = 0
	GameState.freezer_multiplier = 1.0
	GameState.freezer_runs = 0
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.freezer_base, 1234)
	assert_almost_eq(GameState.freezer_multiplier, 1.35, 0.001)
	assert_eq(GameState.freezer_runs, 2)

func test_legacy_freezer_value_migrates_to_base() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("freezer", "value", 900)  # legacy key only
	cfg.set_value("freezer", "runs", 1)
	cfg.save("user://save_test.cfg")
	GameState.freezer_base = 0
	GameState.freezer_multiplier = 9.9
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.freezer_base, 900, "legacy value -> base")
	assert_almost_eq(GameState.freezer_multiplier, 1.0, 0.001, "absent multiplier defaults to 1.0")
