extends GutTest

const BOOT := preload("res://scenes/boot/BootSequence.tscn")

func _instantiate_boot() -> Control:
	var boot := BOOT.instantiate()
	add_child_autofree(boot)
	return boot

func test_mouse_click_skips_boot_sequence() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	boot._finished = false
	boot._waiting_for_key = false

	var click := InputEventMouseButton.new()
	click.pressed = true
	boot._input(click)

	assert_true(boot._finished)

func test_screen_touch_skips_boot_sequence() -> void:
	var boot := _instantiate_boot()
	await get_tree().process_frame
	boot._finished = false
	boot._waiting_for_key = false

	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	boot._input(touch)

	assert_true(boot._finished)
