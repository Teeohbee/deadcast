# tests/test_barge_hub.gd
extends GutTest

const HUB := preload("res://scenes/barge_hub/BargeHub.tscn")

func before_each() -> void:
	GameState.selected_zone = "district7"
	GameState.pressure_level = 0

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

func test_crt_disabled_zeroes_scan_alpha() -> void:
	Settings.crt_enabled = false
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	var overlay := hub.get_node("CRTOverlay") as ColorRect
	assert_eq(overlay.material.get_shader_parameter("scan_alpha"), 0.0)
	Settings.crt_enabled = true

func test_crt_enabled_leaves_shader_default() -> void:
	# scan_alpha must NOT be overridden when CRT is on - shader default is the
	# single source of truth, so null here means no drift between code and shader.
	Settings.crt_enabled = true
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	var overlay := hub.get_node("CRTOverlay") as ColorRect
	assert_null(overlay.material.get_shader_parameter("scan_alpha"))

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
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	var zone := hub.get_node("Margin/VBox/MainGrid/LeftColumn/ZonePanel")
	var first_card: Button = zone.focus_targets()[0]
	var right: Button = hub.get_node("Margin/VBox/MainGrid/RightColumn/RigPanel").focus_targets()[0]
	assert_eq(first_card.get_node(first_card.focus_neighbor_right), right)
