extends GutTest
# OverrideRun: one hostile encounter on screen. Tests drive press() and tick().

const DT := 1.0 / 60.0
const ATTACKS := [{ "name": "SPIKE TRACE", "code": "urr" }, { "name": "LOCKDOWN PULSE", "code": "lurl" }]

var _results: Array = []
var _tensions: Array = []

func before_each() -> void:
	_results.clear()
	_tensions.clear()
	Audio.clear_cue_history()

func _run(overrides := {}) -> OverrideRun:
	var config := { "attacks": ATTACKS, "anchor": 6, "hit_damage": 12, "grow": false,
		"tension": 30.0, "max_tension": 80.0, "rig": { "shock": 1 } }
	config.merge(overrides, true)
	var run := OverrideRun.new()
	run.setup(config, "Axiom Security Drone", "class: [MECH]", OverrideArt.DRONE,
		{ "break": "-1 anchor", "shock": "-2 anchor" }, HaulSim.Lcg.new(5))
	add_child_autofree(run)
	run.set_process(false)
	run.finished.connect(func(r: Dictionary) -> void: _results.append(r))
	run.tension_changed.connect(func(t: float) -> void: _tensions.append(t))
	return run

func _to_charge(run: OverrideRun) -> void:
	while run.sim.phase != OverrideSim.CHARGE:
		run.tick(DT)

func _enter(run: OverrideRun, code: String) -> void:
	for d in code:
		run.press(d)

func test_nulling_an_attack_plays_and_logs() -> void:
	var run := _run()
	_to_charge(run)
	assert_has(Audio.cue_history, "override_charge")
	_enter(run, "urr")
	assert_has(Audio.cue_history, "override_input")
	assert_has(Audio.cue_history, "override_null")
	assert_string_contains(run.view.log_lines[-1].text, "OVERRIDE ACCEPTED")

func test_the_rail_hears_every_change_in_tension() -> void:
	var run := _run()
	_to_charge(run)
	_enter(run, "dru")
	assert_eq(_tensions, [32.0])
	while run.sim.phase == OverrideSim.CHARGE:
		run.tick(DT)
	assert_eq(_tensions, [32.0, 44.0], "the hit lands on the line")

func test_winning_shows_the_card_and_waits_for_a_press() -> void:
	var run := _run({ "anchor": 2 })
	_to_charge(run)
	_enter(run, "dru")
	assert_true(run.result_card.visible)
	assert_eq(run.result.outcome, "won")
	run.continue_pressed()
	assert_eq(_results.size(), 0, "a moment before a press moves on")
	for i in 30:
		run.tick(DT)
	run.continue_pressed()
	run.continue_pressed()
	assert_eq(_results.size(), 1, "finished emits once")

func test_the_result_reports_provisions_spent() -> void:
	var run := _run({ "anchor": 4 })
	_to_charge(run)
	_enter(run, "udud") # shock while exposed: -4
	assert_eq(run.result.outcome, "won")
	assert_eq(run.result.used, { "shock": 1 })

func test_a_wrong_press_is_heard_and_logged() -> void:
	var run := _run()
	_to_charge(run)
	run.press("l") # nothing starts with l (no splice loaded, lock is urr)
	assert_has(Audio.cue_history, "override_wrong")
	assert_string_contains(run.view.log_lines[-1].text, "bad input")

func test_the_d_pad_actions_drive_the_buffer() -> void:
	var run := _run()
	_to_charge(run)
	var up := InputEventAction.new()
	up.action = "ui_up"
	up.pressed = true
	run._input(up)
	assert_eq(run.sim.buffer, "u")

func test_the_guided_fight_explains_itself() -> void:
	var run := _run({ "guided": true })
	assert_string_contains(run.view.hint, "enter the lock")
	_to_charge(run)
	_enter(run, "urr")
	_to_charge(run)
	assert_string_contains(run.view.hint, "BREAK unlocked")

func test_the_view_draws_every_phase_without_errors() -> void:
	var run := _run({ "twist": OverrideSim.TWIST_GHOST, "garble": true })
	await wait_process_frames(1)
	_to_charge(run)
	run.press("r")
	await wait_process_frames(1)
	_enter(run, "ru")
	await wait_process_frames(1)
	_to_charge(run) # hidden lock
	await wait_process_frames(1)
	_enter(run, "dddd")
	await wait_process_frames(1)
	assert_eq(run.result.outcome, "fled")
