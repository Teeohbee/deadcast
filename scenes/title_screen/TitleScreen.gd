# scenes/title_screen/TitleScreen.gd
extends Control

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var confirm_panel: VBoxContainer = $VBoxContainer/ConfirmPanel
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var confirm_label: Label = $VBoxContainer/ConfirmPanel/ConfirmLabel

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_background(self)

	var save_exists := FileAccess.file_exists(GameState.SAVE_PATH)
	continue_button.visible = save_exists
	confirm_panel.visible = false

	title_label.text = "┌ deadcast ──────────┐\n└────────────────────┘"
	UIStyle.apply_label(title_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(confirm_label, UIStyle.COL_WARNING)

	for btn in [continue_button, new_game_button,
			$VBoxContainer/ConfirmPanel/HBoxContainer/YesButton,
			$VBoxContainer/ConfirmPanel/HBoxContainer/NoButton]:
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)

	continue_button.text = "continue"
	new_game_button.text = "new game"
	$VBoxContainer/ConfirmPanel/HBoxContainer/YesButton.text = "yes"
	$VBoxContainer/ConfirmPanel/HBoxContainer/NoButton.text = "no"
	confirm_label.text = "this will erase your progress. are you sure?"

	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/ConfirmPanel/HBoxContainer/YesButton.pressed.connect(_on_confirm_yes)
	$VBoxContainer/ConfirmPanel/HBoxContainer/NoButton.pressed.connect(_on_confirm_no)

	if save_exists:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/AppShell.tscn")

func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(GameState.SAVE_PATH):
		continue_button.visible = false
		new_game_button.visible = false
		confirm_panel.visible = true
		$VBoxContainer/ConfirmPanel/HBoxContainer/YesButton.grab_focus()
	else:
		GameState.new_game()
		get_tree().change_scene_to_file("res://scenes/AppShell.tscn")

func _on_confirm_yes() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/AppShell.tscn")

func _on_confirm_no() -> void:
	confirm_panel.visible = false
	continue_button.visible = true
	new_game_button.visible = true
	continue_button.grab_focus()
