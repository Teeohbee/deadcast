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
	self.theme = UIStyle.get_theme()

	return_button.focus_mode = Control.FOCUS_ALL
	UIStyle.apply_button(return_button)
	return_button.text = "[ RETURN TO DECK ]"
	return_button.pressed.connect(_on_return_pressed)
	return_button.grab_focus()

	var result = GameState.last_run_result
	var snapped = result.get("snapped", false)
	var earned = result.get("credits", 0)
	var bio = result.get("bio_credits", 0)

	result_label.text = "line snapped" if snapped else "run complete"
	UIStyle.apply_label(result_label, UIStyle.COL_DEBT if snapped else UIStyle.COL_TEXT)

	run_credits_label.text = "earned: %d cr" % earned
	UIStyle.apply_label(run_credits_label, UIStyle.COL_ACCENT)

	total_credits_label.text = "wallet: %d cr  ·  debt: %d cr" % [GameState.credits, GameState.debt]
	UIStyle.apply_label(total_credits_label, UIStyle.COL_TEXT)

	if GameState.victory:
		debt_label.text = "debt cleared. the meridian is yours."
		UIStyle.apply_label(debt_label, UIStyle.COL_ACCENT)
	else:
		UIStyle.apply_label(debt_label, UIStyle.COL_DEBT)
		var runs_to_payment = 5 - GameState.runs_since_payment
		if GameState.pressure_level == 0:
			payment_label.text = "next payment: 10,000cr in %d run%s" % [runs_to_payment, "s" if runs_to_payment != 1 else ""]
		else:
			payment_label.text = "pressure %d — %s" % [GameState.pressure_level, _pressure_label(GameState.pressure_level)]
		UIStyle.apply_label(payment_label, UIStyle.COL_DIM)

	if bio > 0:
		freezer_label.text = "bio catches stored in freezer: %d cr" % bio
		UIStyle.apply_label(freezer_label, UIStyle.COL_DIM)

func _pressure_label(level: int) -> String:
	match level:
		1: return "marta is watching."
		2: return "vendor prices up 20%."
		3: return "okeke won't deal with you."
		4: return "debt collector is coming."
		5: return "forced surrender."
		_: return ""

func _on_return_pressed() -> void:
	UIController.navigate_to("deck")
