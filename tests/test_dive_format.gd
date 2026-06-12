extends GutTest

func test_result_line_all_parts() -> void:
	assert_eq(DiveFormat.result_line(200, 5, 8), ">>> +200cr  ·  +5T  ·  SIG -8%")

func test_result_line_omits_zero_fields() -> void:
	assert_eq(DiveFormat.result_line(300, 0, 0), ">>> +300cr")

func test_result_line_negative_tension() -> void:
	assert_eq(DiveFormat.result_line(0, -10, 0), ">>> -10T")

func test_result_line_no_change() -> void:
	assert_eq(DiveFormat.result_line(0, 0, 0), ">>> no change")
