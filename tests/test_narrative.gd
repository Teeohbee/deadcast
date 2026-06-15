# tests/test_narrative.gd
extends GutTest

func before_each() -> void:
	GameState.credits = 50000
	GameState.debt = 80000
	GameState.run_count = 0
	GameState.runs_since_payment = 0
	GameState.pressure_level = 0
	GameState.rod_damaged = false
	GameState.decrypt_box_queue = 0
	GameState.decrypt_box_runs = 0
	GameState.freezer_base = 0
	GameState.freezer_runs = 0
	GameState.marta_last_seen_run = -1
	GameState.journal_entries = []

func after_each() -> void:
	DirAccess.remove_absolute("user://save_test.cfg")

func test_journal_entry_added_after_run_1() -> void:
	GameState.on_run_complete(false, 0)
	assert_eq(GameState.run_count, 1)
	assert_eq(GameState.journal_entries.size(), 1)
	assert_true(GameState.journal_entries[0].begins_with("Run 1."))

func test_no_journal_entry_on_run_2() -> void:
	GameState.on_run_complete(false, 0)  # run 1 — adds entry
	var count = GameState.journal_entries.size()
	GameState.on_run_complete(false, 0)  # run 2 — no new entry
	assert_eq(GameState.journal_entries.size(), count)

func test_journal_entry_added_after_run_5() -> void:
	for i in 5:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.run_count, 5)
	assert_eq(GameState.journal_entries.size(), 2)  # run 1 + run 5

func test_journal_entries_round_trip() -> void:
	GameState.journal_entries = ["First entry", "Second entry"]
	GameState._save_to("user://save_test.cfg")
	GameState.journal_entries = []
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.journal_entries.size(), 2)
	assert_eq(GameState.journal_entries[0], "First entry")

func test_marta_last_seen_run_round_trip() -> void:
	GameState.marta_last_seen_run = 7
	GameState._save_to("user://save_test.cfg")
	GameState.marta_last_seen_run = -1
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.marta_last_seen_run, 7)

func test_new_game_resets_narrative_fields() -> void:
	GameState.marta_last_seen_run = 5
	GameState.journal_entries = ["something"]
	GameState.new_game()
	assert_eq(GameState.marta_last_seen_run, -1)
	assert_eq(GameState.journal_entries.size(), 0)
