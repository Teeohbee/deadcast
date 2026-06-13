# scenes/barge_hub/BargeHub.gd
extends Control

@onready var _zone_panel: Control = $Margin/VBox/MainGrid/LeftColumn/ZonePanel
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

func _on_zone_changed(zone_id: String) -> void:
	var zone: ZoneData = load("res://resources/zones/%s.tres" % zone_id)
	_banner_zone.text = zone.display_name.to_upper() if zone else zone_id.to_upper()

func _on_dive_pressed() -> void:
	UIController.navigate_to("dive")
