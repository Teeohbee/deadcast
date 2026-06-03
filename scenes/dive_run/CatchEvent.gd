# scenes/dive_run/CatchEvent.gd
class_name CatchEvent
extends Control

signal option_selected(index: int)
signal result_dismissed

@onready var hud_label: Label = $VBoxContainer/HUDLabel
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var flavor_label: Label = $VBoxContainer/FlavorLabel
@onready var options_container: VBoxContainer = $VBoxContainer/OptionsContainer
@onready var narrative_panel: VBoxContainer = $VBoxContainer/NarrativePanel
@onready var narrative_text: RichTextLabel = $VBoxContainer/NarrativePanel/NarrativeText
@onready var continue_button: Button = $VBoxContainer/NarrativePanel/ContinueButton

const _SEP := "────────────────────────────────────────────────────────────────"
const _SEP_SHORT := "────────────────────────────────────────────────"

var _catch_data: CatchData = null
var _pending_narrative_index: int = -1

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_background(self)
	continue_button.focus_mode = Control.FOCUS_ALL
	UIStyle.apply_button(continue_button)
	continue_button.text = "[CONTINUE →]"
	continue_button.pressed.connect(_on_continue_pressed)

func populate(catch_data: CatchData, slot: int = 0, total_slots: int = 0, tension: int = 0, max_tension: int = 0) -> void:
	_catch_data = catch_data

	hud_label.text = "SLOT: %d/%d  │  ZONE: %s  │  TENSION: %d/%d" % [
		slot, total_slots,
		GameState.selected_zone.to_upper().replace("_", " "),
		tension, max_tension]
	UIStyle.apply_label(hud_label, UIStyle.COL_DIM)

	var type_tag := _type_tag(catch_data.catch_type)
	var security := _security_status(catch_data.behavior)
	name_label.text = "%s\n[OBJECT DETECTED]\nNAME:     %s\nCLASS:    %s\nSECURITY: %s\n%s" % [
		_SEP, catch_data.catch_name, type_tag, security, _SEP]
	UIStyle.apply_label(name_label, UIStyle.COL_TEXT)

	flavor_label.text = "┌── TELEMETRY_READOUT %s\n│  %s\n└%s" % [
		_SEP_SHORT, catch_data.flavor_text, _SEP_SHORT]
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyle.apply_label(flavor_label, UIStyle.COL_DIM)

	for child in options_container.get_children():
		child.queue_free()

	for i in catch_data.options.size():
		var option := catch_data.options[i]
		var btn := Button.new()
		btn.text = _format_option(i + 1, option, catch_data.behavior)
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)
		var idx := i
		btn.pressed.connect(func() -> void: _on_button_pressed(idx))
		options_container.add_child(btn)

	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()

func _on_button_pressed(index: int) -> void:
	var option := _catch_data.options[index]
	if option.narrative_text != "":
		_pending_narrative_index = index
		_show_narrative_panel(option)
	else:
		option_selected.emit(index)

func _show_narrative_panel(option: CatchOption) -> void:
	options_container.visible = false
	narrative_panel.visible = true
	narrative_text.text = "── LOG_ENTRY: %s %s\n\n%s" % [
		_catch_data.catch_name, _SEP_SHORT, option.narrative_text]
	var entry := "[%s]\n\n%s" % [_catch_data.catch_name, option.narrative_text]
	GameState.journal_entries.append(entry)
	GameState.save()
	await get_tree().process_frame
	continue_button.grab_focus()

func _on_continue_pressed() -> void:
	narrative_panel.visible = false
	options_container.visible = true
	option_selected.emit(_pending_narrative_index)

func show_result(text: String, color: Color) -> void:
	narrative_panel.visible = false
	for child in options_container.get_children():
		child.queue_free()
	_animate_result(text, color)

func _animate_result(text: String, color: Color) -> void:
	var label := Label.new()
	label.theme = UIStyle.get_theme()
	options_container.add_child(label)

	label.text = ">>> [PROCESSING...]"
	UIStyle.apply_label(label, UIStyle.COL_DIM)
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self):
		return

	if color == UIStyle.COL_DEBT:
		label.text = ">>> [!!! COUNTERMEASURE TRIGGERED !!!]"
		UIStyle.apply_label(label, UIStyle.COL_WARNING)
		await get_tree().create_timer(0.6).timeout
		if not is_instance_valid(self):
			return

	label.text = ">>> " + text
	UIStyle.apply_label(label, color)

	var btn := Button.new()
	btn.text = "[CONTINUE →]"
	btn.focus_mode = Control.FOCUS_ALL
	UIStyle.apply_button(btn)
	btn.pressed.connect(result_dismissed.emit)
	options_container.add_child(btn)
	btn.grab_focus()

func _type_tag(catch_type: CatchData.CatchType) -> String:
	match catch_type:
		CatchData.CatchType.DATA:   return "[DATA_CONTAINER]"
		CatchData.CatchType.BIO:    return "[BIO_SPECIMEN]"
		CatchData.CatchType.MECH:   return "[MECH_SYSTEM]"
		CatchData.CatchType.ENTITY: return "[ENTITY_DETECTED]"
	return "[UNKNOWN]"

func _security_status(behavior: CatchData.BehaviorType) -> String:
	match behavior:
		CatchData.BehaviorType.PASSIVE:     return "[STANDARD_YIELD]   → no countermeasures detected"
		CatchData.BehaviorType.RESISTANT:   return "[ENC_RESISTANT]    → high extraction pushback detected"
		CatchData.BehaviorType.NEGOTIATING: return "[NEGOTIATING]      → responsive to structured queries"
		CatchData.BehaviorType.AGGRESSIVE:  return "[HOSTILE]"
	return "[UNKNOWN]"

func _format_option(num: int, option: CatchOption, behavior: CatchData.BehaviorType) -> String:
	if option.cuts_line:
		return "[%d] ABORT_CONNECTION  ·  resets tension  ·  no reward" % num

	var t_str: String
	if option.tension_delta > 0:
		t_str = "+%dT" % option.tension_delta
	elif option.tension_delta < 0:
		t_str = "%dT" % option.tension_delta
	else:
		t_str = "+0T"

	var cr_str := "+%dcr" % option.credit_value if option.credit_value > 0 else "+0cr"
	var risk_str: String

	match behavior:
		CatchData.BehaviorType.RESISTANT:
			if option.resist_chance > 0.0:
				risk_str = "%d%% resist (+%dT, 0cr)" % [
					int(option.resist_chance * 100), option.resist_tension_penalty]
			else:
				risk_str = "none"
		CatchData.BehaviorType.NEGOTIATING:
			if option.roll_difficulty > 0.0:
				var fail_cr := "+%dcr" % option.fail_credit_value if option.fail_credit_value > 0 else "+0cr"
				risk_str = "%d%% fail (+%dT, %s)" % [
					int(option.roll_difficulty * 100), option.fail_tension_delta, fail_cr]
			else:
				risk_str = "none"
		_:
			risk_str = "none"

	var slug := option.label.to_upper().replace(" ", "_").rpad(26)
	return "[%d] %s  COST: %s│  REWARD: %s│  RISK: %s" % [
		num, slug, t_str.rpad(8), cr_str.rpad(11), risk_str]
