# scenes/dive_run/OverloadFight.gd
# Terminal Overload fight state, extracted from UI for testability.
class_name OverloadFight
extends RefCounted

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

var max_tension: int
var starting_tension: int
var tension: int
var anchor: int
var threat: float
var turn: int = 1
var shock_available: bool
var rng := RandomNumberGenerator.new()

func _init(p_max_tension: int, p_starting_tension: int, p_anchor_strength: int,
		corruption: float, p_shock_available: bool) -> void:
	max_tension = p_max_tension
	starting_tension = p_starting_tension
	tension = p_starting_tension
	anchor = p_anchor_strength
	threat = 1.0 + (corruption / 100.0)
	shock_available = p_shock_available
	rng.randomize()

func backlash_amount() -> int:
	return roundi(5.0 * threat)

func apply_backlash() -> int:
	var amount := backlash_amount()
	tension = clampi(tension + amount, 0, max_tension)
	return amount

func pick_commands() -> Array[Dictionary]:
	var pool: Array[Dictionary] = BASE_COMMANDS.duplicate()
	if shock_available:
		pool.append(OVERLOAD_CORE)
	# Fisher-Yates with the instance rng so tests can seed deterministically
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var picked: Array[Dictionary] = []
	for cmd: Dictionary in pool:
		picked.append(cmd)
		if picked.size() >= 3:
			break
	picked.append(ISOLATE_FEED)
	return picked

func execute(cmd: Dictionary) -> Dictionary:
	var succeeded: bool = float(cmd.success_rate) >= 1.0 or rng.randf() < float(cmd.success_rate)
	if succeeded:
		tension = clampi(tension + int(cmd.t_cost), 0, max_tension)
		anchor = maxi(0, anchor + int(cmd.anchor_hit))
	else:
		tension = clampi(tension + int(cmd.t_cost) + int(cmd.fail_t), 0, max_tension)
	return {"succeeded": succeeded}

func next_turn() -> void:
	turn += 1

func is_snapped() -> bool:
	return tension >= max_tension

func is_captured() -> bool:
	return anchor <= 0
