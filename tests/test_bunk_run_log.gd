extends GutTest

const BUNK := preload("res://scenes/barge_hub/Bunk.tscn")

func before_each() -> void:
	GameState.run_logs = [] as Array[Dictionary]

func after_each() -> void:
	GameState.run_logs = [] as Array[Dictionary]

func _make_bunk() -> Node:
	var b := BUNK.instantiate()
	add_child_autofree(b)
	return b

func _record(run: int) -> Dictionary:
	return {
		"run": run, "zone": "axiom depths", "entries": [],
		"banked": 250, "forfeited": 0, "outcome": "surfaced",
	}

func test_run_log_toggle_exists() -> void:
	var b := _make_bunk()
	assert_not_null(b.log_toggle)

func test_empty_run_logs_shows_placeholder() -> void:
	var b := _make_bunk()
	b._set_mode(b.Mode.LOG)
	assert_string_contains(b.content_label.text, "no archived runs")

func test_run_log_shows_newest_first() -> void:
	GameState.add_run_log(_record(1))
	GameState.add_run_log(_record(2))
	var b := _make_bunk()
	b._set_mode(b.Mode.LOG)
	var text: String = b.content_label.text
	assert_true(text.find("RUN_002") < text.find("RUN_001"), "run 2 should appear before run 1")

func test_run_log_toggle_activates_log_mode() -> void:
	GameState.add_run_log(_record(1))
	var b := _make_bunk()
	b.log_toggle.pressed.emit()
	assert_string_contains(b.content_label.text, "RUN_001")

# The right stick scrolls the reader, so the page buttons stay for the mouse
# but drop out of pad navigation and the pad lands on the mode toggles.
func test_reader_is_the_scroll_target() -> void:
	var b := _make_bunk()
	assert_eq(b.scroll_target(), b.scroll_container)

func test_page_buttons_are_mouse_only() -> void:
	var b := _make_bunk()
	assert_eq(b.page_up_btn.focus_mode, Control.FOCUS_NONE)
	assert_eq(b.page_down_btn.focus_mode, Control.FOCUS_NONE)

func test_default_focus_is_the_current_mode_toggle() -> void:
	var b := _make_bunk()
	b._set_mode(b.Mode.LOG)
	assert_eq(b.default_focus(), b.log_toggle)
