# scenes/title_skyline/SkylineTitle.gd
# The title screen: the Sump in the rain, the Meridian riding the swell, and
# the wordmark fading in over the city to music. A fades the title and pushes
# the camera into the terminal on the Meridian's deck, landing on the
# terminal title (CONTINUE / NEW GAME). A again during the push skips it.
class_name SkylineTitle
extends Node

enum State { FADING_IN, WAITING, PUSHING, LEAVING }

const TERMINAL_TITLE := "res://scenes/title_screen/TitleScreen.tscn"
const SKYLINE_SHOT := preload("res://scenes/intro/SkylineShot.tscn")
const TERMINAL_TITLE_SCRIPT := preload("res://scenes/title_screen/TitleScreen.gd")

const TITLE_DELAY_SECONDS := 1.2
const TITLE_FADE_IN_SECONDS := 2.5
const TITLE_FADE_OUT_SECONDS := 0.5
const PUSH_SECONDS := 3.5
const WORDMARK_FONT_SIZE := 22
const PROMPT_BLINK_SECONDS := 1.1

var state: State = State.FADING_IN
var shot: SkylineShot
var overlay: Control
var wordmark_label: Label
var tagline_label: Label
var prompt_label: Label
# Swapped out in tests so they can see where the title would go.
var change_scene: Callable = func(path: String) -> void: get_tree().change_scene_to_file(path)

var _title_tween: Tween

func _ready() -> void:
	shot = SKYLINE_SHOT.instantiate()
	add_child(shot)
	shot.push_finished.connect(_on_push_finished)
	_build_overlay()
	if not Input.get_connected_joypads().is_empty():
		InputGlyphs.mode = InputGlyphs.Mode.PAD
	InputGlyphs.device_changed.connect(func(_mode: int) -> void: refresh_prompt())
	refresh_prompt()
	Audio.set_ambience("title")
	_fade_title_in()

func refresh_prompt() -> void:
	prompt_label.text = "PRESS %s" % InputGlyphs.glyph("accept")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	match state:
		State.FADING_IN, State.WAITING:
			_start_push()
		State.PUSHING:
			_leave()

func _start_push() -> void:
	state = State.PUSHING
	if _title_tween:
		_title_tween.kill()
	_title_tween = create_tween()
	_title_tween.tween_property(overlay, "modulate:a", 0.0, TITLE_FADE_OUT_SECONDS)
	shot.push_to_terminal(PUSH_SECONDS)

func _on_push_finished() -> void:
	_leave()

func _leave() -> void:
	if state == State.LEAVING:
		return
	state = State.LEAVING
	change_scene.call(TERMINAL_TITLE)

func _fade_title_in() -> void:
	overlay.modulate.a = 0.0
	_title_tween = create_tween()
	_title_tween.tween_interval(TITLE_DELAY_SECONDS)
	_title_tween.tween_property(overlay, "modulate:a", 1.0, TITLE_FADE_IN_SECONDS)
	_title_tween.tween_callback(_on_title_shown)

func _on_title_shown() -> void:
	if state == State.FADING_IN:
		state = State.WAITING

# Wordmark and tagline in the upper sky, the prompt low over the water.
func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	overlay = Control.new()
	overlay.name = "TitleOverlay"
	overlay.theme = DeckStyle.get_theme()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)

	var title_column := VBoxContainer.new()
	title_column.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_column.anchor_left = 0.0
	title_column.anchor_right = 1.0
	title_column.offset_top = 70.0
	title_column.add_theme_constant_override("separation", 14)
	overlay.add_child(title_column)

	wordmark_label = Label.new()
	wordmark_label.text = TERMINAL_TITLE_SCRIPT.WORDMARK
	# Left-aligned lines, centred block, or the letters shear.
	wordmark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	wordmark_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	DeckStyle.apply_label(wordmark_label, DeckStyle.GREEN, WORDMARK_FONT_SIZE)
	_add_glow(wordmark_label, DeckStyle.GREEN)
	title_column.add_child(wordmark_label)

	tagline_label = Label.new()
	tagline_label.text = TERMINAL_TITLE_SCRIPT.TAGLINE
	tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DeckStyle.apply_label(tagline_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	_add_glow(tagline_label, Color(0, 0, 0))
	title_column.add_child(tagline_label)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.anchor_left = 0.0
	prompt_label.anchor_right = 1.0
	prompt_label.offset_top = -90.0
	prompt_label.offset_bottom = -60.0
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DeckStyle.apply_label(prompt_label, DeckStyle.GREEN, DeckStyle.SIZE_BODY + 4)
	_add_glow(prompt_label, Color(0, 0, 0))
	overlay.add_child(prompt_label)
	var blink := create_tween().set_loops()
	blink.tween_property(prompt_label, "modulate:a", 0.25, PROMPT_BLINK_SECONDS)
	blink.tween_property(prompt_label, "modulate:a", 1.0, PROMPT_BLINK_SECONDS)

# A soft shadow behind the text: a glow for the wordmark, and a dark halo
# for smaller text so it reads against the neon.
func _add_glow(label: Label, colour: Color) -> void:
	label.add_theme_color_override("font_shadow_color", Color(colour, 0.45))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_constant_override("shadow_outline_size", 10)
