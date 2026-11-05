# tests/pre_run_hook.gd
# Runs before any test (wired up in .gutconfig.json). Points GameState and
# Settings at throwaway files so the suite never overwrites the player's
# real save.cfg or settings.cfg.
extends GutHookScript

const TEST_SAVE_PATH := "user://test_save.cfg"
const TEST_SETTINGS_PATH := "user://test_settings.cfg"

func run() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	root.get_node("GameState").save_path = TEST_SAVE_PATH
	root.get_node("Settings").path = TEST_SETTINGS_PATH
	# Relay calls would hijack every navigation test; relay tests opt back in.
	root.get_node("UIController").relay_calls_enabled = false
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	DirAccess.remove_absolute(TEST_SETTINGS_PATH)
