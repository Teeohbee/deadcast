# tests/test_cipher_crack.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/CipherCrackPanel.tscn")

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_idle_when_no_payload() -> void:
	var p := _make()
	p.set_state(false, 0.0)
	assert_false(p._active)

func test_active_with_payload() -> void:
	var p := _make()
	p.set_state(true, 0.5)
	assert_true(p._active)

func test_progress_is_clamped() -> void:
	var p := _make()
	p.set_state(true, 1.8)
	assert_eq(p._progress, 1.0)
	p.set_state(true, -0.4)
	assert_eq(p._progress, 0.0)

func test_progress_bar_reflects_value() -> void:
	var p := _make()
	p.set_state(true, 1.0)
	assert_string_contains(p._bar.text, "100%")
