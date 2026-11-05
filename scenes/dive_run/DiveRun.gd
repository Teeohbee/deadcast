# scenes/dive_run/DiveRun.gd
extends Control

const ROD_DAMAGE_TENSION_PENALTY: int = 25
const BEAT_PAUSE := 0.5
const SNAP_SHAKE_STRENGTH := 10.0
const SNAP_SHAKE_SECONDS := 0.4
const SNAP_FLASH_SECONDS := 0.6
const FAKE_SIGNAL_LOSS_SECONDS := 0.5
const _DEBRIEF_SEP := "────────────────────────────────────────────────────────────────"
const _DEBRIEF_SEP_SHORT := "────────────────────────────────────────────────"

@onready var line_system: LineSystem = $LineSystem
@onready var line_tension: LineTensionPanel = $Margin/MainRow/Rail/LineTension
@onready var biosign: BiosignPanel = $Margin/MainRow/Rail/Biosign
@onready var hydrophone: HydrophonePanel = $Margin/MainRow/Rail/Hydrophone
@onready var depth_column: DepthColumnPanel = $Margin/MainRow/Rail/DepthColumn
@onready var status_strip: DiveStatusStrip = $Margin/MainRow/LogPanel/LogVBox/StatusStrip
@onready var session_log: SessionLog = $Margin/MainRow/LogPanel/LogVBox/SessionLog

var _column: DiveColumn = null
var _zone_data: ZoneData = null
var _run_record: Dictionary = {}
var _run_credits: int = 0
var _bio_credits: int = 0
var _snapped: bool = false
var _hints_shown: Dictionary = {}
var _facts: RunFacts = null
var _job_outcome: Dictionary = {}

func _ready() -> void:
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
	_run_record = {
		"run": GameState.run_count + 1,
		"zone": _zone_data.display_name.to_lower(),
		"entries": [],
		"banked": 0,
		"forfeited": 0,
		"outcome": "surfaced",
	}

	_facts = RunFacts.new(zone_id)

	var max_depth = GameState.current_rod.max_depth if GameState.current_rod else 100
	_column = DiveColumn.new(zone_id, max_depth)
	_column.generate_current_layer(line_system.corruption)

	depth_column.setup(_column.reachable_layer_sizes())
	status_strip.setup(_initial_lure_label())
	line_tension.setup(line_system.max_tension)
	biosign.setup(line_system.max_tension)
	var bloom := RailBloom.new()
	add_child(bloom)
	bloom.track([line_tension, biosign, depth_column, hydrophone, $Margin/MainRow/LogPanel])
	EventBus.haul_changed.emit(0)
	EventBus.tension_changed.emit(line_system.tension)
	EventBus.corruption_changed.emit(line_system.corruption)

	await get_tree().process_frame
	session_log.log_line("> cast — %s" % _zone_data.display_name.to_lower(), DeckStyle.DIM)
	EventBus.dive_cast.emit()
	if GameState.current_rod and GameState.rod_damaged:
		session_log.log_line(">>> rod damaged — tension cap reduced to %d" % line_system.max_tension,
			DeckStyle.AMBER)
	var job := MartaJobs.find(GameState.active_job_id)
	if job:
		session_log.log_line(">>> marta job: %s  ·  %dcr off the debt if it holds" % [
			job.title, job.debt_relief], DeckStyle.SKY)
	_log_hint(DiveHints.CAST)
	_show_next_catch()

# Each first-dive hint shows once per run, at the first moment it applies.
func _log_hint(moment: String) -> void:
	if _hints_shown.has(moment):
		return
	_hints_shown[moment] = true
	for line in DiveHints.lines_for(moment, GameState.first_dive_hints_done):
		session_log.log_line(line, DeckStyle.GREEN)

func _show_next_catch() -> void:
	if _snapped:
		return
	if _column.layer_cleared():
		# Mark the just-cleared layer's slots resolved on the depth rail; the early
		# return below otherwise skips the slot_changed emit and the last slot stays
		# shown as current (">") through the checkpoint/surface screen.
		EventBus.slot_changed.emit(_column.global_slot_index() + 1, _column.total_reachable_slots())
		if _column.can_descend():
			_show_checkpoint()
		else:
			session_log.log_line("\n>>> column cleared  ·  surfacing", DeckStyle.TEXT)
			await _beat()
			await _end_run(false)
		return
	var catch_data = _column.current_catch()
	EventBus.slot_changed.emit(_column.global_slot_index() + 1, _column.total_reachable_slots())

	if catch_data.behavior == CatchData.BehaviorType.AGGRESSIVE:
		_run_overload(catch_data)
		return

	_present_catch(catch_data)

func _show_checkpoint() -> void:
	var ghost_bait_armed := false
	session_log.log_line("\n─── DEPTH CHECKPOINT ──────────────────────────", DeckStyle.SKY)
	EventBus.checkpoint_reached.emit()
	session_log.log_line("│  %s cleared  ·  haul: %dcr  ·  tension %d/%d  ·  SIG %d%%" % [
		DiveColumn.LAYER_NAMES[_column.current_layer()], _run_credits,
		int(line_system.tension), line_system.max_tension,
		int(100.0 - line_system.corruption)], DeckStyle.TEXT)
	session_log.log_line("│  %s scan: %d contacts  ·  draws weighted by current SIG" % [
		_column.next_layer_name(), _column.next_layer_slot_count()], DeckStyle.DIM)
	_log_hint(DiveHints.CHECKPOINT)

	while true:
		var labels: Array[String] = [
			"[1] DESCEND   — push deeper. higher yields, SIG-weighted draws",
			"[2] SURFACE   — bank %dcr and end the run" % _run_credits,
		]
		var echoes: Array[String] = ["descend", "surface"]

		var offer_ghost_bait := (not ghost_bait_armed and
			GameState.current_lure != null and
			GameState.current_lure.effect == LureData.LureEffect.GHOST_BAIT and
			GameState.has_lure_stock(GameState.current_lure))
		if offer_ghost_bait:
			var qty: int = GameState.lure_inventory.get(GameState.get_lure_id(GameState.current_lure), 0)
			labels.append("[L] fire ghost_bait (x%d)  ·  bait the next layer — entities surface, aggression suppressed" % qty)
			echoes.append("fire ghost_bait")

		var index: int = await session_log.present_choices(labels, echoes)
		if _snapped:
			return

		if offer_ghost_bait and index == labels.size() - 1:
			GameState.consume_lure_use()
			ghost_bait_armed = true
			_run_record.entries.append({"kind": "lure", "text": "ghost bait armed"})
			session_log.log_line(">>> ghost bait armed — the next layer will draw what's listening",
				DeckStyle.SKY)
			continue

		var layer_name: String = DiveColumn.LAYER_NAMES[_column.current_layer()]
		if index == 1:
			_run_record.entries.append({
				"kind": "checkpoint", "layer": layer_name,
				"haul": _run_credits, "choice": "surface"})
			session_log.log_line(">>> surfacing  ·  haul banked", DeckStyle.TEXT)
			await _beat()
			await _end_run(false)
			return

		_run_record.entries.append({
			"kind": "checkpoint", "layer": layer_name,
			"haul": _run_credits, "choice": "descend"})
		_column.descend(line_system.corruption, ghost_bait_armed)
		if ghost_bait_armed:
			_pacify_entities_in_layer()
		_show_next_catch()
		return

func _present_catch(catch_data: CatchData) -> void:
	var current := catch_data
	var need_card := true
	while true:
		var augmented := current
		var using_shock := _shock_ready(current)
		if using_shock:
			augmented = _inject_shock_option(current)

		if need_card:
			await _maybe_fake_signal_loss()
			session_log.log_line(DiveFormat.contact_card(augmented), DeckStyle.TEXT)
			EventBus.contact_presented.emit(catch_data)
			_log_hint(DiveHints.CONTACT)
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
					session_log.log_line(">>> decoy deployed — contact slipped", DeckStyle.SKY)
					_run_record.entries.append({"kind": "lure", "text": "decoy deployed — contact slipped"})
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
		var echo: String = echoes[index]

		if option.narrative_text != "":
			session_log.log_line(DiveFormat.narrative_entry(augmented.catch_name, option.narrative_text),
				DeckStyle.TEXT)
			GameState.journal_entries.append("[%s]\n\n%s" % [augmented.catch_name, option.narrative_text])
			GameState.save()
			await session_log.present_continue()

		if using_shock and index == 0:
			GameState.consume_lure_use()

		if option.sets_entity_flag and augmented.entity_id != "":
			GameState.set_entity_encountered(augmented.entity_id)

		if option.cuts_line:
			_facts.cut_line = true
			var vented := int(line_system.tension) / 2
			line_system.sync_tension(vented)
			line_system.add_corruption(10)
			_record_slot(augmented, echo, "connection cut", 0, 0, 10, option.sets_entity_flag)
			session_log.log_line(">>> connection cut — tension vented to %d/%d  ·  SIG -10%%" % [
				vented, line_system.max_tension], DeckStyle.AMBER)
			await _beat()
			_advance_slot()
			return

		if HaulTurn.hauls(_zone_data, augmented, option):
			await _resolve_haul(option, augmented, echo)
			return

		match augmented.behavior:
			CatchData.BehaviorType.RESISTANT:
				await _resolve_resistant(option, augmented, echo)
			CatchData.BehaviorType.NEGOTIATING:
				await _resolve_negotiating(option, augmented, echo)
			_:
				_apply_and_record(option, augmented)
				_record_slot(augmented, echo, "",
					option.credit_value, option.tension_delta, augmented.corruption_gain,
					option.sets_entity_flag)
				session_log.log_line(
					DiveFormat.result_line(option.credit_value, option.tension_delta, augmented.corruption_gain),
					DeckStyle.TEXT)
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
	var summary := "deep_pulse: %d contacts ahead — %s" % [tags.size(), " ".join(tags)]
	_run_record.entries.append({"kind": "lure", "text": summary})
	session_log.log_line(">>> %s" % summary, DeckStyle.SKY)

# Winch haul (District 7 spike): the player hauls the payload up by hand and the result
# scales what the option pays and costs, in place of the resist/fail dice.
func _resolve_haul(option: CatchOption, catch_data: CatchData, echo: String) -> void:
	var run := HaulRun.new()
	run.setup(HaulTurn.dials(catch_data, option), HaulTurn.difficulty(GameState.run_count),
		catch_data.fragments, HaulTurn.glyph(catch_data.catch_type), catch_data.catch_name.to_lower())
	add_child(run)
	var result: Dictionary = await run.finished
	run.queue_free()

	var pay := HaulTurn.payout(option, result)
	line_system.add_corruption(catch_data.corruption_gain)
	_run_credits += pay.credits
	if catch_data.catch_type == CatchData.CatchType.BIO:
		_bio_credits += pay.credits
	EventBus.haul_changed.emit(_run_credits)
	var outcome: String = result.outcome
	var label := "haul %s" % outcome
	if outcome == "messy":
		label += " (%d hit%s)" % [result.hits, "" if result.hits == 1 else "s"]
	_record_slot(catch_data, echo, label, pay.credits, pay.tension, catch_data.corruption_gain,
		option.sets_entity_flag)
	var color: Color = {"perfect": DeckStyle.SKY, "clean": DeckStyle.GREEN, "messy": DeckStyle.AMBER}.get(outcome, DeckStyle.RED)
	session_log.log_line(">>> %s" % label, color)
	if int(result.get("total", 0)) > 0:
		session_log.log_line("│  recovered: %s" % DiveFormat.recovered_fragments(result.fragments), DeckStyle.TEXT)
	session_log.log_line(DiveFormat.result_line(pay.credits, pay.tension, catch_data.corruption_gain), DeckStyle.TEXT)
	line_system.apply_tension(pay.tension)
	if _snapped:
		return
	await _beat()
	if _snapped:
		return
	_advance_slot()

func _resolve_resistant(option: CatchOption, catch_data: CatchData, echo: String) -> void:
	if option.resist_chance > 0.0 and randf() < option.resist_chance:
		line_system.apply_tension(option.resist_tension_penalty)
		line_system.add_corruption(catch_data.corruption_gain)
		_record_slot(catch_data, echo, "resisted",
			0, option.resist_tension_penalty, catch_data.corruption_gain, option.sets_entity_flag)
		session_log.log_line(">>> [!!! COUNTERMEASURE TRIGGERED !!!]", DeckStyle.AMBER)
		session_log.log_line(">>> resisted  ·  +%dT  ·  no reward" % option.resist_tension_penalty,
			DeckStyle.RED)
	else:
		_apply_and_record(option, catch_data)
		_record_slot(catch_data, echo, "",
			option.credit_value, option.tension_delta, catch_data.corruption_gain, option.sets_entity_flag)
		session_log.log_line(
			DiveFormat.result_line(option.credit_value, option.tension_delta, catch_data.corruption_gain),
			DeckStyle.TEXT)
	await _beat()
	if _snapped:
		return
	_advance_slot()

func _resolve_negotiating(option: CatchOption, catch_data: CatchData, echo: String) -> void:
	if option.fail_chance > 0.0 and randf() < option.fail_chance:
		line_system.apply_tension(option.fail_tension_delta)
		_run_credits += option.fail_credit_value
		if catch_data.catch_type == CatchData.CatchType.BIO:
			_bio_credits += option.fail_credit_value
		EventBus.haul_changed.emit(_run_credits)
		line_system.add_corruption(catch_data.corruption_gain)
		_record_slot(catch_data, echo, "negotiation failed",
			option.fail_credit_value, option.fail_tension_delta, catch_data.corruption_gain,
			option.sets_entity_flag)
		session_log.log_line(">>> [!!! COUNTERMEASURE TRIGGERED !!!]", DeckStyle.AMBER)
		session_log.log_line(
			">>> negotiation failed  ·  " + DiveFormat.result_line(
				option.fail_credit_value, option.fail_tension_delta, catch_data.corruption_gain).trim_prefix(">>> "),
			DeckStyle.RED)
	else:
		_apply_and_record(option, catch_data)
		_record_slot(catch_data, echo, "",
			option.credit_value, option.tension_delta, catch_data.corruption_gain, option.sets_entity_flag)
		session_log.log_line(
			DiveFormat.result_line(option.credit_value, option.tension_delta, catch_data.corruption_gain),
			DeckStyle.TEXT)
	await _beat()
	if _snapped:
		return
	_advance_slot()

func _run_overload(catch_data: CatchData) -> void:
	var shock_ready := _shock_ready(catch_data)
	var fight := OverloadFight.new(line_system.max_tension, int(line_system.tension),
		catch_data.anchor_strength, line_system.corruption, shock_ready)
	var reward: CatchOption = catch_data.options[0]

	session_log.log_line(DiveFormat.contact_card(catch_data), DeckStyle.RED)
	EventBus.contact_presented.emit(catch_data)
	_log_hint(DiveHints.CONTACT)
	session_log.log_line("│  est. yield: ~%dcr" % reward.credit_value, DeckStyle.TEXT)

	var last_echo := ""
	while true:
		var backlash := fight.apply_backlash()
		line_system.sync_tension(fight.tension)
		session_log.log_line(">>> backlash: +%dT" % backlash, DeckStyle.AMBER)
		if fight.is_snapped():
			_record_slot(catch_data, "overload", "tension exceeded", 0, backlash, 0, false)
			_on_line_snapped()
			return
		session_log.log_line(
			DiveFormat.overload_status(fight.anchor, catch_data.anchor_strength, fight.threat, fight.turn),
			DeckStyle.TEXT)

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
		last_echo = str(cmd.id).to_lower()

		if cmd.id == "ISOLATE_FEED":
			line_system.sync_tension(fight.tension)
			session_log.log_line(">>> feed isolated  ·  catch lost  ·  tension holds at %dT" % fight.tension,
				DeckStyle.TEXT)
			_run_record.entries.append({"kind": "lure", "text": "feed isolated — catch lost"})
			await _beat()
			_advance_slot()
			return

		if cmd.id == "OVERLOAD_CORE":
			GameState.consume_lure_use()

		var result: Dictionary = fight.execute(cmd)
		line_system.sync_tension(fight.tension)
		if result.succeeded:
			session_log.log_line(">>> %s — EXECUTED" % cmd.id, DeckStyle.TEXT)
		else:
			session_log.log_line(">>> %s — FAILED  ·  +%dT backlash" % [cmd.id, int(cmd.fail_t)],
				DeckStyle.RED)

		if fight.is_snapped():
			_record_slot(catch_data, last_echo, "tension exceeded", 0, 0, 0, false)
			_on_line_snapped()
			return
		if fight.is_captured():
			_run_credits += reward.credit_value
			if catch_data.catch_type == CatchData.CatchType.BIO:
				_bio_credits += reward.credit_value
			EventBus.haul_changed.emit(_run_credits)
			line_system.add_corruption(catch_data.corruption_gain)
			_record_slot(catch_data, last_echo, "", reward.credit_value, 0, catch_data.corruption_gain, false)
			session_log.log_line(">>> %s captured" % catch_data.catch_name, DeckStyle.TEXT)
			session_log.log_line(
				DiveFormat.result_line(reward.credit_value, 0, catch_data.corruption_gain),
				DeckStyle.TEXT)
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

func _record_slot(catch_data: CatchData, echo: String, result: String,
		credits: int, tension: int, sig: int, engaged: bool = false) -> void:
	_facts.note_slot(catch_data.catch_type, credits, engaged, line_system.corruption)
	_run_record.entries.append({
		"kind": "slot",
		"slot": _column.global_slot_index() + 1,
		"layer": catch_data.layer,
		"engaged": engaged,
		"name": catch_data.catch_name,
		"type_tag": DiveFormat.type_tag(catch_data.catch_type),
		"echo": echo,
		"result": result,
		"credits": credits,
		"tension": tension,
		"sig": sig,
	})

func _advance_slot() -> void:
	if _zone_data and _zone_data.zone_interference > 0:
		line_system.apply_tension(_zone_data.zone_interference)
		if _snapped:
			return
		session_log.log_line(">>> zone interference: +%dT" % _zone_data.zone_interference,
			DeckStyle.AMBER)
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

# Heavy corruption: the feed sometimes drops out before a contact resolves.
func _maybe_fake_signal_loss() -> void:
	if not DiveFormat.should_fake_signal_loss(line_system.corruption, randf()):
		return
	ScreenFX.message_flash(session_log, "[SIGNAL LOST]", DeckStyle.RED, FAKE_SIGNAL_LOSS_SECONDS)
	await get_tree().create_timer(FAKE_SIGNAL_LOSS_SECONDS).timeout

func _beat() -> void:
	await get_tree().create_timer(BEAT_PAUSE).timeout

func _on_line_snapped() -> void:
	if _snapped:
		return
	_snapped = true
	EventBus.line_snapped.emit()
	var forfeited := _run_credits
	_run_record.entries.append({"kind": "snapped"})
	_run_record.outcome = "snapped"
	_run_record.forfeited = forfeited
	_run_credits = 0
	_bio_credits = 0
	EventBus.haul_changed.emit(0)
	session_log.clear_live()
	ScreenFX.shake($Margin, SNAP_SHAKE_STRENGTH, SNAP_SHAKE_SECONDS)
	ScreenFX.flash(self, DeckStyle.RED, SNAP_FLASH_SECONDS)
	session_log.log_line("\n[!!! TENSION EXCEEDED !!!]", DeckStyle.RED)
	await get_tree().create_timer(0.5).timeout
	session_log.log_line(TextFX.corrupt("[LINE SNAPPED — SIGNAL LOST]", 0.2), DeckStyle.RED)
	await get_tree().create_timer(0.6).timeout
	session_log.log_line(">>> haul forfeited: %dcr" % forfeited, DeckStyle.RED)
	await get_tree().create_timer(0.9).timeout
	await _end_run(true)

# Settles the accepted job against this run, before the record is saved.
# Returns the run-log entry, or {} when no job was taken.
func _resolve_active_job(snapped: bool) -> Dictionary:
	if GameState.active_job_id == "":
		return {}
	var job := MartaJobs.find(GameState.active_job_id)
	if job == null:
		GameState.active_job_id = ""
		return {}
	_facts.snapped = snapped
	var met := MartaJobs.is_met(job, _facts)
	var relief := GameState.resolve_job(job, met)
	var entry := {"kind": "job", "title": job.title, "met": met, "relief": relief}
	_run_record.entries.append(entry)
	return entry

func _end_run(snapped: bool) -> void:
	_job_outcome = _resolve_active_job(snapped)
	GameState.add_credits(_run_credits - _bio_credits)  # non-bio credits go directly to wallet
	if not snapped:
		_run_record.banked = _run_credits
	GameState.add_run_log(_run_record)
	GameState.last_run_result = {
		"credits": _run_credits,
		"bio_credits": _bio_credits,
		"snapped": snapped
	}
	GameState.on_run_complete(snapped, _bio_credits)
	EventBus.run_ended.emit(GameState.last_run_result)
	await _show_inline_debrief()
	UIController.navigate_to("deck")

func _show_inline_debrief() -> void:
	session_log.clear_live()
	var result := GameState.last_run_result
	var snapped := result.get("snapped", false) as bool
	var earned := result.get("credits", 0) as int
	var bio := result.get("bio_credits", 0) as int

	session_log.log_line("\n─── RUN_LOG " + _DEBRIEF_SEP, DeckStyle.DIM)
	if snapped:
		session_log.log_line("\n[!!! SIGNAL LOST !!!]\nCRITICAL: LINE TENSION EXCEEDED / SIGNAL LOST\n",
			DeckStyle.RED)
	else:
		session_log.log_line("\n>>> connection closed  ·  run complete\n", DeckStyle.TEXT)

	session_log.log_line(_DEBRIEF_SEP_SHORT, DeckStyle.DIM)

	if snapped:
		session_log.log_line("yield:    +0cr  (run forfeited)", DeckStyle.RED)
	elif earned > 0:
		session_log.log_line("yield:    +%dcr" % earned, DeckStyle.SKY)

	session_log.log_line("wallet:   %dcr  ·  debt: %dcr" % [GameState.credits, GameState.debt], DeckStyle.TEXT)
	if not _job_outcome.is_empty():
		session_log.log_line(DiveFormat.job_result(_job_outcome.title, _job_outcome.met, _job_outcome.relief),
			DeckStyle.SKY if _job_outcome.met else DeckStyle.AMBER)

	if GameState.victory:
		session_log.log_line("\ndebt cleared. the meridian is yours.", DeckStyle.SKY)
	else:
		var runs_to_payment := 5 - GameState.runs_since_payment
		if GameState.pressure_level == 0:
			session_log.log_line("next payment: 10,000cr in %d run%s" % [
				runs_to_payment, "s" if runs_to_payment != 1 else ""], DeckStyle.TEXT)
		else:
			session_log.log_line("pressure %d — %s" % [
				GameState.pressure_level, _pressure_label(GameState.pressure_level)],
				LedgerPanel.pressure_fill_color(GameState.pressure_level))

	if bio > 0:
		session_log.log_line("bio cache: %dcr stored in freezer" % bio, DeckStyle.DIM)

	session_log.log_line("", DeckStyle.DIM)
	await session_log.present_action("[ RETURN TO DECK ]", "return to deck")

func _pressure_label(level: int) -> String:
	match level:
		1: return "marta is watching."
		2: return "vendor prices up 20%."
		3: return "okeke won't deal with you."
		4: return "debt collector is coming."
		5: return "forced surrender."
		_: return ""

func _initial_lure_label() -> String:
	if not GameState.current_lure:
		return "—"
	var lure_id := GameState.get_lure_id(GameState.current_lure)
	var qty: int = GameState.lure_inventory.get(lure_id, 0)
	if qty == GameState.INFINITE_STOCK:
		return "%s ∞" % lure_id
	return "%s x%d" % [lure_id, qty]
