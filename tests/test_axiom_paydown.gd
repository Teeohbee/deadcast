# tests/test_axiom_paydown.gd
# Paying Axiom Credit early, from the RELAY account (shop economy plan, PR A1).
extends GutTest

const STATE_BACKUP := "user://axiom_paydown_state_backup.cfg"

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.credits = 50000
	GameState.debt = 80000
	GameState.victory = false
	GameState.run_count = 3
	GameState.runs_since_payment = 3
	GameState.pressure_level = 0
	GameState.instalment_paid = 0
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.decrypt_box_queue = 0
	GameState.freezer_base = 0

func after_each() -> void:
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func test_an_early_payment_moves_credits_off_the_balance() -> void:
	assert_true(GameState.pay_debt_early(5000))
	assert_eq(GameState.credits, 45000)
	assert_eq(GameState.debt, 75000)

func test_cannot_pay_more_than_the_wallet_holds() -> void:
	GameState.credits = 999
	assert_false(GameState.pay_debt_early(1000))
	assert_eq(GameState.credits, 999)
	assert_eq(GameState.debt, 80000)

func test_a_part_payment_shrinks_the_next_instalment_but_keeps_the_clock() -> void:
	GameState.pay_debt_early(4000)
	assert_eq(GameState.instalment_remaining(), 6000)
	assert_eq(GameState.runs_since_payment, 3)

func test_the_instalment_collects_only_what_is_still_due() -> void:
	GameState.pay_debt_early(4000)
	GameState.on_run_complete(false, 0)
	GameState.on_run_complete(false, 0)
	assert_eq(GameState.credits, 50000 - 4000 - 6000)
	assert_eq(GameState.debt, 70000)
	assert_eq(GameState.instalment_paid, 0, "the next instalment starts from nothing")

func test_covering_the_instalment_resets_the_clock() -> void:
	GameState.pay_debt_early(10000)
	assert_eq(GameState.runs_since_payment, 0)
	assert_eq(GameState.instalment_remaining(), 10000)

func test_overpaying_carries_into_the_next_instalment() -> void:
	GameState.pay_debt_early(5000)
	GameState.pay_debt_early(10000)
	assert_eq(GameState.runs_since_payment, 0)
	assert_eq(GameState.instalment_remaining(), 5000)

func test_covering_an_instalment_lowers_pressure_by_one() -> void:
	GameState.pressure_level = 2
	GameState.pay_debt_early(10000)
	assert_eq(GameState.pressure_level, 1)

func test_each_instalment_covered_lowers_pressure_once() -> void:
	GameState.pressure_level = 3
	GameState.pay_debt_early(10000)
	GameState.pay_debt_early(10000)
	assert_eq(GameState.pressure_level, 1)

func test_a_part_payment_does_not_lower_pressure() -> void:
	GameState.pressure_level = 2
	GameState.pay_debt_early(5000)
	assert_eq(GameState.pressure_level, 2)

func test_pressure_does_not_go_below_zero() -> void:
	GameState.pay_debt_early(10000)
	assert_eq(GameState.pressure_level, 0)

func test_paying_more_than_the_balance_only_takes_the_balance() -> void:
	GameState.debt = 3000
	assert_true(GameState.pay_debt_early(5000))
	assert_eq(GameState.credits, 47000)
	assert_eq(GameState.debt, 0)

func test_clearing_the_balance_closes_the_account() -> void:
	GameState.debt = 5000
	GameState.pay_debt_early(5000)
	assert_true(GameState.victory)
	assert_true(GameState.relay_has_played(AxiomCredit.NOTICE_ACCOUNT_CLOSED))

func test_cannot_pay_a_closed_account() -> void:
	GameState.debt = 0
	GameState.victory = true
	assert_false(GameState.pay_debt_early(1000))
	assert_eq(GameState.credits, 50000)

func test_an_early_payment_files_an_axiom_notice() -> void:
	GameState.pay_debt_early(5000)
	var notices := GameState.relay_entries_for("axiom_credit")
	assert_eq(notices.size(), 1)
	assert_eq(notices[0].script_id, AxiomCredit.NOTICE_EARLY_PAYMENT)
	assert_string_contains(notices[0].lines[1].text, "5,000cr")
	assert_string_contains(notices[0].lines[1].text, "75,000cr")

func test_the_notice_says_when_the_instalment_is_covered_and_the_profile_reviewed() -> void:
	GameState.pressure_level = 1
	GameState.pay_debt_early(10000)
	var text := str(GameState.relay_entries_for("axiom_credit")[0].lines)
	assert_string_contains(text, "interval has been reset")
	assert_string_contains(text, "status revised")

func test_instalment_progress_survives_a_save() -> void:
	GameState.pay_debt_early(3000)
	var path := "user://axiom_paydown_roundtrip.cfg"
	GameState._save_to(path)
	GameState.instalment_paid = 0
	GameState._load_from(path)
	DirAccess.remove_absolute(path)
	assert_eq(GameState.instalment_paid, 3000)

func test_a_new_game_starts_with_nothing_paid() -> void:
	GameState.pay_debt_early(3000)
	GameState.new_game()
	assert_eq(GameState.instalment_paid, 0)
