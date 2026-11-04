# autoload/UIController.gd
extends Node

signal screen_changed(id: String)
signal dive_state_changed(active: bool)

const _REGISTRY: Dictionary = {
	"deck":     "res://scenes/barge_hub/BargeHub.tscn",
	"workshop": "res://scenes/barge_hub/Workshop.tscn",
	"decrypt":  "res://scenes/barge_hub/DecryptBox.tscn",
	"bunk":     "res://scenes/barge_hub/Bunk.tscn",
	"marta":    "res://scenes/barge_hub/MartaTerminal.tscn",
	"vendors":  "res://scenes/barge_hub/VendorsLayout.tscn",
	"dive":     "res://scenes/dive_run/DiveRun.tscn",
	"gameover": "res://scenes/barge_hub/GameOver.tscn",
}

const _TAB_ORDER: Array[String] = [
	"deck", "workshop", "decrypt", "bunk", "marta", "vendors"
]

var current_screen: String = ""
# Tabs opened since the player last visited them; the footer marks them NEW.
var fresh_tabs: Array[String] = []
var _zone2: Control = null
var _current_node: Node = null
# Persistent screens (the hub tabs) are built once and kept alive, hidden, in
# _zone2 so their ambient feeds keep running. Transient screens are freed on exit.
var _cache: Dictionary = {}
# Test seam: screen creation goes through an overridable factory so unit tests
# can inject lightweight fakes instead of loading every real scene.
var _scene_factory: Callable = _default_scene_factory

func initialize(zone2: Control) -> void:
	_zone2 = zone2
	_cache.clear()
	fresh_tabs.clear()
	_current_node = null
	current_screen = ""

func _default_scene_factory(id: String) -> Node:
	var scene: PackedScene = ResourceLoader.load(_REGISTRY[id])
	return scene.instantiate()

func _is_persistent(id: String) -> bool:
	return id in _TAB_ORDER

func navigate_to(id: String) -> void:
	assert(_zone2 != null, "UIController.initialize() must be called before navigate_to()")

	if _is_persistent(id) and not Unlocks.is_tab_open(id):
		id = "deck"

	if id == "deck" and GameState.pressure_level >= 5:
		id = "gameover"

	assert(id in _REGISTRY, "UIController: unknown screen id '%s'" % id)
	fresh_tabs.erase(id)

	# Detach the outgoing screen: keep persistent screens alive (hidden) so they
	# keep ticking; free transient flow screens so they always restart clean.
	if _current_node != null and is_instance_valid(_current_node):
		if _is_persistent(current_screen):
			_current_node.visible = false
		else:
			_zone2.remove_child(_current_node)
			_current_node.queue_free()
	_current_node = null

	# Reveal the cached persistent screen, or build a fresh one.
	var node: Node
	if _is_persistent(id) and _cache.has(id) and is_instance_valid(_cache[id]):
		node = _cache[id]
		node.visible = true
	else:
		node = _scene_factory.call(id)
		if node is Control:
			(node as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_zone2.add_child(node)
		if _is_persistent(id):
			_cache[id] = node

	_current_node = node
	current_screen = id

	if node.has_method("on_screen_shown"):
		node.on_screen_shown()
	if node is Control:
		ScreenFX.wipe_in(node as Control)

	screen_changed.emit(id)
	dive_state_changed.emit(id == "dive")

func mark_fresh_tabs(feature_ids: Array[String]) -> void:
	for feature in feature_ids:
		if feature in _TAB_ORDER and feature not in fresh_tabs:
			fresh_tabs.append(feature)

func navigate_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen/TitleScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if current_screen == "dive":
		return
	if event.is_action_pressed("tab_next"):
		_cycle_tab(1)
	elif event.is_action_pressed("tab_prev"):
		_cycle_tab(-1)

func _cycle_tab(direction: int) -> void:
	var idx := _TAB_ORDER.find(current_screen)
	if idx == -1:
		navigate_to(_TAB_ORDER[0])
		return
	# Step past locked tabs; DECK is always open, so this always lands.
	for step in _TAB_ORDER.size():
		idx = (idx + direction + _TAB_ORDER.size()) % _TAB_ORDER.size()
		if Unlocks.is_tab_open(_TAB_ORDER[idx]):
			break
	navigate_to(_TAB_ORDER[idx])
