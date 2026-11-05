# tests/test_vendor_link.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/VendorLink.tscn")

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_okeke_reads_warm() -> void:
	var info: Dictionary = _make().link_info()
	assert_string_contains(info.channel, "warm")

func test_refresh_shows_okeke_as_dealer() -> void:
	var p := _make()
	p.refresh()
	assert_string_contains(p._body.text, "okeke")

func test_channel_reflects_axiom_pressure() -> void:
	var saved_pressure := GameState.pressure_level
	var link := VendorLink.new()
	add_child_autofree(link)
	GameState.pressure_level = 0
	assert_eq(link.link_info().channel, "open / warm")
	GameState.pressure_level = 2
	assert_eq(link.link_info().channel, "open / prices up")
	GameState.pressure_level = 3
	assert_eq(link.link_info().channel, "under the counter")
	GameState.pressure_level = saved_pressure
