extends GutTest

func test_bpm_scales_with_load() -> void:
	assert_eq(BiosignPanel.bpm_for(0, 80), 60)
	assert_eq(BiosignPanel.bpm_for(80, 80), 130)
	assert_eq(BiosignPanel.bpm_for(40, 80), 95)

func test_bpm_clamps_over_max() -> void:
	assert_eq(BiosignPanel.bpm_for(120, 80), 130)

func test_state_thresholds() -> void:
	assert_eq(BiosignPanel.load_state(0.0), "NOMINAL")
	assert_eq(BiosignPanel.load_state(0.5), "NOMINAL")
	assert_eq(BiosignPanel.load_state(0.69), "NOMINAL")   # just below ELEVATED
	assert_eq(BiosignPanel.load_state(0.7), "ELEVATED")
	assert_eq(BiosignPanel.load_state(0.84), "ELEVATED")  # just below CRITICAL
	assert_eq(BiosignPanel.load_state(0.85), "CRITICAL")  # exact boundary
	assert_eq(BiosignPanel.load_state(0.9), "CRITICAL")
