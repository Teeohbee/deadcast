extends GutTest

func test_format_line_basic() -> void:
	var line := DiveStatusStrip.format_line(42, 80, 1450, 22.0, "deep_pulse x1")
	assert_eq(line, "T 42/80  ·  HAUL 1450cr  ·  SIG 78%  ·  LURE deep_pulse x1")

func test_format_line_full_signal_no_lure() -> void:
	var line := DiveStatusStrip.format_line(0, 80, 0, 0.0, "—")
	assert_eq(line, "T 0/80  ·  HAUL 0cr  ·  SIG 100%  ·  LURE —")
