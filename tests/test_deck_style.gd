# tests/test_deck_style.gd
extends GutTest

func test_panel_style_inactive_uses_border_colour() -> void:
	var sb := DeckStyle.panel_style(false)
	assert_eq(sb.border_color, DeckStyle.BORDER)
	assert_eq(sb.bg_color, DeckStyle.PANEL_BG)

func test_panel_style_active_uses_green_border() -> void:
	var sb := DeckStyle.panel_style(true)
	assert_eq(sb.border_color, DeckStyle.GREEN)

func test_tier_colours() -> void:
	assert_eq(DeckStyle.tier_color(0), DeckStyle.GREEN)
	assert_eq(DeckStyle.tier_color(1), DeckStyle.AMBER)
	assert_eq(DeckStyle.tier_color(2), DeckStyle.RED)

func test_chip_label_carries_tier_styling() -> void:
	var chip: Label = autofree(DeckStyle.make_chip("CIVILIAN", 0))
	assert_eq(chip.text, "CIVILIAN")
	assert_eq(chip.get_theme_color("font_color"), DeckStyle.GREEN)
	assert_not_null(chip.get_theme_stylebox("normal"))

func _relative_luminance(c: Color) -> float:
	var ch := [c.r, c.g, c.b]
	for i in 3:
		var v: float = ch[i]
		ch[i] = v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2]

func _contrast(a: Color, b: Color) -> float:
	var la := _relative_luminance(a)
	var lb := _relative_luminance(b)
	var hi: float = max(la, lb)
	var lo: float = min(la, lb)
	return (hi + 0.05) / (lo + 0.05)

func test_size_tiers_are_job_named_and_legible() -> void:
	assert_eq(DeckStyle.SIZE_VALUE, 18)
	assert_eq(DeckStyle.SIZE_BODY, 14)
	assert_eq(DeckStyle.SIZE_AMBIENT, 12)

func test_dim_clears_contrast_floor_on_panel() -> void:
	assert_gt(_contrast(DeckStyle.DIM, DeckStyle.PANEL_BG), 4.5)
