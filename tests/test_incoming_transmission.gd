# tests/test_incoming_transmission.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/IncomingTransmission.tscn")

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_link_secure_at_low_pressure() -> void:
	var p := _make()
	assert_eq(p.link_status(0).text, "SECURE")
	assert_eq(p.link_status(1).text, "SECURE")

func test_link_monitored_at_mid_pressure() -> void:
	var p := _make()
	assert_eq(p.link_status(2).text, "MONITORED")
	assert_eq(p.link_status(3).text, "MONITORED")

func test_link_traced_at_high_pressure() -> void:
	var p := _make()
	assert_eq(p.link_status(4).text, "TRACED")
	assert_eq(p.link_status(5).text, "TRACED")

func test_traced_is_red() -> void:
	var p := _make()
	assert_eq(p.link_status(4).color, DeckStyle.RED)

func test_refresh_sets_link_label() -> void:
	var p := _make()
	p.refresh(4)
	assert_string_contains(p._link_label.text, "TRACED")
