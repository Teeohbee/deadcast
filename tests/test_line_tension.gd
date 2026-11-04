# tests/test_line_tension.gd
# The dive rail's plain tension readout: the one gauge that never lies.
extends GutTest

func _make_panel(cap: int = 80) -> LineTensionPanel:
	var panel := LineTensionPanel.new()
	panel.setup(cap)
	add_child_autofree(panel)
	return panel

func test_readout_shows_tension_against_the_cap() -> void:
	assert_eq(LineTensionPanel.readout_text(20, 80), "TENSION 20 / 80")

func test_load_colour_is_green_below_three_quarters() -> void:
	assert_eq(LineTensionPanel.load_color(0, 80), DeckStyle.GREEN)
	assert_eq(LineTensionPanel.load_color(59, 80), DeckStyle.GREEN)

func test_load_colour_is_amber_from_three_quarters() -> void:
	assert_eq(LineTensionPanel.load_color(60, 80), DeckStyle.AMBER)
	assert_eq(LineTensionPanel.load_color(71, 80), DeckStyle.AMBER)

func test_load_colour_is_red_from_ninety_percent() -> void:
	assert_eq(LineTensionPanel.load_color(72, 80), DeckStyle.RED)
	assert_eq(LineTensionPanel.load_color(80, 80), DeckStyle.RED)

func test_load_colour_with_no_cap_is_green() -> void:
	assert_eq(LineTensionPanel.load_color(10, 0), DeckStyle.GREEN)

func test_panel_starts_at_zero_against_its_cap() -> void:
	var panel := _make_panel(55)
	assert_eq(panel._readout.text, "TENSION 0 / 55")

func test_panel_follows_tension_changes() -> void:
	var panel := _make_panel(80)
	EventBus.tension_changed.emit(45.0)
	assert_eq(panel._readout.text, "TENSION 45 / 80")
	assert_almost_eq(panel._meter.target, 45.0 / 80.0, 0.001)
	assert_eq(panel._meter.fill_color, DeckStyle.GREEN)

func test_panel_turns_red_near_the_cap() -> void:
	var panel := _make_panel(80)
	EventBus.tension_changed.emit(75.0)
	assert_eq(panel._meter.fill_color, DeckStyle.RED)

func test_panel_reads_snapped_when_the_line_goes() -> void:
	var panel := _make_panel(80)
	EventBus.run_ended.emit({"snapped": true})
	assert_eq(panel._readout.text, "LINE SNAPPED")
	EventBus.tension_changed.emit(0.0)
	assert_eq(panel._readout.text, "LINE SNAPPED", "stays snapped once gone")

func test_surfacing_keeps_the_last_reading() -> void:
	var panel := _make_panel(80)
	EventBus.tension_changed.emit(30.0)
	EventBus.run_ended.emit({"snapped": false})
	assert_eq(panel._readout.text, "TENSION 30 / 80")
