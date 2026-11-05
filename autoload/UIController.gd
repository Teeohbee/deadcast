# autoload/UIController.gd
extends Node

signal screen_changed(id: String)
signal dive_state_changed(active: bool)

const _REGISTRY: Dictionary = {
	"deck":     "res://scenes/barge_hub/BargeHub.tscn",
	"workshop": "res://scenes/barge_hub/Workshop.tscn",
	"decrypt":  "res://scenes/barge_hub/DecryptBox.tscn",
	"bunk":     "res://scenes/barge_hub/Bunk.tscn",
	"relay":    "res://scenes/relay/RelayTab.tscn",
	"vendors":  "res://scenes/barge_hub/VendorsLayout.tscn",
	"dive":     "res://scenes/dive_run/DiveRun.tscn",
	"gameover": "res://scenes/barge_hub/GameOver.tscn",
	"call":     "res://scenes/relay/CallScreen.tscn",
}

const _TAB_ORDER: Array[String] = [
	"deck", "workshop", "decrypt", "bunk", "relay", "vendors"
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

# The relay: a due call takes over the screen on hub arrival or when a tab is
# first shown, then hands back to where the player was going.
# The call the call screen should play: {"script_id", "answered", "return_to"}.
var pending_call: Dictionary = {}
# Set by the boot when the player answers there, so the call opens connected.
var answer_next_call := false
# Test seam: the suite turns calls off (tests/pre_run_hook.gd) so navigation
# tests aren't hijacked by the first call; relay tests turn it back on.
var relay_calls_enabled := true

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

	if relay_calls_enabled:
		_deliver_due_relay_texts(id)
		var due_call := _relay_call_due_before_showing(id)
		if not due_call.is_empty():
			pending_call = {"script_id": due_call.id, "answered": answer_next_call, "return_to": id}
			answer_next_call = false
			id = "call"

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

# Called by the call screen when the call is over (heard, or let ring).
func finish_call() -> void:
	var destination: String = pending_call.get("return_to", "deck")
	pending_call = {}
	navigate_to(destination)

func _is_arriving_at_hub(id: String) -> bool:
	return _is_persistent(id) and current_screen in ["", "dive"]

func _relay_call_due_before_showing(id: String) -> Dictionary:
	if not _is_persistent(id) or current_screen == "call":
		return {}
	if _is_arriving_at_hub(id):
		var hub_call := RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL)
		if not hub_call.is_empty():
			return hub_call
	return RelayDirector.due_call(RelayScripts.TRIGGER_TAB_OPENED, id)

# Texts due on hub arrival land in the RELAY thread straight away.
func _deliver_due_relay_texts(id: String) -> void:
	if not _is_arriving_at_hub(id):
		return
	var delivered := false
	for relay_script in RelayDirector.due_texts(RelayScripts.TRIGGER_HUB_ARRIVAL):
		var runner := RelayRunner.new(relay_script)
		runner.run_to_end_without_replies()
		GameState.relay_file_entry(relay_script.contact, GameState.RELAY_ENTRY_TEXT, relay_script.id, runner.transcript)
		GameState.relay_mark_played(relay_script.id)
		delivered = true
	if delivered:
		GameState.save()

func mark_fresh_tabs(feature_ids: Array[String]) -> void:
	for feature in feature_ids:
		if feature in _TAB_ORDER and feature not in fresh_tabs:
			fresh_tabs.append(feature)

func navigate_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen/TitleScreen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if current_screen in ["dive", "call"]:
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
