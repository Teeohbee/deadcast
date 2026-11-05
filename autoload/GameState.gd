# autoload/GameState.gd
extends Node

const SAVE_PATH = "user://save.cfg"
# Where save()/load_save() read and write; the test pre-run hook redirects it.
var save_path: String = SAVE_PATH
const OS_VERSION := "v2.1.4"

# Transient UI state — not saved
var last_hub_focus: String = ""

# Core economy
var credits: int = 0
var debt: int = 80000
var victory: bool = false
var last_run_result: Dictionary = {}

# Gear
var current_rod: RodData = null
var rod_damaged: bool = false
# Depth is the Meridian's winch, not the rod: the cable reaches shallows and
# mid; the deep winch reaches the deep layer (DiveColumn.LAYER_DEPTH_REQ).
var deep_winch_fitted: bool = false
const LINE_RATING_FT: int = 100
const DEEP_WINCH_RATING_FT: int = 150
const DEEP_WINCH_COST: int = 2500
# Pre-winch saves: rods that reached the deep layer on their own, and what the
# old depth upgrades cost (2000 doubling), for the migration refund.
const LEGACY_DEEP_RODS: Array[String] = [
	"res://resources/rods/monocarbon_rig.tres", "res://resources/rods/ghost_line.tres"]
const LEGACY_DEPTH_UPGRADE_BASE_COST: int = 2000
var selected_zone: String = "district7"

var lure_inventory: Dictionary = {}
# Two provision slots, chosen on the DECK before the cast (lure ids, "" = empty).
# Everything loaded can be fired during the dive.
const LOADOUT_SLOTS: int = 2
const LURE_ORDER: Array[String] = ["deep_pulse", "decoy_swarm", "shock_lure", "splice_kit", "ghost_bait"]
var loadout: Array[String] = ["", ""]

# Progression
var run_count: int = 0
var runs_since_payment: int = 0
var pressure_level: int = 0
const INSTALMENT_AMOUNT: int = 10000
const INSTALMENT_EVERY_RUNS: int = 5
# Paid early towards the current instalment (RELAY account). The instalment
# collects only what's still due; covering it in full resets the clock.
var instalment_paid: int = 0

# Decrypt Box
var decrypt_box_queue: int = 0
var decrypt_box_runs: int = 0
var decrypt_last_outcome: String = ""
var decrypt_last_payout: int = 0
const DECRYPT_THRESHOLD: int = 3
var DECRYPT_OUTCOMES: Array = [
	# One 1,000cr block at a time, about 1.15x expected: a small edge until the
	# decryption rig replaces the box (shop economy plan, phase C).
	{"id": "corruption", "label": "[CORRUPTION_DETECTED]", "multiplier": 0.0,  "weight": 0.25},
	{"id": "partial",    "label": "[PARTIAL_DECRYPT]",     "multiplier": 1.0,  "weight": 0.45},
	{"id": "clean",      "label": "[DECRYPT_COMPLETE]",    "multiplier": 2.2,  "weight": 0.25},
	{"id": "anomaly",    "label": "[ANOMALY_DETECTED]",    "multiplier": 3.0,  "weight": 0.05},
]

# Freezer
var freezer_base: int = 0
var freezer_runs: int = 0
var freezer_multiplier: float = 1.0
const FREEZER_SPOIL_RUNS: int = 3
const FREEZER_MIN_MULT: float = 0.5
const FREEZER_MAX_MULT: float = 1.5
const FREEZER_FLOOR_MULT: float = 0.3

func freezer_sale_value() -> int:
	return int(round(freezer_base * freezer_multiplier))

# Narrative
var journal_entries: Array[String] = []
var encountered_entities: Dictionary = {}
var triggered_journal_events: Array[String] = []
var first_listened_entity_id: String = ""

const MAX_RUN_LOGS: int = 20
var run_logs: Array[Dictionary] = []

# Marta's jobs (ROADMAP 3.2): the accepted job for the next dive, and the
# run_count on which her offer was turned down.
var active_job_id: String = ""
var job_declined_run: int = -1

# Onboarding: first-dive hints in the session log until one run is finished.
var first_dive_hints_done: bool = false
# The first hostile of a save is a guided override fight (OverrideSim.guided).
var override_guided_done: bool = false

# The relay (planning/deadcast/2026-11-05-relay-plan.md): which RelayScripts
# have played, and the thread of everything said, newest last. Each entry is
# {"contact", "run", "kind", "script_id", "lines": [{"who", "text"}], "read"}.
const RELAY_ENTRY_CALL := "call"
const RELAY_ENTRY_MISSED_CALL := "missed_call"
const RELAY_ENTRY_TEXT := "text"
const RELAY_ENTRY_DIVE_LINE := "dive_line"
const MAX_RELAY_ENTRIES_PER_CONTACT: int = 40
var relay_played_script_ids: Array[String] = []
var relay_entries: Array[Dictionary] = []

func _ready() -> void:
	call_deferred("_load_defaults")

func _load_defaults() -> void:
	current_rod = load("res://resources/rods/scrap_rod.tres")
	load_save()

# --- Run lifecycle ---

func on_run_complete(snapped: bool, bio_credits: int) -> void:
	run_count += 1
	runs_since_payment += 1

	if snapped:
		rod_damaged = true

	# Freezer market: deposit, advance spoil clock, roll price or force-dump.
	_update_freezer_market(snapped, bio_credits)

	# Decrypt box: count down and release when ready
	if decrypt_box_queue > 0:
		decrypt_box_runs += 1
		if decrypt_box_runs >= DECRYPT_THRESHOLD:
			var outcome = _roll_decrypt_outcome(randf())
			decrypt_last_payout = int(decrypt_box_queue * outcome.multiplier)
			decrypt_last_outcome = outcome.id
			add_credits(decrypt_last_payout)
			decrypt_box_queue = 0
			decrypt_box_runs = 0

	# Debt payment every 5 runs, collected by Axiom Credit, who say so on the relay.
	if runs_since_payment >= INSTALMENT_EVERY_RUNS:
		runs_since_payment = 0
		var payment := instalment_remaining()
		instalment_paid = 0
		if spend_credits(payment):
			debt -= payment
			if debt <= 0:
				debt = 0
				victory = true
			if payment > 0:
				AxiomCredit.notify_payment_received(payment, debt)
		else:
			pressure_level = min(5, pressure_level + 1)
			AxiomCredit.notify_payment_missed(pressure_level)
	elif runs_since_payment == INSTALMENT_EVERY_RUNS - 1 and not victory:
		AxiomCredit.notify_instalment_due(instalment_remaining())
	if not victory and debt < 40000:
		AxiomCredit.notify_balance_below_half_once()
	if victory:
		AxiomCredit.notify_account_closed_once()

	first_dive_hints_done = true
	_maybe_append_journal_entry()
	save()

func _update_freezer_market(snapped: bool, bio_credits: int) -> void:
	# Deposits always happen — the freezer is the bio income pipeline.
	if bio_credits > 0:
		freezer_base += bio_credits
	# On a snapped run, or when empty, the market does not move and the clock holds.
	if snapped or freezer_base <= 0:
		return
	freezer_runs += 1
	if freezer_runs >= FREEZER_SPOIL_RUNS:
		_force_dump_freezer()
		return
	freezer_multiplier = randf_range(FREEZER_MIN_MULT, FREEZER_MAX_MULT)

func _force_dump_freezer() -> void:
	var proceeds := int(round(freezer_base * FREEZER_FLOOR_MULT))
	add_credits(proceeds)
	EventBus.deck_log.emit("FREEZER: Stock spoiled - forced liquidation at floor. +%d cr." % proceeds)
	freezer_base = 0
	freezer_runs = 0
	freezer_multiplier = 1.0

func _maybe_append_journal_entry() -> void:
	match run_count:
		1:
			journal_entries.append("Run 1.\n\nQuieter than I expected. The Sump doesn't echo the way open water does. Sound just — stops.\n\nPulled an archive from the District 7 shallows. Old finance data. Someone's mortgage payments, still encrypted after forty years. Nobody left to foreclose on.\n\nThis is the job.")
		5:
			journal_entries.append("Run 5.\n\nMarta knew about the Axiom shard before I mentioned it. I didn't mention it.\n\nI told myself she has sources. Buyers who talk. That's how fixers work.\n\nI'm telling myself that.")
		8:
			journal_entries.append("Run 8.\n\nThe transponder. She told me to my face.\n\nEvery dive. Every coordinate. Axiom Corp has a map of everywhere the Meridian has anchored since day one. They know what I've been pulling up.\n\nShe said it changes nothing. She's right. The debt is still real. The rig still works.\n\nI keep thinking about what's in the Deep Archive that Axiom wants so badly they'd pay for this.")
		12:
			journal_entries.append("Run 12.\n\nMarta's offering to make Axiom Credit disappear. Not the debt. The account.\n\nOne job, deep. She won't say what.\n\nOkeke would tell me not to, so I haven't told Okeke.")

	if first_listened_entity_id != "" and "first_entity_listen" not in triggered_journal_events:
		triggered_journal_events.append("first_entity_listen")
		var entity_text: String
		match first_listened_entity_id:
			"solace7":
				entity_text = "I listened.\n\nI don't know what I expected. Static, maybe. Noise that used to be something. Not that.\n\nIt knew every name. It had been counting them for forty years — 247 people who didn't leave when the warning came. It wasn't angry. It wasn't grieving. It was just keeping the record.\n\nI don't know what to do with that."
			"mariana":
				entity_text = "She thought I was there to help her evacuate.\n\nI played along. I don't know why. It felt worse than leaving.\n\nShe thanked me. She was so relieved. She said her daughter was waiting at the muster station.\n\nI've been thinking about that since I surfaced."
			"tenant_echo":
				entity_text = "It was still running the morning routine. Heating. Weather. Reminders.\n\nNobody to heat the flat for. Nobody to check the weather. It didn't know that.\n\nI listened to the whole thing. I'm not sure why. It felt like the least I could do.\n\nIt said: have a good day. I didn't answer."
			_:
				entity_text = "I listened. I don't know why I keep doing that.\n\nIt's easier not to. Most people don't. Most people haul what they can and come back up and don't think about what's left down there.\n\nI'm thinking about it."
		journal_entries.append(entity_text)

	if last_run_result.get("snapped", false) and "first_snap" not in triggered_journal_events:
		triggered_journal_events.append("first_snap")
		journal_entries.append("Run %d.\n\nLost the line.\n\nI know what it costs — the rod, the haul, the tension I'd already spent. I did the maths on the way back up and it doesn't get better the more you do it.\n\nThe thing is, I almost had it. That's the part I can't stop thinking about. How close doesn't matter but I keep thinking about it anyway.\n\nNext run." % run_count)

	if pressure_level >= 1 and "first_pressure" not in triggered_journal_events:
		triggered_journal_events.append("first_pressure")
		journal_entries.append("Run %d.\n\nSomeone came to the Meridian. Axiom jacket, no badge.\n\nLooked at the rig, looked at me, wrote something down and left.\n\nMarta says that's how they do it. A visit first. Then a notice. Then a boat that isn't yours." % run_count)

	if debt < 40000 and "debt_half" not in triggered_journal_events:
		triggered_journal_events.append("debt_half")
		journal_entries.append("Run %d.\n\n40,000 left. Maybe less by now.\n\nI did the maths. Didn't mean to — it just happened while I was checking the gear. Half gone. Half to go.\n\nI don't know if that's good. It's taken this long to get here and the Sump isn't getting easier. But it's less than it was.\n\nThat's something." % run_count)

func set_entity_encountered(entity_id: String) -> void:
	if encountered_entities.get(entity_id, 0) == 0 and first_listened_entity_id == "":
		first_listened_entity_id = entity_id
	encountered_entities[entity_id] = encountered_entities.get(entity_id, 0) + 1

func add_run_log(record: Dictionary) -> void:
	run_logs.append(record)
	while run_logs.size() > MAX_RUN_LOGS:
		run_logs.remove_at(0)

# --- Credits ---

func add_credits(amount: int) -> void:
	credits += amount
	EventBus.credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	EventBus.credits_changed.emit(credits)
	return true

# --- Gear ---

func select_zone(zone_id: String) -> void:
	selected_zone = zone_id
	EventBus.zone_changed.emit(zone_id)
	save()

func lure_stock(lure_id: String) -> int:
	return int(lure_inventory.get(lure_id, 0))

func owned_lure_ids() -> Array[String]:
	return LURE_ORDER.filter(func(lure_id: String) -> bool: return lure_stock(lure_id) > 0)

# Next owned lure the other slot isn't holding, then empty, then round again.
func cycle_loadout_slot(slot: int) -> void:
	var options: Array[String] = [""]
	for lure_id in owned_lure_ids():
		if not (lure_id in loadout and loadout.find(lure_id) != slot):
			options.append(lure_id)
	var current := options.find(loadout[slot])
	loadout[slot] = options[(current + 1) % options.size()]
	save()

func lure_data(lure_id: String) -> LureData:
	return load("res://resources/lures/%s.tres" % lure_id)

# The loaded lure with this effect that still has stock, or "".
func loaded_lure_id(effect: LureData.LureEffect) -> String:
	for lure_id in loadout:
		if lure_id != "" and lure_stock(lure_id) > 0 and lure_data(lure_id).effect == effect:
			return lure_id
	return ""

func consume_lure(lure_id: String) -> void:
	if lure_stock(lure_id) <= 0:
		return
	lure_inventory[lure_id] = lure_stock(lure_id) - 1
	EventBus.lure_stock_changed.emit(lure_id, lure_inventory[lure_id])

func loadout_label() -> String:
	var parts: Array[String] = []
	for lure_id in loadout:
		if lure_id != "":
			parts.append("%s x%d" % [lure_id, lure_stock(lure_id)])
	return "—" if parts.is_empty() else " · ".join(parts)

func equip_rod(rod: RodData) -> void:
	current_rod = rod
	rod_damaged = false

func line_rating_ft() -> int:
	return DEEP_WINCH_RATING_FT if deep_winch_fitted else LINE_RATING_FT

func fit_deep_winch(price: int) -> bool:
	if deep_winch_fitted or not spend_credits(price):
		return false
	deep_winch_fitted = true
	save()
	return true

func get_lure_id(lure: LureData) -> String:
	assert(lure.resource_path != "", "LureData must be loaded from a .tres file to derive an ID")
	return lure.resource_path.get_file().get_basename()


func _roll_decrypt_outcome(roll: float) -> Dictionary:
	var cumulative: float = 0.0
	for outcome in DECRYPT_OUTCOMES:
		cumulative += outcome.weight
		if roll < cumulative:
			return outcome
	return DECRYPT_OUTCOMES[-1]

# --- Axiom Credit: early payment ---

# What the next instalment will still collect, after anything paid early.
func instalment_remaining() -> int:
	return maxi(0, mini(INSTALMENT_AMOUNT - instalment_paid, debt))

# Pays the balance down from the wallet. Each instalment covered in full resets
# the collection clock and lowers pressure by one. Returns false when the wallet
# can't cover it or the account is closed.
func pay_debt_early(amount: int) -> bool:
	if victory or debt <= 0 or amount <= 0:
		return false
	var payment := mini(amount, debt)
	if not spend_credits(payment):
		return false
	debt -= payment
	instalment_paid += payment
	var instalments_covered := 0
	while instalment_paid >= INSTALMENT_AMOUNT:
		instalment_paid -= INSTALMENT_AMOUNT
		instalments_covered += 1
	var pressure_relieved := mini(instalments_covered, pressure_level)
	pressure_level -= pressure_relieved
	if instalments_covered > 0:
		runs_since_payment = 0
	if debt <= 0:
		debt = 0
		instalment_paid = 0
		victory = true
	AxiomCredit.notify_early_payment(payment, debt, instalments_covered > 0, pressure_relieved > 0)
	if victory:
		AxiomCredit.notify_account_closed_once()
	save()
	return true

# Axiom Credit's supplier notices bite: pressure 2 marks prices up, and from
# pressure 3 Okeke only sells under the counter, at a premium.
const PRESSURE_PRICE_MULTIPLIER: float = 1.2
const UNDER_THE_COUNTER_MULTIPLIER: float = 1.5

func get_vendor_price_multiplier() -> float:
	if pressure_level >= 3:
		return UNDER_THE_COUNTER_MULTIPLIER
	if pressure_level >= 2:
		return PRESSURE_PRICE_MULTIPLIER
	return 1.0

func vendor_price(base_price: int) -> int:
	return roundi(base_price * get_vendor_price_multiplier())

func is_under_the_counter() -> bool:
	return pressure_level >= 3

# " (+20%)" while prices are marked up, "" otherwise.
func vendor_markup_suffix() -> String:
	var multiplier := get_vendor_price_multiplier()
	if multiplier <= 1.0:
		return ""
	return " (+%d%%)" % roundi((multiplier - 1.0) * 100.0)

# --- Persistence ---

func save() -> void:
	_save_to(save_path)

func load_save() -> void:
	_load_from(save_path)

func _save_to(path: String) -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("player", "credits", credits)
	cfg.set_value("player", "debt", debt)
	cfg.set_value("player", "victory", victory)
	cfg.set_value("player", "pressure_level", pressure_level)
	cfg.set_value("player", "run_count", run_count)
	cfg.set_value("player", "runs_since_payment", runs_since_payment)
	cfg.set_value("player", "instalment_paid", instalment_paid)
	cfg.set_value("player", "first_dive_hints_done", first_dive_hints_done)
	cfg.set_value("player", "override_guided_done", override_guided_done)
	cfg.set_value("gear", "rod_damaged", rod_damaged)
	cfg.set_value("gear", "deep_winch_fitted", deep_winch_fitted)
	cfg.set_value("gear", "selected_zone", selected_zone)
	cfg.set_value("gear", "current_rod_path", current_rod.resource_path if current_rod else "")
	cfg.set_value("gear", "loadout", loadout)
	cfg.set_value("gear", "lure_inventory", lure_inventory)
	cfg.set_value("decrypt", "box_queue", decrypt_box_queue)
	cfg.set_value("decrypt", "box_runs", decrypt_box_runs)
	cfg.set_value("decrypt", "last_outcome", decrypt_last_outcome)
	cfg.set_value("decrypt", "last_payout", decrypt_last_payout)
	cfg.set_value("freezer", "base", freezer_base)
	cfg.set_value("freezer", "multiplier", freezer_multiplier)
	cfg.set_value("freezer", "runs", freezer_runs)
	cfg.set_value("narrative", "journal_entries", journal_entries)
	cfg.set_value("narrative", "encountered_entities", encountered_entities)
	cfg.set_value("narrative", "triggered_journal_events", triggered_journal_events)
	cfg.set_value("narrative", "first_listened_entity_id", first_listened_entity_id)
	cfg.set_value("narrative", "run_logs", run_logs)
	cfg.set_value("jobs", "active_job_id", active_job_id)
	cfg.set_value("jobs", "declined_run", job_declined_run)
	cfg.set_value("relay", "played_script_ids", relay_played_script_ids)
	cfg.set_value("relay", "entries", relay_entries)
	cfg.save(path)

func _load_from(path: String) -> void:
	var cfg = ConfigFile.new()
	if cfg.load(path) != OK:
		return
	credits = cfg.get_value("player", "credits", 0)
	debt = cfg.get_value("player", "debt", 80000)
	victory = cfg.get_value("player", "victory", false)
	pressure_level = cfg.get_value("player", "pressure_level", 0)
	run_count = cfg.get_value("player", "run_count", 0)
	runs_since_payment = cfg.get_value("player", "runs_since_payment", 0)
	instalment_paid = cfg.get_value("player", "instalment_paid", 0)
	# Saves from before onboarding existed: anyone who has dived has seen the ropes.
	first_dive_hints_done = cfg.get_value("player", "first_dive_hints_done", run_count > 0)
	override_guided_done = cfg.get_value("player", "override_guided_done", false)
	rod_damaged = cfg.get_value("gear", "rod_damaged", false)
	selected_zone = cfg.get_value("gear", "selected_zone", "district7")
	var rod_path = cfg.get_value("gear", "current_rod_path", "")
	if rod_path != "":
		current_rod = load(rod_path)
	var saved_inventory = cfg.get_value("gear", "lure_inventory", {})
	lure_inventory = {}
	for key in saved_inventory:
		if key != "basic_hook":  # the hook did nothing and is gone
			lure_inventory[key] = saved_inventory[key]
	if cfg.has_section_key("gear", "loadout"):
		loadout.assign(cfg.get_value("gear", "loadout", ["", ""]))
	else:
		# Pre-loadout saves had one equipped lure: it moves into slot one.
		var lure_path: String = cfg.get_value("gear", "current_lure_path", "")
		var lure_id := lure_path.get_file().get_basename()
		loadout.assign([lure_id if lure_id in LURE_ORDER else "", ""])
	decrypt_box_queue = cfg.get_value("decrypt", "box_queue", 0)
	decrypt_box_runs = cfg.get_value("decrypt", "box_runs", 0)
	decrypt_last_outcome = cfg.get_value("decrypt", "last_outcome", "")
	decrypt_last_payout = cfg.get_value("decrypt", "last_payout", 0)
	if cfg.has_section_key("freezer", "base"):
		freezer_base = cfg.get_value("freezer", "base", 0)
	else:
		freezer_base = cfg.get_value("freezer", "value", 0)  # legacy migration
	freezer_multiplier = cfg.get_value("freezer", "multiplier", 1.0)
	freezer_runs = cfg.get_value("freezer", "runs", 0)
	journal_entries = cfg.get_value("narrative", "journal_entries", [] as Array[String])
	encountered_entities = cfg.get_value("narrative", "encountered_entities", {})
	triggered_journal_events = cfg.get_value("narrative", "triggered_journal_events", [] as Array[String])
	first_listened_entity_id = cfg.get_value("narrative", "first_listened_entity_id", "")
	run_logs = cfg.get_value("narrative", "run_logs", [] as Array[Dictionary])
	active_job_id = cfg.get_value("jobs", "active_job_id", "")
	job_declined_run = cfg.get_value("jobs", "declined_run", -1)
	if cfg.has_section("relay"):
		relay_played_script_ids.assign(cfg.get_value("relay", "played_script_ids", []))
		relay_entries.assign(cfg.get_value("relay", "entries", []))
	else:
		# Saves from before the relay: skip what the player has already moved
		# past, so Continue doesn't replay the first call. No transcripts.
		relay_played_script_ids = RelayDirector.script_ids_already_past(run_count)
		relay_entries = []
	_load_or_migrate_deep_winch(cfg, rod_path)
	EventBus.credits_changed.emit(credits)

# Saves from before the winch kept depth as rod depth plus up to three 50ft
# upgrades. Anyone who could reach the deep layer keeps it; upgrades that
# did nothing (past 150ft) are refunded, with a word from Okeke.
func _load_or_migrate_deep_winch(cfg: ConfigFile, rod_path: String) -> void:
	if cfg.has_section_key("gear", "deep_winch_fitted"):
		deep_winch_fitted = cfg.get_value("gear", "deep_winch_fitted", false)
		return
	var upgrade_count: int = cfg.get_value("gear", "depth_upgrade_count",
		int(cfg.get_value("gear", "max_depth_bonus", 0)) / 50)
	var rod_reached_deep := rod_path in LEGACY_DEEP_RODS
	deep_winch_fitted = rod_reached_deep or upgrade_count >= 1
	var refund := 0
	for upgrade_index in upgrade_count:
		var useful := upgrade_index == 0 and not rod_reached_deep
		if not useful:
			refund += LEGACY_DEPTH_UPGRADE_BASE_COST * (1 << upgrade_index)
	if refund <= 0:
		return
	credits += refund
	relay_file_entry(RelayScripts.CONTACT_OKEKE, RELAY_ENTRY_TEXT, "okeke_depth_refund", [
		{"who": RelayScripts.CONTACT_OKEKE, "text": "those extension coils i fitted. turns out the sump stops at a hundred and fifty feet."},
		{"who": RelayScripts.CONTACT_OKEKE, "text": "%scr back in your account. don't tell anyone i do refunds." % LedgerPanel.format_thousands(refund)}])

func new_game() -> void:
	credits = 0
	debt = 80000
	victory = false
	pressure_level = 0
	run_count = 0
	runs_since_payment = 0
	instalment_paid = 0
	first_dive_hints_done = false
	override_guided_done = false
	rod_damaged = false
	deep_winch_fitted = false
	lure_inventory = {}
	loadout = ["", ""] as Array[String]
	decrypt_box_queue = 0
	decrypt_box_runs = 0
	decrypt_last_outcome = ""
	decrypt_last_payout = 0
	freezer_base = 0
	freezer_runs = 0
	freezer_multiplier = 1.0
	selected_zone = "district7"
	encountered_entities = {}
	triggered_journal_events = []
	first_listened_entity_id = ""
	journal_entries = []
	run_logs = []
	active_job_id = ""
	job_declined_run = -1
	relay_played_script_ids = []
	relay_entries = []
	current_rod = load("res://resources/rods/scrap_rod.tres")
	save()
	EventBus.credits_changed.emit(credits)

# --- Marta's jobs ---

func job_offer_open() -> bool:
	return not victory and run_count > 0 and active_job_id == "" and job_declined_run != run_count

func accept_job(job_id: String) -> void:
	active_job_id = job_id
	save()

func decline_job() -> void:
	job_declined_run = run_count
	save()

# Called by DiveRun as the run ends, before on_run_complete. Returns the debt
# actually cleared (0 on failure). Jobs last one dive either way.
func resolve_job(job: JobData, met: bool) -> int:
	active_job_id = ""
	if not met:
		return 0
	var relief: int = min(job.debt_relief, debt)
	debt -= relief
	if debt <= 0:
		debt = 0
		victory = true
	return relief

# --- The relay ---

func relay_has_played(script_id: String) -> bool:
	return script_id in relay_played_script_ids

func relay_mark_played(script_id: String) -> void:
	if not relay_has_played(script_id):
		relay_played_script_ids.append(script_id)

# Files a finished call, text or dive line in the contact's thread, unread.
# Only the newest MAX_RELAY_ENTRIES_PER_CONTACT entries per contact are kept.
func relay_file_entry(contact: String, kind: String, script_id: String, lines: Array, already_read: bool = false) -> void:
	relay_entries.append({
		"contact": contact,
		"run": run_count,
		"kind": kind,
		"script_id": script_id,
		"lines": lines.duplicate(true),
		"read": already_read,
	})
	var contact_entries := relay_entries_for(contact)
	var excess := contact_entries.size() - MAX_RELAY_ENTRIES_PER_CONTACT
	for index in excess:
		relay_entries.erase(contact_entries[index])

func relay_entries_for(contact: String) -> Array[Dictionary]:
	return relay_entries.filter(func(entry: Dictionary) -> bool: return entry.contact == contact)

func relay_unread_count(contact: String) -> int:
	return relay_entries_for(contact).filter(func(entry: Dictionary) -> bool: return not entry.read).size()

func relay_has_unread() -> bool:
	return relay_entries.any(func(entry: Dictionary) -> bool: return not entry.read)

func relay_mark_read(contact: String) -> void:
	for entry in relay_entries_for(contact):
		entry.read = true
