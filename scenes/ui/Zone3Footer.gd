# scenes/ui/Zone3Footer.gd
extends Control

const _TABS: Array[Dictionary] = [
	{"id": "deck",     "label": "DECK"},
	{"id": "workshop", "label": "WORKSHOP"},
	{"id": "decrypt",  "label": "DECRYPT"},
	{"id": "bunk",     "label": "BUNK"},
	{"id": "marta",    "label": "MARTA"},
	{"id": "vendors",  "label": "VENDORS"},
]

@onready var tab_row: HBoxContainer = $VBoxContainer/TabRow
@onready var sep_label: Label = $VBoxContainer/SepLabel

var _tab_buttons: Array[Button] = []
var _prev_hint: Label
var _next_hint: Label

func _ready() -> void:
	DeckStyle.apply_label(sep_label, DeckStyle.BORDER)

	_prev_hint = Label.new()
	DeckStyle.apply_label(_prev_hint, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	tab_row.add_child(_prev_hint)

	for i in _TABS.size():
		var tab := _TABS[i]
		if i > 0:
			# Diegetic terminal column divider between menu entries.
			var sep := Label.new()
			sep.text = "│"
			DeckStyle.apply_label(sep, DeckStyle.DIM, DeckStyle.SIZE_BODY)
			tab_row.add_child(sep)
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		DeckStyle.apply_function_key(btn)
		btn.add_theme_font_size_override("font_size", DeckStyle.SIZE_BODY)
		btn.text = tab["label"]
		var id: String = tab["id"]
		btn.pressed.connect(func() -> void: UIController.navigate_to(id))
		tab_row.add_child(btn)
		_tab_buttons.append(btn)

	_next_hint = Label.new()
	DeckStyle.apply_label(_next_hint, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	tab_row.add_child(_next_hint)

	UIController.screen_changed.connect(_on_screen_changed)
	InputGlyphs.device_changed.connect(_refresh_hints)
	_refresh_hints()

# Named method so Godot auto-disconnects when this node frees.
# Accepts the optional mode arg the signal passes; defaulted for direct calls.
func _refresh_hints(_mode: int = 0) -> void:
	_prev_hint.text = "< %s " % InputGlyphs.glyph("prev")
	_next_hint.text = " %s >" % InputGlyphs.glyph("next")

func _on_screen_changed(id: String) -> void:
	visible = _TABS.any(func(t: Dictionary) -> bool: return t["id"] == id)

	for i in _tab_buttons.size():
		var btn: Button = _tab_buttons[i]
		var tab_id: String = _TABS[i]["id"]
		var base_label: String = _TABS[i]["label"]

		if tab_id == "marta" and GameState.has_new_marta_beat():
			btn.text = base_label + " !"
			btn.add_theme_color_override("font_color", DeckStyle.AMBER)
		elif tab_id == id:
			btn.text = base_label
			btn.add_theme_color_override("font_color", DeckStyle.GREEN)
		else:
			btn.text = base_label
			btn.add_theme_color_override("font_color", DeckStyle.DIM)
