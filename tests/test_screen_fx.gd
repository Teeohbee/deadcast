# tests/test_screen_fx.gd
extends GutTest

func _make_screen() -> Control:
	var screen := Control.new()
	screen.size = Vector2(1280, 700)
	add_child_autofree(screen)
	return screen

func _count_wipes(screen: Control) -> int:
	var wipe_count := 0
	for child in screen.get_children():
		if child.name == ScreenFX.WIPE_NODE_NAME and not child.is_queued_for_deletion():
			wipe_count += 1
	return wipe_count

func test_wipe_covers_the_screen_then_removes_itself() -> void:
	var screen := _make_screen()
	ScreenFX.wipe_in(screen)
	assert_eq(_count_wipes(screen), 1, "wipe overlay should be added")
	await get_tree().create_timer(ScreenFX.WIPE_SECONDS + 0.15).timeout
	assert_eq(_count_wipes(screen), 0, "wipe overlay should be gone after the wipe")

func test_rapid_wipes_keep_a_single_overlay() -> void:
	var screen := _make_screen()
	ScreenFX.wipe_in(screen)
	ScreenFX.wipe_in(screen)
	assert_eq(_count_wipes(screen), 1)

func test_shake_returns_target_to_where_it_started() -> void:
	var screen := _make_screen()
	screen.position = Vector2(12, 34)
	ScreenFX.shake(screen, 8.0, 0.2)
	await get_tree().create_timer(0.35).timeout
	assert_eq(screen.position, Vector2(12, 34))

func test_flash_adds_an_overlay_that_fades_away() -> void:
	var screen := _make_screen()
	ScreenFX.flash(screen, DeckStyle.RED, 0.2)
	assert_eq(screen.get_child_count(), 1)
	await get_tree().create_timer(0.35).timeout
	await get_tree().process_frame
	assert_eq(screen.get_child_count(), 0)

func test_navigating_wipes_the_incoming_screen() -> void:
	var zone2 := Control.new()
	add_child_autofree(zone2)
	UIController.initialize(zone2)
	UIController.navigate_to("workshop")
	var screen := zone2.get_child(0) as Control
	assert_eq(_count_wipes(screen), 1)
