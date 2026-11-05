# tests/test_zone_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/ZonePanel.tscn")

var _saved_run_count: int

func before_each() -> void:
	GameState.selected_zone = "district7"
	_saved_run_count = GameState.run_count
	GameState.run_count = 10  # every zone open

func after_each() -> void:
	GameState.run_count = _saved_run_count

func _make_panel() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_builds_three_cards() -> void:
	var p := _make_panel()
	assert_eq(p._cards.size(), 3)

func test_selected_card_has_green_border() -> void:
	var p := _make_panel()
	var sb := (p._cards["district7"] as Button).get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(sb.border_color, DeckStyle.GREEN)

func test_unselected_card_has_dim_border() -> void:
	var p := _make_panel()
	var sb := (p._cards["axiom"] as Button).get_theme_stylebox("normal") as StyleBoxFlat
	assert_ne(sb.border_color, DeckStyle.GREEN)

func test_zone_change_moves_selection() -> void:
	var p := _make_panel()
	GameState.select_zone("axiom")
	var sb := (p._cards["axiom"] as Button).get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(sb.border_color, DeckStyle.GREEN)
	assert_eq(p._indicators["axiom"].modulate.a, 1.0)
	assert_eq(p._indicators["district7"].modulate.a, 0.0)

func test_pressing_card_selects_zone() -> void:
	var p := _make_panel()
	(p._cards["exchange"] as Button).pressed.emit()
	assert_eq(GameState.selected_zone, "exchange")

func test_focus_selected_grabs_selected_card() -> void:
	var p := _make_panel()
	GameState.select_zone("exchange")
	p.focus_selected()
	assert_true((p._cards["exchange"] as Button).has_focus())

func test_zone_name_uses_value_tier() -> void:
	var p := _make_panel()
	assert_eq(p._names["district7"].get_theme_font_size("font_size"), DeckStyle.SIZE_VALUE)

func test_focus_targets_are_the_three_cards_in_order() -> void:
	var p := _make_panel()
	var targets: Array = p.focus_targets()
	assert_eq(targets.size(), 3)
	assert_eq(targets[0], p._cards["district7"])

func _visible_zone_ids(p: Node) -> Array[String]:
	var ids: Array[String] = []
	for zone_id in p.ZONE_IDS:
		if (p._cards[zone_id] as Button).visible:
			ids.append(zone_id)
	return ids

func test_a_new_operator_sees_only_district_7() -> void:
	GameState.run_count = 0
	var p := _make_panel()
	assert_eq(_visible_zone_ids(p), ["district7"] as Array[String])
	assert_eq(p._hosts_label.text, "1 LOCAL HOST CONNECTED")
	assert_eq(p.focus_targets(), [p._cards["district7"]] as Array[Control])

func test_zones_appear_on_refresh_as_runs_complete() -> void:
	GameState.run_count = 0
	var p := _make_panel()
	GameState.run_count = 2
	p.refresh_unlocked()
	assert_eq(_visible_zone_ids(p), ["district7", "exchange"] as Array[String])
	assert_eq(p._hosts_label.text, "2 LOCAL HOSTS CONNECTED")
	var district7: Button = p._cards["district7"]
	assert_eq(district7.get_node(district7.focus_neighbor_bottom), p._cards["exchange"])

func test_a_locked_selected_zone_falls_back_to_district_7() -> void:
	GameState.run_count = 0
	GameState.selected_zone = "axiom"
	_make_panel()
	assert_eq(GameState.selected_zone, "district7")

func test_pressing_card_emits_zone_confirmed() -> void:
	var p := _make_panel()
	watch_signals(p)
	(p._cards["exchange"] as Button).pressed.emit()
	assert_signal_emitted_with_parameters(p, "zone_confirmed", ["exchange"])

func test_nav_hint_hidden_with_a_single_open_zone() -> void:
	GameState.run_count = 0
	var p := _make_panel()
	assert_false(p._nav_hint.visible)

func test_nav_hint_shown_with_several_open_zones() -> void:
	var p := _make_panel()
	assert_true(p._nav_hint.visible)

func test_open_zone_count() -> void:
	var p := _make_panel()
	assert_eq(p.open_zone_count(), 3)
	GameState.run_count = 0
	p.refresh_unlocked()
	assert_eq(p.open_zone_count(), 1)
