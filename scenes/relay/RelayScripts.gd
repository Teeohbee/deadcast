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

static func all_scripts() -> Array[Dictionary]:
	return [
		MARTA_FIRST_CALL,
		AXIOM_MORTGAGE_NOTICE,
		MARTA_AFTER_DIVE_ONE,
		OKEKE_INTRO_CALL,
	]

static func find(script_id: String) -> Dictionary:
	for relay_script in all_scripts():
		if relay_script.id == script_id:
			return relay_script
	return {}

static func is_forced(relay_script: Dictionary) -> bool:
	return relay_script.get("forced", false)
