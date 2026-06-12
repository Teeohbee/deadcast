extends GutTest

func _fight(corruption := 0.0, shock := false) -> OverloadFight:
	return OverloadFight.new(80, 20, 3, corruption, shock)

func test_initial_state() -> void:
	var f := _fight()
	assert_eq(f.tension, 20)
	assert_eq(f.starting_tension, 20)
	assert_eq(f.anchor, 3)
	assert_eq(f.turn, 1)

func test_backlash_scales_with_corruption() -> void:
	assert_eq(_fight(0.0).backlash_amount(), 5)
	assert_eq(_fight(100.0).backlash_amount(), 10)

func test_apply_backlash_raises_tension() -> void:
	var f := _fight()
	var amount := f.apply_backlash()
	assert_eq(f.tension, 20 + amount)

func test_snapped_when_tension_hits_max() -> void:
	var f := OverloadFight.new(80, 79, 3, 0.0, false)
	f.apply_backlash()
	assert_true(f.is_snapped())
	assert_eq(f.tension, 80, "tension clamps at max")

func test_pick_commands_always_ends_with_isolate_feed() -> void:
	var f := _fight()
	for i in 20:
		var cmds := f.pick_commands()
		assert_eq(cmds.size(), 4)
		assert_eq(cmds[-1].id, "ISOLATE_FEED")

func test_pick_commands_includes_overload_core_only_with_shock() -> void:
	var without := _fight(0.0, false)
	for i in 30:
		for cmd in without.pick_commands():
			assert_ne(cmd.id, "OVERLOAD_CORE")
	var with_shock := _fight(0.0, true)
	var seen := false
	for i in 50:
		for cmd in with_shock.pick_commands():
			if cmd.id == "OVERLOAD_CORE":
				seen = true
	assert_true(seen, "OVERLOAD_CORE should appear in the pool when shock is available")

func test_execute_guaranteed_command_applies_costs() -> void:
	var f := _fight()
	var result := f.execute(OverloadFight.BASE_COMMANDS[0])  # DECRYPT_NODE +10T -1 anchor
	assert_true(result.succeeded)
	assert_eq(f.tension, 30)
	assert_eq(f.anchor, 2)

func test_execute_failure_applies_backlash_not_anchor() -> void:
	var f := _fight()
	f.rng.seed = 1  # deterministic
	# SYNGAS_FLOOD: 50% success, fail_t 30. Force failure by finding a seed that fails.
	var cmd := OverloadFight.BASE_COMMANDS[2]
	var failed_seen := false
	for seed_val in 50:
		var g := _fight()
		g.rng.seed = seed_val
		var result := g.execute(cmd)
		if not result.succeeded:
			failed_seen = true
			assert_eq(g.tension, 50, "fail applies t_cost(0) + fail_t(30) on top of 20")
			assert_eq(g.anchor, 3, "anchor untouched on failure")
			break
	assert_true(failed_seen, "expected at least one failing seed in 50")

func test_captured_when_anchor_zero() -> void:
	var f := _fight()
	f.anchor = 1
	f.execute(OverloadFight.BASE_COMMANDS[0])  # -1 anchor, guaranteed
	assert_true(f.is_captured())
