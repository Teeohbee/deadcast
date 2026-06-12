# scenes/ui/Zone3Footer.gd
extends Control

const _TABS: Array[Dictionary] = [
	{"id": "deck",     "label": "[F1] DECK"},
	{"id": "workshop", "label": "[F2] WORKSHOP"},
	{"id": "decrypt",  "label": "[F3] DECRYPT"},
	{"id": "bunk",     "label": "[F4] BUNK"},
	{"id": "marta",    "label": "[F5] MARTA"},
	{"id": "vendors",  "label": "[F6] VENDORS"},
]

@onready var tab_row: HBoxContainer = $VBoxContainer/TabRow
@onready var sep_label: Label = $VBoxContainer/SepLabel

var _tab_buttons: Array[Button] = []

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	DeckStyle.apply_label(sep_label, DeckStyle.BORDER)

	for tab in _TABS:
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		DeckStyle.apply_function_key(btn)
		btn.text = tab["label"]
		var id: String = tab["id"]
		btn.pressed.connect(func() -> void: UIController.navigate_to(id))
		tab_row.add_child(btn)
		_tab_buttons.append(btn)

	UIController.screen_changed.connect(_on_screen_changed)

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

