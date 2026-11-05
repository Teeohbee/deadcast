# tests/test_rig_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/RigPanel.tscn")

func before_each() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	GameState.rod_damaged = false
	GameState.lure_inventory = {"splice_kit": 2, "deep_pulse": 1}
	GameState.loadout = ["splice_kit", ""] as Array[String]

func _make_panel() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_two_slot_buttons_show_role_name_and_stock() -> void:
	var p := _make_panel()
	assert_eq(p.slot_buttons().size(), 2)
	assert_string_contains(p.slot_buttons()[0].text, "[SURVIVE] SPLICE KIT x2")
	assert_string_contains(p.slot_buttons()[1].text, "empty")

func test_pressing_a_slot_cycles_it() -> void:
	var p := _make_panel()
	p.slot_buttons()[1].pressed.emit()
	assert_eq(GameState.loadout[1], "deep_pulse")
	assert_string_contains(p.slot_buttons()[1].text, "[SCOUT] DEEP PULSE x1")

func test_the_slots_are_the_rigs_focus_targets() -> void:
	var p := _make_panel()
	assert_eq(p.focus_targets(), p.slot_buttons())
	assert_eq(p.slot_buttons()[0].focus_mode, Control.FOCUS_ALL)

func test_damaged_rod_shows_tag() -> void:
	GameState.rod_damaged = true
	var p := _make_panel()
	assert_true(p._rod_damage.visible)

func test_undamaged_rod_hides_tag() -> void:
	var p := _make_panel()
	assert_false(p._rod_damage.visible)

func test_rod_name_and_damage_use_body_tier() -> void:
	GameState.rod_damaged = true
	var p := _make_panel()
	assert_eq(p._rod_name.get_theme_font_size("font_size"), DeckStyle.SIZE_BODY)
	assert_eq(p._rod_damage.get_theme_font_size("font_size"), DeckStyle.SIZE_BODY)

func test_depth_rating_uses_feet_like_the_rest_of_the_rig_ui() -> void:
	var p := _make_panel()
	await get_tree().process_frame
	assert_string_contains(p._rod_meta.text, "DEPTH RATING: %dft" % GameState.line_rating_ft())
