# scenes/dive_run/override/OverrideTurn.gd
# How a hostile's CatchData becomes an override fight. Static and pure, like HaulTurn.
class_name OverrideTurn

const GARBLE_SIG := 70.0   # SIG from which one lock arrow flickers to noise
const SIG_HIT_STEP := 20.0 # +1T on every landed attack per this much SIG

## The OverrideSim config for a hostile on the line.
static func config(catch_data: CatchData, tension: float, max_tension: float, corruption: float,
		rig: Dictionary, guided: bool) -> Dictionary:
	var attacks: Array[Dictionary] = []
	for entry in catch_data.override_attacks:
		var parts := entry.split("|")
		attacks.append({ "name": parts[0], "code": parts[1] })
	return {
		"attacks": attacks,
		"anchor": catch_data.anchor_strength,
		"hit_damage": catch_data.override_hit + int(corruption / SIG_HIT_STEP),
		"twist": catch_data.override_twist,
		"grow": true,
		"guided": guided,
		"garble": corruption >= GARBLE_SIG,
		"tension": tension,
		"max_tension": max_tension,
		"rig": rig,
	}

## The encounter frame's class line.
static func class_line(c: CatchData) -> String:
	return "class: %s  security: [HOSTILE]" % DiveFormat.type_tag(c.catch_type)
