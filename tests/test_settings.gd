# tests/test_settings.gd
extends GutTest

func test_crt_enabled_defaults_true() -> void:
	assert_true(Settings.crt_enabled)

func test_set_crt_enabled_persists_and_reloads() -> void:
	Settings.set_crt_enabled(false)
	Settings.load_settings()
	assert_false(Settings.crt_enabled)
	Settings.set_crt_enabled(true)  # restore
