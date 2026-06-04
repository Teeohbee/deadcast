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
	GameState.freezer_value = 0
	GameState.freezer_runs = 0

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

func test_decrypt_box_multiplies_after_3_runs() -> void:
	GameState.decrypt_box_queue = 1000
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.decrypt_box_queue, 0, "Queue should be cleared")
	assert_eq(GameState.credits, 54000, "50000 base + 4x1000 decrypt bonus")

func test_freezer_spoils_after_3_runs() -> void:
	GameState.freezer_value = 2000
	GameState.freezer_runs = 0
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.freezer_value, 1000, "Freezer spoils to 50% after 3 runs")

func test_freezer_spoils_again_after_another_3_runs() -> void:
	GameState.freezer_value = 2000
	GameState.freezer_runs = 0
	for i in 6:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.freezer_value, 500, "Freezer spoils twice: 2000 -> 1000 -> 500")

func test_freezer_added_after_spoil_still_degrades() -> void:
	GameState.freezer_value = 1000
	GameState.freezer_runs = 0
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.freezer_value, 500, "First spoil")
	GameState.on_run_complete(false, 800)
	assert_eq(GameState.freezer_value, 1300, "Added 800 bio credits")
	for i in 2:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.freezer_value, 650, "Second spoil after new bio added")
