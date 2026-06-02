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
    var weight_low = CatchPool._calculate_weight(catch, 0.0, [], LureData.LureEffect.NONE)
    var weight_high = CatchPool._calculate_weight(catch, 100.0, [], LureData.LureEffect.NONE)
    assert_gt(weight_high, weight_low)

func test_calculate_weight_halves_for_duplicate_type() -> void:
    var catch = CatchData.new()
    catch.catch_type = CatchData.CatchType.DATA
    var weight_fresh = CatchPool._calculate_weight(catch, 0.0, [], LureData.LureEffect.NONE)
    var weight_seen = CatchPool._calculate_weight(catch, 0.0, [CatchData.CatchType.DATA], LureData.LureEffect.NONE)
    assert_eq(weight_seen, weight_fresh * 0.5)

func test_scrap_rod_column_has_shallows_and_mid_only() -> void:
    pending("Needs Task 13 content")

func test_monocarbon_rod_column_has_all_layers() -> void:
    pending("Needs Task 13 content")

func test_column_has_correct_slot_counts_for_full_depth() -> void:
    pending("Needs Task 13 content")

func test_column_has_correct_slot_counts_for_mid_depth() -> void:
    pending("Needs Task 13 content")

func test_column_has_shallows_only_for_shallow_rod() -> void:
    pending("Needs Task 13 content")

func test_ghost_bait_boosts_entity_weight_vs_none() -> void:
    var entity_catch = CatchData.new()
    entity_catch.catch_type = CatchData.CatchType.ENTITY
    var weight_none = CatchPool._calculate_weight(entity_catch, 0.0, [], LureData.LureEffect.NONE)
    var weight_ghost = CatchPool._calculate_weight(entity_catch, 0.0, [], LureData.LureEffect.GHOST_BAIT)
    assert_gt(weight_ghost, weight_none)

func test_decoy_reduces_entity_weight() -> void:
    var entity_catch = CatchData.new()
    entity_catch.catch_type = CatchData.CatchType.ENTITY
    var weight_none = CatchPool._calculate_weight(entity_catch, 0.0, [], LureData.LureEffect.NONE)
    var weight_decoy = CatchPool._calculate_weight(entity_catch, 0.0, [], LureData.LureEffect.DECOY)
    assert_lt(weight_decoy, weight_none)
