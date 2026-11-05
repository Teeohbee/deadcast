# tests/test_rod_diagnostics_panel.gd
extends GutTest

func before_each() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	GameState.rod_damaged = false
	GameState.deep_winch_fitted = false

func _panel() -> RodDiagnosticsPanel:
	var p := preload("res://scenes/barge_hub/panels/RodDiagnosticsPanel.tscn").instantiate()
	add_child_autofree(p)
	return p

func test_no_rod_shows_placeholder() -> void:
	GameState.current_rod = null
	var p := _panel()
	await get_tree().process_frame
	assert_true(p._no_rod_label.visible)
	assert_false(p._stat_box.visible)

func test_rod_ok_shows_green_integrity() -> void:
	var p := _panel()
	await get_tree().process_frame
	assert_eq(p._integrity_val.text, "[OK]")
	assert_eq(p._integrity_val.get_theme_color("font_color"), DeckStyle.GREEN)

func test_rod_damaged_shows_red_integrity() -> void:
	GameState.rod_damaged = true
	var p := _panel()
	await get_tree().process_frame
	assert_eq(p._integrity_val.text, "[DAMAGED]")
	assert_eq(p._integrity_val.get_theme_color("font_color"), DeckStyle.RED)

func test_refresh_updates_after_repair() -> void:
	GameState.rod_damaged = true
	var p := _panel()
	await get_tree().process_frame
	assert_eq(p._integrity_val.text, "[DAMAGED]")
	GameState.rod_damaged = false
	p.refresh()
	assert_eq(p._integrity_val.text, "[OK]")
	assert_eq(p._integrity_val.get_theme_color("font_color"), DeckStyle.GREEN)
