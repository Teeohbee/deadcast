# tests/test_ui_controller.gd
extends GutTest

var _zone2: Control
var _built: Array = []

class FakeScreen:
	extends Control
	var shown_count: int = 0
	func on_screen_shown() -> void:
		shown_count += 1

func before_each() -> void:
	_zone2 = Control.new()
	add_child_autofree(_zone2)
	_built = []
	GameState.pressure_level = 0
	UIController._scene_factory = func(id: String) -> Node:
		_built.append(id)
		return FakeScreen.new()
	UIController.initialize(_zone2)

func after_each() -> void:
	UIController._scene_factory = UIController._default_scene_factory

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
