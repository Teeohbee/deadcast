# scenes/barge_hub/DecryptBox.gd
extends Control

const LOAD_AMOUNT: int = 1000

@onready var status_label: Label = $MarginContainer/HBox/LeftColumn/DecryptPanel/VBox/StatusLabel
@onready var load_button: Button = $MarginContainer/HBox/LeftColumn/DecryptPanel/VBox/LoadButton
@onready var message_label: Label = $MarginContainer/HBox/LeftColumn/DecryptPanel/VBox/MessageLabel
@onready var _cipher_crack: CipherCrackPanel = $MarginContainer/HBox/RightColumn/CipherCrackPanel
@onready var _cipher_log: CipherLogPanel = $MarginContainer/HBox/RightColumn/CipherLogPanel

func _ready() -> void:
	for btn in [load_button]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_action_button(btn)

	DeckStyle.apply_label(status_label, DeckStyle.TEXT)
	DeckStyle.apply_label(message_label, DeckStyle.TEXT)

	load_button.pressed.connect(_on_load_pressed)
	_refresh()
	load_button.grab_focus()

func _refresh() -> void:
	var decrypting = GameState.decrypt_box_runs > 0

	if GameState.decrypt_box_queue == 0:
		var last := ""
		if GameState.decrypt_last_outcome != "":
			var outcome_label := GameState.decrypt_last_outcome
			for o in GameState.DECRYPT_OUTCOMES:
				if o.id == GameState.decrypt_last_outcome:
					outcome_label = o.label
					break
			last = "\nlast result: %s → %dcr" % [outcome_label, GameState.decrypt_last_payout]
		status_label.text = "box is empty.%s\ndata integrity not guaranteed.\nload credits to decrypt after %d runs." % [
			last, GameState.DECRYPT_THRESHOLD]
	else:
		var runs_left = GameState.DECRYPT_THRESHOLD - GameState.decrypt_box_runs
		status_label.text = "queued: %dcr\ndecrypts in %d run%s → ?" % [
			GameState.decrypt_box_queue,
			runs_left,
			"s" if runs_left != 1 else "",
		]

	if decrypting:
		load_button.text = "decryption in progress"
		load_button.disabled = true
	else:
		load_button.text = "load %dcr of data" % LOAD_AMOUNT
		load_button.disabled = GameState.credits < LOAD_AMOUNT

	_update_crack()

func _update_crack() -> void:
	var active := GameState.decrypt_box_queue > 0
	var progress := 0.0
	if active and GameState.DECRYPT_THRESHOLD > 0:
		progress = float(GameState.decrypt_box_runs) / float(GameState.DECRYPT_THRESHOLD)
	_cipher_crack.set_state(active, progress)

func _on_load_pressed() -> void:
	if GameState.spend_credits(LOAD_AMOUNT):
		GameState.decrypt_box_queue += LOAD_AMOUNT
		if GameState.decrypt_box_queue == LOAD_AMOUNT:
			GameState.decrypt_box_runs = 0
		GameState.save()
		message_label.text = "%dcr loaded into decrypt queue." % LOAD_AMOUNT
		message_label.add_theme_color_override("font_color", DeckStyle.GREEN)
		_cipher_log.append_line("PAYLOAD: %dcr block queued for decryption." % LOAD_AMOUNT)
		_refresh()
	else:
		message_label.text = "not enough credits."
		message_label.add_theme_color_override("font_color", DeckStyle.RED)
