# scenes/title_screen/TitleScreen.gd
extends Control

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var confirm_panel: VBoxContainer = $VBoxContainer/ConfirmPanel

func _ready() -> void:
	var save_exists := FileAccess.file_exists(GameState.SAVE_PATH)
	continue_button.visible = save_exists
	confirm_panel.visible = false

	for btn in [continue_button, new_game_button,
			$VBoxContainer/ConfirmPanel/HBoxContainer/YesButton,
			$VBoxContainer/ConfirmPanel/HBoxContainer/NoButton]:
		btn.focus_mode = Control.FOCUS_ALL

	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/ConfirmPanel/HBoxContainer/YesButton.pressed.connect(_on_confirm_yes)
	$VBoxContainer/ConfirmPanel/HBoxContainer/NoButton.pressed.connect(_on_confirm_no)

	if save_exists:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn")

func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(GameState.SAVE_PATH):
		continue_button.visible = false
		new_game_button.visible = false
		confirm_panel.visible = true
		$VBoxContainer/ConfirmPanel/HBoxContainer/YesButton.grab_focus()
	else:
		GameState.new_game()
		get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn")

func _on_confirm_yes() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn")

func _on_confirm_no() -> void:
	confirm_panel.visible = false
	continue_button.visible = true
	new_game_button.visible = true
	continue_button.grab_focus()
