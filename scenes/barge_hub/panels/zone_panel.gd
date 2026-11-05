# scenes/barge_hub/panels/zone_panel.gd
extends TerminalPanel

# Pressing a card both selects the zone and confirms it: the deck moves focus
# on to INITIATE DIVE, so picking a zone is always followed by a clear next step.
signal zone_confirmed(zone_id: String)

const ZONE_IDS: Array[String] = ["district7", "exchange", "axiom"]

var _cards: Dictionary = {}       # zone_id -> Button
var _indicators: Dictionary = {}  # zone_id -> Label
var _names: Dictionary = {}       # zone_id -> Label
var _nav_hint: Label
var _hosts_label: Label

func _ready() -> void:
	title = "available_zones"
	active = true
	_build()
	EventBus.zone_changed.connect(_on_zone_changed)
	_on_zone_changed(GameState.selected_zone)

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	var header := HBoxContainer.new()
	_nav_hint = Label.new()
	_nav_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DeckStyle.apply_label(_nav_hint, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	header.add_child(_nav_hint)
	InputGlyphs.device_changed.connect(_refresh_nav_hint)
	_refresh_nav_hint()
	_hosts_label = Label.new()
	DeckStyle.apply_label(_hosts_label, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	header.add_child(_hosts_label)
	root.add_child(header)

	for zone_id in ZONE_IDS:
		var zone: ZoneData = load("res://resources/zones/%s.tres" % zone_id)
		root.add_child(_build_card(zone_id, zone))

	refresh_unlocked()

# Show only the zones Unlocks has opened, chain focus through the visible
# cards, and move the selection off a zone that isn't open yet.
func refresh_unlocked() -> void:
	var open_cards: Array[Control] = []
	for zone_id in ZONE_IDS:
		var open := Unlocks.is_zone_open(zone_id)
		_cards[zone_id].visible = open
		if open:
			open_cards.append(_cards[zone_id])
	for i in open_cards.size():
		var btn: Button = open_cards[i]
		btn.focus_neighbor_top = btn.get_path_to(open_cards[i - 1]) if i > 0 else NodePath()
		btn.focus_neighbor_bottom = btn.get_path_to(open_cards[i + 1]) \
			if i < open_cards.size() - 1 else NodePath()
	_hosts_label.text = "%d LOCAL HOST%s CONNECTED" % [
		open_cards.size(), "" if open_cards.size() == 1 else "S"]
	# Nothing to choose between with one host, so don't ask the player to.
	_nav_hint.visible = open_cards.size() > 1
	if not Unlocks.is_zone_open(GameState.selected_zone):
		GameState.select_zone(ZONE_IDS[0])

func _build_card(zone_id: String, zone: ZoneData) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_ALL
	# Zones with an interference line need a fourth text row; size to fit it so
	# the content does not overflow the card border.
	btn.custom_minimum_size = Vector2(0, 88 if zone.zone_interference > 0 else 66)
	btn.pressed.connect(_on_card_pressed.bind(zone_id))
	DeckStyle.apply_card(btn, false)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(left)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(name_row)

	var indicator := Label.new()
	indicator.text = ">"
	indicator.modulate.a = 0.0
	DeckStyle.apply_label(indicator, DeckStyle.GREEN, DeckStyle.SIZE_VALUE)
	name_row.add_child(indicator)
	_indicators[zone_id] = indicator

	var name_label := Label.new()
	name_label.text = zone.display_name.to_lower()
	DeckStyle.apply_label(name_label, DeckStyle.TEXT, DeckStyle.SIZE_VALUE)
	name_row.add_child(name_label)
	_names[zone_id] = name_label

	name_row.add_child(DeckStyle.make_chip(zone.tag_label, zone.tag_tier, DeckStyle.SIZE_BODY))

	var desc := Label.new()
	desc.text = zone.description.to_lower()
	DeckStyle.apply_label(desc, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	left.add_child(desc)

	if zone.zone_interference > 0:
		var interference := Label.new()
		interference.text = "interference: +%dT per contact" % zone.zone_interference
		DeckStyle.apply_label(interference, DeckStyle.AMBER, DeckStyle.SIZE_BODY)
		left.add_child(interference)

	var stats := VBoxContainer.new()
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var density := Label.new()
	density.text = "DENSITY: %s" % zone.density
	density.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	DeckStyle.apply_label(density, DeckStyle.tier_color(zone.tag_tier), DeckStyle.SIZE_BODY)
	stats.add_child(density)
	var threat := Label.new()
	threat.text = "THREAT: %s" % zone.threat
	threat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	DeckStyle.apply_label(threat, DeckStyle.tier_color(zone.tag_tier), DeckStyle.SIZE_BODY)
	stats.add_child(threat)
	row.add_child(stats)

	_cards[zone_id] = btn
	return btn

func _on_card_pressed(zone_id: String) -> void:
	GameState.select_zone(zone_id)
	zone_confirmed.emit(zone_id)

func open_zone_count() -> int:
	return focus_targets().size()

func _on_zone_changed(zone_id: String) -> void:
	for id in _cards:
		var selected: bool = id == zone_id
		DeckStyle.apply_card(_cards[id], selected)
		_indicators[id].modulate.a = 1.0 if selected else 0.0
		(_names[id] as Label).add_theme_color_override(
			"font_color", DeckStyle.GREEN if selected else DeckStyle.TEXT)

func _refresh_nav_hint(_mode: int = 0) -> void:
	_nav_hint.text = "%s SELECT DESTINATION" % InputGlyphs.glyph("navigate")

func focus_selected() -> void:
	var btn: Button = _cards.get(GameState.selected_zone)
	if btn:
		btn.grab_focus()

func focus_targets() -> Array[Control]:
	var out: Array[Control] = []
	for id in ZONE_IDS:
		if _cards[id].visible:
			out.append(_cards[id])
	return out
