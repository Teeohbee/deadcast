# tests/test_bounce_bars.gd
extends GutTest

func _make() -> BounceBars:
	var b := BounceBars.new()
	add_child_autofree(b)
	return b

func test_default_color_is_sky() -> void:
	assert_eq(_make().bar_color, DeckStyle.SKY)

func test_bar_level_stays_in_range() -> void:
	var b := _make()
	for t in [0.0, 1.3, 4.7, 9.0]:
		for i in BounceBars.BARS:
			var lvl := b.bar_level(i, t)
			assert_between(lvl, 0.0, 1.0)

func test_peaks_initialised_per_bar() -> void:
	assert_eq(_make()._peaks.size(), BounceBars.BARS)
