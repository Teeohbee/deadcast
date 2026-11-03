# tests/test_marta_jobs.gd
extends GutTest

var _saved := {}

func before_each() -> void:
	for key in ["active_job_id", "job_declined_run", "debt", "victory", "run_count"]:
		_saved[key] = GameState.get(key)
	GameState.active_job_id = ""
	GameState.job_declined_run = -1
	GameState.debt = 80000
	GameState.victory = false
	GameState.run_count = 3

func after_each() -> void:
	for key in _saved:
		GameState.set(key, _saved[key])
	DirAccess.remove_absolute("user://save_test.cfg")

func _job(condition: JobData.Condition) -> JobData:
	var job := JobData.new()
	job.id = "test_job"
	job.title = "test job"
	job.condition = condition
	job.debt_relief = 3000
	return job

func _facts(zone_id: String = "district7") -> RunFacts:
	return RunFacts.new(zone_id)

# --- job definitions ---

func test_every_job_resource_loads_with_an_id_and_relief() -> void:
	var jobs := MartaJobs.all_jobs()
	assert_gt(jobs.size(), 3)
	var ids := {}
	for job in jobs:
		assert_ne(job.id, "")
		assert_gt(job.debt_relief, 0, job.id)
		assert_false(ids.has(job.id), "duplicate id %s" % job.id)
		ids[job.id] = true

func test_find_returns_job_by_id_or_null() -> void:
	var first: JobData = MartaJobs.all_jobs()[0]
	assert_eq(MartaJobs.find(first.id), first)
	assert_null(MartaJobs.find("no_such_job"))

# --- offers ---

func test_no_offer_before_the_first_run() -> void:
	assert_null(MartaJobs.offer_for(0))

func test_offer_only_includes_jobs_unlocked_by_run_count() -> void:
	for run in range(1, 14):
		var job := MartaJobs.offer_for(run)
		assert_not_null(job, "run %d" % run)
		assert_true(job.min_run <= run, "%s offered too early at run %d" % [job.id, run])

func test_offer_changes_between_runs() -> void:
	var seen := {}
	for run in range(1, 14):
		seen[MartaJobs.offer_for(run).id] = true
	assert_gt(seen.size(), 2)

func test_later_runs_unlock_more_lucrative_jobs() -> void:
	var best_early := 0
	var best_late := 0
	for job in MartaJobs.all_jobs():
		if job.min_run <= 2:
			best_early = max(best_early, job.debt_relief)
		best_late = max(best_late, job.debt_relief)
	assert_gt(best_late, best_early)

# --- conditions ---

func test_any_job_fails_on_a_snapped_line() -> void:
	var facts := _facts()
	facts.snapped = true
	assert_false(MartaJobs.is_met(_job(JobData.Condition.NO_CUT_LINE), facts))

func test_no_cut_line_met_without_cuts() -> void:
	var facts := _facts()
	facts.note_slot(CatchData.CatchType.DATA, 200, false, 0.0)
	assert_true(MartaJobs.is_met(_job(JobData.Condition.NO_CUT_LINE), facts))

func test_no_cut_line_fails_after_a_cut() -> void:
	var facts := _facts()
	facts.cut_line = true
	assert_false(MartaJobs.is_met(_job(JobData.Condition.NO_CUT_LINE), facts))

func test_no_entity_met_when_entities_left_alone() -> void:
	var facts := _facts()
	facts.note_slot(CatchData.CatchType.ENTITY, 0, false, 0.0)
	assert_true(MartaJobs.is_met(_job(JobData.Condition.NO_ENTITY_ENGAGED), facts))

func test_no_entity_fails_when_an_entity_option_was_taken() -> void:
	var facts := _facts()
	facts.note_slot(CatchData.CatchType.ENTITY, 0, true, 0.0)
	assert_false(MartaJobs.is_met(_job(JobData.Condition.NO_ENTITY_ENGAGED), facts))

func test_no_entity_fails_when_an_entity_was_landed() -> void:
	var facts := _facts()
	facts.note_slot(CatchData.CatchType.ENTITY, 400, false, 0.0)
	assert_false(MartaJobs.is_met(_job(JobData.Condition.NO_ENTITY_ENGAGED), facts))

func test_land_type_in_zone_met_by_matching_catch_in_zone() -> void:
	var job := _job(JobData.Condition.LAND_TYPE_IN_ZONE)
	job.zone_id = "axiom"
	job.catch_type = CatchData.CatchType.DATA
	var facts := _facts("axiom")
	facts.note_slot(CatchData.CatchType.DATA, 300, false, 0.0)
	assert_true(MartaJobs.is_met(job, facts))

func test_land_type_in_zone_fails_in_the_wrong_zone() -> void:
	var job := _job(JobData.Condition.LAND_TYPE_IN_ZONE)
	job.zone_id = "axiom"
	job.catch_type = CatchData.CatchType.DATA
	var facts := _facts("district7")
	facts.note_slot(CatchData.CatchType.DATA, 300, false, 0.0)
	assert_false(MartaJobs.is_met(job, facts))

func test_land_type_in_zone_needs_a_landed_catch_not_a_skipped_one() -> void:
	var job := _job(JobData.Condition.LAND_TYPE_IN_ZONE)
	job.zone_id = "axiom"
	job.catch_type = CatchData.CatchType.DATA
	var facts := _facts("axiom")
	facts.note_slot(CatchData.CatchType.DATA, 0, false, 0.0)
	facts.note_slot(CatchData.CatchType.BIO, 300, false, 0.0)
	assert_false(MartaJobs.is_met(job, facts))

func test_corruption_streak_met_by_consecutive_catches_over_threshold() -> void:
	var job := _job(JobData.Condition.HIGH_CORRUPTION_STREAK)
	job.corruption_threshold = 50.0
	job.streak_length = 3
	var facts := _facts()
	for corruption in [20.0, 55.0, 60.0, 70.0]:
		facts.note_slot(CatchData.CatchType.DATA, 100, false, corruption)
	assert_true(MartaJobs.is_met(job, facts))

func test_corruption_streak_broken_by_a_catch_under_threshold() -> void:
	var job := _job(JobData.Condition.HIGH_CORRUPTION_STREAK)
	job.corruption_threshold = 50.0
	job.streak_length = 3
	var facts := _facts()
	for corruption in [55.0, 60.0, 40.0, 70.0]:
		facts.note_slot(CatchData.CatchType.DATA, 100, false, corruption)
	assert_false(MartaJobs.is_met(job, facts))

func test_longest_streak() -> void:
	assert_eq(MartaJobs.longest_streak([10.0, 80.0, 90.0, 5.0, 85.0], 80.0), 2)
	assert_eq(MartaJobs.longest_streak([], 80.0), 0)

# --- GameState ---

func test_accepting_a_job_makes_it_active() -> void:
	GameState.accept_job("quiet_water")
	assert_eq(GameState.active_job_id, "quiet_water")

func test_declining_hides_the_offer_until_the_next_run() -> void:
	GameState.decline_job()
	assert_false(GameState.job_offer_open())
	GameState.run_count += 1
	assert_true(GameState.job_offer_open())

func test_no_offer_while_a_job_is_active_or_after_victory() -> void:
	GameState.accept_job("quiet_water")
	assert_false(GameState.job_offer_open())
	GameState.active_job_id = ""
	GameState.victory = true
	assert_false(GameState.job_offer_open())

func test_no_offer_before_the_first_run_in_game_state() -> void:
	GameState.run_count = 0
	assert_false(GameState.job_offer_open())

func test_resolving_a_met_job_reduces_debt_and_clears_it() -> void:
	var job := _job(JobData.Condition.NO_CUT_LINE)
	GameState.active_job_id = job.id
	var relief := GameState.resolve_job(job, true)
	assert_eq(relief, 3000)
	assert_eq(GameState.debt, 77000)
	assert_eq(GameState.active_job_id, "")

func test_resolving_a_failed_job_keeps_debt_and_clears_it() -> void:
	var job := _job(JobData.Condition.NO_CUT_LINE)
	GameState.active_job_id = job.id
	assert_eq(GameState.resolve_job(job, false), 0)
	assert_eq(GameState.debt, 80000)
	assert_eq(GameState.active_job_id, "")

func test_job_relief_that_clears_the_debt_wins_the_game() -> void:
	GameState.debt = 2000
	var relief := GameState.resolve_job(_job(JobData.Condition.NO_CUT_LINE), true)
	assert_eq(relief, 2000)
	assert_eq(GameState.debt, 0)
	assert_true(GameState.victory)

func test_job_state_persists() -> void:
	GameState.active_job_id = "quiet_water"
	GameState.job_declined_run = 4
	GameState._save_to("user://save_test.cfg")
	GameState.active_job_id = ""
	GameState.job_declined_run = -1
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.active_job_id, "quiet_water")
	assert_eq(GameState.job_declined_run, 4)

func test_old_save_without_jobs_loads_with_none_active() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "run_count", 6)
	cfg.save("user://save_test.cfg")
	GameState.active_job_id = "leftover"
	GameState.job_declined_run = 9
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.active_job_id, "")
	assert_eq(GameState.job_declined_run, -1)

func test_new_game_clears_jobs() -> void:
	GameState.active_job_id = "quiet_water"
	GameState.job_declined_run = 2
	GameState.new_game()
	assert_eq(GameState.active_job_id, "")
	assert_eq(GameState.job_declined_run, -1)

# --- run log ---

func test_run_log_shows_job_outcome() -> void:
	var record := {"run": 4, "zone": "axiom", "entries": [
		{"kind": "job", "title": "quiet water", "met": true, "relief": 2000},
	], "banked": 100, "forfeited": 0, "outcome": "surfaced"}
	var text := DiveFormat.run_log_text(record)
	assert_string_contains(text, "quiet water")
	assert_string_contains(text, "2000")

func test_job_result_lines() -> void:
	var job := _job(JobData.Condition.NO_CUT_LINE)
	assert_string_contains(DiveFormat.job_result(job.title, true, 3000), "complete")
	assert_string_contains(DiveFormat.job_result(job.title, false, 0), "failed")
