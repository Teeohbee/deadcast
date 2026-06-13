# tests/test_cipher_log_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/CipherLogPanel.tscn")

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_title_is_cipher_log() -> void:
	assert_eq(_make().title, "cipher_log")

func test_append_line_is_timestamped() -> void:
	var p := _make()
	p.append_line("MATCH: block 0x2a")
	assert_string_contains(p._rtl.text, "MATCH: block 0x2a")

func test_caps_at_max_lines() -> void:
	var p := _make()
	for i in 20:
		p.append_line("line %d" % i)
	assert_true(p._lines.size() <= p.MAX_LINES)
