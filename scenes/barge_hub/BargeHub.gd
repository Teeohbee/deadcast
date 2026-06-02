# scenes/barge_hub/BargeHub.gd
extends Control

@onready var debt_label: Label = $VBoxContainer/DebtLabel
@onready var credits_label: Label = $VBoxContainer/CreditsLabel
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
	# P5 game over — redirect before showing hub
	if GameState.pressure_level >= 5:
		_show_game_over()
		return

	# P4 debt collector one-time event
	if GameState.pressure_level >= 4 and not GameState.debt_collector_triggered:
		GameState.debt_collector_triggered = true
		GameState.spend_credits(5000)
		GameState.save()

	dive_button.pressed.connect(_on_dive_pressed)
	EventBus.credits_changed.connect(_refresh_labels)
	_refresh_labels(GameState.credits)
	debt_label.text = "DEBT: %d CR  |  PRESSURE: %d" % [GameState.debt, GameState.pressure_level]

	for btn in [dive_button, workshop_btn, decrypt_btn, freezer_btn,
				bunk_btn, marta_btn, okeke_btn, vendor_btn]:
		btn.focus_mode = Control.FOCUS_ALL

	workshop_btn.pressed.connect(func(): _go_to("workshop"))
	decrypt_btn.pressed.connect(func(): _go_to("decrypt"))
	freezer_btn.pressed.connect(func(): _go_to("freezer"))
	bunk_btn.pressed.connect(func(): _go_to("bunk"))
	marta_btn.pressed.connect(func(): _go_to("marta"))
	okeke_btn.pressed.connect(func(): _go_to("okeke"))
	vendor_btn.pressed.connect(func(): _go_to("vendor"))

	# Show rod damage warning
	if GameState.rod_damaged:
		workshop_btn.text = "Workshop ⚠"

	await get_tree().process_frame
	$VBoxContainer/ZoneSelector/District7Button.grab_focus()

func _refresh_labels(_ignored: int = 0) -> void:
	credits_label.text = "CREDITS: %d CR" % GameState.credits
	debt_label.text = "DEBT: %d CR  |  PRESSURE: %d" % [GameState.debt, GameState.pressure_level]

func _on_dive_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dive_run/DiveRun.tscn")

func _go_to(location: String) -> void:
	get_tree().change_scene_to_file(SCENES[location])

func _show_game_over() -> void:
	# Clear existing children and show game over
	for child in get_children():
		child.queue_free()
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(vbox)
	var label = Label.new()
	label.text = "FORCED SURRENDER\n\nMarta's people came for the Meridian.\nYou made it %d runs." % GameState.run_count
	vbox.add_child(label)
	var btn = Button.new()
	btn.text = "New Game"
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(func(): GameState.new_game(); get_tree().reload_current_scene())
	vbox.add_child(btn)
	btn.grab_focus()
