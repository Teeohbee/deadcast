# scenes/barge_hub/MartaTerminal.gd
extends Control

@onready var debt_status_label: Label = $VBoxContainer/DebtStatusLabel
@onready var dialogue_label: Label = $VBoxContainer/DialogueLabel
@onready var payment_label: Label = $VBoxContainer/PaymentLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))

	if GameState.victory:
		debt_status_label.text = "DEBT: CLEARED"
		dialogue_label.text = "\"Meridian is yours. Don't make me regret it.\"\n— Marta"
		payment_label.text = ""
	else:
		var runs_to_payment = 5 - GameState.runs_since_payment
		debt_status_label.text = "OUTSTANDING DEBT: %d CR  |  PRESSURE: %d/5" % [
			GameState.debt, GameState.pressure_level]
		dialogue_label.text = _marta_dialogue(GameState.pressure_level)
		payment_label.text = "Next payment: 10,000cr due in %d run%s." % [
			runs_to_payment, "s" if runs_to_payment != 1 else ""]

	back_button.grab_focus()

func _marta_dialogue(pressure: int) -> String:
	match pressure:
		0: return "\"You're on schedule. Keep it that way.\"\n— Marta"
		1: return "\"One missed payment. I'm noting it.\nDon't make this a habit.\"\n— Marta"
		2: return "\"My associate on the supply barge has been informed.\nYour costs just went up. Pay what you owe.\"\n— Marta"
		3: return "\"Okeke has been asked not to deal with you.\nYou're running out of options.\"\n— Marta"
		4: return "\"I sent someone to collect what I could.\nThis is your final warning.\"\n— Marta"
		_: return "\"You had your chance.\"\n— Marta"
