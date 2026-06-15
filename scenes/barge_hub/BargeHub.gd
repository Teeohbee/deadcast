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

func _ready() -> void:
	self.theme = DeckStyle.get_theme()

	var banner_sb := DeckStyle.panel_style(false)
	banner_sb.bg_color = Color("#09110d")
	banner_sb.border_color = Color("#14291c")
	_banner.add_theme_stylebox_override("panel", banner_sb)
	DeckStyle.apply_label(_banner_caption, DeckStyle.DIM)
	DeckStyle.apply_label(_banner_zone, Color.WHITE, DeckStyle.SIZE_VALUE)
	DeckStyle.apply_action_button(_dive_button)
	_dive_button.focus_mode = Control.FOCUS_ALL
	_dive_button.pressed.connect(_on_dive_pressed)
	DeckPrompt.bind(_dive_button, "accept", "INITIATE DIVE")
	InputGlyphs.device_changed.connect(_on_device_changed)

	EventBus.zone_changed.connect(_on_zone_changed)
	_on_zone_changed(GameState.selected_zone)

	await get_tree().process_frame
	_zone_panel.focus_selected()
	_wire_focus_graph()

func on_screen_shown() -> void:
	# FreezerPanel and RigPanel don't listen to EventBus, so refresh them on
	# reveal to reflect any dive/vendor changes; LedgerPanel is refreshed too
	# for robustness. Re-grab controller focus on the selected zone card.
	_ledger_panel.refresh()
	_freezer_panel.refresh()
	_rig_panel.refresh()
	_on_zone_changed(GameState.selected_zone)
	_zone_panel.focus_selected()

func _wire_focus_graph() -> void:
	var left: Array[Control] = _zone_panel.focus_targets()
	var right: Array[Control] = _rig_panel.focus_targets() + _freezer_panel.focus_targets()
	if left.is_empty() or right.is_empty():
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
