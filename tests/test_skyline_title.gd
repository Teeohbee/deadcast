extends GutTest

# The skyline title: the city in the rain, the wordmark over it, and A to
# push in to the terminal. These tests check the flow, not the look.

const SCENE := preload("res://scenes/title_skyline/SkylineTitle.tscn")
const TERMINAL_TITLE := "res://scenes/title_screen/TitleScreen.tscn"

var _handed_over: Array[Node] = []
var _previous_glyph_mode: int

func before_each() -> void:
	_handed_over.clear()
	_previous_glyph_mode = InputGlyphs.mode

func after_each() -> void:
	InputGlyphs.mode = _previous_glyph_mode
	Audio.set_ambience("hub")

func _make() -> SkylineTitle:
	var title: SkylineTitle = SCENE.instantiate()
	title.hand_over = func(terminal_title: Node) -> void: _handed_over.append(terminal_title)
	add_child_autofree(title)
	return title

func _press_accept(title: SkylineTitle) -> void:
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	title._unhandled_input(press)

func test_game_launches_into_the_skyline_title() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/title_skyline/SkylineTitle.tscn")

func test_title_starts_hidden_and_fades_in() -> void:
	var title := _make()
	assert_eq(title.state, SkylineTitle.State.FADING_IN)
	assert_almost_eq(title.overlay.modulate.a, 0.0, 0.01)

func test_title_shows_the_wordmark_and_tagline() -> void:
	var title := _make()
	assert_string_contains(title.wordmark_label.text, "██████╗")
	assert_eq(title.tagline_label.text, "signal trawling in the drowned city")

func test_prompt_names_the_pad_button_on_a_pad() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var title := _make()
	assert_true(title.prompt_label.shows_icon())
	assert_same(title.prompt_label.icon_rect.texture, InputGlyphs.icon("accept"))

func test_prompt_names_the_key_on_a_keyboard() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY
	var title := _make()
	title.refresh_prompt()
	assert_eq(title.prompt_label.label.text, "PRESS [ENTER]")

func test_accept_starts_the_push_without_leaving_yet() -> void:
	var title := _make()
	_press_accept(title)
	assert_eq(title.state, SkylineTitle.State.PUSHING)
	assert_eq(_handed_over, [])

func test_the_terminal_screen_shows_the_live_terminal_title() -> void:
	var title := _make()
	assert_not_null(title.terminal_title.get("continue_button"), "terminal title should be the real TitleScreen")
	assert_eq(title.shot.meridian.screen_texture(), title.terminal_viewport.get_texture())

func test_terminal_viewport_matches_the_window_layout() -> void:
	var title := _make()
	assert_eq(title.terminal_viewport.size_2d_override, Vector2i(title.get_viewport().get_visible_rect().size))

func test_pushing_boots_the_terminal() -> void:
	var title := _make()
	_press_accept(title)
	assert_true(title.terminal_title.is_booting)

func test_accept_during_the_push_hands_over_the_booted_terminal() -> void:
	var title := _make()
	_press_accept(title)
	_press_accept(title)
	assert_eq(_handed_over, [title.terminal_title])
	assert_false(title.terminal_title.is_booting)

func test_finished_push_hands_over_once() -> void:
	var title := _make()
	_press_accept(title)
	title.shot.push_finished.emit()
	_press_accept(title)
	assert_eq(_handed_over.size(), 1)

func test_push_ends_on_the_terminal_screen() -> void:
	var title := _make()
	title.shot.set_push_progress(1.0)
	var to_screen := title.shot.meridian.terminal_screen_position() - title.shot.camera.global_position
	var looking := -title.shot.camera.global_transform.basis.z
	assert_gt(looking.normalized().dot(to_screen.normalized()), 0.99, "camera should look at the screen")

func test_title_plays_the_title_music() -> void:
	_make()
	assert_eq(Audio.current_ambience, "title")

# Switching glow off mid-push stalls the GL driver for ~200ms (the stutter at
# 85%), so the push fades glow out instead and never toggles it.
func test_glow_stays_enabled_through_the_push() -> void:
	var title := _make()
	for progress in [0.0, 0.5, 0.86, 0.95, 1.0]:
		title.shot.set_push_progress(progress)
		assert_true(title.shot._environment.glow_enabled, "glow on at %.2f" % progress)

func test_glow_is_full_early_in_the_push_and_gone_by_the_close_view() -> void:
	var title := _make()
	title.shot.set_push_progress(0.5)
	assert_almost_eq(title.shot._environment.glow_intensity, SkylineShot.GLOW_INTENSITY, 0.001)
	title.shot.set_push_progress(0.86)
	assert_almost_eq(title.shot._environment.glow_intensity, 0.0, 0.001)
