# scenes/dive_run/CatchEvent.gd
class_name CatchEvent
extends Control

signal option_selected(index: int)

@onready var hud_label: Label = $VBoxContainer/HUDLabel
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var flavor_label: Label = $VBoxContainer/FlavorLabel
@onready var options_container: VBoxContainer = $VBoxContainer/OptionsContainer
@onready var narrative_panel: VBoxContainer = $VBoxContainer/NarrativePanel
@onready var narrative_text: RichTextLabel = $VBoxContainer/NarrativePanel/NarrativeText
@onready var continue_button: Button = $VBoxContainer/NarrativePanel/ContinueButton

var _catch_data: CatchData = null
var _pending_narrative_index: int = -1

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_background(self)
	$VBoxContainer.offset_right = -220.0
	continue_button.focus_mode = Control.FOCUS_ALL
	UIStyle.apply_button(continue_button)
	continue_button.pressed.connect(_on_continue_pressed)

func populate(catch_data: CatchData, slot: int = 0, total_slots: int = 0, tension: int = 0, max_tension: int = 0) -> void:
	_catch_data = catch_data
	hud_label.text = "slot %d / %d  ·  %s  ·  tension %d / %d" % [
		slot, total_slots, GameState.selected_zone, tension, max_tension]
	UIStyle.apply_label(hud_label, UIStyle.COL_DIM)

	var behavior_tag = _behavior_tag(catch_data.behavior)
	name_label.text = "%s  %s" % [behavior_tag, catch_data.catch_name]
	UIStyle.apply_label(name_label, UIStyle.COL_TEXT)

	flavor_label.text = "│  " + catch_data.flavor_text
	UIStyle.apply_label(flavor_label, UIStyle.COL_DIM)

	for child in options_container.get_children():
		child.queue_free()
	for i in catch_data.options.size():
		var option = catch_data.options[i]
		var btn = Button.new()
		btn.text = option.label
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)
		var idx = i
		btn.pressed.connect(func() -> void: _on_button_pressed(idx))
		options_container.add_child(btn)
		var cost_label = Label.new()
		cost_label.text = _format_cost(option, catch_data.behavior)
		UIStyle.apply_label(cost_label, UIStyle.COL_COST)
		options_container.add_child(cost_label)
		if option.flavor_text != "":
			var flavor = Label.new()
			flavor.text = option.flavor_text
			UIStyle.apply_label(flavor, UIStyle.COL_DIM)
			options_container.add_child(flavor)
	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()

func _on_button_pressed(index: int) -> void:
	var option = _catch_data.options[index]
	if option.narrative_text != "":
		_pending_narrative_index = index
		_show_narrative_panel(option)
	else:
		option_selected.emit(index)

func _show_narrative_panel(option: CatchOption) -> void:
	options_container.visible = false
	narrative_panel.visible = true
	narrative_text.text = option.narrative_text
	var entry = "[%s]\n\n%s" % [_catch_data.catch_name, option.narrative_text]
	GameState.journal_entries.append(entry)
	GameState.save()
	await get_tree().process_frame
	continue_button.grab_focus()

func _on_continue_pressed() -> void:
	narrative_panel.visible = false
	options_container.visible = true
	option_selected.emit(_pending_narrative_index)

func _behavior_tag(behavior: CatchData.BehaviorType) -> String:
	match behavior:
		CatchData.BehaviorType.PASSIVE:     return "[passive]"
		CatchData.BehaviorType.RESISTANT:   return "[resistant]"
		CatchData.BehaviorType.NEGOTIATING: return "[negotiating]"
		CatchData.BehaviorType.AGGRESSIVE:  return "[aggressive]"
	return ""

func _format_cost(option: CatchOption, behavior: CatchData.BehaviorType) -> String:
	if option.cuts_line:
		return "  resets tension — no reward"

	var parts: Array[String] = []
	if option.tension_delta > 0:
		parts.append("+%dT" % option.tension_delta)
	if option.credit_value > 0:
		parts.append("+%dcr" % option.credit_value)

	var base = "  " + ("  ·  ".join(parts) if parts.size() > 0 else "no cost")

	match behavior:
		CatchData.BehaviorType.RESISTANT:
			if option.resist_chance > 0.0:
				base += "   [%d%% resist: +%dT instead]" % [
					int(option.resist_chance * 100), option.resist_tension_penalty]
		CatchData.BehaviorType.NEGOTIATING:
			if option.roll_difficulty > 0.0:
				var fail_parts: Array[String] = []
				if option.fail_tension_delta > 0:
					fail_parts.append("+%dT" % option.fail_tension_delta)
				if option.fail_credit_value > 0:
					fail_parts.append("+%dcr" % option.fail_credit_value)
				else:
					fail_parts.append("+0cr")
				base += "   [%d%% fail: %s]" % [
					int(option.roll_difficulty * 100), "  ·  ".join(fail_parts)]

	return base
