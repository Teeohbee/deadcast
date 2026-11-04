# tests/test_log_feed.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/LogFeedPanel.tscn")
const PANEL_SCRIPT := preload("res://scenes/barge_hub/panels/log_feed_panel.gd")

func _make_panel() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_append_line_adds_timestamped_entry() -> void:
	var p := _make_panel()
	p.append_line("TEST: hello")
	var last: String = p._lines[p._lines.size() - 1]
	assert_string_contains(last, "TEST: hello")
	assert_string_contains(last, "[color=#22c55e][")

func test_deck_log_signal_appends() -> void:
	var p := _make_panel()
	var before: int = p._lines.size()
	EventBus.deck_log.emit("SIGNAL: via bus")
	assert_eq(p._lines.size(), before + 1)
	assert_string_contains(p._lines[p._lines.size() - 1], "SIGNAL: via bus")

func test_line_cap_evicts_oldest() -> void:
	var p := _make_panel()
	for i in 60:
		p.append_line("line %d" % i)
	assert_eq(p._lines.size(), p.MAX_LINES)
	assert_string_contains(p._lines[p._lines.size() - 1], "line 59")

func test_zone_change_logs_realignment() -> void:
	var p := _make_panel()
	var before: int = p._lines.size()
	EventBus.zone_changed.emit("axiom")
	assert_eq(p._lines.size(), before + 1)
	assert_string_contains(p._lines[p._lines.size() - 1], "AXIOM")

func test_feed_uses_ambient_floor() -> void:
	var p := _make_panel()
	assert_eq(p._rtl.get_theme_font_size("normal_font_size"), DeckStyle.SIZE_AMBIENT)

func test_fit_lines_shows_only_whole_lines() -> void:
	# 90px tall, 17px lines -> 5 whole lines (no clipped partial).
	assert_eq(PANEL_SCRIPT._fit_lines(90.0, 17.0, 8), 5)

func test_fit_lines_clamps_to_cap() -> void:
	# Tall panel never shows more than the history cap.
	assert_eq(PANEL_SCRIPT._fit_lines(1000.0, 17.0, 8), 8)

func test_fit_lines_falls_back_before_layout() -> void:
	# Height 0 (not yet laid out) shows the cap; corrects on first resize.
	assert_eq(PANEL_SCRIPT._fit_lines(0.0, 17.0, 8), 8)
	assert_eq(PANEL_SCRIPT._fit_lines(90.0, 0.0, 8), 8)

func test_new_operator_gets_a_first_run_greeting() -> void:
	var saved_run_count := GameState.run_count
	GameState.run_count = 0
	var p := _make_panel()
	GameState.run_count = saved_run_count
	assert_string_contains(p._lines[0], "New operator registered")
	assert_false(p._lines[0].contains("Welcome back"))

func test_returning_operator_is_welcomed_back() -> void:
	var saved_run_count := GameState.run_count
	GameState.run_count = 3
	var p := _make_panel()
	GameState.run_count = saved_run_count
	assert_string_contains(p._lines[0], "Welcome back")
