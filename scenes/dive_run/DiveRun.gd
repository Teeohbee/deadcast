# scenes/dive_run/DiveRun.gd
extends Node2D

@export var catch_event_scene: PackedScene = preload("res://scenes/dive_run/CatchEvent.tscn")
@export var fishing_mini_scene: PackedScene = preload("res://scenes/dive_run/FishingMini.tscn")
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
	call_deferred("_show_next_catch")

func _show_next_catch() -> void:
	if _current_slot >= _column.size():
		_end_run(false)
		return
	var catch_data = _column[_current_slot]
	if catch_data.behavior == CatchData.BehaviorType.AGGRESSIVE:
		_show_fishing_mini(catch_data)
	else:
		var event_ui: CatchEvent = catch_event_scene.instantiate()
		catch_container.add_child(event_ui)
		_current_event = event_ui
		event_ui.populate(catch_data)
		event_ui.option_selected.connect(_on_option_selected)

func _show_fishing_mini(catch_data: CatchData) -> void:
	var mini: FishingMini = fishing_mini_scene.instantiate()
	mini.max_tension = line_system.max_tension
	mini.catch_stamina = catch_data.stamina
	catch_container.add_child(mini)
	mini.start(catch_data.catch_name)
	mini.caught.connect(func(_t: int) -> void: _on_minigame_caught(catch_data))
	mini.snapped.connect(_on_line_snapped)

func _on_minigame_caught(catch_data: CatchData) -> void:
	for child in catch_container.get_children():
		child.queue_free()
	var reward_option: CatchOption = catch_data.options[0]
	_run_credits += reward_option.credit_value
	line_system.add_corruption(catch_data.corruption_gain)
	_current_slot += 1
	_show_next_catch()

func _on_option_selected(index: int) -> void:
	if _snapped:
		return

	if _current_event:
		_current_event.option_selected.disconnect(_on_option_selected)
		_current_event = null

	var catch_data = _column[_current_slot]
	var option: CatchOption = catch_data.options[index]

	if option.cuts_line:
		line_system.reset()
		_advance_slot()
		return

	match catch_data.behavior:
		CatchData.BehaviorType.RESISTANT:
			_resolve_resistant(option, catch_data)
		CatchData.BehaviorType.NEGOTIATING:
			_resolve_negotiating(option, catch_data)
		_:
			_apply_option(option, catch_data)

func _resolve_resistant(option: CatchOption, catch_data: CatchData) -> void:
	if option.resist_chance > 0.0 and randf() < option.resist_chance:
		# Resisted — apply penalty tension, no credits
		line_system.apply_tension(option.resist_tension_penalty)
		line_system.add_corruption(catch_data.corruption_gain)
	else:
		_apply_option(option, catch_data)
		return
	_advance_slot()

func _resolve_negotiating(option: CatchOption, catch_data: CatchData) -> void:
	if option.roll_difficulty > 0.0 and randf() < option.roll_difficulty:
		# Roll failed — apply fail outcomes
		line_system.apply_tension(option.fail_tension_delta)
		_run_credits += option.fail_credit_value
		line_system.add_corruption(catch_data.corruption_gain)
	else:
		_apply_option(option, catch_data)
		return
	_advance_slot()

func _apply_option(option: CatchOption, catch_data: CatchData) -> void:
	line_system.apply_tension(option.tension_delta)
	line_system.add_corruption(catch_data.corruption_gain)
	_run_credits += option.credit_value
	_advance_slot()

func _advance_slot() -> void:
	for child in catch_container.get_children():
		child.queue_free()
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
