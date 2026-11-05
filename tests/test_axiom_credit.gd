# tests/test_axiom_credit.gd
# The mortgage speaks through Axiom Credit's notices on the relay.
extends GutTest

const STATE_BACKUP := "user://axiom_credit_state_backup.cfg"

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.credits = 50000
	GameState.debt = 80000
	GameState.victory = false
	GameState.run_count = 0
	GameState.runs_since_payment = 0
	GameState.pressure_level = 0
	GameState.freezer_base = 0
	GameState.decrypt_box_queue = 0

func after_each() -> void:
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func _axiom_headers() -> Array[String]:
	var headers: Array[String] = []
	for entry in GameState.relay_entries_for("axiom_credit"):
		headers.append(entry.lines[0].text)
	return headers

func _dive(times: int) -> void:
	for index in times:
		GameState.on_run_complete(false, 0)

func test_a_reminder_arrives_the_dive_before_an_instalment() -> void:
	_dive(4)
	assert_eq(_axiom_headers(), ["AXIOM CREDIT · REMINDER"] as Array[String])

func test_a_paid_instalment_gets_a_receipt_with_the_balance() -> void:
	_dive(5)
	var receipt: Dictionary = GameState.relay_entries_for("axiom_credit").back()
	assert_eq(receipt.lines[0].text, "AXIOM CREDIT · PAYMENT RECEIVED")
	assert_string_contains(receipt.lines[1].text, "remaining balance: 70,000cr")

func test_a_missed_instalment_sends_a_notice_and_marta_reacts() -> void:
	GameState.credits = 0
	_dive(5)
	assert_eq(_axiom_headers().back(), "AXIOM CREDIT · MISSED INSTALMENT")
	assert_string_contains(GameState.relay_entries_for("marta").back().lines[0].text, "worse bet")

func test_the_third_miss_cuts_off_supplies_and_okeke_says_so() -> void:
	GameState.credits = 0
	GameState.pressure_level = 2
	GameState.runs_since_payment = 4
	_dive(1)
	assert_eq(_axiom_headers().back(), "AXIOM CREDIT · SUPPLIER NOTICE")
	assert_string_contains(GameState.relay_entries_for("okeke").back().lines[0].text, "names on lists")

func test_every_pressure_level_has_a_notice() -> void:
	for level in range(1, 6):
		assert_true(AxiomCredit.MISSED_NOTICES.has(level), str(level))

func test_dropping_below_half_sends_the_review_notice_once() -> void:
	GameState.debt = 45000
	_dive(5)
	_dive(5)
	var reviews := _axiom_headers().filter(func(header: String) -> bool: return header.contains("ACCOUNT REVIEW"))
	assert_eq(reviews.size(), 1)

func test_clearing_the_debt_closes_the_account_once() -> void:
	GameState.debt = 10000
	_dive(5)
	assert_true(GameState.victory)
	_dive(5)
	var closed := _axiom_headers().filter(func(header: String) -> bool: return header.contains("ACCOUNT CLOSED"))
	assert_eq(closed.size(), 1)

func test_marta_rings_once_a_recovery_agent_is_assigned() -> void:
	GameState.relay_mark_played("marta_first_call")
	GameState.relay_mark_played("marta_after_dive_one")
	GameState.run_count = 20
	GameState.pressure_level = 3
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).is_empty())
	GameState.pressure_level = 4
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_recovery_warning")

func test_an_old_save_doesnt_count_the_recovery_warning_as_heard() -> void:
	assert_false("marta_recovery_warning" in RelayDirector.script_ids_already_past(20))
