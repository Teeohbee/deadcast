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
