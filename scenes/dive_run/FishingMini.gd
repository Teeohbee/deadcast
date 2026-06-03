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
var _tension_fill: StyleBoxFlat = null

@onready var catch_label: Label = $VBoxContainer/CatchLabel
@onready var phase_label: Label = $VBoxContainer/PhaseLabel
@onready var instruction_label: Label = $VBoxContainer/InstructionLabel
@onready var tension_bar: ProgressBar = $VBoxContainer/TensionRow/TensionBar
@onready var stamina_bar: ProgressBar = $VBoxContainer/StaminaRow/StaminaBar
@onready var tension_row_label: Label = $VBoxContainer/TensionRow/TensionRowLabel
@onready var stamina_row_label: Label = $VBoxContainer/StaminaRow/StaminaRowLabel

func _ready() -> void:
    self.theme = UIStyle.get_theme()
    UIStyle.apply_background(self)
    set_process(false)

func start(catch_name: String) -> void:
    catch_stamina_current = float(catch_stamina)
    _current_tension = 0.0
    state = State.ENGAGED

    catch_label.text = catch_name
    UIStyle.apply_label(catch_label, UIStyle.COL_TEXT)
    UIStyle.apply_label(tension_row_label, UIStyle.COL_DIM)
    UIStyle.apply_label(stamina_row_label, UIStyle.COL_DIM)

    _tension_fill = StyleBoxFlat.new()
    _tension_fill.bg_color = UIStyle.COL_TEXT
    var tension_bg := StyleBoxFlat.new()
    tension_bg.bg_color = Color("#1a1a1a")
    tension_bar.add_theme_stylebox_override("background", tension_bg)
    tension_bar.add_theme_stylebox_override("fill", _tension_fill)
    tension_bar.show_percentage = false
    tension_bar.max_value = max_tension
    tension_bar.value = 0.0

    _style_bar(stamina_bar, UIStyle.COL_COST)
    stamina_bar.max_value = catch_stamina
    stamina_bar.value = catch_stamina

    _update_phase_ui()
    set_process(true)

func _style_bar(bar: ProgressBar, fill_color: Color) -> void:
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color("#1a1a1a")
    var fill := StyleBoxFlat.new()
    fill.bg_color = fill_color
    bar.add_theme_stylebox_override("background", bg)
    bar.add_theme_stylebox_override("fill", fill)
    bar.show_percentage = false

func _update_phase_ui() -> void:
    match state:
        State.ENGAGED:
            phase_label.text = "[ fighting ]"
            UIStyle.apply_label(phase_label, UIStyle.COL_DEBT)
            instruction_label.text = "slack [j/b] slows tension  ·  reel [space/a] tires it faster"
            UIStyle.apply_label(instruction_label, UIStyle.COL_DIM)
        State.REELING:
            phase_label.text = "[ reel it in ]"
            UIStyle.apply_label(phase_label, UIStyle.COL_TEXT)
            instruction_label.text = "hold reel [space/a]  ·  bring tension to zero"
            UIStyle.apply_label(instruction_label, UIStyle.COL_TEXT)

func _process(delta: float) -> void:
    if state == State.DONE:
        return

    var reel = _reel_held or Input.is_action_pressed("action_reel")
    var slack_held = Input.is_action_pressed("action_slack")
    _reel_held = reel

    var prev_state = state
    match state:
        State.ENGAGED:
            _process_engaged(delta, slack_held)
        State.REELING:
            _process_reeling(delta)

    if state != prev_state:
        _update_phase_ui()

    tension_bar.value = _current_tension
    stamina_bar.value = catch_stamina_current

    if _tension_fill:
        var t = _current_tension / float(max_tension)
        _tension_fill.bg_color = UIStyle.COL_TEXT.lerp(UIStyle.COL_DEBT, t)

func _process_engaged(delta: float, slack_held: bool) -> void:
    var tension_delta = tension_rate * delta
    if slack_held:
        tension_delta *= 0.2
    if _reel_held:
        tension_delta *= 1.5

    _current_tension += tension_delta

    if _current_tension >= float(max_tension):
        state = State.DONE
        snapped.emit()
        return

    var stamina_drain = base_stamina_drain * delta
    if _reel_held:
        stamina_drain += reel_stamina_drain * delta
    catch_stamina_current = maxf(0.0, catch_stamina_current - stamina_drain)

    if catch_stamina_current <= 0.0:
        state = State.REELING

func _process_reeling(delta: float) -> void:
    if _reel_held:
        _current_tension -= 30.0 * delta
    else:
        _current_tension += 5.0 * delta

    _current_tension = clampf(_current_tension, 0.0, float(max_tension))

    if _current_tension >= float(max_tension):
        state = State.DONE
        snapped.emit()
        return

    if _current_tension <= 0.0:
        state = State.DONE
        caught.emit(int(_current_tension))
