# tests/test_item_schematic.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/ItemSchematic.tscn")

func _make() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_title_is_schematic() -> void:
	assert_eq(_make().title, "schematic")

func test_clear_shows_prompt() -> void:
	var p := _make()
	p.clear()
	assert_string_contains(p._caption.text, "hover")

func test_show_item_sets_caption_and_view() -> void:
	var p := _make()
	p.show_item("rod", 1, "Monocarbon Rig")
	assert_string_contains(p._caption.text, "monocarbon")
	assert_eq(p._view.kind, "rod")
	assert_eq(p._view.variant, 1)
