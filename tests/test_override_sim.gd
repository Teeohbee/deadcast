extends GutTest
# OverrideSim: the override combo's rules, driven with scripted presses and time.

const DRONE_ATTACKS := [
	{ "name": "SPIKE TRACE", "code": "urr" },
	{ "name": "LOCKDOWN PULSE", "code": "lurl" },
]

func _sim(overrides := {}) -> OverrideSim:
	var config := {
		"attacks": DRONE_ATTACKS, "anchor": 20, "hit_damage": 12, "twist": "", "grow": false,
		"guided": false, "garble": false, "tension": 30.0, "max_tension": 80.0, "rig": {},
	}
	config.merge(overrides, true)
	return OverrideSim.new(config, HaulSim.Lcg.new(7))

func _enter(sim: OverrideSim, code: String) -> Array[String]:
	var events: Array[String] = []
	for dir in code:
		events.append_array(sim.press(dir))
	return events

func _to_charge(sim: OverrideSim) -> void:
	while sim.phase != OverrideSim.CHARGE:
		sim.step(0.05)

func test_no_rig_code_is_a_prefix_of_another() -> void:
	for a in OverrideSim.RIG:
		for b in OverrideSim.RIG:
			if a != b:
				assert_false(OverrideSim.clashes(OverrideSim.RIG[a], OverrideSim.RIG[b]), "%s vs %s" % [a, b])

func test_it_winds_up_then_charges_the_first_attack() -> void:
	var sim := _sim()
	assert_eq(sim.phase, OverrideSim.GAP)
	_to_charge(sim)
	assert_eq(sim.lock.name, "SPIKE TRACE")
	assert_eq(sim.lock.expected, "urr")
	assert_almost_eq(sim.dur, OverrideSim.CHARGE_BASE + OverrideSim.CHARGE_PER_INPUT * 3, 0.001)

func test_entering_the_lock_nulls_the_attack() -> void:
	var sim := _sim()
	_to_charge(sim)
	var events := _enter(sim, "urr")
	assert_has(events, "lock")
	assert_eq(sim.phase, OverrideSim.GAP)
	assert_eq(sim.nulled, 1)
	assert_eq(sim.tension, 30.0, "nulling costs nothing")

func test_the_hit_lands_when_the_charge_runs_out() -> void:
	var sim := _sim()
	_to_charge(sim)
	var events: Array[String] = []
	while sim.phase == OverrideSim.CHARGE:
		events.append_array(sim.step(0.05))
	assert_has(events, "hit")
	assert_eq(sim.tension, 42.0)
	assert_eq(sim.hits_taken, 1)

func test_break_hits_twice_as_hard_while_it_charges() -> void:
	var sim := _sim()
	_enter(sim, "dru") # in the wind-up
	assert_eq(sim.anchor, 19)
	_to_charge(sim)
	_enter(sim, "dru")
	assert_eq(sim.anchor, 17, "exposed: -2")
	assert_eq(sim.tension, 34.0, "+2T per BREAK")

func test_a_wrong_press_resets_the_buffer_and_strains_the_line() -> void:
	var sim := _sim()
	_to_charge(sim)
	sim.press("u")
	var events := sim.press("d") # "ud" matches nothing: the lock is urr, shock isn't loaded
	assert_has(events, "wrong")
	assert_eq(sim.buffer, "")
	assert_eq(sim.tension, 32.0)
	_enter(sim, "urr")
	assert_eq(sim.nulled, 1, "the lock can still go in after a reset")

func test_the_buffer_tracks_every_candidate_at_once() -> void:
	var sim := _sim({ "rig": { "shock": 1 } })
	_to_charge(sim)
	sim.press("u")
	var ids := sim.candidates().map(func(c: Dictionary) -> String: return c.id)
	assert_eq(ids, ["lock", "shock"])
	sim.press("d")
	ids = sim.candidates().map(func(c: Dictionary) -> String: return c.id)
	assert_eq(ids, ["shock"])
	assert_eq(sim.lock_progress(), 0, "switching to shock abandons the lock")

func test_landing_the_anchor_wins() -> void:
	var sim := _sim({ "anchor": 2 })
	_to_charge(sim)
	var events := _enter(sim, "dru")
	assert_has(events, "won")
	assert_eq(sim.outcome, OverrideSim.WON)
	assert_eq(sim.phase, OverrideSim.DONE)

func test_taking_hits_past_the_max_snaps() -> void:
	var sim := _sim({ "tension": 75.0 })
	_to_charge(sim)
	var events: Array[String] = []
	while sim.phase == OverrideSim.CHARGE:
		events.append_array(sim.step(0.05))
	assert_has(events, "snap")
	assert_eq(sim.outcome, OverrideSim.SNAP)

func test_isolate_flees() -> void:
	var sim := _sim()
	_enter(sim, "dddd")
	assert_eq(sim.outcome, OverrideSim.FLED)

func test_provisions_are_codes_while_they_last() -> void:
	var sim := _sim({ "rig": { "shock": 1, "splice": 1, "decoy": 1 } })
	_to_charge(sim)
	_enter(sim, "udud")
	assert_eq(sim.anchor, 16, "shock: -4 while exposed")
	assert_false(sim.available("shock"), "one use loaded")
	_enter(sim, "llr")
	assert_eq(sim.tension, 10.0, "splice vents 20T")
	_enter(sim, "rrl")
	assert_eq(sim.outcome, OverrideSim.SLIPPED)

func test_unloaded_provisions_are_not_codes() -> void:
	var sim := _sim()
	assert_false(sim.available("shock"))
	assert_false(sim.available("splice"))
	assert_true(sim.available("break"))
	assert_true(sim.available("isolate"))

func test_a_ghost_reverses_then_hides_its_locks() -> void:
	var sim := _sim({ "twist": OverrideSim.TWIST_GHOST })
	_to_charge(sim)
	assert_eq(sim.lock.mode, OverrideSim.MODE_REVERSED)
	assert_eq(sim.lock.expected, "rru", "entered right to left")
	_enter(sim, "rru")
	_to_charge(sim)
	assert_eq(sim.lock.mode, OverrideSim.MODE_HIDDEN)
	assert_eq(sim.lock.expected, "lurl")

func test_a_volatile_lock_requotes_what_you_have_not_entered() -> void:
	var sim := _sim({ "twist": OverrideSim.TWIST_REQUOTE, "attacks": [{ "name": "MARGIN CALL", "code": "rulr" }] })
	_to_charge(sim)
	sim.press("r")
	var events: Array[String] = []
	while not sim.lock.requoted:
		events.append_array(sim.step(0.05))
	assert_has(events, "requote")
	assert_true(str(sim.lock.expected).begins_with("r"), "entered arrows stay")
	assert_ne(sim.lock.expected, "rulr")
	assert_true(OverrideSim.valid_lock(sim.lock.expected))
	assert_eq(sim.lock_progress(), 1, "progress survives the re-quote")

func test_locks_grow_over_the_fight_and_stay_valid() -> void:
	var sim := _sim({ "grow": true, "twist": OverrideSim.TWIST_GHOST })
	var lengths: Array[int] = []
	for i in 6:
		_to_charge(sim)
		lengths.append(str(sim.lock.code).length())
		assert_true(OverrideSim.valid_lock(sim.lock.expected))
		_enter(sim, sim.lock.expected)
	assert_eq(lengths, [3, 4, 4, 5, 5, 6] as Array[int])

func test_the_guided_fight_unlocks_the_rig_a_round_at_a_time() -> void:
	var sim := _sim({ "guided": true, "rig": { "shock": 1 } })
	_to_charge(sim)
	assert_false(sim.available("break"), "round 1: the lock only")
	_enter(sim, "urr")
	_to_charge(sim)
	assert_true(sim.available("break"), "round 2: BREAK")
	assert_false(sim.available("shock"))
	_enter(sim, "lurl")
	_to_charge(sim)
	assert_true(sim.available("shock"), "round 3: everything")
	assert_true(sim.available("isolate"))
