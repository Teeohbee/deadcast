extends GutTest

func test_scrap_rod_reaches_shallows_and_mid_only() -> void:
	var col := DiveColumn.new("district7", 100)
	assert_eq(col.reachable_layer_sizes(), [3, 3])
	assert_eq(col.total_reachable_slots(), 6)

func test_full_depth_reaches_all_layers() -> void:
	var col := DiveColumn.new("district7", 180)
	assert_eq(col.reachable_layer_sizes(), [3, 3, 2])
	assert_eq(col.total_reachable_slots(), 8)

func test_advance_and_layer_cleared() -> void:
	var col := DiveColumn.new("district7", 100)
	col.generate_current_layer(0.0, false)
	assert_false(col.layer_cleared())
	for i in 3:
		col.advance()
	assert_true(col.layer_cleared())

func test_can_descend_respects_rod_depth() -> void:
	var col := DiveColumn.new("district7", 100)
	col.generate_current_layer(0.0, false)
	for i in 3:
		col.advance()
	assert_true(col.can_descend(), "mid requires depth 60; rod has 100")
	col.descend(0.0, false)
	for i in 3:
		col.advance()
	assert_false(col.can_descend(), "deep requires depth 150; rod has 100")

func test_shallow_rod_cannot_descend_at_all() -> void:
	var col := DiveColumn.new("district7", 50)
	col.generate_current_layer(0.0, false)
	for i in 3:
		col.advance()
	assert_false(col.can_descend())

func test_global_slot_index_spans_layers() -> void:
	var col := DiveColumn.new("district7", 180)
	col.generate_current_layer(0.0, false)
	assert_eq(col.global_slot_index(), 0)
	for i in 3:
		col.advance()
	col.descend(0.0, false)
	assert_eq(col.global_slot_index(), 3)

func test_descend_generates_next_layer() -> void:
	var col := DiveColumn.new("district7", 180)
	col.generate_current_layer(0.0, false)
	for i in 3:
		col.advance()
	col.descend(0.0, false)
	assert_eq(col.current_layer(), CatchData.Layer.MID)
	assert_eq(col.slots.size(), 3)
	assert_false(col.layer_cleared())
