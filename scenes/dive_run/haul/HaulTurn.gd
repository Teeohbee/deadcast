# scenes/dive_run/haul/HaulTurn.gd
# How a haul plugs into the dive turn, in every zone. Pick an option on the card,
# haul it up, and the haul result scales what the option pays and costs - skill in
# place of the resist/fail dice. Static and pure, like DiveFormat.
class_name HaulTurn

const PERFECT_BONUS := 1.25
const MESSY_LOSS_PER_HIT := 0.2
const MESSY_FLOOR := 0.4
const TENSION_PER_HIT := 5
const SNAP_TENSION := 25
## Options this strained also haul heavier: the same force that strains the line now
## strains it during the haul.
const HEAVY_STRAIN := 15
const HEAVY_WEIGHT_MULT := 1.5

## An option hauls if it pays and doesn't cut the line. Entities are the exception:
## talking to a ghost is free, only tearing something out of it (an option with
## strain - harvest, extract, pull) is a haul.
static func hauls(catch_data: CatchData, option: CatchOption) -> bool:
	if not catch_data.haul_enabled:
		return false
	if option.credit_value <= 0 or option.cuts_line:
		return false
	return catch_data.catch_type != CatchData.CatchType.ENTITY or option.tension_delta > 0

static func dials(catch_data: CatchData, option: CatchOption) -> Dictionary:
	var weight := catch_data.haul_weight
	if option.tension_delta >= HEAVY_STRAIN:
		weight *= HEAVY_WEIGHT_MULT
	return { "weight": weight, "slip": catch_data.haul_slip, "tempo": catch_data.haul_tempo,
		"erratic": catch_data.haul_erratic }

## { credits, tension } the option costs once hauled. result.outcome: perfect | clean | messy | snap.
static func payout(option: CatchOption, result: Dictionary) -> Dictionary:
	var hits: int = result.get("hits", 0)
	match result.outcome:
		"perfect":
			return { "credits": roundi(option.credit_value * PERFECT_BONUS), "tension": option.tension_delta }
		"messy":
			var keep := maxf(MESSY_FLOOR, 1.0 - MESSY_LOSS_PER_HIT * hits)
			return { "credits": roundi(option.credit_value * keep), "tension": option.tension_delta + TENSION_PER_HIT * hits }
		"snap":
			return { "credits": 0, "tension": option.tension_delta + SNAP_TENSION }
	return { "credits": option.credit_value, "tension": option.tension_delta }

## The first dive of a save teaches the haul.
static func difficulty(run_count: int) -> String:
	return "tutorial" if run_count == 0 else "normal"

static func glyph(catch_type: CatchData.CatchType) -> String:
	match catch_type:
		CatchData.CatchType.BIO: return "(@)"
		CatchData.CatchType.MECH: return "<=>"
		CatchData.CatchType.ENTITY: return "{?}"
	return "[#]"

# --- card words: tells, not sums. Each word means one thing only. ---

## Line strain (dive tension the option costs). Caps: the DEADCAST_OS voice.
static func strain_word(tension_delta: int) -> String:
	if tension_delta <= 0:
		return ""
	if tension_delta <= 5:
		return "LIGHT"
	if tension_delta < HEAVY_STRAIN:
		return "MODERATE"
	return "HEAVY"

## What the option pays, in absolute bands shared by every zone.
static func value_word(credits: int) -> String:
	if credits <= 0:
		return ""
	if credits <= 300:
		return "LOW"
	if credits <= 800:
		return "MID"
	if credits <= 1500:
		return "HIGH"
	return "PRIME"

## How the contact hauls, from its dials.
static func feel(c: CatchData) -> String:
	var words: Array[String] = []
	if c.haul_erratic:
		words.append("erratic")
	elif c.haul_tempo >= 1.15:
		words.append("fast hits")
	elif c.haul_tempo <= 0.75:
		words.append("slow hits")
	else:
		words.append("steady")
	if c.haul_slip >= 1.2:
		words.append("slips fast")
	elif c.haul_slip <= 0.6:
		words.append("slips slowly")
	if c.haul_weight >= 1.4:
		words.append("loads fast")
	elif c.haul_weight <= 0.8:
		words.append("loads light")
	return " · ".join(words)
