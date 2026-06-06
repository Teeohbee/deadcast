# tests/test_journal_expansion.gd
extends GutTest

func before_each() -> void:
	GameState.triggered_journal_events = []
	GameState.first_listened_entity_id = ""
	GameState.journal_entries = []
	GameState.last_run_result = {}
	GameState.pressure_level = 0
	GameState.debt = 80000
	GameState.run_count = 99
	GameState.encountered_entities = {}

func after_each() -> void:
	DirAccess.remove_absolute("user://save_journal_test.cfg")

func test_triggered_journal_events_saves_and_loads() -> void:
	GameState.triggered_journal_events = ["first_snap", "debt_half"]
	GameState._save_to("user://save_journal_test.cfg")
	GameState.triggered_journal_events = []
	GameState._load_from("user://save_journal_test.cfg")
	assert_eq(GameState.triggered_journal_events.size(), 2)
	assert_true("first_snap" in GameState.triggered_journal_events)
	assert_true("debt_half" in GameState.triggered_journal_events)

func test_first_listened_entity_id_saves_and_loads() -> void:
	GameState.first_listened_entity_id = "solace7"
	GameState._save_to("user://save_journal_test.cfg")
	GameState.first_listened_entity_id = ""
	GameState._load_from("user://save_journal_test.cfg")
	assert_eq(GameState.first_listened_entity_id, "solace7")

func test_new_game_clears_triggered_journal_events() -> void:
	GameState.triggered_journal_events = ["first_snap"]
	GameState.new_game()
	assert_eq(GameState.triggered_journal_events.size(), 0)

func test_new_game_clears_first_listened_entity_id() -> void:
	GameState.first_listened_entity_id = "mariana"
	GameState.new_game()
	assert_eq(GameState.first_listened_entity_id, "")

func test_set_entity_encountered_sets_first_listened_on_first_call() -> void:
	GameState.first_listened_entity_id = ""
	GameState.encountered_entities = {}
	GameState.set_entity_encountered("solace7")
	assert_eq(GameState.first_listened_entity_id, "solace7")

func test_set_entity_encountered_does_not_overwrite_first_listened() -> void:
	GameState.first_listened_entity_id = "solace7"
	GameState.encountered_entities = {"solace7": 1}
	GameState.set_entity_encountered("mariana")
	assert_eq(GameState.first_listened_entity_id, "solace7")

func test_set_entity_encountered_does_not_set_if_entity_already_seen() -> void:
	GameState.first_listened_entity_id = ""
	GameState.encountered_entities = {"solace7": 1}
	GameState.set_entity_encountered("solace7")
	assert_eq(GameState.first_listened_entity_id, "")
