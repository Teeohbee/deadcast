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
var _action_hint: Label = null

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_label(sep_label, UIStyle.COL_DIM)

	for tab in _TABS:
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)
		btn.text = tab["label"]
		var id: String = tab["id"]
		btn.pressed.connect(func() -> void: UIController.navigate_to(id))
		tab_row.add_child(btn)
		_tab_buttons.append(btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.add_child(spacer)

	_action_hint = Label.new()
	_action_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UIStyle.apply_label(_action_hint, UIStyle.COL_DIM)
	tab_row.add_child(_action_hint)

	UIController.screen_changed.connect(_on_screen_changed)
	UIController.dive_state_changed.connect(_on_dive_state_changed)

func _on_screen_changed(id: String) -> void:
	for i in _tab_buttons.size():
		var btn: Button = _tab_buttons[i]
		var tab_id: String = _TABS[i]["id"]
		var base_label: String = _TABS[i]["label"]

		if tab_id == "marta" and GameState.has_new_marta_beat():
			btn.text = base_label + " !"
			btn.add_theme_color_override("font_color", UIStyle.COL_DEBT)
		elif tab_id == id:
			btn.text = base_label
			btn.add_theme_color_override("font_color", UIStyle.COL_ACCENT)
		else:
			btn.text = base_label
			btn.add_theme_color_override("font_color", UIStyle.COL_DIM)

	_action_hint.text = "[ENTER] DIVE" if id == "deck" else ""

func _on_dive_state_changed(active: bool) -> void:
	visible = not active
