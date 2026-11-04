extends GutTest

# The skyline title: the city in the rain, the wordmark over it, and A to
# push in to the terminal. These tests check the flow, not the look.

const SCENE := preload("res://scenes/title_skyline/SkylineTitle.tscn")
const TERMINAL_TITLE := "res://scenes/title_screen/TitleScreen.tscn"

var _requested_scenes: Array[String] = []
var _previous_glyph_mode: int

func before_each() -> void:
	_requested_scenes.clear()
	_previous_glyph_mode = InputGlyphs.mode

func after_each() -> void:
	InputGlyphs.mode = _previous_glyph_mode
	Audio.set_ambience("hub")

func _make() -> SkylineTitle:
	var title: SkylineTitle = SCENE.instantiate()
	title.change_scene = func(path: String) -> void: _requested_scenes.append(path)
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
	assert_string_contains(title.prompt_label.text, "[A]")

func test_prompt_names_the_key_on_a_keyboard() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY
	var title := _make()
	title.refresh_prompt()
	assert_string_contains(title.prompt_label.text, "[ENTER]")

func test_accept_starts_the_push_without_leaving_yet() -> void:
	var title := _make()
	_press_accept(title)
	assert_eq(title.state, SkylineTitle.State.PUSHING)
	assert_eq(_requested_scenes, [])

func test_accept_during_the_push_skips_to_the_terminal_title() -> void:
	var title := _make()
	_press_accept(title)
	_press_accept(title)
	assert_eq(_requested_scenes, [TERMINAL_TITLE])

func test_finished_push_goes_to_the_terminal_title_once() -> void:
	var title := _make()
	_press_accept(title)
	title.shot.push_finished.emit()
	_press_accept(title)
	assert_eq(_requested_scenes, [TERMINAL_TITLE])

func test_push_ends_on_the_terminal_screen() -> void:
	var title := _make()
	title.shot.set_push_progress(1.0)
	var to_screen := title.shot.meridian.terminal_screen_position() - title.shot.camera.global_position
	var looking := -title.shot.camera.global_transform.basis.z
	assert_gt(looking.normalized().dot(to_screen.normalized()), 0.99, "camera should look at the screen")

func test_title_plays_the_title_music() -> void:
	_make()
	assert_eq(Audio.current_ambience, "title")
