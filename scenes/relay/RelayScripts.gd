# scenes/relay/RelayScripts.gd
# Everything said over the relay: calls, text exchanges and notices, as data
# for RelayRunner (step format documented there). Copy source:
# planning/deadcast/2026-11-05-relay-copy.md.
#
# Each script has:
#   id        unique, stored in the save once played
#   contact   who it's from (CONTACTS)
#   channel   CHANNEL_CALL rings and takes the screen; CHANNEL_TEXT lands in the RELAY thread
#   trigger   when RelayDirector offers it (TRIGGER_* moments, see RelayDirector)
#   forced    optional; a forced call can't be let ring or backed out of, and
#             replays on Continue until it has been heard to the end
#   steps     the lines
class_name RelayScripts

const CONTACT_MARTA := "marta"
const CONTACT_OKEKE := "okeke"
const CONTACT_AXIOM_CREDIT := "axiom_credit"
const CONTACTS: Array[String] = [CONTACT_MARTA, CONTACT_OKEKE, CONTACT_AXIOM_CREDIT]

# How each contact appears on the relay: caller ID, route, and speaker colour
# (a DeckStyle colour name, so this file stays free of UI code).
const CONTACT_DISPLAY := {
	CONTACT_MARTA: {"caller_id": "M. VOSS", "speaker": "marta", "route": "relay 7 → meridian", "color": "SKY"},
	CONTACT_OKEKE: {"caller_id": "OKEKE", "speaker": "okeke", "route": "barge · east moorings", "color": "AMBER"},
	CONTACT_AXIOM_CREDIT: {"caller_id": "AXIOM CREDIT", "speaker": "axiom", "route": "axiom finance · automated", "color": "RED"},
}

const CHANNEL_CALL := "call"
const CHANNEL_TEXT := "text"
const CHANNELS: Array[String] = [CHANNEL_CALL, CHANNEL_TEXT]

const TRIGGER_NEW_GAME := "new_game"
const TRIGGER_HUB_ARRIVAL := "hub_arrival"
const TRIGGER_TAB_OPENED := "tab_opened"
const TRIGGERS: Array[String] = [TRIGGER_NEW_GAME, TRIGGER_HUB_ARRIVAL, TRIGGER_TAB_OPENED]

# Game effects a "do" step may ask for. Applied by whoever runs the script.
const ACTION_ACCEPT_JOB := "accept_job"
const ACTION_DECLINE_JOB := "decline_job"
const ACTIONS: Array[String] = [ACTION_ACCEPT_JOB, ACTION_DECLINE_JOB]

# Flags a step may test with "only_if".
const FLAG_LAST_DIVE_SNAPPED := "last_dive_snapped"
const FLAGS: Array[String] = [FLAG_LAST_DIVE_SNAPPED]

const MARTA_FIRST_CALL := {
	"id": "marta_first_call",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_CALL,
	"trigger": {"moment": TRIGGER_NEW_GAME},
	"forced": true,
	"steps": [
		{"say": "you're on the meridian's terminal. good. the keys worked."},
		{"say": "i'm marta. i find work for people with boats they can't afford."},
		{"say": "that's you, by the way."},
		{"replies": [
			{"text": "i own this boat.", "then": [
				{"say": "axiom credit owns this boat. you own the debt."},
				{"say": "eighty thousand. their notices will find you. they always do."},
			]},
			{"text": "what work?", "then": [
				{"say": "people lost things in the sump. some of them will pay to get them back."},
				{"say": "i find the people. you find the things."},
			]},
		], "silent": [
			{"say": "quiet type. fine. quiet's cheaper."},
		]},
		{"say": "the sump was a city. forty years under. everything that was in it is still down there."},
		{"say": "ledgers. backups. people who uploaded themselves when the water came."},
		{"say": "fishers have words for what you'll pull up."},
		{"say": "a ghost still acts like a person. an echo is a recording that loops. a fragment is a piece of something bigger."},
		{"say": "don't get sentimental about any of them."},
		{"say": "first dive's on me. no client. learn the winch, bring something up."},
		{"say": "haul when the line's quiet. let go when it warns you. snap it and you lose the lot."},
		{"replies": [
			{"text": "what's your cut?", "then": [
				{"say": "thirty percent."},
				{"say": "it was twenty for the last one. he asked a lot of questions."},
			]},
			{"text": "and if i don't?", "then": [
				{"say": "then axiom takes the boat and you go back to whatever you were doing before."},
				{"say": "i didn't ask what that was. i'm being polite."},
			]},
		], "silent": [
			{"say": "no questions. we'll get on."},
		]},
		{"say": "go fishing. i'll call when you're up."},
	],
}

const AXIOM_MORTGAGE_NOTICE := {
	"id": "axiom_mortgage_notice",
	"contact": CONTACT_AXIOM_CREDIT,
	"channel": CHANNEL_TEXT,
	"trigger": {"moment": TRIGGER_NEW_GAME},
	"steps": [
		{"say": "AXIOM CREDIT · ACCOUNT NOTICE"},
		{"say": "vessel MERIDIAN (class IV) has been assigned to your operator profile, together with its outstanding mortgage."},
		{"say": "balance: 80,000cr. instalments: 10,000cr every 5 dives, collected automatically from your wallet."},
		{"say": "missed instalments revise your terms. revised terms are not more favourable."},
		{"say": "thank you for choosing axiom. reply STOP to forfeit vessel."},
	],
}

const MARTA_AFTER_DIVE_ONE := {
	"id": "marta_after_dive_one",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_CALL,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "from_run": 1},
	"steps": [
		{"say": "you came back. that's above average.", "only_if": FLAG_LAST_DIVE_SNAPPED, "is": false},
		{"say": "you came back without the haul. still above average. the bar's on the floor.", "only_if": FLAG_LAST_DIVE_SNAPPED, "is": true},
		{"say": "here's how this goes. people come to me with problems. i turn their problems into jobs."},
		{"say": "you do the job, i get paid, axiom gets its instalment, everyone sleeps."},
		{"say": "some jobs are simple. some have conditions. read them."},
		{"replies": [
			{"text": "what kind of conditions?", "then": [
				{"say": "don't touch this. bring up that. keep the line in one piece."},
				{"say": "clients are fussy. fussy pays."},
			]},
			{"text": "who are the clients?", "then": [
				{"say": "people who can't dive. people who shouldn't be seen diving."},
				{"say": "that's all you need. it's all i'd tell you anyway."},
			]},
		], "silent": [
			{"say": "good. the less you ask, the more i like you."},
		]},
		{"say": "i'll send work to the relay. you take it or you don't."},
		{"say": "and okeke's barge is open to you now. he'll want to say hello."},
		{"say": "let him. buy what you need. believe about half of it."},
	],
}

const OKEKE_INTRO_CALL := {
	"id": "okeke_intro_call",
	"contact": CONTACT_OKEKE,
	"channel": CHANNEL_CALL,
	"trigger": {"moment": TRIGGER_TAB_OPENED, "tab": "vendors"},
	"steps": [
		{"say": "meridian. you're the new one. marta's new one."},
		{"say": "okeke. supply barge, east moorings. rods, lures, parts that fell off something."},
		{"say": "if you need it, i can get it. don't ask where from."},
		{"replies": [
			{"text": "marta sent you?", "then": [
				{"say": "marta doesn't send me anywhere."},
				{"say": "i was on this water before she had a name worth using."},
			]},
			{"text": "what's it cost?", "then": [
				{"say": "less than axiom charges you. more than it's worth."},
				{"say": "that's trade."},
			]},
		], "silent": [
			{"say": "a quiet customer. i like those. they come back."},
		]},
		{"say": "one thing, since nobody told me either when i started."},
		{"say": "whatever she's paying you, she's getting three times that."},
		{"say": "i'm not saying don't. i'm saying count."},
	],
}

# --- Marta's job offers ---
# Each run Marta texts the job MartaJobs offers, with take / pass / say
# nothing. "condition" is the plain-words version for the case_file panel.
const JOB_OFFER_COPY := {
	"quiet_water": {
		"offer": ["something's been talking back on the deep channels. client wants it left alone.", "no entities this run. not one. not even a polite one."],
		"condition": "engage no entities this dive.",
		"take": "good. ears shut, line down.",
		"pass": "your boat.",
		"silent": "i'll find someone who listens.",
	},
	"steady_hands": {
		"offer": ["a buyer wants proof you can hold a line.", "no cutting loose this run. whatever bites, you see it through."],
		"condition": "don't cut the line this dive.",
		"take": "don't make me regret vouching.",
		"pass": "fine. hands shaking?",
		"silent": "silence. noted.",
	},
	"exchange_ledger": {
		"offer": ["the voss exchange lost a ledger. a man who used to own a floor of it would like it found.", "any data container from the exchange."],
		"condition": "land a data container in the voss exchange.",
		"take": "exchange floor. mind the other lines.",
		"pass": "he'll be disappointed. he's used to it.",
		"silent": "i'll tell him you're thinking about it. you're not.",
	},
	"static_walk": {
		"offer": ["axiom's tracers ignore noisy lines. a client wants to know what's under them.", "three catches in a row with the signal at half or worse. get noisy."],
		"condition": "three catches in a row at SIG 50% or under.",
		"take": "loud as you like.",
		"pass": "coward. a well-paid coward, but.",
		"silent": "i'll take that as a no.",
	},
	"sub_basement": {
		"offer": ["there's a server rack under axiom that never got decommissioned.", "data container, axiom sub-basement. don't read it."],
		"condition": "land a data container in the axiom sub-basement.",
		"take": "and don't read it. i mean that.",
		"pass": "sensible. boring, but sensible.",
		"silent": "quiet. sensible, maybe.",
	},
	"dead_air": {
		"offer": ["the people paying for this want you deep in the static. i didn't ask why.", "three catches in a row with the signal at a fifth or worse. then come home."],
		"condition": "three catches in a row at SIG 20% or under.",
		"take": "come home. that's the part that matters.",
		"pass": "i'd pass too. i'm not going to tell them that.",
		"silent": "nothing. good instinct.",
	},
}

# The text exchange for one job offer, in the usual script shape. Not in
# all_scripts(): offers recur every run, so they're never marked played.
static func job_offer_script(job_id: String) -> Dictionary:
	var copy: Dictionary = JOB_OFFER_COPY.get(job_id, {})
	if copy.is_empty():
		return {}
	var steps: Array = []
	for line in copy.offer:
		steps.append({"say": line})
	steps.append({"replies": [
		{"text": "i'll take it.", "then": [{"say": copy.take}, {"do": ACTION_ACCEPT_JOB}]},
		{"text": "pass.", "then": [{"say": copy["pass"]}, {"do": ACTION_DECLINE_JOB}]},
	], "silent": [{"say": copy.silent}, {"do": ACTION_DECLINE_JOB}]})
	return {
		"id": "job_offer_" + job_id,
		"contact": CONTACT_MARTA,
		"channel": CHANNEL_TEXT,
		"trigger": {"moment": TRIGGER_HUB_ARRIVAL},
		"steps": steps,
	}

static func job_condition_text(job_id: String) -> String:
	return JOB_OFFER_COPY.get(job_id, {}).get("condition", "")

# Marta's text after a dive that carried a job.
static func job_outcome_line(met: bool, snapped: bool, relief: int) -> String:
	if met:
		return "job done. client's paid. %scr off what you owe axiom. don't spend it all at once. you can't, it's not yours." % LedgerPanel.format_thousands(relief)
	if snapped:
		return "no line, no job. try keeping the rod in one piece next time."
	return "client's not paying. i told them you were good. now i look like a liar, and i'm not cheap to make a liar."

# Rings once a recovery agent has been assigned (four missed instalments).
const MARTA_RECOVERY_WARNING := {
	"id": "marta_recovery_warning",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_CALL,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "min_pressure": 4},
	"steps": [
		{"say": "they're sending someone. i've seen what they send."},
		{"replies": [
			{"text": "can you stop them?", "then": [
				{"say": "i can stop a lot of things. not axiom's accountants."},
			]},
			{"text": "how long have i got?", "then": [
				{"say": "one more missed payment. then you're a story fishers tell."},
			]},
		], "silent": [
			{"say": "yes. that's the right reaction."},
		]},
		{"say": "find the money, or find a way to be somewhere else when they arrive."},
	],
}

# --- Marta's story beats (relay copy doc section 9) ---
# Hub-arrival scripts from a given run. "after_fishing_zone" holds a beat back
# until the player has dived that zone, so the line has something to point at.

const MARTA_BEAT_EXCHANGE_SHARD := {
	"id": "marta_beat_exchange_shard",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_TEXT,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "from_run": 3, "after_fishing_zone": "exchange"},
	"steps": [
		{"say": "that shard you pulled from the exchange sub-level."},
		{"say": "i've seen that serial number before."},
		{"say": "don't worry about where."},
	],
}

const MARTA_BEAT_FIVE_DIVES := {
	"id": "marta_beat_five_dives",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_TEXT,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "from_run": 5},
	"steps": [
		{"say": "five dives and the rod's still in one piece."},
		{"say": "most people i stake don't get this far. i'm not saying i'm proud. i'm saying i've noticed."},
	],
}

const MARTA_BEAT_ARCHIVE_MOVED := {
	"id": "marta_beat_archive_moved",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_TEXT,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "from_run": 6, "after_fishing_zone": "axiom"},
	"steps": [
		{"say": "the archive from the axiom sub-basement. the one with the specs in it."},
		{"say": "good work. it's already moved."},
		{"say": "you didn't read it. say you didn't read it."},
	],
}

const MARTA_BEAT_TRANSPONDER := {
	"id": "marta_beat_transponder",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_CALL,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "from_run": 8},
	"steps": [
		{"say": "something you should hear from me before you hear it from okeke."},
		{"say": "the meridian has a transponder. it was fitted before you ever touched the keys."},
		{"say": "axiom's been paying me for your dive coordinates since the first night."},
		{"replies": [
			{"text": "you sold me out.", "then": [
				{"say": "i sold your location. you're still here. that's not the same thing."},
			]},
			{"text": "why tell me now?", "then": [
				{"say": "because okeke counts. and because you'd have found it. you're getting good."},
			]},
		], "silent": [
			{"say": "yes. that's about what i expected."},
		]},
		{"say": "it changes nothing. the debt is real. the work is real. my thirty percent is very real."},
		{"say": "if it helps, they never asked about you. only about where you were."},
		{"say": "i'll leave you to decide whether that's better."},
	],
}

const MARTA_BEAT_OKEKE_TALKS := {
	"id": "marta_beat_okeke_talks",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_TEXT,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "from_run": 10},
	"steps": [
		{"say": "okeke talks too much."},
		{"say": "he's not wrong often. he's not right often enough."},
		{"say": "count your money, by all means. count his too."},
	],
}

const MARTA_BEAT_THE_OFFER := {
	"id": "marta_beat_the_offer",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_CALL,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "from_run": 12},
	"steps": [
		{"say": "i've got a proposal. sit down if the boat has anywhere to sit."},
		{"say": "axiom credit is a department. departments have people. people owe me things."},
		{"say": "i can make your account go away. not smaller. away."},
		{"replies": [
			{"text": "what's the price?", "then": [
				{"say": "one job. deep. axiom water. i'll tell you more when you need to know it."},
			]},
			{"text": "why would you?", "then": [
				{"say": "because what i need is further down than anyone else i know can reach."},
			]},
		], "silent": [
			{"say": "take your time. you've got until your next instalment."},
		]},
		{"say": "don't answer now. answer when i call again."},
		{"say": "and don't mention this to okeke. not because he'd talk. because he'd try to talk you out of it."},
	],
}

const MARTA_VICTORY_CALL := {
	"id": "marta_victory_call",
	"contact": CONTACT_MARTA,
	"channel": CHANNEL_CALL,
	"trigger": {"moment": TRIGGER_HUB_ARRIVAL, "requires_victory": true},
	"steps": [
		{"say": "axiom's closed your account. i saw the notice before you did."},
		{"say": "the meridian's yours. no mortgage, no instalments, no reply STOP."},
		{"replies": [
			{"text": "thank you.", "then": [
				{"say": "don't. it was business. it was mostly business."},
			]},
			{"text": "what about your cut?", "then": [
				{"say": "i was paid. i was always going to be paid."},
			]},
		], "silent": [
			{"say": "yes. it's strange the first time."},
		]},
		{"say": "don't make me regret it. call me if you want work. you won't need to, and you'll call anyway."},
	],
}

static func all_scripts() -> Array[Dictionary]:
	return [
		MARTA_FIRST_CALL,
		AXIOM_MORTGAGE_NOTICE,
		MARTA_AFTER_DIVE_ONE,
		OKEKE_INTRO_CALL,
		MARTA_RECOVERY_WARNING,
		MARTA_VICTORY_CALL,
		MARTA_BEAT_EXCHANGE_SHARD,
		MARTA_BEAT_FIVE_DIVES,
		MARTA_BEAT_ARCHIVE_MOVED,
		MARTA_BEAT_TRANSPONDER,
		MARTA_BEAT_OKEKE_TALKS,
		MARTA_BEAT_THE_OFFER,
	]

static func find(script_id: String) -> Dictionary:
	for relay_script in all_scripts():
		if relay_script.id == script_id:
			return relay_script
	return {}

static func is_forced(relay_script: Dictionary) -> bool:
	return relay_script.get("forced", false)
