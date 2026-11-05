# tests/test_relay_log.gd
extends GutTest

const TEST_SAVE := "user://relay_log_test.cfg"
# Loading test saves and new_game() touch all of GameState, so the whole
# state is snapshotted to disk and restored after each test.
const STATE_BACKUP := "user://relay_log_state_backup.cfg"

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.run_count = 2

func after_each() -> void:
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)
	DirAccess.remove_absolute(TEST_SAVE)

func _lines(text: String) -> Array[Dictionary]:
	return [{"who": "marta", "text": text}]

func test_marking_a_script_played_is_remembered_once() -> void:
	assert_false(GameState.relay_has_played("marta_first_call"))
	GameState.relay_mark_played("marta_first_call")
	GameState.relay_mark_played("marta_first_call")
	assert_true(GameState.relay_has_played("marta_first_call"))
	assert_eq(GameState.relay_played_script_ids.size(), 1)

func test_a_filed_entry_lands_in_its_contacts_thread_unread_with_the_run() -> void:
	GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_CALL, "marta_first_call", _lines("hello."))
	var thread := GameState.relay_entries_for("marta")
	assert_eq(thread.size(), 1)
	assert_eq(thread[0].kind, GameState.RELAY_ENTRY_CALL)
	assert_eq(thread[0].run, 2)
	assert_eq(thread[0].lines, _lines("hello."))
	assert_false(thread[0].read)
	assert_eq(GameState.relay_entries_for("okeke").size(), 0)

func test_unread_counts_are_per_contact_and_clear_when_read() -> void:
	GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_TEXT, "a", _lines("one."))
	GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_TEXT, "b", _lines("two."))
	GameState.relay_file_entry("axiom_credit", GameState.RELAY_ENTRY_TEXT, "c", _lines("notice."))
	assert_eq(GameState.relay_unread_count("marta"), 2)
	assert_eq(GameState.relay_unread_count("axiom_credit"), 1)
	GameState.relay_mark_read("marta")
	assert_eq(GameState.relay_unread_count("marta"), 0)
	assert_eq(GameState.relay_unread_count("axiom_credit"), 1)

func test_each_thread_keeps_only_its_newest_entries() -> void:
	for index in GameState.MAX_RELAY_ENTRIES_PER_CONTACT + 3:
		GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_DIVE_LINE, "line", _lines("line %d" % index))
	GameState.relay_file_entry("okeke", GameState.RELAY_ENTRY_TEXT, "okeke", _lines("still here."))
	var thread := GameState.relay_entries_for("marta")
	assert_eq(thread.size(), GameState.MAX_RELAY_ENTRIES_PER_CONTACT)
	assert_eq(thread[0].lines[0].text, "line 3")
	assert_eq(GameState.relay_entries_for("okeke").size(), 1)

func test_filing_copies_the_lines_so_later_edits_dont_leak_in() -> void:
	var lines := _lines("original.")
	GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_TEXT, "a", lines)
	lines[0].text = "changed."
	assert_eq(GameState.relay_entries_for("marta")[0].lines[0].text, "original.")

func test_played_scripts_and_entries_survive_save_and_load() -> void:
	GameState.relay_mark_played("marta_first_call")
	GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_CALL, "marta_first_call", _lines("hello."))
	GameState._save_to(TEST_SAVE)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState._load_from(TEST_SAVE)
	assert_true(GameState.relay_has_played("marta_first_call"))
	assert_eq(GameState.relay_entries_for("marta")[0].lines, _lines("hello."))

func test_new_game_clears_the_relay() -> void:
	var saved_path := GameState.save_path
	GameState.save_path = TEST_SAVE
	GameState.relay_mark_played("marta_first_call")
	GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_CALL, "marta_first_call", _lines("hello."))
	GameState.new_game()
	GameState.save_path = saved_path
	assert_eq(GameState.relay_played_script_ids.size(), 0)
	assert_eq(GameState.relay_entries.size(), 0)

# --- saves from before the relay ---

func _write_pre_relay_save(run_count: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "run_count", run_count)
	cfg.set_value("player", "debt", 70000)
	cfg.save(TEST_SAVE)

func test_an_old_save_mid_game_doesnt_replay_the_first_call() -> void:
	_write_pre_relay_save(5)
	GameState._load_from(TEST_SAVE)
	assert_true(GameState.relay_has_played("marta_first_call"))
	assert_true(GameState.relay_has_played("marta_after_dive_one"))
	assert_false(GameState.relay_has_played("okeke_intro_call"))
	assert_eq(GameState.relay_entries.size(), 0)
	assert_eq(GameState.debt, 70000)
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).is_empty())

func test_an_old_save_that_never_dived_still_gets_the_first_call() -> void:
	_write_pre_relay_save(0)
	GameState._load_from(TEST_SAVE)
	assert_eq(GameState.relay_played_script_ids.size(), 0)
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_first_call")

func test_a_relay_save_is_loaded_as_saved_not_migrated() -> void:
	GameState.run_count = 5
	GameState._save_to(TEST_SAVE)
	GameState._load_from(TEST_SAVE)
	assert_eq(GameState.relay_played_script_ids.size(), 0)
