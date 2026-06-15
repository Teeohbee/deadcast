# tests/test_debt_clock.gd
extends GutTest

func before_each() -> void:
	GameState.credits = 50000
	GameState.debt = 80000
	GameState.run_count = 0
	GameState.runs_since_payment = 0
	GameState.pressure_level = 0
	GameState.rod_damaged = false
	GameState.decrypt_box_queue = 0
	GameState.decrypt_box_runs = 0
	GameState.decrypt_last_outcome = ""
	GameState.decrypt_last_payout = 0
	GameState.freezer_base = 0
	GameState.freezer_runs = 0
	GameState.freezer_multiplier = 1.0

func test_run_count_increments_each_run() -> void:
	GameState.on_run_complete(false, 0)
	assert_eq(GameState.run_count, 1)
	GameState.on_run_complete(false, 0)
	assert_eq(GameState.run_count, 2)

func test_debt_payment_deducted_every_5_runs() -> void:
	for i in 5:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.credits, 40000, "10000cr payment after 5 runs")
	assert_eq(GameState.debt, 70000, "Debt reduced by payment")

func test_missed_payment_increases_pressure() -> void:
	GameState.credits = 0
	for i in 5:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.pressure_level, 1)

func test_rod_marked_damaged_on_snap() -> void:
	GameState.on_run_complete(true, 0)
	assert_true(GameState.rod_damaged)

func test_rod_not_damaged_on_clean_run() -> void:
	GameState.on_run_complete(false, 0)
	assert_false(GameState.rod_damaged)

func test_debt_reaches_zero_marks_victory() -> void:
	GameState.debt = 10000
	GameState.credits = 50000
	for i in 5:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.debt, 0)
	assert_true(GameState.victory)

func test_decrypt_box_pays_out_after_3_runs() -> void:
	GameState.decrypt_box_queue = 1000
	GameState.decrypt_box_runs = 0
	var credits_before = GameState.credits
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.decrypt_box_queue, 0, "Queue should be cleared after payout")
	assert_true(GameState.credits != credits_before or GameState.decrypt_last_outcome == "corruption",
		"Credits should change unless corruption outcome")

func test_freezer_force_dumps_at_floor_after_3_runs() -> void:
	GameState.freezer_base = 2000
	GameState.freezer_runs = 0
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.freezer_base, 0, "Pool emptied on force-dump")
	assert_eq(GameState.freezer_runs, 0, "Clock reset after force-dump")
	# 2000 * 0.3 = 600 credited; credits start at 50000, no debt payment (only 3 runs)
	assert_eq(GameState.credits, 50600, "Floor proceeds added to credits")

func test_freezer_stays_empty_after_force_dump() -> void:
	GameState.freezer_base = 2000
	GameState.freezer_runs = 0
	for i in 6:
		GameState.on_run_complete(false, 0)
	# After dump on run 3, pool is empty. Runs 4-6 deposit nothing (bio=0), clock stays at 0.
	assert_eq(GameState.freezer_base, 0, "Pool stays empty after force-dump with no new deposits")
	assert_eq(GameState.freezer_runs, 0, "Clock stays at zero when pool is empty")

func test_freezer_deposit_after_dump_restarts_cycle() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_runs = 0
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.freezer_base, 0, "Force-dump clears pool")
	# Next run deposits 800 — pool non-empty, clock should start advancing again
	GameState.on_run_complete(false, 800)
	assert_eq(GameState.freezer_base, 800, "Deposit restarts pool after dump")
	assert_eq(GameState.freezer_runs, 1, "Clock advances on first run with new stock")
