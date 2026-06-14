extends GutTest

func test_border_clean_is_base() -> void:
	# corruption 0 -> fully blended toward base BORDER (no rot)
	assert_eq(RailBloom.border_for(0.0), DeckStyle.BORDER)

func test_border_max_is_red() -> void:
	# corruption 100 -> fully rotted to RED
	assert_eq(RailBloom.border_for(100.0), DeckStyle.RED)

func test_border_clamps_over_max() -> void:
	assert_eq(RailBloom.border_for(150.0), DeckStyle.RED)

func test_border_ramps_toward_red() -> void:
	# the rot is monotonic: more corruption -> more red in the border
	assert_gt(RailBloom.border_for(80.0).r, RailBloom.border_for(20.0).r)
	assert_gt(RailBloom.border_for(50.0).r, RailBloom.border_for(10.0).r)
