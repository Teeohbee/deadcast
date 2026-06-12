extends GutTest

const TEST_PATH := "user://test_run_log_save.cfg"

func _record(run: int) -> Dictionary:
	return {
		"run": run,
		"zone": "district 7 ruins",
		"entries": [],
		"banked": 100,
		"forfeited": 0,
		"outcome": "surfaced",
	}

func before_each() -> void:
	GameState.run_logs = [] as Array[Dictionary]

func after_all() -> void:
	GameState.run_logs = [] as Array[Dictionary]
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

func test_add_run_log_appends() -> void:
	GameState.add_run_log(_record(1))
	assert_eq(GameState.run_logs.size(), 1)
	assert_eq(int(GameState.run_logs[0].run), 1)

func test_add_run_log_caps_at_20_dropping_oldest() -> void:
	for i in 25:
		GameState.add_run_log(_record(i + 1))
	assert_eq(GameState.run_logs.size(), 20)
	assert_eq(int(GameState.run_logs[0].run), 6, "runs 1-5 dropped")
	assert_eq(int(GameState.run_logs[-1].run), 25)

func test_run_logs_round_trip_through_save() -> void:
	GameState.add_run_log(_record(1))
	GameState.add_run_log(_record(2))
	GameState._save_to(TEST_PATH)
	GameState.run_logs = [] as Array[Dictionary]
	GameState._load_from(TEST_PATH)
	assert_eq(GameState.run_logs.size(), 2)
	assert_eq(int(GameState.run_logs[1].run), 2)

func test_load_without_run_logs_key_defaults_empty() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "credits", GameState.credits)
	cfg.save(TEST_PATH)
	GameState.add_run_log(_record(1))
	GameState._load_from(TEST_PATH)
	assert_eq(GameState.run_logs.size(), 0, "old saves default to empty, no migration")
