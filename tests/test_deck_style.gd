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
