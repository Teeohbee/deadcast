# tests/test_freezer_market.gd
extends GutTest

func before_each() -> void:
	GameState.credits = 0
	GameState.freezer_base = 0
	GameState.freezer_runs = 0
	GameState.freezer_multiplier = 1.0

func test_sale_value_applies_multiplier() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_multiplier = 1.2
	assert_eq(GameState.freezer_sale_value(), 1200)

func test_sale_value_rounds() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_multiplier = 0.755
	assert_eq(GameState.freezer_sale_value(), 755)

func test_sale_value_empty_is_zero() -> void:
	GameState.freezer_base = 0
	GameState.freezer_multiplier = 1.5
	assert_eq(GameState.freezer_sale_value(), 0)

func test_deposit_adds_to_base() -> void:
	GameState.freezer_base = 500
	GameState._update_freezer_market(false, 300)
	assert_eq(GameState.freezer_base, 800)

func test_clock_advances_when_holding() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_runs = 0
	GameState._update_freezer_market(false, 0)
	assert_eq(GameState.freezer_runs, 1)

func test_clock_does_not_advance_when_empty() -> void:
	GameState.freezer_base = 0
	GameState.freezer_runs = 0
	GameState._update_freezer_market(false, 0)
	assert_eq(GameState.freezer_runs, 0)

func test_clock_does_not_advance_on_snap() -> void:
	GameState.freezer_base = 1000
	GameState.freezer_runs = 1
	GameState._update_freezer_market(true, 0)
	assert_eq(GameState.freezer_runs, 1)
	assert_eq(GameState.freezer_base, 1000)

func test_deposit_still_happens_on_snap() -> void:
	GameState.freezer_base = 500
	GameState._update_freezer_market(true, 200)
	assert_eq(GameState.freezer_base, 700)

func test_force_dump_at_floor_on_deadline() -> void:
	GameState.credits = 0
	GameState.freezer_base = 1000
	GameState.freezer_runs = GameState.FREEZER_SPOIL_RUNS - 1
	GameState._update_freezer_market(false, 0)
	assert_eq(GameState.credits, 300, "1000 * 0.3 floor")
	assert_eq(GameState.freezer_base, 0)
	assert_eq(GameState.freezer_runs, 0)

func test_deposit_on_force_dump_run_is_included_in_proceeds() -> void:
	GameState.credits = 0
	GameState.freezer_base = 1000
	GameState.freezer_runs = GameState.FREEZER_SPOIL_RUNS - 1
	GameState._update_freezer_market(false, 200)  # fresh catch on the spoil-deadline run
	assert_eq(GameState.credits, 360, "(1000 + 200) * 0.3 floor")
	assert_eq(GameState.freezer_base, 0)
	assert_eq(GameState.freezer_runs, 0)

func test_roll_stays_in_band() -> void:
	for i in range(200):
		GameState.freezer_base = 1000
		GameState.freezer_runs = 0
		GameState._update_freezer_market(false, 0)
		assert_between(GameState.freezer_multiplier, GameState.FREEZER_MIN_MULT, GameState.FREEZER_MAX_MULT)
