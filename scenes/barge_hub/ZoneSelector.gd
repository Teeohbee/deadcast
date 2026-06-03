# scenes/barge_hub/ZoneSelector.gd
extends VBoxContainer

const ZONE_IDS: Array[String] = ["district7", "exchange", "axiom"]
const _FOOTER := "└────────────────────────────────────────────────────────────"

var _buttons: Dictionary = {}

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_label($ZoneLabel, UIStyle.COL_DIM)

	for zone_id in ZONE_IDS:
		var zone_data: ZoneData = load("res://resources/zones/%s.tres" % zone_id)

		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIStyle.apply_button(btn)
		btn.pressed.connect(func() -> void: GameState.select_zone(zone_id))
		add_child(btn)
		_buttons[zone_id] = btn

		var desc := Label.new()
		UIStyle.apply_label(desc, UIStyle.COL_DIM)
		desc.text = "│  " + zone_data.description.to_lower()
		add_child(desc)

	for i in ZONE_IDS.size():
		var btn: Button = _buttons[ZONE_IDS[i]]
		if i > 0:
			btn.focus_neighbor_top = btn.get_path_to(_buttons[ZONE_IDS[i - 1]])
		if i < ZONE_IDS.size() - 1:
			btn.focus_neighbor_bottom = btn.get_path_to(_buttons[ZONE_IDS[i + 1]])

	var footer := Label.new()
	footer.text = _FOOTER
	UIStyle.apply_label(footer, UIStyle.COL_DIM)
	add_child(footer)

	EventBus.zone_changed.connect(_on_zone_changed)
	_on_zone_changed(GameState.selected_zone)

func _on_zone_changed(zone_id: String) -> void:
	for id in _buttons:
		var btn: Button = _buttons[id]
		btn.text = ("│  > " if zone_id == id else "│    ") + _zone_display_name(id)

func _zone_display_name(zone_id: String) -> String:
	match zone_id:
		"district7": return "district 7 ruins"
		"exchange":  return "the voss exchange"
		"axiom":     return "axiom tower sub-basement"
	return zone_id
