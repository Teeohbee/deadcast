# scenes/dive_run/SessionLog.gd
# Scrolling dive session log + the live decision block at its tail.
class_name SessionLog
extends Control

signal _choice_made(index: int)

@onready var scroll: ScrollContainer = $VBoxContainer/Scroll
@onready var log_text: RichTextLabel = $VBoxContainer/Scroll/LogText
@onready var live_block: VBoxContainer = $VBoxContainer/LiveBlock

var glitch_intensity: float = 0.0

func _ready() -> void:
	self.theme = UIStyle.get_theme()

func log_line(text: String, color: Color) -> void:
	var display := TextFX.corrupt(text, glitch_intensity)
	var safe := display.replace("[", "[lb]")
	log_text.append_text("[color=#%s]%s[/color]\n" % [color.to_html(false), safe])
	_scroll_to_bottom()

func present_choices(labels: Array[String], echoes: Array[String]) -> int:
	clear_live()
	for i in labels.size():
		var btn := Button.new()
		btn.text = labels[i]
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIStyle.apply_button(btn)
		var idx := i
		btn.pressed.connect(func() -> void: _choice_made.emit(idx))
		live_block.add_child(btn)
	if live_block.get_child_count() > 0:
		(live_block.get_child(0) as Button).grab_focus()
	var index: int = await _choice_made
	clear_live()
	if index < echoes.size() and echoes[index] != "":
		log_line("> %s" % echoes[index], UIStyle.COL_DIM)
	return index

func present_continue() -> void:
	clear_live()
	var btn := Button.new()
	btn.text = "[CONTINUE →]"
	btn.focus_mode = Control.FOCUS_ALL
	UIStyle.apply_button(btn)
	btn.pressed.connect(func() -> void: _choice_made.emit(0))
	live_block.add_child(btn)
	btn.grab_focus()
	await _choice_made
	clear_live()

func clear_live() -> void:
	for child in live_block.get_children():
		live_block.remove_child(child)
		child.queue_free()

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
