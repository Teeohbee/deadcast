# scenes/dive_run/haul/HaulSim.gd
# Winch haul rules: pure state, no nodes, so GUT can drive it headless.
# A line-for-line port of the HTML prototype's haul-sim.js (planning folder), which
# stays the tuning source. tests/test_haul_sim.gd checks the two against golden runs,
# so change the JS first, regenerate the fixture, then mirror it here.
#
# One button: hold to haul the payload up, let go on the amber warning. Load builds
# while hauling and drains when you let go. A hit that lands while you haul jumps the
# load (capped at 99, so a hit alone never snaps). Hauling on in the red zone for
# longer than `grace` snaps the line.
class_name HaulSim
extends RefCounted

const READY := "ready"
const LIVE := "live"
const DONE := "done"
const CLEAN := "clean"
const MESSY := "messy"
const SNAP := "snap"

const START_DEPTH := 240.0 # ft
const HAUL_SPEED := 50.0   # ft/s while hauling
const RISE_RATE := 16.0    # load %/s while hauling, x weight
const DRAIN_RATE := 30.0   # load %/s when released
const SLIP_SPEED := 14.0   # ft/s sinking when released, x slip
const HIT_SIZE := 45.0     # load % added by a hit taken while hauling
const TELL := 0.7          # s of amber warning before a hit
const INTERVAL := 1.8      # s between hits, / tempo
const RED_ZONE := 85.0     # load % where hauling strains the line
const MAX_DEPTH := START_DEPTH * 1.2

# grace: seconds you can keep hauling in the red before the line snaps
const DIFFICULTY := {
	"tutorial": { "tell": 1.4, "hit_size": 0.7, "rise": 0.7, "grace": 1.2, "hints": true },
	"normal":   { "tell": 1.0, "hit_size": 1.0, "rise": 1.0, "grace": 0.9, "hints": false },
	"hard":     { "tell": 0.7, "hit_size": 1.15, "rise": 1.0, "grace": 0.6, "hints": false },
}

# Par: a little slack on prompt play's average landing time, so reacting to amber is enough for PERFECT.
const PAR_SLACK := 1.0

## Park-Miller LCG, the same one the prototype uses, so seeded runs match it exactly.
class Lcg extends RefCounted:
	var state: int
	func _init(p_seed: int) -> void:
		state = p_seed
	func next() -> float:
		state = (state * 16807) % 2147483647
		return float(state) / 2147483647.0

var rng: Lcg # null = engine randf()
var dials: Dictionary # weight, slip, tempo: float multipliers; erratic: bool
var difficulty: String
var tell: float
var hit_size: float
var rise: float
var grace: float
var strain := 0.0
var phase := READY
var t := 0.0
var depth := START_DEPTH
var line_load := 0.0 # %
var peak := 0.0
var next_hit := 0.0
var told := false
var hits := 0
var absorbed := 0
var outcome := ""

func _init(p_dials: Dictionary, p_difficulty: String, p_rng: Lcg = null) -> void:
	var d: Dictionary = DIFFICULTY[p_difficulty]
	rng = p_rng
	dials = p_dials.duplicate()
	difficulty = p_difficulty
	tell = TELL * d.tell
	hit_size = HIT_SIZE * d.hit_size
	rise = RISE_RATE * d.rise
	grace = d.grace

func hints() -> bool:
	return DIFFICULTY[difficulty].hints

func _gap(first: bool) -> float:
	var g: float = INTERVAL / dials.tempo
	if dials.erratic:
		g *= 0.45 + (rng.next() if rng else randf()) * 1.1
	if first:
		g = maxf(g, 1.0)
	return maxf(g, tell + 0.9) # always leave a hauling window between warnings

## Advances the sim by dt with the haul button state. Returns the events that happened:
## start, tell, hit, absorbed, red, snap, land.
func step(dt: float, haul: bool) -> Array[String]:
	var ev: Array[String] = []
	if phase == READY:
		if not haul:
			return ev
		phase = LIVE
		next_hit = _gap(true)
		ev.append("start")
	if phase != LIVE:
		return ev
	t += dt
	if haul:
		line_load += rise * dials.weight * dt
		depth -= HAUL_SPEED * dt
	else:
		line_load -= DRAIN_RATE * dt
		depth += SLIP_SPEED * dials.slip * dt
	if not told and t >= next_hit - tell:
		told = true
		ev.append("tell")
	if t >= next_hit:
		if haul:
			line_load = minf(99.0, line_load + hit_size)
			hits += 1
			ev.append("hit")
		else:
			absorbed += 1
			ev.append("absorbed")
		next_hit = t + _gap(false)
		told = false
	line_load = maxf(0.0, minf(100.0, line_load))
	# in the red: keep hauling and the line strains; let go and it recovers
	if line_load >= RED_ZONE and haul:
		if strain == 0.0:
			ev.append("red")
		strain += dt
	else:
		strain = maxf(0.0, strain - dt * 2.0)
	depth = minf(MAX_DEPTH, depth)
	peak = maxf(peak, minf(100.0, line_load))
	if strain >= grace:
		phase = DONE
		outcome = SNAP
		ev.append("snap")
		return ev
	if depth <= 0.0:
		depth = 0.0
		phase = DONE
		outcome = CLEAN if hits == 0 else MESSY
		ev.append("land")
	return ev

func telling() -> bool:
	return phase == LIVE and told and t < next_hit

## 0 at the start of a warning, 1 as the hit lands; -1 when no warning is showing.
func tell_progress() -> float:
	if not telling():
		return -1.0
	return clampf(1.0 - (next_hit - t) / tell, 0.0, 1.0)

## 0 at the start depth, 1 landed; slightly negative while it slips below the start.
func progress() -> float:
	return clampf(1.0 - depth / START_DEPTH, -0.2, 1.0)

## Expert play: haul until the last moment before each hit, back off only near the top of the load bar.
static func expert(s: HaulSim, m: Dictionary) -> bool:
	if s.telling() and s.next_hit - s.t < 0.12:
		return false
	if s.line_load > 84.0:
		m.cool = true
	if m.get("cool", false) and s.line_load < 70.0:
		m.cool = false
	return not m.get("cool", false)

## Prompt play: lets go 0.3s after the amber warning appears (what the game teaches), breathes at 84% load.
static func prompt(s: HaulSim, m: Dictionary) -> bool:
	if s.telling() and s.tell - (s.next_hit - s.t) >= 0.3:
		return false
	if s.line_load > 84.0:
		m.cool = true
	if m.get("cool", false) and s.line_load < 59.0:
		m.cool = false
	return not m.get("cool", false)

## Par time in seconds, rounded up to the half second. 0 when prompt play never lands.
static func par(p_dials: Dictionary, p_difficulty: String) -> float:
	var total := 0.0
	var n := 0
	var lcg := Lcg.new(7)
	for i in 40:
		var s := HaulSim.new(p_dials, p_difficulty, lcg)
		var m := {}
		var steps := 0
		while s.phase != DONE and steps < 3600:
			s.step(1.0 / 60.0, prompt(s, m))
			steps += 1
		if s.outcome != "" and s.outcome != SNAP:
			total += s.t
			n += 1
	if n == 0:
		return 0.0
	return ceilf((total / n) * PAR_SLACK * 2.0) / 2.0
