# autoload/GameState.gd
extends Node

const SAVE_PATH = "user://save.cfg"
# Where save()/load_save() read and write; the test pre-run hook redirects it.
var save_path: String = SAVE_PATH
const INFINITE_STOCK: int = -1
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
var current_lure: LureData = null
var rod_damaged: bool = false
var max_depth_bonus: int = 0
var depth_upgrade_count: int = 0
const MAX_DEPTH_UPGRADES: int = 3
var selected_zone: String = "district7"

var lure_inventory: Dictionary = {
	"basic_hook": INFINITE_STOCK,
}

# Progression
var run_count: int = 0
var runs_since_payment: int = 0
var pressure_level: int = 0

# Decrypt Box
var decrypt_box_queue: int = 0
var decrypt_box_runs: int = 0
var decrypt_last_outcome: String = ""
var decrypt_last_payout: int = 0
const DECRYPT_THRESHOLD: int = 3
var DECRYPT_OUTCOMES: Array = [
	{"id": "corruption", "label": "[CORRUPTION_DETECTED]", "multiplier": 0.0,  "weight": 0.20},
	{"id": "partial",    "label": "[PARTIAL_DECRYPT]",     "multiplier": 1.5,  "weight": 0.35},
	{"id": "clean",      "label": "[DECRYPT_COMPLETE]",    "multiplier": 4.0,  "weight": 0.35},
	{"id": "anomaly",    "label": "[ANOMALY_DETECTED]",    "multiplier": 6.0,  "weight": 0.10},
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
var marta_last_seen_run: int = -1
var journal_entries: Array[String] = []
var encountered_entities: Dictionary = {}
var triggered_journal_events: Array[String] = []
var first_listened_entity_id: String = ""

const MAX_RUN_LOGS: int = 20
var run_logs: Array[Dictionary] = []

# Onboarding: first-dive hints in the session log until one run is finished.
var first_dive_hints_done: bool = false

func _ready() -> void:
	call_deferred("_load_defaults")

func _load_defaults() -> void:
	current_rod = load("res://resources/rods/scrap_rod.tres")
	current_lure = load("res://resources/lures/basic_hook.tres")
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

	# Debt payment every 5 runs
	if runs_since_payment >= 5:
		runs_since_payment = 0
		var payment = min(10000, debt)
		if spend_credits(payment):
			debt -= payment
			if debt <= 0:
				debt = 0
				victory = true
		else:
			pressure_level = min(5, pressure_level + 1)

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
			journal_entries.append("Run 12.\n\nOkeke left a lure on my line. Basic hook, nothing special. No note.\n\nHe hasn't spoken to me in three runs. Either Marta got to him or he figured something out on his own.\n\nShe's offering to accelerate the debt. Won't say what for.\n\nI haven't said yes.")

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
		journal_entries.append("Run %d.\n\nSomeone came to the Meridian.\n\nDidn't say who sent them. Didn't have to. They looked at the rig, looked at me, and left without saying anything.\n\nMarta's way of reminding me the debt is real. Like I'd forgotten.\n\nI haven't forgotten." % run_count)

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

func equip_lure(lure: LureData) -> void:
	current_lure = lure

func equip_rod(rod: RodData) -> void:
	if max_depth_bonus > 0:
		var upgraded = rod.duplicate()
		upgraded.max_depth = rod.max_depth + max_depth_bonus
		current_rod = upgraded
	else:
		current_rod = rod
	rod_damaged = false

func get_lure_id(lure: LureData) -> String:
	assert(lure.resource_path != "", "LureData must be loaded from a .tres file to derive an ID")
	return lure.resource_path.get_file().get_basename()

func has_lure_stock(lure: LureData) -> bool:
	var qty = lure_inventory.get(get_lure_id(lure), 0)
	return qty == INFINITE_STOCK or qty > 0

func consume_lure_use() -> void:
	if current_lure == null:
		return
	var lure_id = get_lure_id(current_lure)
	if lure_inventory.get(lure_id, 0) == INFINITE_STOCK:
		return
	if lure_inventory.has(lure_id):
		lure_inventory[lure_id] = max(0, lure_inventory[lure_id] - 1)
		EventBus.lure_stock_changed.emit(lure_id, lure_inventory[lure_id])

func _roll_decrypt_outcome(roll: float) -> Dictionary:
	var cumulative: float = 0.0
	for outcome in DECRYPT_OUTCOMES:
		cumulative += outcome.weight
		if roll < cumulative:
			return outcome
	return DECRYPT_OUTCOMES[-1]

func get_vendor_price_multiplier() -> float:
	return 1.2 if pressure_level >= 2 else 1.0

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
	cfg.set_value("player", "first_dive_hints_done", first_dive_hints_done)
	cfg.set_value("gear", "rod_damaged", rod_damaged)
	cfg.set_value("gear", "max_depth_bonus", max_depth_bonus)
	cfg.set_value("gear", "depth_upgrade_count", depth_upgrade_count)
	cfg.set_value("gear", "selected_zone", selected_zone)
	cfg.set_value("gear", "current_rod_path", current_rod.resource_path if current_rod else "")
	cfg.set_value("gear", "current_lure_path", current_lure.resource_path if current_lure else "")
	cfg.set_value("gear", "lure_inventory", lure_inventory)
	cfg.set_value("decrypt", "box_queue", decrypt_box_queue)
	cfg.set_value("decrypt", "box_runs", decrypt_box_runs)
	cfg.set_value("decrypt", "last_outcome", decrypt_last_outcome)
	cfg.set_value("decrypt", "last_payout", decrypt_last_payout)
	cfg.set_value("freezer", "base", freezer_base)
	cfg.set_value("freezer", "multiplier", freezer_multiplier)
	cfg.set_value("freezer", "runs", freezer_runs)
	cfg.set_value("narrative", "marta_last_seen_run", marta_last_seen_run)
	cfg.set_value("narrative", "journal_entries", journal_entries)
	cfg.set_value("narrative", "encountered_entities", encountered_entities)
	cfg.set_value("narrative", "triggered_journal_events", triggered_journal_events)
	cfg.set_value("narrative", "first_listened_entity_id", first_listened_entity_id)
	cfg.set_value("narrative", "run_logs", run_logs)
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
	# Saves from before onboarding existed: anyone who has dived has seen the ropes.
	first_dive_hints_done = cfg.get_value("player", "first_dive_hints_done", run_count > 0)
	rod_damaged = cfg.get_value("gear", "rod_damaged", false)
	max_depth_bonus = cfg.get_value("gear", "max_depth_bonus", 0)
	if cfg.has_section_key("gear", "depth_upgrade_count"):
		depth_upgrade_count = cfg.get_value("gear", "depth_upgrade_count", 0)
	else:
		depth_upgrade_count = max_depth_bonus / 50
	selected_zone = cfg.get_value("gear", "selected_zone", "district7")
	var rod_path = cfg.get_value("gear", "current_rod_path", "")
	if rod_path != "":
		var base_rod = load(rod_path)
		if max_depth_bonus > 0:
			var upgraded = base_rod.duplicate()
			upgraded.max_depth = base_rod.max_depth + max_depth_bonus
			current_rod = upgraded
		else:
			current_rod = base_rod
	var lure_path = cfg.get_value("gear", "current_lure_path", "")
	if lure_path != "":
		current_lure = load(lure_path)
	var saved_inventory = cfg.get_value("gear", "lure_inventory", {})
	# Merge rather than replace: preserves defaults for lures added after an old save was written.
	for key in saved_inventory:
		lure_inventory[key] = saved_inventory[key]
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
	marta_last_seen_run = cfg.get_value("narrative", "marta_last_seen_run", -1)
	journal_entries = cfg.get_value("narrative", "journal_entries", [] as Array[String])
	encountered_entities = cfg.get_value("narrative", "encountered_entities", {})
	triggered_journal_events = cfg.get_value("narrative", "triggered_journal_events", [] as Array[String])
	first_listened_entity_id = cfg.get_value("narrative", "first_listened_entity_id", "")
	run_logs = cfg.get_value("narrative", "run_logs", [] as Array[Dictionary])
	EventBus.credits_changed.emit(credits)

func new_game() -> void:
	credits = 0
	debt = 80000
	victory = false
	pressure_level = 0
	run_count = 0
	runs_since_payment = 0
	first_dive_hints_done = false
	rod_damaged = false
	max_depth_bonus = 0
	depth_upgrade_count = 0
	lure_inventory = { "basic_hook": INFINITE_STOCK }
	decrypt_box_queue = 0
	decrypt_box_runs = 0
	decrypt_last_outcome = ""
	decrypt_last_payout = 0
	freezer_base = 0
	freezer_runs = 0
	freezer_multiplier = 1.0
	selected_zone = "district7"
	marta_last_seen_run = -1
	encountered_entities = {}
	triggered_journal_events = []
	first_listened_entity_id = ""
	journal_entries = []
	run_logs = []
	current_rod = load("res://resources/rods/scrap_rod.tres")
	current_lure = load("res://resources/lures/basic_hook.tres")
	save()
	EventBus.credits_changed.emit(credits)

func has_new_marta_beat() -> bool:
	return _beat_index(run_count) > _beat_index(marta_last_seen_run)

static func _beat_index(run: int) -> int:
	if run >= 12: return 7
	if run >= 10: return 6
	if run >= 8:  return 5
	if run >= 6:  return 4
	if run >= 5:  return 3
	if run >= 3:  return 2
	if run >= 1:  return 1
	return 0
