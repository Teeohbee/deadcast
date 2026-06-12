# tests/test_log_feed.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/LogFeedPanel.tscn")

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
