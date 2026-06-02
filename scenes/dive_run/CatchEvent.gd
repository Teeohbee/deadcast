# scenes/dive_run/CatchEvent.gd
class_name CatchEvent
extends Control

signal option_selected(index: int)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var flavor_label: Label = $VBoxContainer/FlavorLabel
@onready var options_container: VBoxContainer = $VBoxContainer/OptionsContainer

func populate(catch_data: CatchData) -> void:
	name_label.text = catch_data.catch_name
	flavor_label.text = catch_data.flavor_text
	for child in options_container.get_children():
		child.queue_free()
	for i in catch_data.options.size():
		var btn = Button.new()
		btn.text = catch_data.options[i].label
		btn.focus_mode = Control.FOCUS_ALL
		var idx = i
		btn.pressed.connect(func() -> void: option_selected.emit(idx))
		options_container.add_child(btn)
		if catch_data.options[i].flavor_text != "":
			var flavor = Label.new()
			flavor.text = catch_data.options[i].flavor_text
			flavor.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			options_container.add_child(flavor)
	if options_container.get_child_count() > 0:
		options_container.get_child(0).grab_focus()
