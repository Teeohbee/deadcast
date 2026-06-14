extends GutTest

func test_cells_basic() -> void:
	# 3 shallows + 3 mid, current slot index 1, nothing revealed.
	var cells := DepthColumnPanel.column_cells([3, 3], 1, {})
	assert_eq(cells.size(), 6)
	assert_eq(cells[0], {"glyph": "✓", "first_in_layer": true})
	assert_eq(cells[1], {"glyph": "▶", "first_in_layer": false})
	assert_eq(cells[2], {"glyph": "?", "first_in_layer": false})
	assert_eq(cells[3], {"glyph": "?", "first_in_layer": true})

func test_cells_revealed_marker() -> void:
	var cells := DepthColumnPanel.column_cells([3], 0, {1: "D", 2: "!"})
	assert_eq(cells[0]["glyph"], "▶")
	assert_eq(cells[1]["glyph"], "D")
	assert_eq(cells[2]["glyph"], "!")

func test_cells_all_resolved() -> void:
	var cells := DepthColumnPanel.column_cells([3], 3, {})
	for c in cells:
		assert_eq(c["glyph"], "✓")
