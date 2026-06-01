# scenes/dive_run/DiveRun.gd
extends Node2D

@export var catch_event_scene: PackedScene = preload("res://scenes/dive_run/CatchEvent.tscn")
@export var zone: String = "district7"

@onready var line_system: LineSystem = $LineSystem
@onready var catch_container: Control = $CatchContainer
@onready var hud: HUD = $HUD

var _column: Array[CatchData] = []
var _current_slot: int = 0
var _run_credits: int = 0
var _snapped: bool = false
var _current_event: CatchEvent = null

func _ready() -> void:
	line_system.snapped.connect(_on_line_snapped)
	line_system.tension_updated.connect(func(v: float) -> void: EventBus.tension_changed.emit(v))
	hud.set_max_tension(line_system.max_tension)
	_column = CatchPool.generate_column(zone, line_system.corruption)
	_show_next_catch()

func _show_next_catch() -> void:
	if _current_slot >= _column.size():
		_end_run(false)
		return
	var event_ui: CatchEvent = catch_event_scene.instantiate()
	catch_container.add_child(event_ui)
	event_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_current_event = event_ui
	event_ui.populate(_column[_current_slot])
	event_ui.option_selected.connect(_on_option_selected)

func _on_option_selected(index: int) -> void:
	if _snapped:
		return

	if _current_event:
		_current_event.option_selected.disconnect(_on_option_selected)
		_current_event = null
	for child in catch_container.get_children():
		child.queue_free()

	var catch_data: CatchData = _column[_current_slot]
	var option: CatchOption = catch_data.options[index]

	if option.cuts_line:
		line_system.reset()
	else:
		line_system.apply_tension(option.tension_delta)
		line_system.add_corruption(catch_data.corruption_gain)

	if _snapped:
		return

	_run_credits += option.credit_value
	_current_slot += 1
	_show_next_catch()

func _on_line_snapped() -> void:
	_snapped = true
	_run_credits = 0
	_end_run(true)

func _end_run(snapped: bool) -> void:
	GameState.add_credits(_run_credits)
	GameState.last_run_result = {"credits": _run_credits, "snapped": snapped}
	EventBus.run_ended.emit(GameState.last_run_result)
	get_tree().change_scene_to_file("res://scenes/ui/PostRun.tscn")
