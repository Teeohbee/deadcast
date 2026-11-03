# scenes/barge_hub/MartaTerminal.gd
extends Control

# Story beats from Marta's relay, newest threshold first: [first run seen, text].
const BEATS: Array = [
	[12, "\"keep working. i can make the debt go away faster.\"\n\"the price is reasonable. we'll discuss it.\"\n— marta"],
	[10, "\"okeke's been quiet. probably just busy.\"\n\"focus on your runs.\"\n— marta"],
	[8, "\"the meridian has a transponder. it was installed before i gave you the rig.\"\n\"axiom has been paying me for your dive coordinates since run one.\"\n\"this changes nothing between us. the debt is still real.\"\n— marta"],
	[6, "\"that archive you pulled from the axiom sub-basement — the one with the bioweapon specs.\"\n\"good work. i've already moved it.\"\n— marta"],
	[5, "\"eight runs without a snap. consistent.\"\n\"most people i stake don't make it this far.\"\n— marta"],
	[3, "\"the shard from the exchange sub-level — i've seen that serial number before.\"\n\"don't worry about how.\"\n— marta"],
	[1, "\"80,000 credits. the rig, the mooring fee, and the meridian's registration.\"\n\"10,000 every five runs. miss a payment and the terms change.\"\n\"questions?\"\n— marta"],
]

@onready var debt_status_label: Label = $MarginContainer/VBoxContainer/TopRow/LedgerPanel/LedgerVBox/DebtStatusLabel
@onready var payment_label: Label = $MarginContainer/VBoxContainer/TopRow/LedgerPanel/LedgerVBox/PaymentLabel
@onready var story_beat_label: Label = $MarginContainer/VBoxContainer/DialoguePanel/DialogueVBox/StoryBeatLabel
@onready var dialogue_label: Label = $MarginContainer/VBoxContainer/DialoguePanel/DialogueVBox/DialogueLabel
@onready var _transmission: IncomingTransmission = $MarginContainer/VBoxContainer/TopRow/IncomingTransmission
@onready var _history_label: Label = $MarginContainer/VBoxContainer/HistoryPanel/HistoryScroll/HistoryLabel

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if GameState.has_new_marta_beat():
		GameState.marta_last_seen_run = GameState.run_count
		GameState.save()

	var beat = _marta_story_beat(GameState.run_count)
	story_beat_label.text = beat
	story_beat_label.visible = beat != ""
	DeckStyle.apply_label(story_beat_label, DeckStyle.SKY)

	if GameState.victory:
		debt_status_label.text = "debt: cleared"
		DeckStyle.apply_label(debt_status_label, DeckStyle.SKY)
		dialogue_label.text = "\"meridian is yours. don't make me regret it.\"\n— marta"
		DeckStyle.apply_label(dialogue_label, DeckStyle.TEXT)
		payment_label.text = ""
	else:
		var runs_to_payment = 5 - GameState.runs_since_payment
		debt_status_label.text = "outstanding debt: %d cr  ·  pressure %d/5" % [
			GameState.debt, GameState.pressure_level]
		DeckStyle.apply_label(debt_status_label, DeckStyle.RED)
		dialogue_label.text = _marta_dialogue(GameState.pressure_level)
		DeckStyle.apply_label(dialogue_label, DeckStyle.TEXT)
		payment_label.text = "next payment: 10,000cr due in %d run%s." % [
			runs_to_payment, "s" if runs_to_payment != 1 else ""]
		DeckStyle.apply_label(payment_label, DeckStyle.AMBER)

	_transmission.refresh(GameState.pressure_level)
	_history_label.text = _history_text(GameState.run_count)
	DeckStyle.apply_label(_history_label, DeckStyle.DIM)

func on_screen_shown() -> void:
	_refresh()

func _marta_story_beat(run: int) -> String:
	var history := beat_history(run)
	return history[0] if not history.is_empty() else ""

# Every beat received by this run, newest first.
func beat_history(run: int) -> Array[String]:
	var received: Array[String] = []
	for beat in BEATS:
		if run >= beat[0]:
			received.append(beat[1])
	return received

# Earlier beats only; the current one is already in the marta panel.
func _history_text(run: int) -> String:
	var entries: Array[String] = []
	var skipped_current_beat := false
	for beat in BEATS:
		if run < beat[0]:
			continue
		if not skipped_current_beat:
			skipped_current_beat = true
			continue
		entries.append("── relay · run %d ──\n%s" % [beat[0], beat[1]])
	if entries.is_empty():
		return "no earlier transmissions."
	return "\n\n".join(entries)

func _marta_dialogue(pressure: int) -> String:
	match pressure:
		0: return "\"you're on schedule. keep it that way.\"\n— marta"
		1: return "\"one missed payment. i'm noting it.\ndon't make this a habit.\"\n— marta"
		2: return "\"my associate on the supply barge has been informed.\nyour costs just went up. pay what you owe.\"\n— marta"
		3: return "\"okeke has been asked not to deal with you.\nyou're running out of options.\"\n— marta"
		4: return "\"i sent someone to collect what i could.\nthis is your final warning.\"\n— marta"
		_: return "\"you had your chance.\"\n— marta"
