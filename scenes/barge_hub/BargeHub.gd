# scenes/barge_hub/BargeHub.gd
extends Control

@onready var _zone_panel: Control = $Margin/VBox/MainGrid/LeftColumn/ZonePanel
@onready var _rig_panel: Control = $Margin/VBox/MainGrid/RightColumn/RigPanel
@onready var _freezer_panel: Control = $Margin/VBox/MainGrid/RightColumn/FreezerPanel
@onready var _banner: PanelContainer = $Margin/VBox/DiveBanner
@onready var _banner_caption: Label = $Margin/VBox/DiveBanner/BannerRow/BannerCaption
@onready var _banner_zone: Label = $Margin/VBox/DiveBanner/BannerRow/BannerZone
@onready var _dive_button: Button = $Margin/VBox/DiveBanner/BannerRow/DiveButton
@onready var _crt_overlay: ColorRect = $CRTOverlay

func _ready() -> void:
	self.theme = UIStyle.get_theme()

	var crt_mat := (_crt_overlay.material as ShaderMaterial).duplicate() as ShaderMaterial
	if not Settings.crt_enabled:
		crt_mat.set_shader_parameter("scan_alpha", 0.0)
	_crt_overlay.material = crt_mat

	var banner_sb := DeckStyle.panel_style(false)
	banner_sb.bg_color = Color("#09110d")
	banner_sb.border_color = Color("#14291c")
	_banner.add_theme_stylebox_override("panel", banner_sb)
	DeckStyle.apply_label(_banner_caption, DeckStyle.DIM)
	DeckStyle.apply_label(_banner_zone, Color.WHITE, DeckStyle.SIZE_VALUE)
	DeckStyle.apply_action_button(_dive_button)
	_dive_button.focus_mode = Control.FOCUS_ALL
	_dive_button.pressed.connect(_on_dive_pressed)

	EventBus.zone_changed.connect(_on_zone_changed)
	_on_zone_changed(GameState.selected_zone)

	await get_tree().process_frame
	_zone_panel.focus_selected()
	_wire_focus_graph()

func _wire_focus_graph() -> void:
	var left: Array[Control] = _zone_panel.focus_targets()
	var right: Array[Control] = _rig_panel.focus_targets() + _freezer_panel.focus_targets()
	if left.is_empty() or right.is_empty():
		return
	var first_right: Control = right[0]
	# Left column -> right column, and bottom of left -> dive.
	for i in left.size():
		var card: Control = left[i]
		card.focus_neighbor_right = card.get_path_to(first_right)
		if i == left.size() - 1:
			card.focus_neighbor_bottom = card.get_path_to(_dive_button)
	# Right column vertical chain + back to left + bottom -> dive.
	for i in right.size():
		var node: Control = right[i]
		node.focus_neighbor_left = node.get_path_to(left[0])
		if i < right.size() - 1:
			node.focus_neighbor_bottom = node.get_path_to(right[i + 1])
		else:
			node.focus_neighbor_bottom = node.get_path_to(_dive_button)
		if i > 0:
			node.focus_neighbor_top = node.get_path_to(right[i - 1])
	# Dive back up into the right column.
	_dive_button.focus_neighbor_top = _dive_button.get_path_to(right[right.size() - 1])

func _on_zone_changed(zone_id: String) -> void:
	var zone: ZoneData = load("res://resources/zones/%s.tres" % zone_id)
	_banner_zone.text = zone.display_name.to_upper() if zone else zone_id.to_upper()

func _on_dive_pressed() -> void:
	UIController.navigate_to("dive")
