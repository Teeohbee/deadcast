# scenes/ui/deck_prompt_row.gd
# A device-aware prompt that isn't a button: [icon] CAPTION on a pad, or
# "[KEY] CAPTION" text on a keyboard. trailing puts the glyph after the caption
# ("PRESS [A]", "< [L1]"). The icon is tinted to the caption colour and sized to
# the font, and the row re-renders itself whenever the input device changes.
class_name DeckPromptRow
extends HBoxContainer

var action: String
var caption: String
var trailing: bool
var icon_rect: TextureRect
var label: Label

# Icon edge for a given font size: a touch taller than the cap height so the
# button reads as a keycap next to the text, not a dot.
static func icon_px(font_size: int) -> int:
	return roundi(font_size * 1.4)

func _init(p_action: String = "", p_caption: String = "", color: Color = DeckStyle.TEXT,
		font_size: int = DeckStyle.SIZE_BODY, p_trailing: bool = false) -> void:
	action = p_action
	caption = p_caption
	trailing = p_trailing
	add_theme_constant_override("separation", 6)
	icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label = Label.new()
	add_child(label)
	add_child(icon_rect)
	if not trailing:
		move_child(icon_rect, 0)
	set_color(color)
	set_font_size(font_size)
	refresh()

func _enter_tree() -> void:
	if not InputGlyphs.device_changed.is_connected(refresh):
		InputGlyphs.device_changed.connect(refresh)
	refresh()

func _exit_tree() -> void:
	if InputGlyphs.device_changed.is_connected(refresh):
		InputGlyphs.device_changed.disconnect(refresh)

func set_caption(p_caption: String) -> void:
	caption = p_caption
	refresh()

func set_color(color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	icon_rect.self_modulate = color

func set_font_size(font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	var px := icon_px(font_size)
	icon_rect.custom_minimum_size = Vector2(px, px)

func shows_icon() -> bool:
	return icon_rect.visible

func refresh(_mode: int = 0) -> void:
	var tex := InputGlyphs.icon(action)
	icon_rect.texture = tex
	icon_rect.visible = tex != null
	if tex != null:
		label.text = caption
	else:
		var parts := [caption, InputGlyphs.glyph(action)] if trailing \
			else [InputGlyphs.glyph(action), caption]
		label.text = " ".join(parts.filter(func(p: String) -> bool: return p != ""))
	label.visible = label.text != ""
