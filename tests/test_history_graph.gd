# tests/test_history_graph.gd
extends GutTest

func _make() -> HistoryGraph:
	var g := HistoryGraph.new()
	add_child_autofree(g)
	return g

func test_starts_at_capacity() -> void:
	assert_eq(_make()._samples.size(), HistoryGraph.CAPACITY)

func test_push_never_exceeds_capacity() -> void:
	var g := _make()
	for i in HistoryGraph.CAPACITY * 2:
		g.push(0.5)
	assert_eq(g._samples.size(), HistoryGraph.CAPACITY)

func test_push_drops_oldest_keeps_newest() -> void:
	var g := _make()
	for i in HistoryGraph.CAPACITY:
		g.push(1.0)
	g.push(0.25)
	assert_almost_eq(g._samples[HistoryGraph.CAPACITY - 1], 0.25, 0.001)

func test_push_clamps_value() -> void:
	var g := _make()
	g.push(5.0)
	assert_almost_eq(g._samples[HistoryGraph.CAPACITY - 1], 1.0, 0.001)
