# autoload/UIStyle.gd
extends Node

const COL_TEXT     := Color("#b0f0b0")
const COL_DIM      := Color("#555555")
const COL_SEP      := Color("#444444")
const COL_DEBT     := Color("#ff8888")
const COL_PRESSURE := Color("#ffaa88")
const COL_ACCENT   := Color("#44aaff")
const COL_COST     := Color("#3a7a3a")
const COL_BORDER   := Color("#2a4a2a")
const COL_WARNING  := Color("#ffff88")
const COL_BG       := Color("#0a0a0a")
const COL_BAR_BG   := Color("#1a1a1a")

var _theme: Theme = null

func get_theme() -> Theme:
	if _theme:
		return _theme
	var font := load("res://fonts/IBMPlexMono-Regular.otf") as FontFile
	_theme = Theme.new()
	_theme.set_font("font", "Label", font)
	_theme.set_font("font", "Button", font)
	_theme.set_font("normal_font", "RichTextLabel", font)
	_theme.set_color("font_color", "Label", COL_TEXT)
	_theme.set_color("default_color", "RichTextLabel", COL_TEXT)
	return _theme

func apply_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = COL_BORDER
	normal.set_border_width_all(1)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#0a1a0a")
	hover.border_color = Color("#3a8a3a")
	hover.set_border_width_all(1)
	hover.content_margin_left = 8
	hover.content_margin_right = 8
	hover.content_margin_top = 4
	hover.content_margin_bottom = 4

	var focus := normal.duplicate()
	focus.border_color = COL_TEXT

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("#0a2a0a")
	pressed.border_color = COL_ACCENT
	pressed.set_border_width_all(1)
	pressed.content_margin_left = 8
	pressed.content_margin_right = 8
	pressed.content_margin_top = 4
	pressed.content_margin_bottom = 4

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_hover_color", COL_TEXT)
	btn.add_theme_color_override("font_focus_color", COL_TEXT)
	btn.add_theme_color_override("font_pressed_color", COL_ACCENT)

func apply_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COL_BG
	style.border_color = COL_BORDER
	style.set_border_width_all(1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

func apply_label(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)

func apply_background(node: Control) -> void:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(bg)
	node.move_child(bg, 0)
