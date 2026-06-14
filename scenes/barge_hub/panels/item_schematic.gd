# scenes/barge_hub/panels/item_schematic.gd
extends TerminalPanel
class_name ItemSchematic

# Right-rail panel for the vendor screen: a blueprint of whatever stock item the
# operator is hovering, with a caption. Folds the WireframeView into a titled box.

var _view: WireframeView
var _caption: Label
var _description: Label

func _ready() -> void:
	title = "schematic"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 150)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	_view = WireframeView.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.custom_minimum_size = Vector2(0, 110)
	root.add_child(_view)

	_caption = Label.new()
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DeckStyle.apply_label(_caption, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_caption)

	_description = Label.new()
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DeckStyle.apply_label(_description, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_description)

	clear()

func show_item(kind: String, item_variant: int, item_name: String, description: String = "") -> void:
	_view.set_item(kind, item_variant)
	_caption.text = item_name.to_lower()
	_description.text = description.to_lower()

func clear() -> void:
	_view.set_item("", 0)
	_caption.text = "hover stock to inspect"
	_description.text = ""
