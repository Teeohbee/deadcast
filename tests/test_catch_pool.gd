# tests/test_catch_pool.gd
extends GutTest

func test_weighted_random_returns_item_from_array() -> void:
	var items = ["a", "b", "c"]
	var weights = [1.0, 1.0, 1.0]
	var result = CatchPool._weighted_random(items, weights)
	assert_true(result in items)

func test_weighted_random_with_zero_weight_never_returns_that_item() -> void:
	var items = ["a", "b"]
	var weights = [1.0, 0.0]
	for i in 100:
		var result = CatchPool._weighted_random(items, weights)
		assert_eq(result, "a", "Item with zero weight should never be selected")

func test_weighted_random_with_dominant_weight_prefers_that_item() -> void:
	var items = ["rare", "common"]
	var weights = [0.01, 100.0]
	var common_count = 0
	for i in 200:
		if CatchPool._weighted_random(items, weights) == "common":
			common_count += 1
	assert_gt(common_count, 180, "High-weight item should dominate")

func test_calculate_weight_boosts_entity_with_high_corruption() -> void:
	var catch = CatchData.new()
	catch.catch_type = CatchData.CatchType.ENTITY
	var weight_low = CatchPool._calculate_weight(catch, 0.0, [], false)
	var weight_high = CatchPool._calculate_weight(catch, 100.0, [], false)
	assert_gt(weight_high, weight_low)

func test_calculate_weight_halves_for_duplicate_type() -> void:
	var catch = CatchData.new()
	catch.catch_type = CatchData.CatchType.DATA
	var weight_fresh = CatchPool._calculate_weight(catch, 0.0, [], false)
	var weight_seen = CatchPool._calculate_weight(catch, 0.0, [CatchData.CatchType.DATA], false)
	assert_eq(weight_seen, weight_fresh * 0.5)

func test_generate_layer_shallows_has_3_slots() -> void:
	var layer = CatchPool.generate_layer("district7", CatchData.Layer.SHALLOWS)
	assert_eq(layer.size(), 3)
	for c in layer:
		assert_eq(c.layer, CatchData.Layer.SHALLOWS)

func test_generate_layer_mid_has_3_slots() -> void:
	var layer = CatchPool.generate_layer("district7", CatchData.Layer.MID)
	assert_eq(layer.size(), 3)
	for c in layer:
		assert_eq(c.layer, CatchData.Layer.MID)

func test_generate_layer_deep_has_2_slots() -> void:
	var layer = CatchPool.generate_layer("axiom", CatchData.Layer.DEEP)
	assert_eq(layer.size(), 2)
	for c in layer:
		assert_eq(c.layer, CatchData.Layer.DEEP)

func test_generate_layer_accepts_corruption() -> void:
	var layer = CatchPool.generate_layer("district7", CatchData.Layer.SHALLOWS, 80.0)
	assert_eq(layer.size(), 3)

func test_entity_bias_boosts_entity_weight() -> void:
	var catch = CatchData.new()
	catch.catch_type = CatchData.CatchType.ENTITY
	var plain = CatchPool._calculate_weight(catch, 0.0, [], false)
	var biased = CatchPool._calculate_weight(catch, 0.0, [], true)
	assert_eq(biased, plain * 1.5)

func test_entity_bias_ignores_non_entities() -> void:
	var catch = CatchData.new()
	catch.catch_type = CatchData.CatchType.DATA
	assert_eq(CatchPool._calculate_weight(catch, 0.0, [], true),
		CatchPool._calculate_weight(catch, 0.0, [], false))

func test_draw_replacement_returns_catch_from_layer() -> void:
	var c = CatchPool.draw_replacement("district7", CatchData.Layer.SHALLOWS, 0.0)
	assert_not_null(c)
	assert_eq(c.layer, CatchData.Layer.SHALLOWS)

func test_draw_replacement_damps_entities_and_hostiles() -> void:
	var risky := 0
	for i in 100:
		var c = CatchPool.draw_replacement("district7", CatchData.Layer.MID, 0.0)
		if c.catch_type == CatchData.CatchType.ENTITY or c.behavior == CatchData.BehaviorType.AGGRESSIVE:
			risky += 1
	assert_lt(risky, 50, "entity/aggressive draws weighted x0.2 should be a clear minority")
