# scenes/dive_run/TerminalOverloadMini.gd
class_name TerminalOverloadMini
extends Control

signal caught(tension_at_catch: int)
signal aborted(tension_at_abort: int)
signal snapped

# Set by DiveRun before start()
var max_tension: int = 80
var anchor_strength: int = 3
var starting_tension: int = 0
var catch_name_str: String = ""
var catch_type: CatchData.CatchType = CatchData.CatchType.MECH
var corruption: float = 0.0
var slot: int = 1
var total_slots: int = 1
var shock_lure_equipped: bool = false

var _current_tension: int = 0
var _anchor_current: int = 0
var _security_threat: float = 1.0
var _turn: int = 1
var _active_commands: Array[Dictionary] = []

signal _command_chosen(cmd_index: int)

# Indices 0–3 are drawn randomly 3 at a time; ISOLATE_FEED is always appended.
const BASE_COMMANDS: Array[Dictionary] = [
    { "id": "DECRYPT_NODE",         "t_cost": 10,  "anchor_hit": -1, "success_rate": 1.0, "fail_t": 0  },
    { "id": "BRUTE_FORCE_OVERRIDE", "t_cost": 25,  "anchor_hit": -2, "success_rate": 0.6, "fail_t": 15 },
    { "id": "SYNGAS_FLOOD",         "t_cost": 0,   "anchor_hit": -1, "success_rate": 0.5, "fail_t": 30 },
    { "id": "SIGNAL_DAMPEN",        "t_cost": -15, "anchor_hit": 0,  "success_rate": 1.0, "fail_t": 0  },
]
const ISOLATE_FEED: Dictionary = {
    "id": "ISOLATE_FEED", "t_cost": 0, "anchor_hit": 0, "success_rate": 1.0, "fail_t": 0
}
const OVERLOAD_CORE: Dictionary = {
    "id": "OVERLOAD_CORE", "t_cost": 15, "anchor_hit": -2, "success_rate": 1.0, "fail_t": 0
}

@onready var hud_label: Label = $VBoxContainer/HUDLabel
@onready var alert_label: Label = $VBoxContainer/AlertLabel
@onready var tension_row_label: Label = $VBoxContainer/TensionRow/TensionRowLabel
@onready var tension_bar: ProgressBar = $VBoxContainer/TensionRow/TensionBar
@onready var anchor_label: Label = $VBoxContainer/AnchorLabel
@onready var warning_label: Label = $VBoxContainer/WarningLabel
@onready var commands_label: Label = $VBoxContainer/CommandsLabel
@onready var commands_container: VBoxContainer = $VBoxContainer/CommandsContainer
@onready var result_label: Label = $VBoxContainer/ResultLabel

var _tension_fill: StyleBoxFlat = null

func _ready() -> void:
    self.theme = UIStyle.get_theme()
    UIStyle.apply_background(self)

func start() -> void:
    _current_tension = starting_tension
    _anchor_current = anchor_strength
    _security_threat = 1.0 + (corruption / 100.0)

    UIStyle.apply_label(hud_label, UIStyle.COL_DIM)
    UIStyle.apply_label(alert_label, UIStyle.COL_DEBT)
    UIStyle.apply_label(tension_row_label, UIStyle.COL_DIM)
    UIStyle.apply_label(anchor_label, UIStyle.COL_TEXT)
    UIStyle.apply_label(warning_label, UIStyle.COL_WARNING)
    UIStyle.apply_label(commands_label, UIStyle.COL_DIM)
    UIStyle.apply_label(result_label, UIStyle.COL_DIM)

    _tension_fill = StyleBoxFlat.new()
    _tension_fill.bg_color = UIStyle.COL_TEXT
    var tension_bg := StyleBoxFlat.new()
    tension_bg.bg_color = Color("#1a1a1a")
    tension_bar.add_theme_stylebox_override("background", tension_bg)
    tension_bar.add_theme_stylebox_override("fill", _tension_fill)
    tension_bar.show_percentage = false
    tension_bar.max_value = max_tension

    _update_status_ui()
    result_label.text = ""
    _run_turns()

func _run_turns() -> void:
    while true:
        # Environmental backlash at the top of every turn
        var backlash := roundi(5.0 * _security_threat)
        _current_tension = clampi(_current_tension + backlash, 0, max_tension)
        _update_status_ui()
        result_label.text = ">>> backlash: +%dT" % backlash
        UIStyle.apply_label(result_label, UIStyle.COL_WARNING)

        if _current_tension >= max_tension:
            snapped.emit()
            return

        _active_commands = _pick_commands()
        _show_commands()

        var cmd_idx: int = await _command_chosen
        _clear_commands()
        result_label.text = ""

        var cmd: Dictionary = _active_commands[cmd_idx]

        if cmd.id == "ISOLATE_FEED":
            aborted.emit(starting_tension)
            return

        _execute_command(cmd)
        await get_tree().create_timer(0.6).timeout

        if _current_tension >= max_tension:
            snapped.emit()
            return

        if _anchor_current <= 0:
            caught.emit(_current_tension)
            return

        _turn += 1

func _pick_commands() -> Array[Dictionary]:
    var pool: Array[Dictionary] = BASE_COMMANDS.duplicate()
    if shock_lure_equipped and catch_type == CatchData.CatchType.MECH:
        pool.append(OVERLOAD_CORE)
    pool.shuffle()
    var picked: Array[Dictionary] = []
    for cmd: Dictionary in pool:
        picked.append(cmd)
        if picked.size() >= 3:
            break
    picked.append(ISOLATE_FEED)
    return picked

func _execute_command(cmd: Dictionary) -> void:
    if cmd.id == "OVERLOAD_CORE":
        GameState.consume_lure_use()

    var succeeded := cmd.success_rate >= 1.0 or randf() < cmd.success_rate
    if succeeded:
        _current_tension = clampi(_current_tension + cmd.t_cost, 0, max_tension)
        _anchor_current = maxi(0, _anchor_current + cmd.anchor_hit)
        _update_status_ui()
        _show_result_text(cmd.id + " — EXECUTED", UIStyle.COL_TEXT)
    else:
        var total_penalty := cmd.t_cost + cmd.fail_t
        _current_tension = clampi(_current_tension + total_penalty, 0, max_tension)
        _update_status_ui()
        _show_result_text("%s — FAILED  +%dT backlash" % [cmd.id, cmd.fail_t], UIStyle.COL_DEBT)

func _show_result_text(text: String, color: Color) -> void:
    result_label.text = text
    UIStyle.apply_label(result_label, color)

func _update_status_ui() -> void:
    var next_backlash := roundi(5.0 * _security_threat)
    hud_label.text = "slot %d / %d  ·  %s  ·  threat ×%.2f  ·  turn %d" % [
        slot, total_slots, GameState.selected_zone, _security_threat, _turn]
    alert_label.text = "[ALERT] HOSTILE UPLINK: %s" % catch_name_str
    warning_label.text = "backlash loop active  —  +%dT on next turn" % next_backlash

    tension_bar.value = _current_tension
    tension_row_label.text = "line tension  %d / %d T  " % [_current_tension, max_tension]
    if _tension_fill:
        var t := float(_current_tension) / float(max_tension)
        _tension_fill.bg_color = UIStyle.COL_TEXT.lerp(UIStyle.COL_DEBT, t)

    var filled := "◆".repeat(_anchor_current)
    var empty := "◇".repeat(anchor_strength - _anchor_current)
    anchor_label.text = "entity anchor  %s%s  %d / %d stabilized" % [
        filled, empty, _anchor_current, anchor_strength]

func _show_commands() -> void:
    commands_label.text = "available commands:"
    for i: int in _active_commands.size():
        var cmd: Dictionary = _active_commands[i]
        var btn := Button.new()
        btn.text = _format_command(i + 1, cmd)
        btn.focus_mode = Control.FOCUS_ALL
        UIStyle.apply_button(btn)
        var idx := i
        btn.pressed.connect(func() -> void: _command_chosen.emit(idx))
        commands_container.add_child(btn)
    if commands_container.get_child_count() > 0:
        commands_container.get_child(0).grab_focus()

func _format_command(num: int, cmd: Dictionary) -> String:
    match cmd.id:
        "DECRYPT_NODE":
            return "[%d] DECRYPT_NODE          +10T  ·  -1 anchor  ·  guaranteed" % num
        "BRUTE_FORCE_OVERRIDE":
            return "[%d] BRUTE_FORCE_OVERRIDE  +25T  ·  -2 anchor  ·  60%%  (fail: +40T)" % num
        "SYNGAS_FLOOD":
            return "[%d] SYNGAS_FLOOD          +0T   ·  -1 anchor  ·  50%%  (fail: +30T)" % num
        "SIGNAL_DAMPEN":
            return "[%d] SIGNAL_DAMPEN         -15T  ·  no effect  ·  guaranteed" % num
        "OVERLOAD_CORE":
            return "[%d] OVERLOAD_CORE [shock] +15T  ·  -2 anchor  ·  guaranteed" % num
        "ISOLATE_FEED":
            return "[%d] ISOLATE_FEED          emergency disconnect  (lose catch, restore tension)" % num
    return ""

func _clear_commands() -> void:
    for child in commands_container.get_children():
        child.queue_free()
    commands_label.text = ""
