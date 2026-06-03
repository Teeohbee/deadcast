# scenes/dive_run/DiveRun.gd
extends Node2D

@export var catch_event_scene: PackedScene = preload("res://scenes/dive_run/CatchEvent.tscn")
@export var terminal_overload_scene: PackedScene = preload("res://scenes/dive_run/TerminalOverloadMini.tscn")

const ROD_DAMAGE_TENSION_PENALTY: int = 25
@onready var line_system: LineSystem = $LineSystem
@onready var catch_container: Control = $CatchContainer

var _column: Array[CatchData] = []
var _current_slot: int = 0
var _zone_data: ZoneData = null
var _run_credits: int = 0
var _bio_credits: int = 0
var _snapped: bool = false
var _current_event: CatchEvent = null
var _current_catch_data: CatchData = null  # augmented data shown to player (may have Shock option injected)

func _ready() -> void:
	catch_container.theme = UIStyle.get_theme()
	UIStyle.apply_background(catch_container)
	line_system.snapped.connect(_on_line_snapped)
	line_system.tension_updated.connect(func(v: float) -> void: EventBus.tension_changed.emit(v))
	line_system.corruption_updated.connect(func(v: float) -> void: EventBus.corruption_changed.emit(v))

	if GameState.current_rod:
		line_system.max_tension = GameState.current_rod.tension_cap
		if GameState.rod_damaged:
			line_system.max_tension = max(10, line_system.max_tension - ROD_DAMAGE_TENSION_PENALTY)
	EventBus.max_tension_changed.emit(line_system.max_tension)

	var zone_id = GameState.selected_zone
	_zone_data = load("res://resources/zones/%s.tres" % zone_id)

	var max_depth = GameState.current_rod.max_depth if GameState.current_rod else 100
	var lure_effect = GameState.current_lure.effect if GameState.current_lure else LureData.LureEffect.NONE
	_column = CatchPool.generate_column(zone_id, line_system.corruption, max_depth, lure_effect)
	if GameState.current_lure and GameState.current_lure.effect == LureData.LureEffect.GHOST_BAIT:
		for i in _column.size():
			var c = _column[i]
			if c.catch_type == CatchData.CatchType.ENTITY and c.behavior == CatchData.BehaviorType.AGGRESSIVE:
				var dup = c.duplicate()
				dup.behavior = CatchData.BehaviorType.PASSIVE
				_column[i] = dup
	await get_tree().process_frame
	catch_container.position = Vector2.ZERO
	catch_container.size = get_viewport().get_visible_rect().size
	_show_next_catch()

func _show_next_catch() -> void:
	if _current_slot >= _column.size():
		_end_run(false)
		return
	var catch_data = _column[_current_slot]
	EventBus.slot_changed.emit(_current_slot + 1, _column.size())

	if catch_data.behavior == CatchData.BehaviorType.AGGRESSIVE:
		_show_terminal_overload(catch_data)
		return

	if GameState.current_lure and GameState.current_lure.effect == LureData.LureEffect.DEEP_PULSE:
		_show_deep_pulse_reveal(catch_data)
		return

	_show_catch_event(catch_data)

func _show_deep_pulse_reveal(catch_data: CatchData) -> void:
	var label = Label.new()
	label.text = "DEEP PULSE: Incoming - [%s]" % CatchData.CatchType.keys()[catch_data.catch_type]
	catch_container.add_child(label)
	await get_tree().create_timer(2.0).timeout
	if _snapped:
		return
	label.queue_free()
	_show_catch_event(catch_data)

func _show_catch_event(catch_data: CatchData) -> void:
	var augmented = catch_data
	if GameState.current_lure and GameState.current_lure.effect == LureData.LureEffect.SHOCK:
		if catch_data.catch_type == CatchData.CatchType.MECH:
			augmented = _inject_shock_option(catch_data)
	_current_catch_data = augmented
	var event_ui: CatchEvent = catch_event_scene.instantiate()
	catch_container.add_child(event_ui)
	event_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_current_event = event_ui
	event_ui.populate(augmented, _current_slot + 1, _column.size(), int(line_system.tension), line_system.max_tension)
	event_ui.option_selected.connect(_on_option_selected)

func _inject_shock_option(catch_data: CatchData) -> CatchData:
	var overload_opt = CatchOption.new()
	overload_opt.label = "Overload (Shock Lure)"
	overload_opt.tension_delta = 5
	overload_opt.credit_value = int(catch_data.options[0].credit_value * 0.7)
	overload_opt.flavor_text = "Short-circuit it. Destroys one Shock Lure use."
	var augmented = catch_data.duplicate()
	var new_options: Array[CatchOption] = []
	for opt in catch_data.options:
		new_options.append(opt)
	new_options.insert(0, overload_opt)
	augmented.options = new_options
	return augmented

func _show_terminal_overload(catch_data: CatchData) -> void:
	var mini: TerminalOverloadMini = terminal_overload_scene.instantiate()
	mini.max_tension = line_system.max_tension
	mini.anchor_strength = catch_data.anchor_strength
	mini.starting_tension = int(line_system.tension)
	mini.corruption = line_system.corruption
	mini.catch_name_str = catch_data.catch_name
	mini.catch_type = catch_data.catch_type
	mini.slot = _current_slot + 1
	mini.total_slots = _column.size()
	mini.shock_lure_equipped = (GameState.current_lure != null and
		GameState.current_lure.effect == LureData.LureEffect.SHOCK)
	catch_container.add_child(mini)
	mini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mini.caught.connect(func(final_tension: int) -> void: _on_terminal_caught(catch_data, final_tension))
	mini.aborted.connect(func(restore_tension: int) -> void: _on_terminal_aborted(restore_tension))
	mini.snapped.connect(_on_line_snapped)
	mini.start()

func _on_terminal_caught(catch_data: CatchData, final_tension: int) -> void:
	for child in catch_container.get_children():
		child.queue_free()
	line_system.sync_tension(final_tension)
	var reward_option: CatchOption = catch_data.options[0]
	_run_credits += reward_option.credit_value
	if catch_data.catch_type == CatchData.CatchType.BIO:
		_bio_credits += reward_option.credit_value
	line_system.add_corruption(catch_data.corruption_gain)
	_current_slot += 1
	_show_next_catch()

func _on_terminal_aborted(restore_tension: int) -> void:
	for child in catch_container.get_children():
		child.queue_free()
	line_system.sync_tension(restore_tension)
	_current_slot += 1
	_show_next_catch()

func _on_option_selected(index: int) -> void:
	if _snapped:
		return

	if _current_event:
		_current_event.option_selected.disconnect(_on_option_selected)

	var catch_data = _column[_current_slot]

	# Shock Lure: if MECH catch with Shock equipped, index 0 is the injected Overload
	var using_shock = (GameState.current_lure != null and
		GameState.current_lure.effect == LureData.LureEffect.SHOCK and
		catch_data.catch_type == CatchData.CatchType.MECH)

	if using_shock and index == 0:
		# Overload selected — read from augmented data stored at show time (single source of truth)
		GameState.consume_lure_use()
		_apply_option(_current_catch_data.options[0], catch_data)
		return

	# Adjust index back if Shock Lure injected an option at index 0
	var effective_index = index - 1 if using_shock else index
	var option: CatchOption = catch_data.options[effective_index]

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

func _show_result_beat(text: String, color: Color) -> void:
	if _current_event and not _snapped:
		_current_event.show_result(text, color)
		await _current_event.result_dismissed

func _apply_and_record(option: CatchOption, catch_data: CatchData) -> void:
	line_system.apply_tension(option.tension_delta)
	line_system.add_corruption(catch_data.corruption_gain)
	_run_credits += option.credit_value
	if catch_data.catch_type == CatchData.CatchType.BIO:
		_bio_credits += option.credit_value

func _apply_option(option: CatchOption, catch_data: CatchData) -> void:
	_apply_and_record(option, catch_data)
	_advance_slot()

func _resolve_resistant(option: CatchOption, catch_data: CatchData) -> void:
	if option.resist_chance > 0.0 and randf() < option.resist_chance:
		line_system.apply_tension(option.resist_tension_penalty)
		line_system.add_corruption(catch_data.corruption_gain)
		await _show_result_beat(
			"resisted  ·  +%dT  no reward" % option.resist_tension_penalty,
			UIStyle.COL_DEBT)
	else:
		_apply_and_record(option, catch_data)
		await _show_result_beat("+%dcr" % option.credit_value, UIStyle.COL_TEXT)
	if _snapped:
		return
	_advance_slot()

func _resolve_negotiating(option: CatchOption, catch_data: CatchData) -> void:
	if option.roll_difficulty > 0.0 and randf() < option.roll_difficulty:
		line_system.apply_tension(option.fail_tension_delta)
		_run_credits += option.fail_credit_value
		if catch_data.catch_type == CatchData.CatchType.BIO:
			_bio_credits += option.fail_credit_value
		line_system.add_corruption(catch_data.corruption_gain)
		await _show_result_beat(
			"negotiation failed  ·  +%dT" % option.fail_tension_delta,
			UIStyle.COL_DEBT)
	else:
		_apply_and_record(option, catch_data)
		await _show_result_beat("+%dcr" % option.credit_value, UIStyle.COL_TEXT)
	if _snapped:
		return
	_advance_slot()

func _advance_slot() -> void:
	_current_catch_data = null
	_current_event = null
	for child in catch_container.get_children():
		child.queue_free()
	if _zone_data and _zone_data.passive_tension_drain > 0:
		line_system.apply_tension(_zone_data.passive_tension_drain)
	_current_slot += 1
	_show_next_catch()

func _on_line_snapped() -> void:
	if _snapped:
		return
	_snapped = true
	_run_credits = 0
	_bio_credits = 0
	for child in catch_container.get_children():
		child.queue_free()

	# Build corrupted terminal screen that mirrors CatchEvent's layout
	var root := VBoxContainer.new()
	root.theme = UIStyle.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20.0
	root.offset_top = 20.0
	root.offset_right = -20.0
	root.offset_bottom = -20.0
	catch_container.add_child(root)

	var _row := func(text: String, color: Color) -> void:
		var lbl := Label.new()
		lbl.text = text
		UIStyle.apply_label(lbl, color)
		root.add_child(lbl)

	var sep  := "────────────────────────────────────────────────────────────────"
	var sep_s := "────────────────────────────────────────────────"

	_row.call("SLOT: %d/%d  │  ZONE: %s  │  TENSION: [OVERFLOW]" % [
		_current_slot + 1, _column.size(),
		GameState.selected_zone.to_upper().replace("_", " ")],
		UIStyle.COL_DIM)

	_row.call(
		"%s\n[!!! SIGNAL LOST !!!]\nNAME:     ░░░░░░░░░░░░░░░░░░░░░░░░\nSTATUS:   [CRITICAL FAILURE]\n%s" % [sep, sep],
		UIStyle.COL_DEBT)

	_row.call(
		"┌── TELEMETRY_READOUT %s\n│  [ !!! CONNECTION TERMINATED !!! ]\n│  CRITICAL: LINE TENSION EXCEEDED / SIGNAL LOST\n└%s" % [sep_s, sep_s],
		UIStyle.COL_DEBT)

	var dismiss := Button.new()
	dismiss.text = ">>> [ RETREAT TO SURFACE ]"
	dismiss.focus_mode = Control.FOCUS_ALL
	UIStyle.apply_button(dismiss)
	root.add_child(dismiss)

	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(dismiss):
		dismiss.grab_focus()
		await dismiss.pressed

	_end_run(true)

func _end_run(snapped: bool) -> void:
	GameState.add_credits(_run_credits - _bio_credits)  # non-bio credits go directly to wallet
	GameState.last_run_result = {
		"credits": _run_credits,
		"bio_credits": _bio_credits,
		"snapped": snapped
	}
	GameState.on_run_complete(snapped, _bio_credits)
	EventBus.run_ended.emit(GameState.last_run_result)
	get_tree().change_scene_to_file("res://scenes/ui/PostRun.tscn")
