# scenes/ui/PostRun.gd
extends Control

@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var run_credits_label: Label = $VBoxContainer/RunCreditsLabel
@onready var total_credits_label: Label = $VBoxContainer/TotalCreditsLabel
@onready var debt_label: Label = $VBoxContainer/DebtLabel
@onready var payment_label: Label = $VBoxContainer/PaymentLabel
@onready var freezer_label: Label = $VBoxContainer/FreezerLabel
@onready var return_button: Button = $VBoxContainer/ReturnButton

func _ready() -> void:
	return_button.pressed.connect(_on_return_pressed)
	return_button.focus_mode = Control.FOCUS_ALL
	return_button.grab_focus()

	var result = GameState.last_run_result
	var snapped = result.get("snapped", false)
	var earned = result.get("credits", 0)
	var bio = result.get("bio_credits", 0)

	result_label.text = "LINE SNAPPED" if snapped else "RUN COMPLETE"
	run_credits_label.text = "EARNED: %d CR" % earned
	total_credits_label.text = "TOTAL: %d CR  |  DEBT: %d CR" % [GameState.credits, GameState.debt]

	if GameState.victory:
		debt_label.text = "DEBT CLEARED. THE MERIDIAN IS YOURS."
	else:
		var runs_to_payment = 5 - GameState.runs_since_payment
		if GameState.pressure_level == 0:
			payment_label.text = "Next payment: 10,000cr in %d run%s" % [runs_to_payment, "s" if runs_to_payment != 1 else ""]
		else:
			payment_label.text = "PRESSURE %d — %s" % [GameState.pressure_level, _pressure_label(GameState.pressure_level)]

	if bio > 0:
		freezer_label.text = "BIO catches stored in Freezer: %d CR" % bio

func _pressure_label(level: int) -> String:
	match level:
		1: return "Marta is watching."
		2: return "Vendor prices up 20%."
		3: return "Okeke won't deal with you."
		4: return "Debt collector is coming."
		5: return "FORCED SURRENDER."
		_: return ""

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn")
