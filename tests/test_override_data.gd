extends GutTest
# Every hostile carries a playable override fight.

const STATE_BACKUP := "user://override_data_state_backup.cfg"

func _hostiles() -> Array[CatchData]:
	var out: Array[CatchData] = []
	for zone in ["axiom", "district7", "exchange"]:
		var dir := DirAccess.open("res://resources/catches/%s" % zone)
		for file in dir.get_files():
			if not file.ends_with(".tres"):
				continue
			var res = load("res://resources/catches/%s/%s" % [zone, file])
			if res is CatchData and res.behavior == CatchData.BehaviorType.AGGRESSIVE:
				out.append(res)
	return out

func test_there_are_ten_hostiles() -> void:
	assert_eq(_hostiles().size(), 10)

func test_every_hostile_has_valid_attacks_in_the_order_they_are_entered() -> void:
	for c in _hostiles():
		assert_gt(c.override_attacks.size(), 1, c.catch_name)
		for entry in c.override_attacks:
			var parts := entry.split("|")
			assert_eq(parts.size(), 2, "%s: %s" % [c.catch_name, entry])
			var code := parts[1]
			assert_true(OverrideSim.valid_lock(code), "%s: %s" % [c.catch_name, code])
			if c.override_twist == OverrideSim.TWIST_GHOST:
				assert_true(OverrideSim.valid_lock(OverrideSim.reversed(code)), "%s reversed: %s" % [c.catch_name, code])

func test_every_hostile_has_a_twist_art_and_a_fight_length_anchor() -> void:
	for c in _hostiles():
		assert_true(c.override_twist in ["", OverrideSim.TWIST_GHOST, OverrideSim.TWIST_REQUOTE], c.catch_name)
		assert_true(c.override_art in HostileWireframe.MODELS, c.catch_name)
		assert_between(c.anchor_strength, 10, 30, c.catch_name)

func test_sig_garbles_and_hardens_the_attacks() -> void:
	var c: CatchData = _hostiles()[0]
	var calm := OverrideTurn.config(c, 20.0, 80.0, 0.0, {}, false)
	var hot := OverrideTurn.config(c, 20.0, 80.0, 80.0, {}, false)
	assert_false(calm.garble)
	assert_true(hot.garble)
	assert_eq(hot.hit_damage, calm.hit_damage + 4)

func test_every_hostile_fight_can_be_played_to_a_landing() -> void:
	for c in _hostiles():
		var sim := OverrideSim.new(OverrideTurn.config(c, 0.0, 200.0, 0.0, {}, false), HaulSim.Lcg.new(11))
		var guard := 0
		while sim.phase != OverrideSim.DONE and guard < 5000:
			guard += 1
			if sim.phase == OverrideSim.CHARGE:
				for d in "dru":
					sim.press(d)
				if sim.phase == OverrideSim.CHARGE:
					for d in str(sim.lock.expected):
						sim.press(d)
			else:
				sim.step(0.1)
		assert_eq(sim.outcome, OverrideSim.WON, c.catch_name)

func test_the_guided_flag_is_saved() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.override_guided_done = true
	GameState.save()
	GameState.override_guided_done = false
	GameState.load_save()
	assert_true(GameState.override_guided_done)
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func test_wireframe_model_falls_back_by_catch_type() -> void:
	assert_eq(HostileWireframe.model_for("core", CatchData.CatchType.ENTITY), "core")
	assert_eq(HostileWireframe.model_for("", CatchData.CatchType.ENTITY), "ghost")
	assert_eq(HostileWireframe.model_for("nope", CatchData.CatchType.MECH), "drone")
