extends GutTest

const PATH := "user://test_lifecycle.log"

func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

func _fresh() -> Node:
	var lifecycle: Node = load("res://autoload/Lifecycle.gd").new()
	lifecycle.log_path = PATH
	add_child_autofree(lifecycle)
	return lifecycle

func test_it_logs_a_start_line_and_flushes_each_write() -> void:
	var lifecycle := _fresh()
	lifecycle.write("hello")
	var text := FileAccess.get_file_as_string(PATH)
	assert_string_contains(text, "---- start")
	assert_string_contains(text, "hello")

func test_it_appends_across_runs() -> void:
	_fresh().write("first run")
	_fresh().write("second run")
	var text := FileAccess.get_file_as_string(PATH)
	assert_string_contains(text, "first run")
	assert_string_contains(text, "second run")

func test_an_oversized_log_is_dropped_at_start() -> void:
	var big := FileAccess.open(PATH, FileAccess.WRITE)
	big.store_string("x".repeat(250_000))
	big = null
	_fresh()
	assert_lt(FileAccess.get_file_as_string(PATH).length(), 10_000)
