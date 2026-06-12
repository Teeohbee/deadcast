extends GutTest

func test_depth_track_basic() -> void:
	# 3 shallows + 3 mid, currently on slot index 1 (0-based), nothing revealed
	var track := DiveHUD.format_depth_track([3, 3], 1, {})
	assert_eq(track, "DEPTH  [✓][▶][?] ── [?][?][?]")

func test_depth_track_first_slot() -> void:
	var track := DiveHUD.format_depth_track([3], 0, {})
	assert_eq(track, "DEPTH  [▶][?][?]")

func test_depth_track_revealed_markers() -> void:
	var track := DiveHUD.format_depth_track([3], 0, {1: "D", 2: "!"})
	assert_eq(track, "DEPTH  [▶][D][!]")

func test_depth_track_all_resolved() -> void:
	var track := DiveHUD.format_depth_track([3], 3, {})
	assert_eq(track, "DEPTH  [✓][✓][✓]")

func test_status_line() -> void:
	var status := DiveHUD.format_status(1450, 22.0, "deep_pulse x1")
	assert_eq(status, "HAUL 1450cr  ·  SIG 78%  ·  LURE deep_pulse x1")

func test_tension_label() -> void:
	assert_eq(DiveHUD.format_tension(42, 80), "T  42/80")
