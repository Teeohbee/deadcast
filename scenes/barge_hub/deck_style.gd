# scenes/barge_hub/deck_style.gd
class_name DeckStyle

# Prototype palette (see planning/prototype.html)
const BG       := Color("#050806")  # screen background
const PANEL_BG := Color("#070c09")  # panel fill
const BORDER   := Color("#16251d")  # 1px borders, separators
const GREEN    := Color("#22c55e")  # active/primary
const DIM      := Color("#4a6b57")  # secondary text
const AMBER    := Color("#f59e0b")  # medium risk
const RED      := Color("#ef4444")  # debt/critical
const TEXT     := Color("#d1d5db")  # bright value text
const SKY      := Color("#38bdf8")  # depth/thermocline accents

const FONT_SIZE_TINY  := 10
const FONT_SIZE_SMALL := 11
const FONT_SIZE_BODY  := 13

static func panel_style(active: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = GREEN if active else BORDER
	sb.set_border_width_all(1)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 12
	sb.content_margin_bottom = 8
	return sb

static func tier_color(tier: int) -> Color:
	match tier:
		1: return AMBER
		2: return RED
		_: return GREEN

static func apply_label(label: Label, color: Color, font_size: int = FONT_SIZE_SMALL) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)

static func make_chip(text: String, tier: int) -> Label:
	var c := tier_color(tier)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(c.r, c.g, c.b, 0.10)
	sb.border_color = Color(c.r, c.g, c.b, 0.45)
	sb.set_border_width_all(1)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	var chip := Label.new()
	chip.text = text
	chip.add_theme_stylebox_override("normal", sb)
	apply_label(chip, c, 9)
	return chip

static func apply_action_button(btn: Button, color: Color = GREEN) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color.r, color.g, color.b, 0.08)
	normal.border_color = color
	normal.set_border_width_all(1)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 3
	normal.content_margin_bottom = 3
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = TEXT
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", BG)
	btn.add_theme_color_override("font_pressed_color", BG)
	btn.add_theme_color_override("font_focus_color", color)

static func apply_card(btn: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#070e0a") if selected else PANEL_BG
	normal.border_color = GREEN if selected else Color("#1d3226")
	normal.set_border_width_all(1)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = GREEN
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", focus)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("pressed", focus)

static func apply_function_key(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = PANEL_BG
	normal.border_color = BORDER
	normal.set_border_width_all(1)
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = GREEN
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = GREEN
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_hover_color", BG)
	btn.add_theme_color_override("font_pressed_color", BG)
