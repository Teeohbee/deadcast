# scenes/ui/system_menu.gd
# The way out of the hub: RESUME, SOUND, CRT and SAVE & QUIT TO TITLE over a
# dimmed deck. UIController owns it, opens it on Menu/Esc from any hub tab and
# routes back/menu presses to close it. Focus is held inside while it's open
# and handed back to whatever had it on close.
class_name SystemMenu
extends Control

signal closed

# Test seam: leaving for the title swaps the whole scene.
var quit_to_title: Callable = func() -> void: UIController.navigate_to_title()

var resume_button: Button
var sound_button: Button
var crt_button: Button
var quit_button: Button

var _return_focus: WeakRef = null

func _init() -> void:
	theme = DeckStyle.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(DeckStyle.BG, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DeckStyle.panel_style(true))
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var heading := Label.new()
	heading.text = "deadcast_os · system"
	DeckStyle.apply_label(heading, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	box.add_child(heading)

	resume_button = _action("[ RESUME ]", DeckStyle.GREEN)
	resume_button.pressed.connect(close)
	sound_button = SettingsToggles.sound_button()
	crt_button = SettingsToggles.crt_button()
	quit_button = _action("[ SAVE & QUIT TO TITLE ]", DeckStyle.AMBER)
	quit_button.pressed.connect(_on_quit)
	for b in buttons():
		box.add_child(b)

	var list: Array[Control] = []
	list.assign(buttons())
	DeckNav.chain_vertical(list)
	DeckNav.link(list[0], list[list.size() - 1], SIDE_TOP)
	DeckNav.link(list[list.size() - 1], list[0], SIDE_BOTTOM)

func buttons() -> Array[Button]:
	return [resume_button, sound_button, crt_button, quit_button]

func is_open() -> bool:
	return visible

func open() -> void:
	var owner := get_viewport().gui_get_focus_owner()
	_return_focus = weakref(owner) if owner != null else null
	visible = true
	if get_parent() != null:
		get_parent().move_child(self, -1)
	resume_button.grab_focus()

func close() -> void:
	if not visible:
		return
	visible = false
	var back: Control = _return_focus.get_ref() if _return_focus != null else null
	if back != null and back.is_visible_in_tree():
		back.grab_focus()
	closed.emit()

func _on_quit() -> void:
	GameState.save()
	close()
	quit_to_title.call()

func _action(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	DeckStyle.apply_action_button(b, color)
	return b
