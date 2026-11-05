# tests/test_barge_hub.gd
extends GutTest

const HUB := preload("res://scenes/barge_hub/BargeHub.tscn")

var _saved_run_count: int

func before_each() -> void:
	GameState.selected_zone = "district7"
	GameState.pressure_level = 0
	_saved_run_count = GameState.run_count
	GameState.run_count = 10  # every zone and panel open

func after_each() -> void:
	GameState.run_count = _saved_run_count

func test_hub_instantiates_with_all_panels() -> void:
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	assert_not_null(hub.get_node("Margin/VBox/MainGrid/LeftColumn/SonarPanel"))
	assert_not_null(hub.get_node("Margin/VBox/MainGrid/LeftColumn/ZonePanel"))
	assert_not_null(hub.get_node("Margin/VBox/MainGrid/LeftColumn/LogFeedPanel"))
	assert_not_null(hub.get_node("Margin/VBox/MainGrid/RightColumn/LedgerPanel"))
	assert_not_null(hub.get_node("Margin/VBox/MainGrid/RightColumn/RigPanel"))
	assert_not_null(hub.get_node("Margin/VBox/MainGrid/RightColumn/FreezerPanel"))

func test_banner_shows_selected_zone() -> void:
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	assert_string_contains(hub._banner_zone.text, "DISTRICT 7 RUINS")
	GameState.select_zone("axiom")
	assert_string_contains(hub._banner_zone.text, "AXIOM TOWER SUB-BASEMENT")

func test_banner_zone_uses_value_tier() -> void:
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	assert_eq(hub._banner_zone.get_theme_font_size("font_size"), DeckStyle.SIZE_VALUE)

func test_default_focus_on_selected_zone_card() -> void:
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	var zone_panel := hub.get_node("Margin/VBox/MainGrid/LeftColumn/ZonePanel")
	assert_true((zone_panel._cards["district7"] as Button).has_focus())

func test_last_zone_card_descends_to_dive() -> void:
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	var zone := hub.get_node("Margin/VBox/MainGrid/LeftColumn/ZonePanel")
	var last_card: Button = zone.focus_targets()[2]
	assert_eq(last_card.get_node(last_card.focus_neighbor_bottom), hub._dive_button)

func test_sell_button_descends_to_dive() -> void:
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	var freezer := hub.get_node("Margin/VBox/MainGrid/RightColumn/FreezerPanel")
	var sell: Button = freezer.focus_targets()[0]
	assert_eq(sell.get_node(sell.focus_neighbor_bottom), hub._dive_button)

func test_zone_card_reaches_right_column() -> void:
	# Rig is no longer a focus stop, so the right column is just the freezer's
	# Sell button - a zone card's right neighbour resolves to it.
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	var zone := hub.get_node("Margin/VBox/MainGrid/LeftColumn/ZonePanel")
	var first_card: Button = zone.focus_targets()[0]
	var right: Button = hub.get_node("Margin/VBox/MainGrid/RightColumn/FreezerPanel").focus_targets()[0]
	assert_eq(first_card.get_node(first_card.focus_neighbor_right), right)

func test_dive_button_shows_pad_glyph_and_verb() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	assert_string_contains(hub._dive_button.text, "[A]")
	assert_string_contains(hub._dive_button.text, "INITIATE DIVE")

func test_dive_button_updates_on_device_change() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	InputGlyphs.mode = InputGlyphs.Mode.KEY
	InputGlyphs.device_changed.emit(InputGlyphs.Mode.KEY)
	assert_string_contains(hub._dive_button.text, "[ENTER]")

func test_newly_opened_zone_becomes_the_card_above_the_dive_button() -> void:
	GameState.run_count = 1
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	var zone_panel: Node = hub._zone_panel
	var district7: Button = zone_panel._cards["district7"]
	assert_eq(district7.get_node(district7.focus_neighbor_bottom), hub._dive_button)
	GameState.run_count = 2
	hub.on_screen_shown()
	var exchange: Button = zone_panel._cards["exchange"]
	assert_eq(district7.get_node(district7.focus_neighbor_bottom), exchange)
	assert_eq(exchange.get_node(exchange.focus_neighbor_bottom), hub._dive_button)

func test_freezer_is_hidden_for_a_new_operator() -> void:
	GameState.run_count = 0
	var saved_freezer_base := GameState.freezer_base
	GameState.freezer_base = 0
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(hub._freezer_panel.visible)
	var district7: Button = hub._zone_panel._cards["district7"]
	assert_eq(district7.get_node(district7.focus_neighbor_bottom), hub._dive_button)
	assert_eq(hub._dive_button.get_node(hub._dive_button.focus_neighbor_top), district7)
	GameState.freezer_base = saved_freezer_base

func test_freezer_appears_with_its_first_deposit() -> void:
	GameState.run_count = 0
	var saved_freezer_base := GameState.freezer_base
	GameState.freezer_base = 0
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	GameState.run_count = 1
	GameState.freezer_base = 350
	hub.on_screen_shown()
	assert_true(hub._freezer_panel.visible)
	GameState.freezer_base = saved_freezer_base

func test_first_run_unlocks_are_announced_once_on_the_deck() -> void:
	GameState.run_count = 0
	var saved_freezer_base := GameState.freezer_base
	GameState.freezer_base = 0
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	var lines: Array[String] = []
	var collect := func(line: String) -> void: lines.append(line)
	EventBus.deck_log.connect(collect)
	GameState.run_count = 1
	hub.on_screen_shown()
	hub.on_screen_shown()
	EventBus.deck_log.disconnect(collect)
	GameState.freezer_base = saved_freezer_base
	assert_eq(lines.size(), 2, str(lines))
	assert_string_contains(lines[0], "Workshop")
	assert_string_contains(lines[1], "Okeke")
	assert_eq(UIController.fresh_tabs, ["workshop", "vendors"] as Array[String])
	UIController.fresh_tabs.clear()

func test_a_continued_save_announces_nothing() -> void:
	GameState.run_count = 7
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	watch_signals(EventBus)
	hub.on_screen_shown()
	assert_signal_not_emitted(EventBus, "deck_log")

func test_confirming_a_zone_moves_focus_to_dive() -> void:
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	(hub._zone_panel._cards["exchange"] as Button).pressed.emit()
	assert_eq(GameState.selected_zone, "exchange")
	assert_true(hub._dive_button.has_focus())

func test_single_open_zone_opens_on_the_dive_button() -> void:
	GameState.run_count = 0
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(hub._dive_button.has_focus())
	hub._zone_panel._cards["district7"].grab_focus()
	hub.on_screen_shown()
	assert_true(hub._dive_button.has_focus())
