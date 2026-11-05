# tests/test_ui_controller.gd
extends GutTest

var _zone2: Control
var _saved_run_count: int

class FakeScreen:
	extends Control
	var shown_count: int = 0
	var button: Button
	func _init() -> void:
		button = Button.new()
		button.focus_mode = Control.FOCUS_ALL
		add_child(button)
	func on_screen_shown() -> void:
		shown_count += 1
	func default_focus() -> Control:
		return button

class ScrollingScreen:
	extends Control
	var scroll: ScrollContainer
	func _init() -> void:
		scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(100, 100)
		scroll.size = Vector2(100, 100)
		var tall := Control.new()
		tall.custom_minimum_size = Vector2(50, 2000)
		scroll.add_child(tall)
		add_child(scroll)
	func scroll_target() -> Control:
		return scroll

func _action(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e

func before_each() -> void:
	_zone2 = Control.new()
	add_child_autofree(_zone2)
	GameState.pressure_level = 0
	_saved_run_count = GameState.run_count
	GameState.run_count = 10  # every tab open
	UIController._scene_factory = func(_id: String) -> Node:
		return FakeScreen.new()
	UIController.initialize(_zone2)

func after_each() -> void:
	UIController.fresh_tabs.clear()
	GameState.run_count = _saved_run_count
	UIController._scene_factory = UIController._default_scene_factory

# --- navigation behaviour (retained from the original test file) ---

func test_navigate_to_sets_current_screen() -> void:
	UIController.navigate_to("workshop")
	assert_eq(UIController.current_screen, "workshop")

func test_navigate_to_emits_screen_changed() -> void:
	watch_signals(UIController)
	UIController.navigate_to("bunk")
	assert_signal_emitted_with_parameters(UIController, "screen_changed", ["bunk"])

func test_navigate_to_dive_emits_dive_state_true() -> void:
	watch_signals(UIController)
	UIController.navigate_to("dive")
	assert_signal_emitted_with_parameters(UIController, "dive_state_changed", [true])

func test_navigate_to_deck_emits_dive_state_false() -> void:
	watch_signals(UIController)
	UIController.navigate_to("deck")
	assert_signal_emitted_with_parameters(UIController, "dive_state_changed", [false])

func test_only_one_screen_visible_at_a_time() -> void:
	# Persistent screens stay in the container (hidden) instead of being freed,
	# so the container accumulates children but only the current one is visible.
	UIController.navigate_to("workshop")
	UIController.navigate_to("bunk")
	var visible_count := 0
	for child in _zone2.get_children():
		if (child as Control).visible:
			visible_count += 1
	assert_eq(visible_count, 1, "exactly one screen should be visible at a time")

func test_cycle_tab_advances_from_deck_to_workshop() -> void:
	UIController.navigate_to("deck")
	UIController._cycle_tab(1)
	assert_eq(UIController.current_screen, "workshop")

func test_cycle_tab_wraps_from_vendors_to_deck() -> void:
	UIController.navigate_to("vendors")
	UIController._cycle_tab(1)
	assert_eq(UIController.current_screen, "deck")

func test_cycle_tab_wraps_backward_from_deck_to_vendors() -> void:
	UIController.navigate_to("deck")
	UIController._cycle_tab(-1)
	assert_eq(UIController.current_screen, "vendors")

# --- caching / lifecycle behaviour (new) ---

func test_persistent_revisit_reuses_same_instance() -> void:
	UIController.navigate_to("deck")
	var first := UIController._current_node
	UIController.navigate_to("workshop")
	UIController.navigate_to("deck")
	assert_true(first == UIController._current_node, "deck should be the cached instance")

func test_leaving_persistent_hides_not_frees() -> void:
	UIController.navigate_to("deck")
	var deck := UIController._current_node
	UIController.navigate_to("workshop")
	assert_true(is_instance_valid(deck), "deck must stay alive")
	assert_false(deck.visible, "deck must be hidden when not current")
	assert_eq(deck.get_parent(), _zone2, "deck must remain in the container")

func test_transient_is_freed_and_rebuilt() -> void:
	UIController.navigate_to("deck")
	UIController.navigate_to("dive")
	var dive1 := UIController._current_node
	UIController.navigate_to("deck")
	await get_tree().process_frame
	assert_false(is_instance_valid(dive1), "old dive instance must be freed")
	UIController.navigate_to("dive")
	assert_true(is_instance_valid(UIController._current_node), "a fresh dive must exist")
	assert_true(UIController._current_node != dive1, "dive must be a new instance")

func test_on_screen_shown_fires_on_every_reveal() -> void:
	UIController.navigate_to("deck")
	var deck := UIController._current_node as FakeScreen
	assert_eq(deck.shown_count, 1)
	UIController.navigate_to("workshop")
	UIController.navigate_to("deck")
	assert_eq(deck.shown_count, 2)

func test_initialize_clears_cache() -> void:
	UIController.navigate_to("deck")
	var first := UIController._current_node
	UIController.initialize(_zone2)
	UIController.navigate_to("deck")
	assert_true(UIController._current_node != first, "re-init must drop the cached instance")

func test_navigate_to_deck_remaps_to_gameover_under_pressure() -> void:
	GameState.pressure_level = 5
	UIController.navigate_to("deck")
	assert_eq(UIController.current_screen, "gameover")

# --- staged unlocks ---

func test_cycle_tab_skips_locked_tabs_for_a_new_operator() -> void:
	GameState.run_count = 0
	UIController.navigate_to("deck")
	UIController._cycle_tab(1)
	assert_eq(UIController.current_screen, "bunk")
	UIController._cycle_tab(1)
	assert_eq(UIController.current_screen, "relay")
	UIController._cycle_tab(1)
	assert_eq(UIController.current_screen, "deck")

func test_cycle_tab_backward_skips_locked_tabs() -> void:
	GameState.run_count = 0
	UIController.navigate_to("deck")
	UIController._cycle_tab(-1)
	assert_eq(UIController.current_screen, "relay")
	UIController._cycle_tab(-1)
	assert_eq(UIController.current_screen, "bunk")

func test_navigating_to_a_locked_tab_lands_on_the_deck() -> void:
	GameState.run_count = 0
	UIController.navigate_to("decrypt")
	assert_eq(UIController.current_screen, "deck")

func test_dive_is_never_locked() -> void:
	GameState.run_count = 0
	UIController.navigate_to("dive")
	assert_eq(UIController.current_screen, "dive")

func test_fresh_tabs_clear_when_visited() -> void:
	UIController.mark_fresh_tabs(["workshop", "vendors", "exchange"] as Array[String])
	assert_eq(UIController.fresh_tabs, ["workshop", "vendors"] as Array[String], "zones are not tabs")
	UIController.navigate_to("workshop")
	assert_eq(UIController.fresh_tabs, ["vendors"] as Array[String])

# --- pad back and focus recovery ---

func test_back_returns_to_deck_from_a_hub_tab() -> void:
	UIController.navigate_to("workshop")
	UIController._unhandled_input(_action("ui_cancel"))
	assert_eq(UIController.current_screen, "deck")

func test_back_on_deck_stays_on_deck() -> void:
	UIController.navigate_to("deck")
	watch_signals(UIController)
	UIController._unhandled_input(_action("ui_cancel"))
	assert_eq(UIController.current_screen, "deck")
	assert_signal_not_emitted(UIController, "screen_changed")

func test_back_is_ignored_mid_dive() -> void:
	UIController.navigate_to("dive")
	UIController._unhandled_input(_action("ui_cancel"))
	assert_eq(UIController.current_screen, "dive")

func test_pad_input_with_nothing_focused_restores_the_screen_default() -> void:
	UIController.navigate_to("bunk")
	var screen: FakeScreen = UIController._current_node
	screen.button.release_focus()
	assert_null(get_viewport().gui_get_focus_owner())
	UIController._unhandled_input(_action("ui_down"))
	assert_true(screen.button.has_focus())

func test_focus_recovery_works_mid_dive_too() -> void:
	UIController.navigate_to("dive")
	var screen: FakeScreen = UIController._current_node
	screen.button.release_focus()
	UIController._unhandled_input(_action("ui_accept"))
	assert_true(screen.button.has_focus())

func test_focus_recovery_skips_a_hidden_default() -> void:
	UIController.navigate_to("bunk")
	var screen: FakeScreen = UIController._current_node
	screen.button.release_focus()
	screen.button.visible = false
	UIController._unhandled_input(_action("ui_down"))
	assert_null(get_viewport().gui_get_focus_owner())

# --- right-stick scrolling ---

func _scrolling_screen() -> ScrollingScreen:
	UIController._scene_factory = func(_id: String) -> Node:
		return ScrollingScreen.new()
	UIController.navigate_to("bunk")
	await get_tree().process_frame
	return UIController._current_node

func test_stick_down_scrolls_the_screen_target() -> void:
	var screen: ScrollingScreen = await _scrolling_screen()
	UIController.apply_scroll(1.0, 0.1)
	assert_gt(screen.scroll.scroll_vertical, 0)

func test_stick_up_at_the_top_stays_put() -> void:
	var screen: ScrollingScreen = await _scrolling_screen()
	UIController.apply_scroll(-1.0, 0.1)
	assert_eq(screen.scroll.scroll_vertical, 0)

func test_scroll_speed_follows_stick_deflection() -> void:
	var screen: ScrollingScreen = await _scrolling_screen()
	UIController.apply_scroll(0.5, 0.1)
	var half := screen.scroll.scroll_vertical
	screen.scroll.scroll_vertical = 0
	UIController.apply_scroll(1.0, 0.1)
	assert_gt(screen.scroll.scroll_vertical, half)

func test_screen_without_a_scroll_target_ignores_the_stick() -> void:
	UIController.navigate_to("workshop")
	UIController.apply_scroll(1.0, 0.1)
	pass_test("no target, no error")

func test_scroll_by_moves_a_rich_text_label() -> void:
	var rtl := RichTextLabel.new()
	rtl.size = Vector2(100, 40)
	rtl.text = "\n".join(range(200).map(func(i: int) -> String: return str(i)))
	add_child_autofree(rtl)
	await get_tree().process_frame
	UIController.scroll_by(rtl, 120.0)
	assert_gt(rtl.get_v_scroll_bar().value, 0.0)

