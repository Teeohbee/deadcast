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
