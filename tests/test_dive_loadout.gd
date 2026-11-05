# tests/test_dive_loadout.gd
# Two provision slots chosen on the DECK before the cast; everything loaded can
# be fired during the dive (shop economy plan, PR B5).
extends GutTest

const STATE_BACKUP := "user://dive_loadout_state_backup.cfg"

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.lure_inventory = {"deep_pulse": 1, "splice_kit": 2, "shock_lure": 0}
	GameState.loadout = ["", ""] as Array[String]

func after_each() -> void:
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func test_owned_lures_skip_empty_stock_in_shop_order() -> void:
	assert_eq(GameState.owned_lure_ids(), ["deep_pulse", "splice_kit"] as Array[String])

func test_a_slot_cycles_through_owned_lures_then_empty() -> void:
	GameState.cycle_loadout_slot(0)
	assert_eq(GameState.loadout[0], "deep_pulse")
	GameState.cycle_loadout_slot(0)
	assert_eq(GameState.loadout[0], "splice_kit")
	GameState.cycle_loadout_slot(0)
	assert_eq(GameState.loadout[0], "")

func test_a_slot_skips_what_the_other_slot_holds() -> void:
	GameState.loadout = ["splice_kit", ""] as Array[String]
	GameState.cycle_loadout_slot(1)
	assert_eq(GameState.loadout[1], "deep_pulse")
	GameState.cycle_loadout_slot(1)
	assert_eq(GameState.loadout[1], "", "splice kit is already in slot 1")

func test_loaded_lures_are_found_by_effect() -> void:
	GameState.loadout = ["splice_kit", "deep_pulse"] as Array[String]
	assert_eq(GameState.loaded_lure_id(LureData.LureEffect.SPLICE), "splice_kit")
	assert_eq(GameState.loaded_lure_id(LureData.LureEffect.DEEP_PULSE), "deep_pulse")
	assert_eq(GameState.loaded_lure_id(LureData.LureEffect.DECOY), "")

func test_a_loaded_lure_with_no_stock_is_not_ready() -> void:
	GameState.loadout = ["shock_lure", ""] as Array[String]
	assert_eq(GameState.loaded_lure_id(LureData.LureEffect.SHOCK), "")

func test_firing_consumes_stock_and_says_so() -> void:
	watch_signals(EventBus)
	GameState.consume_lure("splice_kit")
	assert_eq(GameState.lure_inventory["splice_kit"], 1)
	assert_signal_emitted_with_parameters(EventBus, "lure_stock_changed", ["splice_kit", 1])

func test_the_loadout_label_lists_both_slots() -> void:
	assert_eq(GameState.loadout_label(), "—")
	GameState.loadout = ["splice_kit", "deep_pulse"] as Array[String]
	assert_eq(GameState.loadout_label(), "splice_kit x2 · deep_pulse x1")

func test_roles_read_as_words() -> void:
	assert_eq(load("res://resources/lures/deep_pulse.tres").role_label(), "SCOUT")
	assert_eq(load("res://resources/lures/decoy_swarm.tres").role_label(), "ESCAPE")
	assert_eq(load("res://resources/lures/shock_lure.tres").role_label(), "FIGHT")
	assert_eq(load("res://resources/lures/splice_kit.tres").role_label(), "SURVIVE")
	assert_eq(load("res://resources/lures/ghost_bait.tres").role_label(), "BAIT")

# --- saves ---

func test_the_loadout_survives_a_save() -> void:
	GameState.loadout = ["splice_kit", "deep_pulse"] as Array[String]
	var path := "user://dive_loadout_roundtrip.cfg"
	GameState._save_to(path)
	GameState.loadout = ["", ""] as Array[String]
	GameState._load_from(path)
	DirAccess.remove_absolute(path)
	assert_eq(GameState.loadout, ["splice_kit", "deep_pulse"] as Array[String])

func test_an_old_equipped_lure_moves_into_slot_one_and_the_hook_goes() -> void:
	var path := "user://dive_loadout_legacy.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("gear", "current_lure_path", "res://resources/lures/decoy_swarm.tres")
	cfg.set_value("gear", "lure_inventory", {"basic_hook": -1, "decoy_swarm": 2})
	cfg.save(path)
	GameState._load_from(path)
	DirAccess.remove_absolute(path)
	assert_eq(GameState.loadout, ["decoy_swarm", ""] as Array[String])
	assert_false(GameState.lure_inventory.has("basic_hook"))

func test_an_old_basic_hook_save_starts_empty() -> void:
	var path := "user://dive_loadout_legacy.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("gear", "current_lure_path", "res://resources/lures/basic_hook.tres")
	cfg.save(path)
	GameState._load_from(path)
	DirAccess.remove_absolute(path)
	assert_eq(GameState.loadout, ["", ""] as Array[String])

func test_a_new_game_starts_with_empty_slots_and_no_stock() -> void:
	GameState.new_game()
	assert_eq(GameState.loadout, ["", ""] as Array[String])
	assert_eq(GameState.lure_inventory, {})
