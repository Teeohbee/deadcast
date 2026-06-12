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

func test_default_focus_on_selected_zone_card() -> void:
	var hub := HUB.instantiate()
	add_child_autofree(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	var zone_panel := hub.get_node("Margin/VBox/MainGrid/LeftColumn/ZonePanel")
	assert_true((zone_panel._cards["district7"] as Button).has_focus())
