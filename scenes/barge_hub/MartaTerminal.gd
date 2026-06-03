# scenes/barge_hub/MartaTerminal.gd
extends Control

@onready var debt_status_label: Label = $VBoxContainer/DebtStatusLabel
@onready var dialogue_label: Label = $VBoxContainer/DialogueLabel
@onready var payment_label: Label = $VBoxContainer/PaymentLabel
@onready var story_beat_label: Label = $VBoxContainer/StoryBeatLabel

func _ready() -> void:
	self.theme = UIStyle.get_theme()

	$VBoxContainer/TitleLabel.text = "┌── [ MARTA VOSS — ENCRYPTED TERMINAL ] ──────────────────────"
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

func _marta_story_beat(run: int) -> String:
	if run >= 12:
		return "\"keep working. i can make the debt go away faster.\"\n\"the price is reasonable. we'll discuss it.\"\n— marta"
	if run >= 10:
		return "\"okeke's been quiet. probably just busy.\"\n\"focus on your runs.\"\n— marta"
	if run >= 8:
		return "\"the meridian has a transponder. it was installed before i gave you the rig.\"\n\"axiom has been paying me for your dive coordinates since run one.\"\n\"this changes nothing between us. the debt is still real.\"\n— marta"
	if run >= 6:
		return "\"that archive you pulled from the axiom sub-basement — the one with the bioweapon specs.\"\n\"good work. i've already moved it.\"\n— marta"
	if run >= 5:
		return "\"eight runs without a snap. consistent.\"\n\"most people i stake don't make it this far.\"\n— marta"
	if run >= 3:
		return "\"the shard from the exchange sub-level — i've seen that serial number before.\"\n\"don't worry about how.\"\n— marta"
	if run >= 1:
		return "\"80,000 credits. the rig, the mooring fee, and the meridian's registration.\"\n\"10,000 every five runs. miss a payment and the terms change.\"\n\"questions?\"\n— marta"
	return ""

func _marta_dialogue(pressure: int) -> String:
	match pressure:
		0: return "\"you're on schedule. keep it that way.\"\n— marta"
		1: return "\"one missed payment. i'm noting it.\ndon't make this a habit.\"\n— marta"
		2: return "\"my associate on the supply barge has been informed.\nyour costs just went up. pay what you owe.\"\n— marta"
		3: return "\"okeke has been asked not to deal with you.\nyou're running out of options.\"\n— marta"
		4: return "\"i sent someone to collect what i could.\nthis is your final warning.\"\n— marta"
		_: return "\"you had your chance.\"\n— marta"
