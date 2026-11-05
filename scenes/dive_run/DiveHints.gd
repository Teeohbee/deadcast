# scenes/dive_run/DiveHints.gd
# First-dive hints written into the session log. Shown until the player has
# finished one run (GameState.first_dive_hints_done). No scene-tree dependencies.
class_name DiveHints

const PREFIX := "  // "
const CAST := "cast"
const CONTACT := "contact"
const CHECKPOINT := "checkpoint"
const MOMENTS: Array[String] = [CAST, CONTACT, CHECKPOINT]

const _LINES := {
	CAST: [
		"first dive. each contact on the line gets a card and a set of options.",
		"the card isn't timed - read it, then choose. then haul it up: hold, and let go on amber.",
	],
	CONTACT: [
		"strain is line tension. options add to it; past your rod's cap the line snaps.",
		"SIG is signal integrity. corrupted catches wear it down; low SIG means stranger draws.",
	],
	CHECKPOINT: [
		"checkpoint. descend for richer contacts at higher risk, or surface to bank the haul.",
		"a snapped line forfeits everything you haven't banked.",
	],
}

static func lines_for(moment: String, hints_done: bool) -> Array[String]:
	var lines: Array[String] = []
	if hints_done:
		return lines
	for line in _LINES.get(moment, []):
		lines.append(PREFIX + line)
	return lines
