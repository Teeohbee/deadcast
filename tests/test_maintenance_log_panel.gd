# tests/test_maintenance_log_panel.gd
extends GutTest

func _panel() -> MaintenanceLogPanel:
	var p := preload("res://scenes/barge_hub/panels/MaintenanceLogPanel.tscn").instantiate()
	add_child_autofree(p)
	return p

func test_append_line_adds_entry() -> void:
	var p := _panel()
	await get_tree().process_frame
	p.append_line("TEST: entry added.")
	assert_eq(p._lines.size(), 1)
	assert_string_contains(p._lines[0], "TEST: entry added.")

func test_append_line_includes_timestamp_colour() -> void:
	var p := _panel()
	await get_tree().process_frame
	p.append_line("THERMAL: test.")
	assert_string_contains(p._lines[0], "[color=#22c55e]")

func test_lines_cap_at_max() -> void:
	var p := _panel()
	await get_tree().process_frame
	for i in MaintenanceLogPanel.MAX_LINES + 3:
		p.append_line("LINE %d" % i)
	assert_eq(p._lines.size(), MaintenanceLogPanel.MAX_LINES)

func test_oldest_line_dropped_when_full() -> void:
	var p := _panel()
	await get_tree().process_frame
	for i in MaintenanceLogPanel.MAX_LINES:
		p.append_line("FILL %d" % i)
	p.append_line("NEWEST: last entry.")
	assert_string_contains(p._lines[p._lines.size() - 1], "NEWEST: last entry.")
	var has_fill_0 := false
	for l in p._lines:
		if "FILL 0" in l:
			has_fill_0 = true
			break
	assert_false(has_fill_0)
