# scenes/barge_hub/panels/terminal_panel.gd
class_name TerminalPanel
extends PanelContainer

# btop-style box: 1px border with the panel title floating on the top border line.
# Style is applied in _init (not _ready) so subclasses don't need super._ready().

@export var title: String = "":
	set(value):
		title = value
		queue_redraw()

@export var active: bool = false:
	set(value):
		active = value
		_apply_style()
		queue_redraw()

func _init() -> void:
	_apply_style()

func _apply_style() -> void:
	add_theme_stylebox_override("panel", DeckStyle.panel_style(active))

# Interactive panels override this to report focusable controls, in focus order.
func focus_targets() -> Array[Control]:
	return []

func _draw() -> void:
	if title.is_empty():
		return
	var font := get_theme_font("font", "Label")
	var fsize := DeckStyle.SIZE_BODY
	var text_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var x := 14.0
	# Mask the border line behind the title, then draw it overhanging the top edge.
	draw_rect(Rect2(x - 4.0, -text_size.y / 2.0, text_size.x + 8.0, text_size.y), DeckStyle.BG)
	draw_string(font, Vector2(x, -text_size.y / 2.0 + font.get_ascent(fsize)), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, DeckStyle.GREEN)
