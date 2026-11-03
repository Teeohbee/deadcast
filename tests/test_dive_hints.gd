# tests/test_dive_hints.gd
extends GutTest

var _saved_hints_done: bool
var _saved_run_count: int
# new_game() and on_run_complete() write the real save; keep the player's copy.
var _real_save_existed: bool = false
var _real_save_bytes: PackedByteArray = PackedByteArray()

func before_all() -> void:
	_real_save_existed = FileAccess.file_exists(GameState.SAVE_PATH)
	if _real_save_existed:
		_real_save_bytes = FileAccess.get_file_as_bytes(GameState.SAVE_PATH)

func after_all() -> void:
	if _real_save_existed:
		var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		file.store_buffer(_real_save_bytes)
	else:
		DirAccess.remove_absolute(GameState.SAVE_PATH)

func before_each() -> void:
	_saved_hints_done = GameState.first_dive_hints_done
	_saved_run_count = GameState.run_count

func after_each() -> void:
	GameState.first_dive_hints_done = _saved_hints_done
	GameState.run_count = _saved_run_count
	DirAccess.remove_absolute("user://save_test.cfg")

# --- DiveHints content ---

func test_each_moment_has_hint_lines_before_first_dive() -> void:
	for moment in DiveHints.MOMENTS:
		assert_gt(DiveHints.lines_for(moment, false).size(), 0, "no hint for %s" % moment)

func test_no_hint_lines_once_first_dive_is_done() -> void:
	for moment in DiveHints.MOMENTS:
		assert_eq(DiveHints.lines_for(moment, true).size(), 0)

func test_unknown_moment_has_no_hint_lines() -> void:
	assert_eq(DiveHints.lines_for("no_such_moment", false).size(), 0)

func test_contact_hint_explains_tension_and_sig() -> void:
	var text := "\n".join(DiveHints.lines_for(DiveHints.CONTACT, false))
	assert_string_contains(text, "T ")
	assert_string_contains(text, "SIG")

func test_checkpoint_hint_explains_descend_and_surface() -> void:
	var text := "\n".join(DiveHints.lines_for(DiveHints.CHECKPOINT, false)).to_lower()
	assert_string_contains(text, "descend")
	assert_string_contains(text, "surface")

func test_hint_lines_are_marked_as_hints() -> void:
	for moment in DiveHints.MOMENTS:
		for line in DiveHints.lines_for(moment, false):
			assert_true(line.begins_with(DiveHints.PREFIX), line)

# --- GameState flag ---

func test_new_game_shows_hints_again() -> void:
	GameState.first_dive_hints_done = true
	GameState.new_game()
	assert_false(GameState.first_dive_hints_done)

func test_completing_a_run_marks_hints_done() -> void:
	GameState.first_dive_hints_done = false
	GameState.on_run_complete(false, 0)
	assert_true(GameState.first_dive_hints_done)

func test_snapped_run_also_marks_hints_done() -> void:
	GameState.first_dive_hints_done = false
	GameState.on_run_complete(true, 0)
	assert_true(GameState.first_dive_hints_done)

func test_hints_flag_persists() -> void:
	GameState.first_dive_hints_done = true
	GameState._save_to("user://save_test.cfg")
	GameState.first_dive_hints_done = false
	GameState._load_from("user://save_test.cfg")
	assert_true(GameState.first_dive_hints_done)

func test_old_save_with_runs_skips_hints() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "run_count", 4)
	cfg.save("user://save_test.cfg")
	GameState.first_dive_hints_done = false
	GameState._load_from("user://save_test.cfg")
	assert_true(GameState.first_dive_hints_done)

func test_old_save_without_runs_still_shows_hints() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "run_count", 0)
	cfg.save("user://save_test.cfg")
	GameState.first_dive_hints_done = true
	GameState._load_from("user://save_test.cfg")
	assert_false(GameState.first_dive_hints_done)
