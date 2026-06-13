# tests/test_sonar_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/SonarPanel.tscn")

func _make_panel() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_params_exist_for_all_zones() -> void:
	var p := _make_panel()
	for zone_id in ["district7", "exchange", "axiom"]:
		var params: Dictionary = p.params_for(zone_id)
		assert_true(params.has("amp"), zone_id)
		assert_true(params.has("freq"), zone_id)
		assert_true(params.has("sig"), zone_id)

func test_unknown_zone_falls_back_to_district7() -> void:
	var p := _make_panel()
	assert_eq(p.params_for("nonsense"), p.params_for("district7"))

func test_zone_change_updates_wave_and_legend() -> void:
	var p := _make_panel()
	EventBus.zone_changed.emit("axiom")
	assert_eq(p._wave.amplitude, 35.0)
	assert_eq(p._wave.frequency, 0.04)
	assert_string_contains(p._sig_label.text, "CRITICAL")

func test_ghost_sig_uses_body_tier() -> void:
	var p := _make_panel()
	assert_eq(p._sig_label.get_theme_font_size("font_size"), DeckStyle.SIZE_BODY)
