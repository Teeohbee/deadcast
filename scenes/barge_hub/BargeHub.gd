# scenes/barge_hub/BargeHub.gd
extends Control

@onready var debt_label: Label = $VBoxContainer/EconomyRow/DebtPanel/DebtLabel
@onready var credits_label: Label = $VBoxContainer/EconomyRow/CreditsPanel/CreditsLabel
@onready var debt_panel: PanelContainer = $VBoxContainer/EconomyRow/DebtPanel
@onready var credits_panel: PanelContainer = $VBoxContainer/EconomyRow/CreditsPanel
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var separator_label: Label = $VBoxContainer/SeparatorLabel
@onready var dive_button: Button = $VBoxContainer/DiveButton
@onready var workshop_btn: Button = $VBoxContainer/LocationButtons/WorkshopBtn
@onready var decrypt_btn: Button = $VBoxContainer/LocationButtons/DecryptBtn
@onready var freezer_btn: Button = $VBoxContainer/LocationButtons/FreezerBtn
@onready var bunk_btn: Button = $VBoxContainer/LocationButtons/BunkBtn
@onready var marta_btn: Button = $VBoxContainer/LocationButtons/MartaBtn
@onready var okeke_btn: Button = $VBoxContainer/LocationButtons/OkekeBtn
@onready var vendor_btn: Button = $VBoxContainer/LocationButtons/VendorBtn

const SCENES = {
	"workshop": "res://scenes/barge_hub/Workshop.tscn",
	"decrypt": "res://scenes/barge_hub/DecryptBox.tscn",
	"freezer": "res://scenes/barge_hub/Freezer.tscn",
	"bunk": "res://scenes/barge_hub/Bunk.tscn",
	"marta": "res://scenes/barge_hub/MartaTerminal.tscn",
	"okeke": "res://scenes/barge_hub/OkekeShop.tscn",
	"vendor": "res://scenes/barge_hub/VendorShop.tscn",
}

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_background(self)

	if GameState.pressure_level >= 5:
		get_tree().change_scene_to_file("res://scenes/barge_hub/GameOver.tscn")
		return

	# P4 debt collector one-time event
	if GameState.pressure_level >= 4 and not GameState.debt_collector_triggered:
		GameState.debt_collector_triggered = true
		GameState.spend_credits(5000)
		GameState.save()

	dive_button.pressed.connect(_on_dive_pressed)
	EventBus.credits_changed.connect(_refresh_labels)
	_refresh_labels(GameState.credits)

	UIStyle.apply_label(title_label, UIStyle.COL_DIM)
	UIStyle.apply_label(separator_label, UIStyle.COL_SEP)
	UIStyle.apply_panel(debt_panel)
	UIStyle.apply_panel(credits_panel)
	UIStyle.apply_button(dive_button)
	dive_button.focus_mode = Control.FOCUS_ALL

	for btn in [workshop_btn, decrypt_btn, freezer_btn,
				bunk_btn, marta_btn, okeke_btn, vendor_btn]:
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)

	if GameState.rod_damaged:
		workshop_btn.text = "workshop ⚠"
		workshop_btn.add_theme_color_override("font_color", UIStyle.COL_WARNING)

	if _has_new_marta_beat():
		marta_btn.text = "marta !"
		marta_btn.add_theme_color_override("font_color", UIStyle.COL_DEBT)

	workshop_btn.pressed.connect(func(): _go_to("workshop"))
	decrypt_btn.pressed.connect(func(): _go_to("decrypt"))
	freezer_btn.pressed.connect(func(): _go_to("freezer"))
	bunk_btn.pressed.connect(func(): _go_to("bunk"))
	marta_btn.pressed.connect(func(): _go_to("marta"))
	okeke_btn.pressed.connect(func(): _go_to("okeke"))
	vendor_btn.pressed.connect(func(): _go_to("vendor"))

	await get_tree().process_frame
	$VBoxContainer/ZoneSelector/District7Button.grab_focus()

func _refresh_labels(_ignored: int = 0) -> void:
	var runs_to_pmt = 5 - GameState.runs_since_payment
	debt_label.text = "debt  %d cr\npressure %d/5  ·  payment in %d run%s" % [
		GameState.debt, GameState.pressure_level,
		runs_to_pmt, "s" if runs_to_pmt != 1 else ""]
	UIStyle.apply_label(debt_label, UIStyle.COL_DEBT)

	credits_label.text = "wallet\n%d cr" % GameState.credits
	UIStyle.apply_label(credits_label, UIStyle.COL_TEXT)

func _on_dive_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dive_run/DiveRun.tscn")

func _go_to(location: String) -> void:
	get_tree().change_scene_to_file(SCENES[location])

func _has_new_marta_beat() -> bool:
	return _beat_index(GameState.run_count) > _beat_index(GameState.marta_last_seen_run)

static func _beat_index(run: int) -> int:
	if run >= 12: return 7
	if run >= 10: return 6
	if run >= 8:  return 5
	if run >= 6:  return 4
	if run >= 5:  return 3
	if run >= 3:  return 2
	if run >= 1:  return 1
	return 0
