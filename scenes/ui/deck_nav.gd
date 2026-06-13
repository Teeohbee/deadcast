# scenes/ui/deck_nav.gd
# Mechanical focus-graph primitives. Screens declare their own graph shape in
# _wire_focus_graph() and call these to set the focus_neighbor_* NodePaths,
# instead of hand-rolling get_path_to plumbing.
class_name DeckNav

const _EDGE := {
	SIDE_LEFT: "focus_neighbor_left",
	SIDE_TOP: "focus_neighbor_top",
	SIDE_RIGHT: "focus_neighbor_right",
	SIDE_BOTTOM: "focus_neighbor_bottom",
}

# Wire focus_neighbor_top/bottom down an ordered list of controls.
static func chain_vertical(controls: Array[Control]) -> void:
	for i in controls.size():
		var node := controls[i]
		if i > 0:
			node.focus_neighbor_top = node.get_path_to(controls[i - 1])
		if i < controls.size() - 1:
			node.focus_neighbor_bottom = node.get_path_to(controls[i + 1])

# Set one focus_neighbor_<edge> on `from` pointing at `to`.
static func link(from: Control, to: Control, edge: Side) -> void:
	from.set(_EDGE[edge], from.get_path_to(to))
