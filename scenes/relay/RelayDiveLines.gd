# scenes/relay/RelayDiveLines.gd
# What Marta says on the line during a dive (relay copy doc section 4). The
# first dive has its own set and every line plays. Later dives draw from pools,
# now and then, never repeating within a dive and never more than
# MAX_LINES_PER_LATER_DIVE. Pure: the caller passes the dice.
class_name RelayDiveLines

const MOMENT_CAST := "cast"
const MOMENT_CONTACT := "contact"
const MOMENT_HAUL := "haul"
const MOMENT_CHECKPOINT := "checkpoint"
const MOMENT_SURFACED := "surfaced"
const MOMENT_SNAPPED := "snapped"

const LATER_DIVE_CHANCE := 0.3
const MAX_LINES_PER_LATER_DIVE := 4
const HEAVY_LINE_RATIO := 0.6
const BIG_HAUL_CREDITS := 1500

const DIVE_ONE := {
	"cast": "that's the old tram depot under you. good pickings, no owners.",
	"contact_echo": "echo. a recording that loops. worthless unless someone wants it.",
	"contact_ghost": "ghost. it thinks it's still somebody. be polite, then take what's useful.",
	"contact_other": "first one's always ugly. take it anyway.",
	"haul_clean": "there. that's a living.",
	"haul_messy": "you got it. most of it. the rest is fish food.",
	"checkpoint": "down is more money. up is still being alive. your call.",
	"surfaced": "good. now you know what it feels like.",
	"snapped": "line's gone. so's everything on it. that's the lesson. it's cheaper today than it will be.",
}

const POOLS := {
	"cast": ["quiet night on the relay. i don't like quiet nights."],
	"cast_district7": ["district 7 again. the dead don't move house."],
	"cast_exchange": ["exchange floor. watch for other lines. not everyone down there works for me."],
	"cast_axiom": ["axiom water. keep your head down. they can hear you think."],
	"contact": [
		"that one's been down there longer than you've been alive.",
		"someone paid good money to bury that.",
		"if it talks, don't answer.",
	],
	"haul_messy": [
		"sloppy. it costs you, not me. well. it costs me thirty percent.",
		"you're pulling like you're angry at it.",
	],
	"haul_clean": ["clean. don't let it go to your head."],
	"checkpoint_heavy": ["you're carrying a lot. heavy lines snap."],
	"snapped": [
		"i'll put it down as a learning experience. axiom won't.",
		"gone. go again.",
	],
	"surfaced_big": ["now that's a dive. i'll pretend i'm not impressed."],
}

# The line for this moment, or "" for silence.
# context keys: zone_id (cast); catch_type, catch_name, first_contact (contact);
# outcome (haul: perfect/clean/messy); tension_ratio (checkpoint); credits (surfaced).
static func pick(moment: String, context: Dictionary, first_dive: bool, already_said: Array,
		random: RandomNumberGenerator) -> String:
	if first_dive:
		var dive_one_line: String = DIVE_ONE.get(_dive_one_key(moment, context), "")
		return "" if dive_one_line in already_said else dive_one_line
	if already_said.size() >= MAX_LINES_PER_LATER_DIVE:
		return ""
	var pool := _later_pool(moment, context).filter(func(line: String) -> bool: return line not in already_said)
	if pool.is_empty() or random.randf() >= LATER_DIVE_CHANCE:
		return ""
	return pool[random.randi_range(0, pool.size() - 1)]

static func _dive_one_key(moment: String, context: Dictionary) -> String:
	match moment:
		MOMENT_CONTACT:
			if not context.get("first_contact", false):
				return ""
			if context.get("catch_type", -1) == CatchData.CatchType.ENTITY:
				return "contact_echo" if "echo" in str(context.get("catch_name", "")).to_lower() else "contact_ghost"
			return "contact_other"
		MOMENT_HAUL:
			return "haul_messy" if context.get("outcome", "") == "messy" else "haul_clean"
	return moment

static func _later_pool(moment: String, context: Dictionary) -> Array:
	match moment:
		MOMENT_CAST:
			return POOLS.cast + POOLS.get("cast_" + str(context.get("zone_id", "")), [])
		MOMENT_CONTACT:
			return POOLS.contact
		MOMENT_HAUL:
			match context.get("outcome", ""):
				"messy": return POOLS.haul_messy
				"clean", "perfect": return POOLS.haul_clean
			return []
		MOMENT_CHECKPOINT:
			return POOLS.checkpoint_heavy if context.get("tension_ratio", 0.0) >= HEAVY_LINE_RATIO else []
		MOMENT_SURFACED:
			return POOLS.surfaced_big if context.get("credits", 0) >= BIG_HAUL_CREDITS else []
		MOMENT_SNAPPED:
			return POOLS.snapped
	return []
