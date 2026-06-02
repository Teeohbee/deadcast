# scenes/dive_run/CatchEvent.gd
class_name CatchEvent
extends Control

signal option_selected(index: int)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var flavor_label: Label = $VBoxContainer/FlavorLabel
@onready var options_container: VBoxContainer = $VBoxContainer/OptionsContainer

func populate(catch_data: CatchData) -> void:
	var behavior_tag = _behavior_tag(catch_data.behavior)
	name_label.text = "%s  %s" % [behavior_tag, catch_data.catch_name]
	flavor_label.text = catch_data.flavor_text
	for child in options_container.get_children():
		child.queue_free()
	for i in catch_data.options.size():
		var option = catch_data.options[i]
		var btn = Button.new()
		btn.text = option.label
		btn.focus_mode = Control.FOCUS_ALL
		var idx = i
		btn.pressed.connect(func() -> void: option_selected.emit(idx))
		options_container.add_child(btn)
		var cost_label = Label.new()
		cost_label.text = _format_cost(option, catch_data.behavior)
		cost_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
		options_container.add_child(cost_label)
		if option.flavor_text != "":
			var flavor = Label.new()
			flavor.text = option.flavor_text
			flavor.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			options_container.add_child(flavor)
	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()

func _behavior_tag(behavior: CatchData.BehaviorType) -> String:
	match behavior:
		CatchData.BehaviorType.PASSIVE:     return "[PASSIVE]"
		CatchData.BehaviorType.RESISTANT:   return "[RESISTANT]"
		CatchData.BehaviorType.NEGOTIATING: return "[NEGOTIATING]"
		CatchData.BehaviorType.AGGRESSIVE:  return "[AGGRESSIVE]"
	return ""

func _format_cost(option: CatchOption, behavior: CatchData.BehaviorType) -> String:
	if option.cuts_line:
		return "resets tension — no reward"

	var parts: Array[String] = []
	if option.tension_delta > 0:
		parts.append("+%dT" % option.tension_delta)
	if option.credit_value > 0:
		parts.append("+%dcr" % option.credit_value)

	var base = "  ·  ".join(parts) if parts.size() > 0 else "no cost"

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
