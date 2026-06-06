# tests/test_ghost_memory.gd
extends GutTest

func before_each() -> void:
	GameState.encountered_entities = {}

func after_each() -> void:
	DirAccess.remove_absolute("user://save_ghost_test.cfg")

func test_set_entity_encountered_increments_counter() -> void:
	GameState.set_entity_encountered("solace7")
	assert_eq(GameState.encountered_entities.get("solace7", 0), 1)

func test_set_entity_encountered_increments_on_second_call() -> void:
	GameState.set_entity_encountered("solace7")
	GameState.set_entity_encountered("solace7")
	assert_eq(GameState.encountered_entities.get("solace7", 0), 2)

func test_set_entity_encountered_tracks_multiple_entities() -> void:
	GameState.set_entity_encountered("solace7")
	GameState.set_entity_encountered("mariana")
	assert_eq(GameState.encountered_entities.get("solace7", 0), 1)
	assert_eq(GameState.encountered_entities.get("mariana", 0), 1)

func test_encountered_entities_persists_across_save_load() -> void:
	GameState.set_entity_encountered("solace7")
	GameState.set_entity_encountered("solace7")
	GameState._save_to("user://save_ghost_test.cfg")
	GameState.encountered_entities = {}
	GameState._load_from("user://save_ghost_test.cfg")
	assert_eq(GameState.encountered_entities.get("solace7", 0), 2)

func test_new_game_clears_encountered_entities() -> void:
	GameState.encountered_entities = {"solace7": 3, "mariana": 1}
	GameState.new_game()
	assert_eq(GameState.encountered_entities.size(), 0)

# --- CatchPool entity substitution ---

func test_generate_column_returns_base_catch_when_no_encounter() -> void:
	# Build a minimal CatchPool scenario using real zone data
	# When entity not encountered, base catch should be returned
	GameState.encountered_entities = {}
	var pool = CatchPool
	# Verify the substitution helper directly
	var base_catch: CatchData = CatchData.new()
	base_catch.entity_id = "solace7"
	var returning: CatchData = CatchData.new()
	returning.entity_id = "solace7"
	returning.returning_variants = []
	base_catch.returning_variants = [returning]
	var result = pool._apply_entity_substitution(base_catch)
	assert_eq(result, base_catch, "No encounter → base catch returned")

func test_apply_entity_substitution_returns_variant_on_first_encounter() -> void:
	GameState.encountered_entities = {"solace7": 1}
	var base_catch: CatchData = CatchData.new()
	base_catch.entity_id = "solace7"
	var returning: CatchData = CatchData.new()
	returning.entity_id = "solace7"
	returning.returning_variants = []
	base_catch.returning_variants = [returning]
	var result = CatchPool._apply_entity_substitution(base_catch)
	assert_eq(result, returning, "count=1 → returning_variants[0]")

func test_apply_entity_substitution_clamps_to_last_variant() -> void:
	GameState.encountered_entities = {"solace7": 99}
	var base_catch: CatchData = CatchData.new()
	base_catch.entity_id = "solace7"
	var returning: CatchData = CatchData.new()
	returning.entity_id = "solace7"
	returning.returning_variants = []
	base_catch.returning_variants = [returning]
	var result = CatchPool._apply_entity_substitution(base_catch)
	assert_eq(result, returning, "count exceeds variants → last variant")

func test_apply_entity_substitution_ignores_catch_with_no_entity_id() -> void:
	GameState.encountered_entities = {"solace7": 5}
	var base_catch: CatchData = CatchData.new()
	base_catch.entity_id = ""
	var result = CatchPool._apply_entity_substitution(base_catch)
	assert_eq(result, base_catch, "empty entity_id → pass through unchanged")
