# scenes/barge_hub/MartaTerminal.gd
extends Control

@onready var debt_status_label: Label = $VBoxContainer/DebtStatusLabel
@onready var dialogue_label: Label = $VBoxContainer/DialogueLabel
@onready var payment_label: Label = $VBoxContainer/PaymentLabel
@onready var story_beat_label: Label = $VBoxContainer/StoryBeatLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	back_button.focus_mode = Control.FOCUS_ALL
	UIStyle.apply_button(back_button)
	back_button.text = "disconnect"
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))

	$VBoxContainer/TitleLabel.text = "// marta voss — encrypted terminal"
	UIStyle.apply_label($VBoxContainer/TitleLabel, UIStyle.COL_DIM)

	GameState.marta_last_seen_run = GameState.run_count
	GameState.save()

	var beat = _marta_story_beat(GameState.run_count)
	story_beat_label.text = beat
	story_beat_label.visible = beat != ""
	UIStyle.apply_label(story_beat_label, UIStyle.COL_ACCENT)

	if GameState.victory:
		debt_status_label.text = "debt: cleared"
		UIStyle.apply_label(debt_status_label, UIStyle.COL_ACCENT)
		dialogue_label.text = "\"meridian is yours. don't make me regret it.\"\n— marta"
		UIStyle.apply_label(dialogue_label, UIStyle.COL_TEXT)
		payment_label.text = ""
	else:
		var runs_to_payment = 5 - GameState.runs_since_payment
		debt_status_label.text = "outstanding debt: %d cr  ·  pressure %d/5" % [
			GameState.debt, GameState.pressure_level]
		UIStyle.apply_label(debt_status_label, UIStyle.COL_DEBT)
		dialogue_label.text = _marta_dialogue(GameState.pressure_level)
		UIStyle.apply_label(dialogue_label, UIStyle.COL_TEXT)
		payment_label.text = "next payment: 10,000cr due in %d run%s." % [
			runs_to_payment, "s" if runs_to_payment != 1 else ""]
		UIStyle.apply_label(payment_label, UIStyle.COL_DIM)

	back_button.grab_focus()

func _marta_story_beat(run: int) -> String:
	if run >= 12:
		return "\"Keep working. I can make the debt go away faster.\"\n\"The price is reasonable. We'll discuss it.\"\n— Marta"
	if run >= 10:
		return "\"Okeke's been quiet. Probably just busy.\"\n\"Focus on your runs.\"\n— Marta"
	if run >= 8:
		return "\"The Meridian has a transponder. It was installed before I gave you the rig.\"\n\"Axiom has been paying me for your dive coordinates since run one.\"\n\"This changes nothing between us. The debt is still real.\"\n— Marta"
	if run >= 6:
		return "\"That archive you pulled from the Axiom sub-basement — the one with the bioweapon specs.\"\n\"Good work. I've already moved it.\"\n— Marta"
	if run >= 5:
		return "\"Eight runs without a snap. Consistent.\"\n\"Most people I stake don't make it this far.\"\n— Marta"
	if run >= 3:
		return "\"The shard from the Exchange sub-level — I've seen that serial number before.\"\n\"Don't worry about how.\"\n— Marta"
	if run >= 1:
		return "\"80,000 credits. The rig, the mooring fee, and the Meridian's registration.\"\n\"10,000 every five runs. Miss a payment and the terms change.\"\n\"Questions?\"\n— Marta"
	return ""

func _marta_dialogue(pressure: int) -> String:
	match pressure:
		0: return "\"You're on schedule. Keep it that way.\"\n— Marta"
		1: return "\"One missed payment. I'm noting it.\nDon't make this a habit.\"\n— Marta"
		2: return "\"My associate on the supply barge has been informed.\nYour costs just went up. Pay what you owe.\"\n— Marta"
		3: return "\"Okeke has been asked not to deal with you.\nYou're running out of options.\"\n— Marta"
		4: return "\"I sent someone to collect what I could.\nThis is your final warning.\"\n— Marta"
		_: return "\"You had your chance.\"\n— Marta"
