# scenes/dive_run/DiveRun.gd
extends Control

const ROD_DAMAGE_TENSION_PENALTY: int = 25
const BEAT_PAUSE := 0.5

@onready var line_system: LineSystem = $LineSystem
@onready var dive_hud: DiveHUD = $VBoxContainer/DiveHUD
@onready var session_log: SessionLog = $VBoxContainer/SessionLog

var _column: DiveColumn = null
var _zone_data: ZoneData = null
var _run_credits: int = 0
var _bio_credits: int = 0
var _snapped: bool = false

func _ready() -> void:
	UIStyle.apply_background(self)
	line_system.snapped.connect(_on_line_snapped)
	line_system.tension_updated.connect(func(v: float) -> void: EventBus.tension_changed.emit(v))
	line_system.corruption_updated.connect(func(v: float) -> void:
		EventBus.corruption_changed.emit(v)
		session_log.glitch_intensity = DiveFormat.glitch_intensity(v))

	if GameState.current_rod:
		line_system.max_tension = GameState.current_rod.tension_cap
		if GameState.rod_damaged:
			line_system.max_tension = max(10, line_system.max_tension - ROD_DAMAGE_TENSION_PENALTY)

	var zone_id = GameState.selected_zone
	_zone_data = load("res://resources/zones/%s.tres" % zone_id)

	var max_depth = GameState.current_rod.max_depth if GameState.current_rod else 100
	_column = DiveColumn.new(zone_id, max_depth)
	_column.generate_current_layer(line_system.corruption)

	dive_hud.setup(line_system.max_tension, _column.reachable_layer_sizes(), _initial_lure_label())
	EventBus.haul_changed.emit(0)
	EventBus.tension_changed.emit(line_system.tension)
	EventBus.corruption_changed.emit(line_system.corruption)

	await get_tree().process_frame
	session_log.log_line("> cast — %s" % _zone_data.display_name.to_lower(), UIStyle.COL_DIM)
	if GameState.current_rod and GameState.rod_damaged:
		session_log.log_line(">>> rod damaged — tension cap reduced to %d" % line_system.max_tension,
			UIStyle.COL_WARNING)
	_show_next_catch()

func _show_next_catch() -> void:
	if _snapped:
		return
	if _column.layer_cleared():
		if _column.can_descend():
			_show_checkpoint()
		else:
			session_log.log_line("\n>>> column cleared  ·  surfacing", UIStyle.COL_TEXT)
			await _beat()
			_end_run(false)
		return
	var catch_data = _column.current_catch()
	EventBus.slot_changed.emit(_column.global_slot_index() + 1, _column.total_reachable_slots())

	if catch_data.behavior == CatchData.BehaviorType.AGGRESSIVE:
		_run_overload(catch_data)
		return

	_present_catch(catch_data)

func _show_checkpoint() -> void:
	session_log.log_line("\n─── DEPTH CHECKPOINT ──────────────────────────", UIStyle.COL_ACCENT)
	session_log.log_line("│  %s cleared  ·  haul: %dcr  ·  tension %d/%d  ·  SIG %d%%" % [
		DiveColumn.LAYER_NAMES[_column.current_layer()], _run_credits,
		int(line_system.tension), line_system.max_tension,
		int(100.0 - line_system.corruption)], UIStyle.COL_TEXT)
	session_log.log_line("│  %s scan: %d contacts  ·  draws weighted by current SIG" % [
		_column.next_layer_name(), _column.next_layer_slot_count()], UIStyle.COL_DIM)

	var labels: Array[String] = [
		"[1] DESCEND   — push deeper. higher yields, SIG-weighted draws",
		"[2] SURFACE   — bank %dcr and end the run" % _run_credits,
	]
	var index: int = await session_log.present_choices(labels, ["descend", "surface"])
	if _snapped:
		return
	if index == 1:
		session_log.log_line(">>> surfacing  ·  haul banked", UIStyle.COL_TEXT)
		await _beat()
		_end_run(false)
		return
	_column.descend(line_system.corruption)
	_show_next_catch()

func _present_catch(catch_data: CatchData) -> void:
	var current := catch_data
	var need_card := true
	while true:
		var augmented := current
		var using_shock := _shock_ready(current)
		if using_shock:
			augmented = _inject_shock_option(current)

		if need_card:
			session_log.log_line(DiveFormat.contact_card(augmented), UIStyle.COL_TEXT)
			need_card = false

		var labels: Array[String] = []
		var echoes: Array[String] = []
		for i in augmented.options.size():
			labels.append(DiveFormat.option_label(i + 1, augmented.options[i], augmented.behavior))
			echoes.append(augmented.options[i].label.to_lower().replace(" ", "_"))

		var lure_action := _contact_lure_action()
		if not lure_action.is_empty():
			labels.append(lure_action.label)
			echoes.append(lure_action.echo)

		var index: int = await session_log.present_choices(labels, echoes)
		if _snapped:
			return

		if not lure_action.is_empty() and index == labels.size() - 1:
			match lure_action.effect:
				LureData.LureEffect.DECOY:
					GameState.consume_lure_use()
					session_log.log_line(">>> decoy deployed — contact slipped", UIStyle.COL_ACCENT)
					current = CatchPool.draw_replacement(
						_column.zone_id, _column.current_layer(), line_system.corruption)
					_column.slots[_column.slot_in_layer] = current
					need_card = true
					if current.behavior == CatchData.BehaviorType.AGGRESSIVE:
						_run_overload(current)
						return
					continue
				LureData.LureEffect.DEEP_PULSE:
					_fire_deep_pulse()
					continue
			continue

		var option: CatchOption = augmented.options[index]

		if option.narrative_text != "":
			session_log.log_line(DiveFormat.narrative_entry(augmented.catch_name, option.narrative_text),
				UIStyle.COL_DIM)
			GameState.journal_entries.append("[%s]\n\n%s" % [augmented.catch_name, option.narrative_text])
			GameState.save()
			await session_log.present_continue()

		if using_shock and index == 0:
			GameState.consume_lure_use()

		if option.sets_entity_flag and augmented.entity_id != "":
			GameState.set_entity_encountered(augmented.entity_id)

		if option.cuts_line:
			var vented := int(line_system.tension) / 2
			line_system.sync_tension(vented)
			line_system.add_corruption(10)
			session_log.log_line(">>> connection cut — tension vented to %d/%d  ·  SIG -10%%" % [
				vented, line_system.max_tension], UIStyle.COL_WARNING)
			await _beat()
			_advance_slot()
			return

		match augmented.behavior:
			CatchData.BehaviorType.RESISTANT:
				await _resolve_resistant(option, augmented)
			CatchData.BehaviorType.NEGOTIATING:
				await _resolve_negotiating(option, augmented)
			_:
				_apply_and_record(option, augmented)
				session_log.log_line(
					DiveFormat.result_line(option.credit_value, option.tension_delta, augmented.corruption_gain),
					UIStyle.COL_TEXT)
				await _beat()
				if _snapped:
					return
				_advance_slot()
		return

func _contact_lure_action() -> Dictionary:
	if GameState.current_lure == null or not GameState.has_lure_stock(GameState.current_lure):
		return {}
	var lure_id := GameState.get_lure_id(GameState.current_lure)
	var qty: int = GameState.lure_inventory.get(lure_id, 0)
	match GameState.current_lure.effect:
		LureData.LureEffect.DECOY:
			return {
				"label": "[L] fire %s (x%d)  ·  slip this contact, draw a safer replacement" % [lure_id, qty],
				"echo": "fire %s" % lure_id,
				"effect": LureData.LureEffect.DECOY,
			}
		LureData.LureEffect.DEEP_PULSE:
			if _column.slot_in_layer + 1 >= _column.slots.size():
				return {}
			return {
				"label": "[L] fire %s (x%d)  ·  scan remaining contacts in this layer" % [lure_id, qty],
				"echo": "fire %s" % lure_id,
				"effect": LureData.LureEffect.DEEP_PULSE,
			}
	return {}

func _fire_deep_pulse() -> void:
	GameState.consume_lure_use()
	var base := _column.global_slot_index() - _column.slot_in_layer
	var tags: Array[String] = []
	for i in range(_column.slot_in_layer + 1, _column.slots.size()):
		var c := _column.slots[i]
		var marker: String
		var tag: String
		if c.behavior == CatchData.BehaviorType.AGGRESSIVE:
			marker = "!"
			tag = "[HOSTILE]"
		else:
			var type_name := str(CatchData.CatchType.keys()[c.catch_type])
			marker = type_name.substr(0, 1)
			tag = "[%s]" % type_name
		EventBus.slot_revealed.emit(base + i, marker)
		tags.append(tag)
	session_log.log_line(">>> deep_pulse: %d contacts ahead — %s" % [tags.size(), " ".join(tags)],
		UIStyle.COL_ACCENT)

func _resolve_resistant(option: CatchOption, catch_data: CatchData) -> void:
	if option.resist_chance > 0.0 and randf() < option.resist_chance:
		line_system.apply_tension(option.resist_tension_penalty)
		line_system.add_corruption(catch_data.corruption_gain)
		session_log.log_line(">>> [!!! COUNTERMEASURE TRIGGERED !!!]", UIStyle.COL_WARNING)
		session_log.log_line(">>> resisted  ·  +%dT  ·  no reward" % option.resist_tension_penalty,
			UIStyle.COL_DEBT)
	else:
		_apply_and_record(option, catch_data)
		session_log.log_line(
			DiveFormat.result_line(option.credit_value, option.tension_delta, catch_data.corruption_gain),
			UIStyle.COL_TEXT)
	await _beat()
	if _snapped:
		return
	_advance_slot()

func _resolve_negotiating(option: CatchOption, catch_data: CatchData) -> void:
	if option.fail_chance > 0.0 and randf() < option.fail_chance:
		line_system.apply_tension(option.fail_tension_delta)
		_run_credits += option.fail_credit_value
		if catch_data.catch_type == CatchData.CatchType.BIO:
			_bio_credits += option.fail_credit_value
		EventBus.haul_changed.emit(_run_credits)
		line_system.add_corruption(catch_data.corruption_gain)
		session_log.log_line(">>> [!!! COUNTERMEASURE TRIGGERED !!!]", UIStyle.COL_WARNING)
		session_log.log_line(
			">>> negotiation failed  ·  " + DiveFormat.result_line(
				option.fail_credit_value, option.fail_tension_delta, catch_data.corruption_gain).trim_prefix(">>> "),
			UIStyle.COL_DEBT)
	else:
		_apply_and_record(option, catch_data)
		session_log.log_line(
			DiveFormat.result_line(option.credit_value, option.tension_delta, catch_data.corruption_gain),
			UIStyle.COL_TEXT)
	await _beat()
	if _snapped:
		return
	_advance_slot()

func _run_overload(catch_data: CatchData) -> void:
	var shock_ready := _shock_ready(catch_data)
	var fight := OverloadFight.new(line_system.max_tension, int(line_system.tension),
		catch_data.anchor_strength, line_system.corruption, shock_ready)
	var reward: CatchOption = catch_data.options[0]

	session_log.log_line(DiveFormat.contact_card(catch_data), UIStyle.COL_DEBT)
	session_log.log_line("│  est. yield: ~%dcr" % reward.credit_value, UIStyle.COL_DIM)

	while true:
		var backlash := fight.apply_backlash()
		line_system.sync_tension(fight.tension)
		session_log.log_line(">>> backlash: +%dT" % backlash, UIStyle.COL_WARNING)
		if fight.is_snapped():
			_on_line_snapped()
			return
		session_log.log_line(
			DiveFormat.overload_status(fight.anchor, catch_data.anchor_strength, fight.threat, fight.turn),
			UIStyle.COL_DIM)

		var commands := fight.pick_commands()
		var labels: Array[String] = []
		var echoes: Array[String] = []
		for i in commands.size():
			labels.append(DiveFormat.command_label(i + 1, commands[i]))
			echoes.append(str(commands[i].id).to_lower())
		var index: int = await session_log.present_choices(labels, echoes)
		if _snapped:
			return
		var cmd: Dictionary = commands[index]

		if cmd.id == "ISOLATE_FEED":
			line_system.sync_tension(fight.tension)
			session_log.log_line(">>> feed isolated  ·  catch lost  ·  tension holds at %dT" % fight.tension,
				UIStyle.COL_DIM)
			await _beat()
			_advance_slot()
			return

		if cmd.id == "OVERLOAD_CORE":
			GameState.consume_lure_use()

		var result: Dictionary = fight.execute(cmd)
		line_system.sync_tension(fight.tension)
		if result.succeeded:
			session_log.log_line(">>> %s — EXECUTED" % cmd.id, UIStyle.COL_TEXT)
		else:
			session_log.log_line(">>> %s — FAILED  ·  +%dT backlash" % [cmd.id, int(cmd.fail_t)],
				UIStyle.COL_DEBT)

		if fight.is_snapped():
			_on_line_snapped()
			return
		if fight.is_captured():
			_run_credits += reward.credit_value
			if catch_data.catch_type == CatchData.CatchType.BIO:
				_bio_credits += reward.credit_value
			EventBus.haul_changed.emit(_run_credits)
			line_system.add_corruption(catch_data.corruption_gain)
			session_log.log_line(">>> %s captured" % catch_data.catch_name, UIStyle.COL_TEXT)
			session_log.log_line(
				DiveFormat.result_line(reward.credit_value, 0, catch_data.corruption_gain),
				UIStyle.COL_TEXT)
			await _beat()
			_advance_slot()
			return
		fight.next_turn()

func _inject_shock_option(catch_data: CatchData) -> CatchData:
	var overload_opt = CatchOption.new()
	overload_opt.label = "shock overload"
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

func _apply_and_record(option: CatchOption, catch_data: CatchData) -> void:
	line_system.apply_tension(option.tension_delta)
	line_system.add_corruption(catch_data.corruption_gain)
	_run_credits += option.credit_value
	if catch_data.catch_type == CatchData.CatchType.BIO:
		_bio_credits += option.credit_value
	EventBus.haul_changed.emit(_run_credits)

func _advance_slot() -> void:
	if _zone_data and _zone_data.passive_tension_drain > 0:
		line_system.apply_tension(_zone_data.passive_tension_drain)
		if _snapped:
			return
		session_log.log_line(">>> zone interference: +%dT" % _zone_data.passive_tension_drain,
			UIStyle.COL_WARNING)
	_column.advance()
	_show_next_catch()

func _shock_ready(catch_data: CatchData) -> bool:
	return (GameState.current_lure != null and
		GameState.current_lure.effect == LureData.LureEffect.SHOCK and
		GameState.has_lure_stock(GameState.current_lure) and
		catch_data.catch_type == CatchData.CatchType.MECH)

func _pacify_entities_in_layer() -> void:
	for i in _column.slots.size():
		var c = _column.slots[i]
		if c.catch_type == CatchData.CatchType.ENTITY and c.behavior == CatchData.BehaviorType.AGGRESSIVE:
			var dup = c.duplicate()
			dup.behavior = CatchData.BehaviorType.PASSIVE
			_column.slots[i] = dup

func _beat() -> void:
	await get_tree().create_timer(BEAT_PAUSE).timeout

func _on_line_snapped() -> void:
	if _snapped:
		return
	_snapped = true
	var forfeited := _run_credits
	_run_credits = 0
	_bio_credits = 0
	EventBus.haul_changed.emit(0)
	session_log.clear_live()
	session_log.log_line("\n[!!! TENSION EXCEEDED !!!]", UIStyle.COL_DEBT)
	await get_tree().create_timer(0.5).timeout
	session_log.log_line(TextFX.corrupt("[LINE SNAPPED — SIGNAL LOST]", 0.2), UIStyle.COL_DEBT)
	await get_tree().create_timer(0.6).timeout
	session_log.log_line(">>> haul forfeited: %dcr" % forfeited, UIStyle.COL_DEBT)
	await get_tree().create_timer(0.9).timeout
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
	UIController.navigate_to("debrief")

func _initial_lure_label() -> String:
	if not GameState.current_lure:
		return "—"
	var lure_id := GameState.get_lure_id(GameState.current_lure)
	var qty: int = GameState.lure_inventory.get(lure_id, 0)
	if qty == GameState.INFINITE_STOCK:
		return "%s ∞" % lure_id
	return "%s x%d" % [lure_id, qty]
