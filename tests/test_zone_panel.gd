# tests/test_zone_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/ZonePanel.tscn")

func before_each() -> void:
	GameState.selected_zone = "district7"

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
