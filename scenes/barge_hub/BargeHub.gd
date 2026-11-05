# scenes/barge_hub/BargeHub.gd
extends Control

@onready var _zone_panel: Control = $Margin/VBox/MainGrid/LeftColumn/ZonePanel
@onready var _rig_panel: Control = $Margin/VBox/MainGrid/RightColumn/RigPanel
@onready var _freezer_panel: Control = $Margin/VBox/MainGrid/RightColumn/FreezerPanel
@onready var _ledger_panel: Control = $Margin/VBox/MainGrid/RightColumn/LedgerPanel
@onready var _banner: PanelContainer = $Margin/VBox/DiveBanner
@onready var _banner_caption: Label = $Margin/VBox/DiveBanner/BannerRow/BannerCaption
@onready var _banner_zone: Label = $Margin/VBox/DiveBanner/BannerRow/BannerZone
@onready var _dive_button: Button = $Margin/VBox/DiveBanner/BannerRow/DiveButton

# What Unlocks had open when the deck was last shown, to announce what's new.
# Taken fresh each session, so continuing a save never replays old unlocks.
var _known_features: Array[String] = []

func _ready() -> void:
	self.theme = DeckStyle.get_theme()
	_known_features = Unlocks.open_features()

	var banner_sb := DeckStyle.panel_style(false)
	banner_sb.bg_color = Color("#09110d")
	banner_sb.border_color = Color("#14291c")
	_banner.add_theme_stylebox_override("panel", banner_sb)
	DeckStyle.apply_label(_banner_caption, DeckStyle.DIM)
	DeckStyle.apply_label(_banner_zone, Color.WHITE, DeckStyle.SIZE_VALUE)
	DeckStyle.apply_action_button(_dive_button)
	_dive_button.focus_mode = Control.FOCUS_ALL
	_dive_button.pressed.connect(_on_dive_pressed)
	_zone_panel.zone_confirmed.connect(func(_id: String) -> void: _dive_button.grab_focus())
	DeckPrompt.bind(_dive_button, "accept", "INITIATE DIVE")
	InputGlyphs.device_changed.connect(_on_device_changed)

	EventBus.zone_changed.connect(_on_zone_changed)
	_on_zone_changed(GameState.selected_zone)

	await get_tree().process_frame
	_wire_focus_graph()
	_focus_default()

func on_screen_shown() -> void:
	# FreezerPanel and RigPanel don't listen to EventBus, so refresh them on
	# reveal to reflect any dive/vendor changes; LedgerPanel is refreshed too
	# for robustness. Re-grab controller focus on the selected zone card.
	_ledger_panel.refresh()
	_freezer_panel.refresh()
	_rig_panel.refresh()
	_announce_new_unlocks()
	_zone_panel.refresh_unlocked()
	_wire_focus_graph()
	_on_zone_changed(GameState.selected_zone)
	_focus_default()

# With one zone open there is nothing to pick, so land on the dive itself.
func _focus_default() -> void:
	if _zone_panel.open_zone_count() <= 1:
		_dive_button.grab_focus()
	else:
		_zone_panel.focus_selected()

func _announce_new_unlocks() -> void:
	var open_now := Unlocks.open_features()
	var opened := Unlocks.newly_opened(_known_features, open_now)
	_known_features = open_now
	for feature in opened:
		var line := Unlocks.announcement_for(feature)
		if line != "":
			EventBus.deck_log.emit(line)
	UIController.mark_fresh_tabs(opened)

func _wire_focus_graph() -> void:
	var left: Array[Control] = _zone_panel.focus_targets()
	var right: Array[Control] = _rig_panel.focus_targets() + _freezer_panel.focus_targets()
	if left.is_empty():
		return
	if right.is_empty():
		# Nothing focusable on the right yet (the freezer is still locked):
		# the zone cards lead straight down to the dive button and back.
		for card in left:
			card.focus_neighbor_right = NodePath()
		DeckNav.link(left[left.size() - 1], _dive_button, SIDE_BOTTOM)
		DeckNav.link(_dive_button, left[left.size() - 1], SIDE_TOP)
		return
	var first_right: Control = right[0]
	# Left column: each card reaches the right column; the last descends to dive.
	for i in left.size():
		DeckNav.link(left[i], first_right, SIDE_RIGHT)
		if i == left.size() - 1:
			DeckNav.link(left[i], _dive_button, SIDE_BOTTOM)
	# Right column: vertical chain, back to left, last descends to dive.
	DeckNav.chain_vertical(right)
	for node in right:
		DeckNav.link(node, left[0], SIDE_LEFT)
	DeckNav.link(right[right.size() - 1], _dive_button, SIDE_BOTTOM)
	# Dive button climbs back into the right column.
	DeckNav.link(_dive_button, right[right.size() - 1], SIDE_TOP)

func _on_zone_changed(zone_id: String) -> void:
	var zone: ZoneData = load("res://resources/zones/%s.tres" % zone_id)
	_banner_zone.text = zone.display_name.to_upper() if zone else zone_id.to_upper()

func _on_device_changed(mode: int) -> void:
	var line := "INPUT: gamepad peripheral linked." if mode == InputGlyphs.Mode.PAD \
		else "INPUT: keyboard relay active."
	EventBus.deck_log.emit(line)

func _on_dive_pressed() -> void:
	UIController.navigate_to("dive")
