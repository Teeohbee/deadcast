# tests/test_dive_jobs.gd
extends GutTest

var _saved := {}

func before_each() -> void:
	for key in ["active_job_id", "debt", "victory", "selected_zone", "first_dive_hints_done", "relay_entries"]:
		_saved[key] = GameState.get(key)
	GameState.selected_zone = "district7"
	GameState.debt = 80000
	GameState.victory = false
	GameState.first_dive_hints_done = true
	GameState.relay_entries = []

func after_each() -> void:
	for key in _saved:
		GameState.set(key, _saved[key])

func _start_dive() -> Node:
	var dive: Node = load("res://scenes/dive_run/DiveRun.tscn").instantiate()
	add_child_autofree(dive)
	await get_tree().process_frame
	await get_tree().process_frame
	return dive

func test_active_job_is_announced_at_the_cast() -> void:
	GameState.active_job_id = "steady_hands"
	var dive = await _start_dive()
	assert_string_contains(dive.session_log.log_text.get_parsed_text(), "marta job: steady hands")

func test_no_job_line_without_a_job() -> void:
	GameState.active_job_id = ""
	var dive = await _start_dive()
	assert_false(dive.session_log.log_text.get_parsed_text().contains("marta job"))

func test_met_job_clears_debt_and_lands_in_the_run_record() -> void:
	GameState.active_job_id = "steady_hands"
	var dive = await _start_dive()
	var outcome: Dictionary = dive._resolve_active_job(false)
	assert_true(outcome.met)
	assert_eq(GameState.debt, 77500)
	assert_eq(GameState.active_job_id, "")
	assert_true(dive._run_record.entries.has(outcome))

func test_cutting_the_line_fails_steady_hands() -> void:
	GameState.active_job_id = "steady_hands"
	var dive = await _start_dive()
	dive._facts.cut_line = true
	var outcome: Dictionary = dive._resolve_active_job(false)
	assert_false(outcome.met)
	assert_eq(GameState.debt, 80000)

func test_snapped_run_fails_the_job() -> void:
	GameState.active_job_id = "steady_hands"
	var dive = await _start_dive()
	assert_false(dive._resolve_active_job(true).met)

func test_no_outcome_without_a_job() -> void:
	GameState.active_job_id = ""
	var dive = await _start_dive()
	assert_true(dive._resolve_active_job(false).is_empty())

func test_resolved_contacts_feed_the_run_facts() -> void:
	var dive = await _start_dive()
	var catch_data := CatchData.new()
	catch_data.catch_type = CatchData.CatchType.ENTITY
	dive._record_slot(catch_data, "listen", "", 0, 0, 0, true)
	assert_true(dive._facts.entity_engaged)
	assert_eq(dive._facts.corruption_per_contact.size(), 1)

func test_marta_texts_the_outcome_of_a_met_job() -> void:
	GameState.active_job_id = "steady_hands"
	var dive = await _start_dive()
	dive._resolve_active_job(false)
	var filed: Array[Dictionary] = GameState.relay_entries_for("marta")
	assert_eq(filed.size(), 1)
	assert_string_contains(filed[0].lines[0].text, "2,500cr off what you owe axiom")

func test_marta_texts_a_snapped_job_differently() -> void:
	GameState.active_job_id = "steady_hands"
	var dive = await _start_dive()
	dive._resolve_active_job(true)
	assert_string_contains(GameState.relay_entries_for("marta")[0].lines[0].text, "no line, no job")
