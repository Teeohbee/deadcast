# tests/test_wireframe_view.gd
extends GutTest

func _make() -> WireframeView:
	var v := WireframeView.new()
	add_child_autofree(v)
	return v

func test_starts_empty() -> void:
	assert_eq(_make().kind, "")

func test_set_item_records_kind_and_variant() -> void:
	var v := _make()
	v.set_item("lure", LureData.LureEffect.SHOCK)
	assert_eq(v.kind, "lure")
	assert_eq(v.variant, int(LureData.LureEffect.SHOCK))
