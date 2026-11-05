# scenes/dive_run/override/OverrideSim.gd
# Override combo rules for hostile contacts: pure state, no nodes, so GUT can drive it.
# Tuned in the planning look book (2026-11-05-override-combo-v2.html).
#
# Real-time rounds. Each round the hostile winds up (GAP), then CHARGES an attack behind
# a lock - a d-pad code - with a timer. The player has one input buffer, matched against
# the lock and every rig code at once (no code is a prefix of another). Enter the lock
# in time and the attack is nulled; otherwise the hit lands on the line. While it
# charges the hostile is exposed, so BREAK hits twice as hard - the question every
# charge asks is how many BREAKs fit before the lock has to go in.
class_name OverrideSim
extends RefCounted

const GAP := "gap"
const CHARGE := "charge"
const DONE := "done"

const WON := "won"
const SNAP := "snap"
const FLED := "fled"
const SLIPPED := "slipped"

const DIRS := "udlr"

# The rig's codes: fixed, so they become muscle memory. None is a prefix of another.
const RIG := {
	"break": "dru",
	"isolate": "dddd",
	"shock": "udud",
	"splice": "llr",
	"decoy": "rrl",
}
const RIG_ORDER: Array[String] = ["break", "splice", "shock", "decoy", "isolate"]

const FIRST_GAP := 1.2      # s before the first charge
const GAP_AFTER := 1.0      # s between a charge ending and the next wind-up
const CHARGE_BASE := 1.6    # s of charge, plus...
const CHARGE_PER_INPUT := 0.65 # s per input in the lock
const REQUOTE_AT := 0.5     # fraction of the charge left when a volatile lock re-quotes
const MAX_GROWTH := 2       # extra inputs a lock gains over the fight
const WRONG_STRAIN := 2     # T for a wrong press
const BREAK_STRAIN := 2     # T per BREAK
const BREAK_DAMAGE := 1     # anchor, doubled while exposed
const SHOCK_DAMAGE := 2     # anchor, doubled while exposed
const SPLICE_VENT := 20     # T

# Twists. "ghost": locks alternate reversed (enter right to left) and hidden (arrows
# show as you reach them). "requote": half-way through, the unentered arrows change.
const TWIST_NONE := ""
const TWIST_GHOST := "ghost"
const TWIST_REQUOTE := "requote"

const MODE_PLAIN := "plain"
const MODE_REVERSED := "reversed"
const MODE_HIDDEN := "hidden"
const MODE_REQUOTE := "requote"

var attacks: Array[Dictionary] = [] # [{ name, code }], cycled
var anchor_max: int
var anchor: int
var hit_damage: int
var twist: String
var grow: bool
var guided: bool
var garble: bool
var tension: float
var max_tension: float
## Rig command id -> uses left (-1 = unlimited).
var uses: Dictionary = {}
var rng: HaulSim.Lcg # null = engine randf()

var phase := GAP
var t := 0.0   # seconds into the current phase
var dur := FIRST_GAP
var round_number := 0
var buffer := ""
## The charging lock: { name, code (as shown), expected (as entered), mode, requoted,
## requote_from, garble_index }. Empty between charges.
var lock: Dictionary = {}
var outcome := ""
var nulled := 0
var hits_taken := 0
var wrong := 0

## config: attacks, anchor, hit_damage, twist, grow, guided, garble, tension, max_tension,
## rig (Dictionary id -> uses; break and isolate are always added, unlimited).
func _init(config: Dictionary, p_rng: HaulSim.Lcg = null) -> void:
	rng = p_rng
	for a in config.attacks:
		attacks.append({ "name": str(a.name), "code": str(a.code) })
	anchor_max = int(config.anchor)
	anchor = anchor_max
	hit_damage = int(config.hit_damage)
	twist = str(config.get("twist", TWIST_NONE))
	grow = bool(config.get("grow", true))
	guided = bool(config.get("guided", false))
	garble = bool(config.get("garble", false))
	tension = float(config.tension)
	max_tension = float(config.max_tension)
	uses = { "break": -1, "isolate": -1 }
	var rig: Dictionary = config.get("rig", {})
	for id in rig:
		uses[id] = int(rig[id])

static func clashes(a: String, b: String) -> bool:
	return a.begins_with(b) or b.begins_with(a)

## A lock may not collide with any rig code, in the order it is entered.
static func valid_lock(code: String) -> bool:
	if code.length() < 2:
		return false
	for id in RIG:
		if clashes(code, RIG[id]):
			return false
	return true

static func reversed(code: String) -> String:
	var out := ""
	for i in range(code.length() - 1, -1, -1):
		out += code[i]
	return out

func exposed() -> bool:
	return phase == CHARGE

## Whether a rig command can be entered now (guided staging, uses left).
func available(id: String) -> bool:
	if not uses.has(id) or uses[id] == 0:
		return false
	if guided and round_number < 2:
		return false
	if guided and round_number < 3 and id != "break":
		return false
	return true

## Codes the buffer could still become: [{ id, code }], the lock first.
func candidates() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	if phase == CHARGE and not lock.is_empty():
		all.append({ "id": "lock", "code": str(lock.expected) })
	for id in RIG_ORDER:
		if available(id):
			all.append({ "id": id, "code": RIG[id] })
	var out: Array[Dictionary] = []
	for c in all:
		if str(c.code).begins_with(buffer):
			out.append(c)
	return out

## How much of the lock is entered (in entry order).
func lock_progress() -> int:
	if lock.is_empty() or not str(lock.expected).begins_with(buffer):
		return 0
	return buffer.length()

func _rand() -> float:
	return rng.next() if rng != null else randf()

func _rand_dir() -> String:
	return DIRS[mini(3, int(_rand() * 4.0))]

# --- time ---

## Advance the clock. Events: charge, requote, hit, snap.
func step(dt: float) -> Array[String]:
	var events: Array[String] = []
	if phase == DONE:
		return events
	t += dt
	if phase == GAP and t >= dur:
		_start_charge()
		events.append("charge")
	elif phase == CHARGE:
		var left := 1.0 - t / dur
		if lock.mode == MODE_REQUOTE and not lock.requoted and left <= REQUOTE_AT:
			_requote()
			events.append("requote")
		if t >= dur:
			lock = {}
			buffer = ""
			hits_taken += 1
			tension = minf(max_tension, tension + hit_damage)
			events.append("hit")
			if tension >= max_tension:
				_end(SNAP)
				events.append("snap")
			else:
				_gap(GAP_AFTER)
	return events

func _gap(seconds: float) -> void:
	phase = GAP
	t = 0.0
	dur = seconds

func _start_charge() -> void:
	round_number += 1
	var attack: Dictionary = attacks[(round_number - 1) % attacks.size()]
	var code: String = attack.code
	if grow:
		for i in mini(MAX_GROWTH, (round_number - 1) / 2):
			code = _extend(code)
	var mode := MODE_PLAIN
	match twist:
		TWIST_GHOST:
			mode = MODE_REVERSED if round_number % 2 == 1 else MODE_HIDDEN
		TWIST_REQUOTE:
			mode = MODE_REQUOTE
	var expected := reversed(code) if mode == MODE_REVERSED else code
	lock = {
		"name": attack.name,
		"code": code,
		"expected": expected,
		"mode": mode,
		"requoted": false,
		"requote_from": 0,
		"garble_index": int(_rand() * code.length()) if garble else -1,
	}
	phase = CHARGE
	t = 0.0
	dur = CHARGE_BASE + CHARGE_PER_INPUT * code.length()
	buffer = ""

# One more input, keeping the lock valid whichever way round it is entered.
func _extend(code: String) -> String:
	for attempt in 32:
		var longer := code + _rand_dir()
		if valid_lock(longer) and valid_lock(reversed(longer)):
			return longer
	return code

# Every arrow not yet entered changes; what's entered stays.
func _requote() -> void:
	var keep := lock_progress()
	var old: String = lock.expected
	for attempt in 32:
		var fresh := old.substr(0, keep)
		for i in range(keep, old.length()):
			fresh += _rand_dir()
		if fresh != old and valid_lock(fresh):
			lock.expected = fresh
			lock.code = fresh
			break
	lock.requoted = true
	lock.requote_from = keep

# --- input ---

## One d-pad press ("u", "d", "l", "r"). Events: input, wrong, lock, break, shock,
## splice, decoy, isolate, won, snap.
func press(dir: String) -> Array[String]:
	var events: Array[String] = []
	if phase == DONE:
		return events
	buffer += dir
	var cands := candidates()
	if cands.is_empty():
		buffer = ""
		wrong += 1
		tension = minf(max_tension, tension + WRONG_STRAIN)
		events.append("wrong")
		if tension >= max_tension:
			_end(SNAP)
			events.append("snap")
		return events
	events.append("input")
	for c in cands:
		if c.code == buffer:
			buffer = ""
			events.append_array(_fire(str(c.id)))
			break
	return events

func _fire(id: String) -> Array[String]:
	var events: Array[String] = [id]
	var doubled := exposed()
	match id:
		"lock":
			nulled += 1
			lock = {}
			_gap(GAP_AFTER)
			return events
		"break":
			tension = minf(max_tension, tension + BREAK_STRAIN)
			anchor = maxi(0, anchor - BREAK_DAMAGE * (2 if doubled else 1))
		"shock":
			anchor = maxi(0, anchor - SHOCK_DAMAGE * (2 if doubled else 1))
		"splice":
			tension = maxf(0.0, tension - SPLICE_VENT)
		"decoy":
			_end(SLIPPED)
		"isolate":
			_end(FLED)
	if uses.get(id, -1) > 0:
		uses[id] -= 1
	if phase == DONE:
		return events
	if anchor <= 0:
		_end(WON)
		events.append("won")
	elif tension >= max_tension:
		_end(SNAP)
		events.append("snap")
	return events

func _end(how: String) -> void:
	phase = DONE
	outcome = how
	lock = {}
	buffer = ""
