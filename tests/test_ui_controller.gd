# tests/test_ui_controller.gd
extends GutTest

var _zone2: Control
var _zone3: Control

func before_each() -> void:
    _zone2 = add_child_autofree(Control.new())
    _zone3 = add_child_autofree(Control.new())
    UIController.initialize(_zone2)
    UIController.current_screen = ""

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

func test_navigate_to_replaces_zone2_child() -> void:
    UIController.navigate_to("workshop")
    assert_eq(_zone2.get_child_count(), 1)
    UIController.navigate_to("bunk")
    await get_tree().process_frame
    assert_eq(_zone2.get_child_count(), 1)

# _cycle_tab is tested directly to avoid the complexity of constructing InputEvents.
# The signal-to-call wiring in _unhandled_input is too simple to warrant separate testing.
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
