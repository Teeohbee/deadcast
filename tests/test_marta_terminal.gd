# tests/test_marta_terminal.gd
extends GutTest

const SCREEN := preload("res://scenes/barge_hub/MartaTerminal.tscn")

func before_each() -> void:
	GameState.run_count = 1
	GameState.pressure_level = 4
	GameState.victory = false
	GameState.debt = 80000

func _make() -> Node:
	var s := SCREEN.instantiate()
	add_child_autofree(s)
	return s

func test_screen_instantiates_with_transmission() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_not_null(s._transmission)

func test_transmission_reflects_pressure() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s._transmission._link_label.text, "TRACED")

func test_dialogue_still_renders() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s.dialogue_label.text, "marta")

# --- transmission history ---

func test_no_beats_before_first_run() -> void:
	var s := _make()
	assert_eq(s.beat_history(0).size(), 0)

func test_beat_history_is_newest_first() -> void:
	var s := _make()
	var history: Array = s.beat_history(8)
	assert_eq(history.size(), 5)
	assert_string_contains(history[0], "transponder")
	assert_string_contains(history[4], "80,000")

func test_history_panel_lists_earlier_beats_not_the_current_one() -> void:
	GameState.run_count = 8
	var s := _make()
	await get_tree().process_frame
	var text: String = s._history_label.text
	assert_string_contains(text, "shard")
	assert_string_contains(text, "80,000")
	assert_false(text.contains("transponder"), "current beat belongs in the marta panel")

func test_history_panel_says_when_empty() -> void:
	GameState.run_count = 1
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s._history_label.text, "no earlier transmissions")

# --- job panel ---

func _reset_jobs() -> void:
	GameState.active_job_id = ""
	GameState.job_declined_run = -1

func test_job_panel_offers_a_job_with_accept_and_decline() -> void:
	_reset_jobs()
	GameState.run_count = 3
	var s := _make()
	await get_tree().process_frame
	var offer := MartaJobs.offer_for(3)
	assert_string_contains(s._job_label.text, offer.title)
	assert_true(s._accept_button.visible)
	assert_true(s._decline_button.visible)

func test_accept_button_activates_the_offered_job() -> void:
	_reset_jobs()
	GameState.run_count = 3
	var s := _make()
	await get_tree().process_frame
	s._accept_button.pressed.emit()
	assert_eq(GameState.active_job_id, MartaJobs.offer_for(3).id)
	assert_false(s._accept_button.visible)
	assert_string_contains(s._job_label.text, "active")
	_reset_jobs()

func test_decline_button_closes_the_offer() -> void:
	_reset_jobs()
	GameState.run_count = 3
	var s := _make()
	await get_tree().process_frame
	s._decline_button.pressed.emit()
	assert_eq(GameState.active_job_id, "")
	assert_false(s._accept_button.visible)
	_reset_jobs()

func test_no_job_offered_before_first_run() -> void:
	_reset_jobs()
	GameState.run_count = 0
	var s := _make()
	await get_tree().process_frame
	assert_false(s._accept_button.visible)

func test_debt_status_names_missed_payments() -> void:
	GameState.pressure_level = 1
	var s := _make()
	await get_tree().process_frame
	assert_eq(s.debt_status_label.text, "outstanding debt: 80,000 cr  ·  missed payments 1/5")

func test_payment_line_shows_a_smaller_final_payment() -> void:
	GameState.debt = 4000
	GameState.runs_since_payment = 3
	var s := _make()
	await get_tree().process_frame
	assert_eq(s.payment_label.text, "next payment: 4,000cr due in 2 runs.")

func test_marta_does_not_praise_a_schedule_before_the_first_run() -> void:
	GameState.run_count = 0
	GameState.pressure_level = 0
	var s := _make()
	await get_tree().process_frame
	assert_false(s.dialogue_label.text.contains("on schedule"))
	assert_string_contains(s.dialogue_label.text, "go fishing")

func test_marta_on_schedule_after_a_run() -> void:
	GameState.run_count = 1
	GameState.pressure_level = 0
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s.dialogue_label.text, "on schedule")
