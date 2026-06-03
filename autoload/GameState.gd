# autoload/GameState.gd
extends Node

const SAVE_PATH = "user://save.cfg"
const INFINITE_STOCK: int = -1

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
var selected_zone: String = "district7"

var lure_inventory: Dictionary = {
	"basic_hook": INFINITE_STOCK,
}

# Progression
var run_count: int = 0
var runs_since_payment: int = 0
var pressure_level: int = 0
var debt_collector_triggered: bool = false

# Decrypt Box
var decrypt_box_queue: int = 0
var decrypt_box_runs: int = 0
const DECRYPT_THRESHOLD: int = 3
const DECRYPT_MULTIPLIER: int = 4

# Freezer
var freezer_value: int = 0
var freezer_runs: int = 0
const FREEZER_SPOIL_RUNS: int = 3

# Narrative
var marta_last_seen_run: int = -1
var journal_entries: Array[String] = []

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

	# Add bio catches to freezer
	if bio_credits > 0:
		freezer_value += bio_credits

	# Decrypt box: count down and release when ready
	if decrypt_box_queue > 0:
		decrypt_box_runs += 1
		if decrypt_box_runs >= DECRYPT_THRESHOLD:
			add_credits(decrypt_box_queue * DECRYPT_MULTIPLIER)
			decrypt_box_queue = 0
			decrypt_box_runs = 0

	# Freezer spoil check
	if freezer_value > 0 and not snapped:
		freezer_runs += 1
		if freezer_runs == FREEZER_SPOIL_RUNS:
			freezer_value = freezer_value / 2
			freezer_runs = FREEZER_SPOIL_RUNS  # cap so it keeps showing as spoiled

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

	_maybe_append_journal_entry()
	save()

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

func get_vendor_price_multiplier() -> float:
	return 1.2 if pressure_level >= 2 else 1.0

# --- Persistence ---

func save() -> void:
	_save_to(SAVE_PATH)

func load_save() -> void:
	_load_from(SAVE_PATH)

func _save_to(path: String) -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("player", "credits", credits)
	cfg.set_value("player", "debt", debt)
	cfg.set_value("player", "victory", victory)
	cfg.set_value("player", "pressure_level", pressure_level)
	cfg.set_value("player", "run_count", run_count)
	cfg.set_value("player", "runs_since_payment", runs_since_payment)
	cfg.set_value("player", "debt_collector_triggered", debt_collector_triggered)
	cfg.set_value("gear", "rod_damaged", rod_damaged)
	cfg.set_value("gear", "max_depth_bonus", max_depth_bonus)
	cfg.set_value("gear", "current_rod_path", current_rod.resource_path if current_rod else "")
	cfg.set_value("gear", "current_lure_path", current_lure.resource_path if current_lure else "")
	cfg.set_value("gear", "lure_inventory", lure_inventory)
	cfg.set_value("decrypt", "box_queue", decrypt_box_queue)
	cfg.set_value("decrypt", "box_runs", decrypt_box_runs)
	cfg.set_value("freezer", "value", freezer_value)
	cfg.set_value("freezer", "runs", freezer_runs)
	cfg.set_value("narrative", "marta_last_seen_run", marta_last_seen_run)
	cfg.set_value("narrative", "journal_entries", journal_entries)
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
	debt_collector_triggered = cfg.get_value("player", "debt_collector_triggered", false)
	rod_damaged = cfg.get_value("gear", "rod_damaged", false)
	max_depth_bonus = cfg.get_value("gear", "max_depth_bonus", 0)
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
	freezer_value = cfg.get_value("freezer", "value", 0)
	freezer_runs = cfg.get_value("freezer", "runs", 0)
	marta_last_seen_run = cfg.get_value("narrative", "marta_last_seen_run", -1)
	journal_entries = cfg.get_value("narrative", "journal_entries", [])
	EventBus.credits_changed.emit(credits)

func new_game() -> void:
	credits = 0
	debt = 80000
	victory = false
	pressure_level = 0
	run_count = 0
	runs_since_payment = 0
	debt_collector_triggered = false
	rod_damaged = false
	max_depth_bonus = 0
	lure_inventory = { "basic_hook": INFINITE_STOCK }
	decrypt_box_queue = 0
	decrypt_box_runs = 0
	freezer_value = 0
	freezer_runs = 0
	marta_last_seen_run = -1
	journal_entries = []
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
