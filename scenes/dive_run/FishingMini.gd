# scenes/dive_run/FishingMini.gd
class_name FishingMini
extends Control

enum State { ENGAGED, REELING, DONE }

signal caught(tension_at_catch: int)
signal snapped

@export var max_tension: int = 80
@export var catch_stamina: int = 100
@export var tension_rate: float = 10.0
@export var reel_stamina_drain: float = 20.0
@export var base_stamina_drain: float = 8.0

var state: State = State.ENGAGED
var catch_stamina_current: float = 100.0
var _current_tension: float = 0.0
var _reel_held: bool = false

@onready var catch_label: Label = $VBoxContainer/CatchLabel
@onready var instruction_label: Label = $VBoxContainer/InstructionLabel
@onready var tension_bar: ProgressBar = $VBoxContainer/TensionBar

func _ready() -> void:
    self.theme = UIStyle.get_theme()
    UIStyle.apply_background(self)
    set_process(false)

func start(catch_name: String) -> void:
    catch_stamina_current = float(catch_stamina)
    _current_tension = 0.0
    state = State.ENGAGED
    if catch_label:
        catch_label.text = catch_name
        UIStyle.apply_label(catch_label, UIStyle.COL_TEXT)
    if instruction_label:
        instruction_label.text = "REEL [SPACE/A]   SLACK [J/B]"
        UIStyle.apply_label(instruction_label, UIStyle.COL_DIM)
    if tension_bar:
        tension_bar.max_value = max_tension
        tension_bar.value = 0.0
    set_process(true)

func _process(delta: float) -> void:
    if state == State.DONE:
        return

    var reel = _reel_held or Input.is_action_pressed("action_reel")
    var slack_held = Input.is_action_pressed("action_slack")
    _reel_held = reel

    match state:
        State.ENGAGED:
            _process_engaged(delta, slack_held)
        State.REELING:
            _process_reeling(delta)

func _process_engaged(delta: float, slack_held: bool) -> void:
    var tension_delta = tension_rate * delta
    if slack_held:
        tension_delta *= 0.2
    if _reel_held:
        tension_delta *= 1.5

    _current_tension += tension_delta
    if tension_bar:
        tension_bar.value = _current_tension

    if _current_tension >= float(max_tension):
        state = State.DONE
        snapped.emit()
        return

    var stamina_drain = base_stamina_drain * delta
    if _reel_held:
        stamina_drain += reel_stamina_drain * delta
    catch_stamina_current -= stamina_drain

    if catch_stamina_current <= 0.0:
        state = State.REELING

func _process_reeling(delta: float) -> void:
    if _reel_held:
        _current_tension -= 30.0 * delta
    else:
        _current_tension += 5.0 * delta

    _current_tension = clampf(_current_tension, 0.0, float(max_tension))
    if tension_bar:
        tension_bar.value = _current_tension

    if _current_tension >= float(max_tension):
        state = State.DONE
        snapped.emit()
        return

    if _current_tension <= 0.0:
        state = State.DONE
        caught.emit(int(_current_tension))
