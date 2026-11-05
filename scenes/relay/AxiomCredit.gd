# scenes/relay/AxiomCredit.gd
# Axiom Credit's automated notices, and Marta's and Okeke's reactions, filed
# in the relay when the mortgage moves. Called by GameState.on_run_complete
# after the instalment clock has run. Copy: relay copy doc section 8.
class_name AxiomCredit

const NOTICE_INSTALMENT_DUE := "axiom_instalment_due"
const NOTICE_PAYMENT_RECEIVED := "axiom_payment_received"
const NOTICE_BALANCE_HALF := "axiom_balance_half"
const NOTICE_MISSED := "axiom_missed_%d"
const NOTICE_ACCOUNT_CLOSED := "axiom_account_closed"
const NOTICE_EARLY_PAYMENT := "axiom_early_payment"

const MISSED_NOTICES := {
	1: ["AXIOM CREDIT · MISSED INSTALMENT",
		"collection failed: insufficient funds. this has been noted on your operator profile.",
		"the instalment will be collected at the next interval in addition to the regular amount."],
	2: ["AXIOM CREDIT · TERMS REVISED",
		"following a second missed instalment, approved suppliers have been notified of your account status. supplier pricing may be adjusted.",
		"reply STOP to forfeit vessel."],
	3: ["AXIOM CREDIT · SUPPLIER NOTICE",
		"approved suppliers have been instructed to suspend trade with your operator profile until your account is in good standing."],
	4: ["AXIOM CREDIT · FINAL NOTICE",
		"a recovery agent has been assigned to vessel MERIDIAN. this is your final notice. there will not be another."],
	5: ["AXIOM CREDIT · VESSEL RECOVERED",
		"vessel MERIDIAN has been recovered in partial settlement. your operator profile has been closed.",
		"thank you for choosing axiom."],
}

# Others react to some missed instalments by text: pressure -> [[contact, line]].
const REACTIONS := {
	1: [[RelayScripts.CONTACT_MARTA, "axiom says you missed one. i don't care about axiom. i care that you're a worse bet than you were yesterday."]],
	3: [[RelayScripts.CONTACT_MARTA, "okeke's been told not to sell to you. that's not me. but it's not not me either. pay them."],
		[RelayScripts.CONTACT_OKEKE, "axiom's put your name on a list. i can't sell to names on lists. not openly. pay them and i'll have forgotten by morning."]],
}

static func notify_instalment_due(amount: int) -> void:
	_file_notice(NOTICE_INSTALMENT_DUE, [
		"AXIOM CREDIT · REMINDER",
		"instalment of %scr will be collected after your next dive. ensure sufficient funds." % LedgerPanel.format_thousands(amount),
		"reply STOP to forfeit vessel."])

static func notify_payment_received(amount: int, balance: int) -> void:
	_file_notice(NOTICE_PAYMENT_RECEIVED, [
		"AXIOM CREDIT · PAYMENT RECEIVED",
		"%scr collected. remaining balance: %scr." % [LedgerPanel.format_thousands(amount), LedgerPanel.format_thousands(balance)],
		"thank you for your continued custom."])

static func notify_early_payment(amount: int, balance: int, instalment_covered: bool, status_revised: bool) -> void:
	var lines: Array = [
		"AXIOM CREDIT · PAYMENT RECEIVED EARLY",
		"%scr received ahead of schedule. remaining balance: %scr." % [
			LedgerPanel.format_thousands(amount), LedgerPanel.format_thousands(balance)]]
	if instalment_covered:
		lines.append("your next instalment is satisfied. the collection interval has been reset.")
	if status_revised:
		lines.append("your operator profile has been reviewed. status revised.")
	if not instalment_covered:
		lines.append("we appreciate your enthusiasm.")
	_file_notice(NOTICE_EARLY_PAYMENT, lines)

static func notify_payment_missed(pressure_level: int) -> void:
	var level := clampi(pressure_level, 1, 5)
	var lines: Array = MISSED_NOTICES[level]
	_file_notice(NOTICE_MISSED % level, lines)
	for reaction in REACTIONS.get(level, []):
		GameState.relay_file_entry(reaction[0], GameState.RELAY_ENTRY_TEXT, "%s_reacts_missed_%d" % [reaction[0], level],
			[{"who": reaction[0], "text": reaction[1]}])

# Once per game, the first time the balance drops below half.
static func notify_balance_below_half_once() -> void:
	if GameState.relay_has_played(NOTICE_BALANCE_HALF):
		return
	GameState.relay_mark_played(NOTICE_BALANCE_HALF)
	_file_notice(NOTICE_BALANCE_HALF, [
		"AXIOM CREDIT · ACCOUNT REVIEW",
		"your balance is below 50% of the original principal. you are now eligible for our premium refinancing products.",
		"you will not be offered them."])

static func notify_account_closed_once() -> void:
	if GameState.relay_has_played(NOTICE_ACCOUNT_CLOSED):
		return
	GameState.relay_mark_played(NOTICE_ACCOUNT_CLOSED)
	_file_notice(NOTICE_ACCOUNT_CLOSED, [
		"AXIOM CREDIT · ACCOUNT CLOSED",
		"balance: 0cr. vessel MERIDIAN is released from mortgage.",
		"we look forward to doing business with you again."])

static func _file_notice(notice_id: String, lines: Array) -> void:
	var transcript: Array[Dictionary] = []
	for line in lines:
		transcript.append({"who": RelayScripts.CONTACT_AXIOM_CREDIT, "text": line})
	GameState.relay_file_entry(RelayScripts.CONTACT_AXIOM_CREDIT, GameState.RELAY_ENTRY_TEXT, notice_id, transcript)
