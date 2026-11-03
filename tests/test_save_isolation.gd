# tests/test_save_isolation.gd
# The pre-run hook (tests/pre_run_hook.gd) points saves at test-only files,
# so running the suite never touches the player's real save or settings.
extends GutTest

func test_game_save_goes_to_a_test_file() -> void:
	assert_ne(GameState.save_path, GameState.SAVE_PATH)

func test_settings_go_to_a_test_file() -> void:
	assert_ne(Settings.path, Settings.PATH)

func test_saving_writes_the_test_file_not_the_real_one() -> void:
	var real_modified_before := FileAccess.get_modified_time(GameState.SAVE_PATH)
	GameState.save()
	assert_true(FileAccess.file_exists(GameState.save_path))
	assert_eq(FileAccess.get_modified_time(GameState.SAVE_PATH), real_modified_before)
