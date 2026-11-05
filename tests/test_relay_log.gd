# tests/test_relay_log.gd
extends GutTest

const TEST_SAVE := "user://relay_log_test.cfg"
var _saved := {}

func before_each() -> void:
	for key in ["relay_played_script_ids", "relay_entries", "run_count"]:
		_saved[key] = GameState.get(key)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.run_count = 2

func after_each() -> void:
	for key in _saved:
		GameState.set(key, _saved[key])
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
