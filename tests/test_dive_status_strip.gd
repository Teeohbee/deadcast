extends GutTest

func test_format_line_basic() -> void:
	var line := DiveStatusStrip.format_line(1450, "deep_pulse x1")
	assert_eq(line, "HAUL 1450cr  ·  LURE deep_pulse x1")

func test_format_line_empty() -> void:
	var line := DiveStatusStrip.format_line(0, "—")
	assert_eq(line, "HAUL 0cr  ·  LURE —")
