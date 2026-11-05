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

func test_get_theme_sets_default_text_colours_to_palette() -> void:
	var theme := DeckStyle.get_theme()
	assert_eq(theme.get_color("font_color", "Label"), DeckStyle.TEXT)
	assert_eq(theme.get_color("default_color", "RichTextLabel"), DeckStyle.TEXT)

func test_get_theme_provides_mono_font() -> void:
	var theme := DeckStyle.get_theme()
	assert_not_null(theme.get_font("font", "Label"))
	assert_not_null(theme.get_font("normal_font", "RichTextLabel"))

func test_get_theme_is_cached() -> void:
	assert_same(DeckStyle.get_theme(), DeckStyle.get_theme())


# Pad focus must never look like selection (green), or a focused, selected card
# reads as unfocused. Every focusable deck button shares one bright ring.
func _focus_of(btn: Button) -> StyleBoxFlat:
	return btn.get_theme_stylebox("focus") as StyleBoxFlat

func test_focus_ring_is_bright_and_thicker_on_every_button_style() -> void:
	var card: Button = autofree(Button.new())
	DeckStyle.apply_card(card, true)
	var key: Button = autofree(Button.new())
	DeckStyle.apply_function_key(key)
	var action: Button = autofree(Button.new())
	DeckStyle.apply_action_button(action)
	for btn in [card, key, action]:
		var focus := _focus_of(btn)
		assert_eq(focus.border_color, DeckStyle.TEXT)
		assert_eq(focus.border_width_top, 2)

func test_selected_card_focus_differs_from_its_normal_style() -> void:
	var card: Button = autofree(Button.new())
	DeckStyle.apply_card(card, true)
	var normal := card.get_theme_stylebox("normal") as StyleBoxFlat
	assert_ne(_focus_of(card).border_color, normal.border_color)
