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

# --- _maybe_append_journal_entry event triggers ---

func test_entity_listen_entry_written_when_entity_id_set() -> void:
	GameState.first_listened_entity_id = "solace7"
	GameState._maybe_append_journal_entry()
	assert_true("first_entity_listen" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 1)

func test_entity_listen_entry_not_written_twice() -> void:
	GameState.first_listened_entity_id = "solace7"
	GameState.triggered_journal_events = ["first_entity_listen"]
	GameState._maybe_append_journal_entry()
	assert_eq(GameState.journal_entries.size(), 0)

func test_entity_listen_entry_not_written_without_entity_id() -> void:
	GameState.first_listened_entity_id = ""
	GameState._maybe_append_journal_entry()
	assert_false("first_entity_listen" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 0)

func test_snap_entry_written_on_first_snap() -> void:
	GameState.last_run_result = {"snapped": true, "credits": 0, "bio_credits": 0}
	GameState._maybe_append_journal_entry()
	assert_true("first_snap" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 1)

func test_snap_entry_not_written_twice() -> void:
	GameState.last_run_result = {"snapped": true, "credits": 0, "bio_credits": 0}
	GameState.triggered_journal_events = ["first_snap"]
	GameState._maybe_append_journal_entry()
	assert_eq(GameState.journal_entries.size(), 0)

func test_snap_entry_not_written_when_not_snapped() -> void:
	GameState.last_run_result = {"snapped": false, "credits": 0, "bio_credits": 0}
	GameState._maybe_append_journal_entry()
	assert_false("first_snap" in GameState.triggered_journal_events)

func test_pressure_entry_written_on_first_escalation() -> void:
	GameState.pressure_level = 1
	GameState._maybe_append_journal_entry()
	assert_true("first_pressure" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 1)

func test_pressure_entry_not_written_twice() -> void:
	GameState.pressure_level = 1
	GameState.triggered_journal_events = ["first_pressure"]
	GameState._maybe_append_journal_entry()
	assert_eq(GameState.journal_entries.size(), 0)

func test_pressure_entry_not_written_at_zero_pressure() -> void:
	GameState.pressure_level = 0
	GameState._maybe_append_journal_entry()
	assert_false("first_pressure" in GameState.triggered_journal_events)

func test_debt_entry_written_below_half() -> void:
	GameState.debt = 39999
	GameState._maybe_append_journal_entry()
	assert_true("debt_half" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 1)

func test_debt_entry_not_written_twice() -> void:
	GameState.debt = 39999
	GameState.triggered_journal_events = ["debt_half"]
	GameState._maybe_append_journal_entry()
	assert_eq(GameState.journal_entries.size(), 0)

func test_debt_entry_not_written_at_exactly_half() -> void:
	GameState.debt = 40000
	GameState._maybe_append_journal_entry()
	assert_false("debt_half" in GameState.triggered_journal_events)
