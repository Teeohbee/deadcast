extends GutTest

func test_bpm_scales_with_load() -> void:
	assert_eq(BiosignPanel.bpm_for(0, 80), 60)
	assert_eq(BiosignPanel.bpm_for(80, 80), 130)
	assert_eq(BiosignPanel.bpm_for(40, 80), 95)

func test_bpm_clamps_over_max() -> void:
	assert_eq(BiosignPanel.bpm_for(120, 80), 130)

func test_bpm_with_non_positive_max_returns_rest() -> void:
	assert_eq(BiosignPanel.bpm_for(50, 0), 60)
	assert_eq(BiosignPanel.bpm_for(50, -10), 60)

func test_state_thresholds() -> void:
	assert_eq(BiosignPanel.load_state(0.0), "NOMINAL")
	assert_eq(BiosignPanel.load_state(0.5), "NOMINAL")
	assert_eq(BiosignPanel.load_state(0.69), "NOMINAL")   # just below ELEVATED
	assert_eq(BiosignPanel.load_state(0.7), "ELEVATED")
	assert_eq(BiosignPanel.load_state(0.84), "ELEVATED")  # just below CRITICAL
	assert_eq(BiosignPanel.load_state(0.85), "CRITICAL")  # exact boundary
	assert_eq(BiosignPanel.load_state(0.9), "CRITICAL")

func test_bpm_reads_true_below_half_corruption() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for attempt in 20:
		assert_eq(BiosignPanel.displayed_bpm(90, 49.0, rng), 90)

func test_bpm_jitters_within_bounds_at_half_corruption_and_above() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var saw_a_wrong_reading := false
	for attempt in 40:
		var reading := BiosignPanel.displayed_bpm(90, 60.0, rng)
		assert_between(reading, 90 - BiosignPanel.CORRUPT_BPM_JITTER, 90 + BiosignPanel.CORRUPT_BPM_JITTER)
		if reading != 90:
			saw_a_wrong_reading = true
	assert_true(saw_a_wrong_reading, "readout should be unreliable at 50+ corruption")
