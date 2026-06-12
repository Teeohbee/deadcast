extends GutTest

var log_scene := preload("res://scenes/dive_run/SessionLog.tscn")

func _make_log() -> SessionLog:
	var sl: SessionLog = log_scene.instantiate()
	add_child_autofree(sl)
	return sl

func test_log_line_renders_brackets_literally() -> void:
	var sl := _make_log()
	sl.log_line("contact [DATA_CONTAINER] found", UIStyle.COL_TEXT)
	assert_string_contains(sl.log_text.get_parsed_text(), "[DATA_CONTAINER]")

func test_present_choices_returns_index_and_echoes() -> void:
	var sl := _make_log()
	var state := {"result": -1}
	_run_choice(sl, state)        # starts the coroutine; it pauses awaiting a press
	await wait_frames(2)
	assert_eq(sl.live_block.get_child_count(), 2, "two buttons presented")
	(sl.live_block.get_child(1) as Button).pressed.emit()
	await wait_frames(2)
	assert_eq(state.result, 1)
	assert_string_contains(sl.log_text.get_parsed_text(), "> release")
	assert_eq(sl.live_block.get_child_count(), 0, "live block cleared after choice")

func _run_choice(sl: SessionLog, state: Dictionary) -> void:
	state.result = await sl.present_choices(["[1] reel_in", "[2] release"], ["reel_in", "release"])
