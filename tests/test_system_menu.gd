# tests/test_system_menu.gd
extends GutTest

var _quits := 0

func before_each() -> void:
	_quits = 0

func _menu() -> SystemMenu:
	var m := SystemMenu.new()
	m.quit_to_title = func() -> void: _quits += 1
	add_child_autofree(m)
	return m

func test_starts_closed() -> void:
	var m := _menu()
	assert_false(m.is_open())

func test_open_shows_and_focuses_resume() -> void:
	var m := _menu()
	m.open()
	assert_true(m.is_open())
	assert_true(m.resume_button.has_focus())

func test_offers_resume_sound_crt_and_quit_in_order() -> void:
	var m := _menu()
	var labels: Array = m.buttons().map(func(b: Button) -> String: return b.text)
	assert_eq(labels.size(), 4)
	assert_string_contains(labels[0], "RESUME")
	assert_string_contains(labels[1], "SOUND")
	assert_string_contains(labels[2], "CRT")
	assert_string_contains(labels[3], "QUIT TO TITLE")

func test_focus_wraps_top_to_bottom() -> void:
	var m := _menu()
	var first: Button = m.buttons()[0]
	var last: Button = m.buttons()[3]
	assert_eq(first.get_node(first.focus_neighbor_top), last)
	assert_eq(last.get_node(last.focus_neighbor_bottom), first)

func test_resume_closes_and_hands_focus_back() -> void:
	var before := Button.new()
	add_child_autofree(before)
	before.grab_focus()
	var m := _menu()
	m.open()
	m.resume_button.pressed.emit()
	assert_false(m.is_open())
	assert_true(before.has_focus())

func test_quit_saves_then_leaves_for_the_title() -> void:
	DirAccess.remove_absolute(GameState.save_path)
	var m := _menu()
	m.open()
	m.quit_button.pressed.emit()
	assert_true(FileAccess.file_exists(GameState.save_path))
	assert_eq(_quits, 1)
	DirAccess.remove_absolute(GameState.save_path)

func test_blocks_the_mouse_from_the_screen_behind() -> void:
	var m := _menu()
	assert_eq(m.mouse_filter, Control.MOUSE_FILTER_STOP)
