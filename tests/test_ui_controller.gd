# tests/test_ui_controller.gd
extends GutTest

var _zone2: Control
var _saved_run_count: int

class FakeScreen:
	extends Control
	var shown_count: int = 0
	func on_screen_shown() -> void:
		shown_count += 1

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
	assert_eq(UIController.current_screen, "deck")

func test_cycle_tab_backward_skips_locked_tabs() -> void:
	GameState.run_count = 0
	UIController.navigate_to("deck")
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
