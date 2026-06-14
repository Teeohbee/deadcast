# tests/test_vendor_link.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/VendorLink.tscn")

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_okeke_reads_warm() -> void:
	var info: Dictionary = _make().link_info("okeke")
	assert_string_contains(info.channel, "warm")

func test_vendor_reads_cold() -> void:
	var info: Dictionary = _make().link_info("vendor")
	assert_string_contains(info.channel, "cold")

func test_refresh_updates_dealer_label() -> void:
	var p := _make()
	p.refresh("okeke")
	assert_string_contains(p._body.text, "okeke")
