# scenes/title_skyline/SkylineTitle.gd
# The title screen: the Sump in the rain, the Meridian riding the swell, and
# the wordmark fading in over the city to music. A fades the title and pushes
# the camera into the terminal on the Meridian's deck. That terminal shows the
# real terminal title (CONTINUE / NEW GAME), rendered live in a SubViewport at
# the window's own layout size. It boots up as the camera arrives; when the
# screen fills the frame the same title node moves out of the SubViewport to
# become the current scene, so nothing jumps. A again during the push skips.
class_name SkylineTitle
extends Node

enum State { FADING_IN, WAITING, PUSHING, LEAVING }

const TERMINAL_TITLE := preload("res://scenes/title_screen/TitleScreen.tscn")
const SKYLINE_SHOT := preload("res://scenes/intro/SkylineShot.tscn")
const TERMINAL_TITLE_SCRIPT := preload("res://scenes/title_screen/TitleScreen.gd")

const TITLE_DELAY_SECONDS := 1.2
const TITLE_FADE_IN_SECONDS := 2.5
const TITLE_FADE_OUT_SECONDS := 0.5
const PUSH_SECONDS := 3.5
const WORDMARK_FONT_SIZE := 22
const PROMPT_BLINK_SECONDS := 1.1
const HANDOVER_FADE_SECONDS := 0.25

var state: State = State.FADING_IN
var shot: SkylineShot
var overlay: Control
var wordmark_label: Label
var tagline_label: Label
var prompt_label: Label
var terminal_viewport: SubViewport
var terminal_title: Control
# Swapped out in tests, which can't hand the scene tree over.
var hand_over: Callable = _hand_over_to_terminal_title

var _title_tween: Tween

func _ready() -> void:
	shot = SKYLINE_SHOT.instantiate()
	add_child(shot)
	shot.push_finished.connect(_on_push_finished)
	_build_terminal_viewport()
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
	terminal_title.play_boot_flicker()
	shot.push_to_terminal(PUSH_SECONDS)

func _on_push_finished() -> void:
	_leave()

func _leave() -> void:
	if state == State.LEAVING:
		return
	state = State.LEAVING
	terminal_title.finish_boot_flicker()
	hand_over.call(terminal_title)

# Move the live terminal title out of the SubViewport to be the current scene,
# fade it up over the last 3D frame (hiding the tonemapper's slight colour
# shift), then free the skyline.
func _hand_over_to_terminal_title(title: Control) -> void:
	var tree := get_tree()
	terminal_viewport.remove_child(title)
	title.modulate.a = 0.0
	tree.root.add_child(title)
	tree.current_scene = title
	title.focus_default_action()
	var fade := title.create_tween()
	fade.tween_property(title, "modulate:a", 1.0, HANDOVER_FADE_SECONDS)
	fade.tween_callback(queue_free)

# The terminal title renders at the window's real pixel size with the same
# layout size the game uses full screen, so the screen texture matches the
# full-screen title exactly when it fills the frame.
func _build_terminal_viewport() -> void:
	var layout_size := Vector2i(get_viewport().get_visible_rect().size)
	var pixel_size := get_window().size if get_window() else layout_size
	terminal_viewport = SubViewport.new()
	terminal_viewport.name = "TerminalViewport"
	terminal_viewport.size = pixel_size
	terminal_viewport.size_2d_override = layout_size
	terminal_viewport.size_2d_override_stretch = true
	terminal_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(terminal_viewport)
	terminal_title = TERMINAL_TITLE.instantiate()
	terminal_viewport.add_child(terminal_title)
	shot.meridian.set_screen_aspect(float(layout_size.x) / float(layout_size.y))
	shot.meridian.set_screen_texture(terminal_viewport.get_texture())

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
