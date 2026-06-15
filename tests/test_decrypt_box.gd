# tests/test_decrypt_box.gd
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

func test_roll_returns_corruption_at_low_roll() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.0)
	assert_eq(outcome.id, "corruption")

func test_roll_returns_corruption_just_before_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.199)
	assert_eq(outcome.id, "corruption")

func test_roll_returns_partial_at_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.20)
	assert_eq(outcome.id, "partial")

func test_roll_returns_partial_before_clean_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.549)
	assert_eq(outcome.id, "partial")

func test_roll_returns_clean_at_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.55)
	assert_eq(outcome.id, "clean")

func test_roll_returns_clean_before_anomaly_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.899)
	assert_eq(outcome.id, "clean")

func test_roll_returns_anomaly_at_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.90)
	assert_eq(outcome.id, "anomaly")

func test_roll_returns_anomaly_at_max() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.999)
	assert_eq(outcome.id, "anomaly")

func test_outcome_has_required_fields() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.5)
	assert_true(outcome.has("id"))
	assert_true(outcome.has("label"))
	assert_true(outcome.has("multiplier"))

func test_corruption_multiplier_is_zero() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.0)
	assert_eq(outcome.multiplier, 0.0)

func test_anomaly_multiplier_is_six() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.90)
	assert_eq(outcome.multiplier, 6.0)

func test_decrypt_payout_clears_queue() -> void:
	GameState.decrypt_box_queue = 1000
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.decrypt_box_queue, 0)

func test_decrypt_payout_sets_last_outcome() -> void:
	GameState.decrypt_box_queue = 1000
	for i in 3:
		GameState.on_run_complete(false, 0)
	var valid_ids = ["corruption", "partial", "clean", "anomaly"]
	assert_true(GameState.decrypt_last_outcome in valid_ids)

func test_decrypt_payout_sets_last_payout() -> void:
	GameState.decrypt_box_queue = 1000
	for i in 3:
		GameState.on_run_complete(false, 0)
	var valid_payouts = [0, 1500, 4000, 6000]
	assert_true(GameState.decrypt_last_payout in valid_payouts)

func test_decrypt_last_outcome_saved_and_loaded() -> void:
	GameState.decrypt_last_outcome = "anomaly"
	GameState.decrypt_last_payout = 6000
	GameState._save_to("user://save_test.cfg")
	GameState.decrypt_last_outcome = ""
	GameState.decrypt_last_payout = 0
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.decrypt_last_outcome, "anomaly")
	assert_eq(GameState.decrypt_last_payout, 6000)

func test_new_game_resets_decrypt_last_outcome() -> void:
	GameState.decrypt_last_outcome = "clean"
	GameState.decrypt_last_payout = 4000
	GameState.new_game()
	assert_eq(GameState.decrypt_last_outcome, "")
	assert_eq(GameState.decrypt_last_payout, 0)

func after_each() -> void:
	DirAccess.remove_absolute("user://save_test.cfg")
