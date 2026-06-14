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
