# scenes/ui/Zone3Footer.gd
extends Control

const _TABS: Array[Dictionary] = [
	{"id": "deck",     "label": "DECK"},
	{"id": "workshop", "label": "WORKSHOP"},
	{"id": "decrypt",  "label": "DECRYPT"},
	{"id": "bunk",     "label": "BUNK"},
	{"id": "relay",    "label": "RELAY"},
	{"id": "vendors",  "label": "VENDORS"},
]

@onready var tab_row: HBoxContainer = $VBoxContainer/TabMargin/TabRow
@onready var sep_label: Label = $VBoxContainer/SepLabel

var _tab_buttons: Array[Button] = []
# The divider before each tab (null for the first), hidden with its tab.
var _dividers: Array[Label] = []
var _prev_hint: DeckPromptRow
var _next_hint: DeckPromptRow
# What the pad does here, right-aligned after the tabs.
var _legend: HBoxContainer

func _ready() -> void:
	DeckStyle.apply_label(sep_label, DeckStyle.BORDER)

	_prev_hint = DeckPromptRow.new("prev", "<", DeckStyle.TEXT, DeckStyle.SIZE_BODY, true)
	tab_row.add_child(_prev_hint)

	for i in _TABS.size():
		var tab := _TABS[i]
		var sep: Label = null
		if i > 0:
			# Diegetic terminal column divider between menu entries.
			sep = Label.new()
			sep.text = "│"
			DeckStyle.apply_label(sep, DeckStyle.DIM, DeckStyle.SIZE_BODY)
			tab_row.add_child(sep)
		_dividers.append(sep)
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		DeckStyle.apply_function_key(btn)
		btn.add_theme_font_size_override("font_size", DeckStyle.SIZE_BODY)
		btn.text = tab["label"]
		var id: String = tab["id"]
		btn.pressed.connect(func() -> void: UIController.navigate_to(id))
		tab_row.add_child(btn)
		_tab_buttons.append(btn)

	_next_hint = DeckPromptRow.new("next", ">", DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	tab_row.add_child(_next_hint)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.add_child(spacer)
	_legend = HBoxContainer.new()
	_legend.add_theme_constant_override("separation", 18)
	tab_row.add_child(_legend)

	UIController.screen_changed.connect(_on_screen_changed)
	_refresh_unlocked_tabs()

# Locked tabs (see Unlocks) are hidden along with the divider before them.
# DECK is always open and first, so a hidden tab always has a divider to drop.
func _refresh_unlocked_tabs() -> void:
	for i in _tab_buttons.size():
		var open := Unlocks.is_tab_open(_TABS[i]["id"])
		_tab_buttons[i].visible = open
		if _dividers[i] != null:
			_dividers[i].visible = open

func _on_screen_changed(id: String) -> void:
	visible = _TABS.any(func(t: Dictionary) -> bool: return t["id"] == id)
	_refresh_unlocked_tabs()
	_render_legend(UIController.legend())

	for i in _tab_buttons.size():
		var btn: Button = _tab_buttons[i]
		var tab_id: String = _TABS[i]["id"]
		var base_label: String = _TABS[i]["label"]

		if tab_id in UIController.fresh_tabs:
			btn.text = base_label + " NEW"
			btn.add_theme_color_override("font_color", DeckStyle.AMBER)
		elif tab_id == "relay" and GameState.relay_has_unread():
			btn.text = base_label + " !"
			btn.add_theme_color_override("font_color", DeckStyle.AMBER)
		elif tab_id == id:
			btn.text = base_label
			btn.add_theme_color_override("font_color", DeckStyle.GREEN)
		else:
			btn.text = base_label
			btn.add_theme_color_override("font_color", DeckStyle.DIM)

func _render_legend(pairs: Array) -> void:
	for child in _legend.get_children():
		_legend.remove_child(child)
		child.queue_free()
	for pair in pairs:
		_legend.add_child(DeckPromptRow.new(pair[0], pair[1], DeckStyle.DIM, DeckStyle.SIZE_AMBIENT))
