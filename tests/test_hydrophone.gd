extends GutTest

func test_pool_clean_at_high_signal() -> void:
	# corruption 0 == SIG 100% == clean tier
	assert_eq(HydrophonePanel.tier_for(0.0), 0)
	assert_eq(HydrophonePanel.tier_for(29.0), 0)

func test_pool_noisy_mid() -> void:
	assert_eq(HydrophonePanel.tier_for(30.0), 1)
	assert_eq(HydrophonePanel.tier_for(69.0), 1)

func test_pool_whispers_high_corruption() -> void:
	assert_eq(HydrophonePanel.tier_for(70.0), 2)
	assert_eq(HydrophonePanel.tier_for(100.0), 2)

func test_each_tier_has_lines() -> void:
	for t in [0, 1, 2]:
		assert_gt(HydrophonePanel.LINES[t].size(), 0, "tier %d has lines" % t)
