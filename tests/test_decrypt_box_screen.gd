# tests/test_decrypt_box_screen.gd
extends GutTest

const SCREEN := preload("res://scenes/barge_hub/DecryptBox.tscn")

func before_each() -> void:
	GameState.credits = 50000
	GameState.decrypt_box_queue = 0
	GameState.decrypt_box_runs = 0

func _make() -> Node:
	var s := SCREEN.instantiate()
	add_child_autofree(s)
	return s

func test_screen_instantiates_with_panels() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_not_null(s._cipher_crack)
	assert_not_null(s._cipher_log)

func test_crack_idle_when_queue_empty() -> void:
	GameState.decrypt_box_queue = 0
	var s := _make()
	await get_tree().process_frame
	assert_false(s._cipher_crack._active)

func test_crack_active_when_queued() -> void:
	GameState.decrypt_box_queue = 1000
	GameState.decrypt_box_runs = 1
	var s := _make()
	await get_tree().process_frame
	assert_true(s._cipher_crack._active)

func test_one_block_at_a_time() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_false(s.load_button.disabled)
	s.load_button.pressed.emit()
	assert_eq(GameState.decrypt_box_queue, 1000)
	assert_true(s.load_button.disabled, "a queued block locks the box until it pays out")
	assert_eq(GameState.credits, 49000)
