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
    "debrief":  "res://scenes/ui/PostRun.tscn",
    "gameover": "res://scenes/barge_hub/GameOver.tscn",
}

const _TAB_ORDER: Array[String] = [
    "deck", "workshop", "decrypt", "bunk", "marta", "vendors"
]

var current_screen: String = ""
var _zone2: Control = null
var _zone3: Control = null

func initialize(zone2: Control, zone3: Control) -> void:
    _zone2 = zone2
    _zone3 = zone3

func navigate_to(id: String) -> void:
    assert(_zone2 != null, "UIController.initialize() must be called before navigate_to()")

    if id == "deck" and GameState.pressure_level >= 5:
        id = "gameover"

    for child in _zone2.get_children():
        child.queue_free()

    var scene: PackedScene = ResourceLoader.load(_REGISTRY[id])
    var node: Node = scene.instantiate()
    if node is Control:
        (node as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _zone2.add_child(node)

    current_screen = id
    screen_changed.emit(id)
    dive_state_changed.emit(id == "dive")

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
    idx = (idx + direction + _TAB_ORDER.size()) % _TAB_ORDER.size()
    navigate_to(_TAB_ORDER[idx])
