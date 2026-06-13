# tests/test_deck_nav.gd
extends GutTest

func _make(n: int) -> Array[Control]:
	var out: Array[Control] = []
	var root := Control.new()
	add_child_autofree(root)
	for i in n:
		var c := Control.new()
		c.name = "C%d" % i
		c.focus_mode = Control.FOCUS_ALL
		root.add_child(c)
		out.append(c)
	return out

func test_chain_vertical_wires_top_and_bottom() -> void:
	var c := _make(3)
	DeckNav.chain_vertical(c)
	# First has no top, links down to second.
	assert_true(c[0].focus_neighbor_top.is_empty())
	assert_eq(c[0].get_node(c[0].focus_neighbor_bottom), c[1])
	# Middle links both ways.
	assert_eq(c[1].get_node(c[1].focus_neighbor_top), c[0])
	assert_eq(c[1].get_node(c[1].focus_neighbor_bottom), c[2])
	# Last has no bottom, links up to second.
	assert_eq(c[2].get_node(c[2].focus_neighbor_top), c[1])
	assert_true(c[2].focus_neighbor_bottom.is_empty())

func test_chain_vertical_single_control_is_noop() -> void:
	var c := _make(1)
	DeckNav.chain_vertical(c)
	assert_true(c[0].focus_neighbor_top.is_empty())
	assert_true(c[0].focus_neighbor_bottom.is_empty())

func test_link_sets_correct_edge_property() -> void:
	var c := _make(2)
	DeckNav.link(c[0], c[1], SIDE_RIGHT)
	assert_eq(c[0].get_node(c[0].focus_neighbor_right), c[1])
	assert_true(c[0].focus_neighbor_left.is_empty())
	DeckNav.link(c[1], c[0], SIDE_LEFT)
	assert_eq(c[1].get_node(c[1].focus_neighbor_left), c[0])
