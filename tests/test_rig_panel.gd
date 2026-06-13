# tests/test_rig_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/RigPanel.tscn")

func before_each() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	GameState.current_lure = load("res://resources/lures/basic_hook.tres")
	GameState.rod_damaged = false
	GameState.lure_inventory = {"basic_hook": GameState.INFINITE_STOCK}

func _make_panel() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_owned_lures_skip_zero_stock() -> void:
	GameState.lure_inventory = {
		"basic_hook": GameState.INFINITE_STOCK,
		"shock_lure": 0,
		"decoy_swarm": 2,
	}
	var p := _make_panel()
	assert_eq(p.owned_lure_ids(), ["basic_hook", "decoy_swarm"])

func test_cycle_advances_and_wraps() -> void:
	GameState.lure_inventory = {
		"basic_hook": GameState.INFINITE_STOCK,
		"shock_lure": 2,
	}
	var p := _make_panel()
	p.cycle_lure()
	assert_eq(GameState.get_lure_id(GameState.current_lure), "shock_lure")
	p.cycle_lure()
	assert_eq(GameState.get_lure_id(GameState.current_lure), "basic_hook")

func test_cycle_with_single_lure_is_noop() -> void:
	var p := _make_panel()
	p.cycle_lure()
	assert_eq(GameState.get_lure_id(GameState.current_lure), "basic_hook")

func test_damaged_rod_shows_tag() -> void:
	GameState.rod_damaged = true
	var p := _make_panel()
	assert_true(p._rod_damage.visible)

func test_undamaged_rod_hides_tag() -> void:
	var p := _make_panel()
	assert_false(p._rod_damage.visible)

func test_lure_button_shows_name_and_stock() -> void:
	var p := _make_panel()
	assert_string_contains(p._lure_button.text, "BASIC HOOK")
	assert_string_contains(p._lure_button.text, "∞")

func test_rod_name_and_damage_use_body_tier() -> void:
	GameState.rod_damaged = true
	var p := _make_panel()
	assert_eq(p._rod_name.get_theme_font_size("font_size"), DeckStyle.SIZE_BODY)
	assert_eq(p._rod_damage.get_theme_font_size("font_size"), DeckStyle.SIZE_BODY)

func test_focus_targets_are_switch_then_lure() -> void:
	var p := _make_panel()
	var targets: Array = p.focus_targets()
	assert_eq(targets.size(), 2)
	assert_eq(targets[0], p._switch_btn)
	assert_eq(targets[1], p._lure_button)
