# scenes/barge_hub/BargeHub.gd
extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var account_label: Label = $VBoxContainer/ContentRow/AccountLabel
@onready var separator_label: Label = $VBoxContainer/SeparatorLabel
@onready var loc_footer: Label = $VBoxContainer/LocFooter
@onready var dive_button: Button = $VBoxContainer/DiveRow/DiveButton
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

	if GameState.pressure_level >= 4 and not GameState.debt_collector_triggered:
		GameState.debt_collector_triggered = true
		GameState.spend_credits(5000)
		GameState.save()

	dive_button.pressed.connect(_on_dive_pressed)
	EventBus.credits_changed.connect(_refresh_account)

	UIStyle.apply_label(title_label, UIStyle.COL_DIM)
	UIStyle.apply_label(separator_label, UIStyle.COL_DIM)
	UIStyle.apply_label(loc_footer, UIStyle.COL_DIM)
	UIStyle.apply_label(account_label, UIStyle.COL_TEXT)
	UIStyle.apply_button(dive_button)
	dive_button.focus_mode = Control.FOCUS_ALL

	for btn in [workshop_btn, decrypt_btn, freezer_btn,
				bunk_btn, marta_btn, okeke_btn, vendor_btn]:
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)

	if GameState.rod_damaged:
		workshop_btn.text = "workshop ⚠"
		workshop_btn.add_theme_color_override("font_color", UIStyle.COL_WARNING)

	if GameState.has_new_marta_beat():
		marta_btn.text = "marta !"
		marta_btn.add_theme_color_override("font_color", UIStyle.COL_DEBT)

	workshop_btn.pressed.connect(func(): _go_to("workshop"))
	decrypt_btn.pressed.connect(func(): _go_to("decrypt"))
	freezer_btn.pressed.connect(func(): _go_to("freezer"))
	bunk_btn.pressed.connect(func(): _go_to("bunk"))
	marta_btn.pressed.connect(func(): _go_to("marta"))
	okeke_btn.pressed.connect(func(): _go_to("okeke"))
	vendor_btn.pressed.connect(func(): _go_to("vendor"))

	_refresh_account()

	await get_tree().process_frame
	var focus_id := GameState.last_hub_focus
	GameState.last_hub_focus = ""
	match focus_id:
		"workshop": workshop_btn.grab_focus()
		"decrypt":  decrypt_btn.grab_focus()
		"freezer":  freezer_btn.grab_focus()
		"bunk":     bunk_btn.grab_focus()
		"marta":    marta_btn.grab_focus()
		"okeke":    okeke_btn.grab_focus()
		"vendor":   vendor_btn.grab_focus()
		_:          $VBoxContainer/ContentRow/LeftColumn/ZoneSelector.get_child(1).grab_focus()

func _refresh_account(_ignored: int = 0) -> void:
	var runs_to_pmt := 5 - GameState.runs_since_payment
	var run_str := "in %d run%s" % [runs_to_pmt, "s" if runs_to_pmt != 1 else ""]
	account_label.text = (
		"┌── [ ACCOUNT STATUS ]\n"
		+ "│  WALLET:   %dcr\n" % GameState.credits
		+ "│  DEBT:     %dcr\n" % GameState.debt
		+ "│  PRESSURE: %d/5\n" % GameState.pressure_level
		+ "│  PAYMENT:  %s\n" % run_str
		+ "└──────────────────────"
	)
	var color := UIStyle.COL_DEBT if GameState.pressure_level >= 3 else UIStyle.COL_TEXT
	UIStyle.apply_label(account_label, color)

func _on_dive_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dive_run/DiveRun.tscn")

func _go_to(location: String) -> void:
	GameState.last_hub_focus = location
	get_tree().change_scene_to_file(SCENES[location])

