# scenes/ui/PostRun.gd
extends Control

const _SEP  := "────────────────────────────────────────────────────────────────"
const _SEP_S := "────────────────────────────────────────────────"

@onready var container: VBoxContainer = $VBoxContainer

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_background(self)

	for child in container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var result  := GameState.last_run_result
	var snapped := result.get("snapped", false) as bool
	var earned  := result.get("credits", 0) as int
	var bio     := result.get("bio_credits", 0) as int

	_row("─── RUN_LOG " + _SEP, UIStyle.COL_SEP)

	if snapped:
		_row("\n[!!! SIGNAL LOST !!!]\nCRITICAL: LINE TENSION EXCEEDED / SIGNAL LOST\n", UIStyle.COL_DEBT)
	else:
		_row("\n>>> connection closed  ·  run complete\n", UIStyle.COL_TEXT)

	_row(_SEP_S, UIStyle.COL_SEP)

	if snapped:
		_row("yield:    +0cr  (run forfeited)", UIStyle.COL_DEBT)
	elif earned > 0:
		_row("yield:    +%dcr" % earned, UIStyle.COL_ACCENT)

	_row("wallet:   %dcr  ·  debt: %dcr" % [GameState.credits, GameState.debt], UIStyle.COL_TEXT)

	if GameState.victory:
		_row("\ndebt cleared. the meridian is yours.", UIStyle.COL_ACCENT)
	else:
		var runs_to_payment := 5 - GameState.runs_since_payment
		if GameState.pressure_level == 0:
			_row("next payment: 10,000cr in %d run%s" % [
				runs_to_payment, "s" if runs_to_payment != 1 else ""], UIStyle.COL_DIM)
		else:
			_row("pressure %d — %s" % [
				GameState.pressure_level, _pressure_label(GameState.pressure_level)], UIStyle.COL_DIM)

	if bio > 0:
		_row("bio cache: %dcr stored in freezer" % bio, UIStyle.COL_DIM)

	_row("", UIStyle.COL_DIM)

	var btn := Button.new()
	btn.text = "[ RETURN TO DECK ]"
	btn.focus_mode = Control.FOCUS_ALL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIStyle.apply_button(btn)
	btn.pressed.connect(func(): UIController.navigate_to("deck"))
	container.add_child(btn)
	await get_tree().process_frame
	btn.grab_focus()

func _row(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	UIStyle.apply_label(lbl, color)
	container.add_child(lbl)

func _pressure_label(level: int) -> String:
	match level:
		1: return "marta is watching."
		2: return "vendor prices up 20%."
		3: return "okeke won't deal with you."
		4: return "debt collector is coming."
		5: return "forced surrender."
		_: return ""
