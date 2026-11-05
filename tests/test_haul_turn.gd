extends GutTest
# The haul turn (District 7 spike): pick an option on the card, then haul it up. The
# haul result scales what the option pays and costs, replacing the resist/fail dice.

const PENSION := "res://resources/catches/district7/encrypted_pension_record.tres"

func _option(credits: int, tension: int, cuts := false) -> CatchOption:
	var o := CatchOption.new()
	o.credit_value = credits
	o.tension_delta = tension
	o.cuts_line = cuts
	return o

func _catch(haul := true) -> CatchData:
	var c := CatchData.new()
	c.haul_enabled = haul
	c.haul_weight = 1.2
	c.haul_slip = 0.6
	c.haul_tempo = 1.0
	c.haul_erratic = false
	return c

func _zone(haul := true) -> ZoneData:
	var z := ZoneData.new()
	z.haul_enabled = haul
	return z

func _result(outcome: String, hits := 0) -> Dictionary:
	return { "outcome": outcome, "hits": hits }

# --- which options haul ---

func test_options_that_pay_haul_in_a_haul_zone() -> void:
	assert_true(HaulTurn.hauls(_zone(), _catch(), _option(200, 5)))
	assert_true(HaulTurn.hauls(_zone(), _catch(), _option(150, 0)), "a free skim still has to come up")

func test_release_cut_line_and_other_zones_skip_the_haul() -> void:
	assert_false(HaulTurn.hauls(_zone(), _catch(), _option(0, 0)), "release")
	assert_false(HaulTurn.hauls(_zone(), _catch(), _option(0, 0, true)), "cut line")
	assert_false(HaulTurn.hauls(_zone(false), _catch(), _option(200, 5)), "zone without hauls")
	assert_false(HaulTurn.hauls(_zone(), _catch(false), _option(200, 5)), "contact without haul data")
	assert_false(HaulTurn.hauls(null, _catch(), _option(200, 5)))

func test_ghosts_haul_only_when_you_tear_something_out() -> void:
	var ghost := _catch()
	ghost.catch_type = CatchData.CatchType.ENTITY
	assert_true(HaulTurn.hauls(_zone(), ghost, _option(800, 15)), "harvest hauls")
	assert_false(HaulTurn.hauls(_zone(), ghost, _option(350, 0)), "talking is free")
	assert_false(HaulTurn.hauls(_zone(), ghost, _option(0, 0)), "leaving is free")

func test_cargo_hauls_even_without_strain() -> void:
	assert_true(HaulTurn.hauls(_zone(), _catch(), _option(150, 0)))

# --- payout table ---

func test_perfect_pays_a_quarter_extra() -> void:
	assert_eq(HaulTurn.payout(_option(400, 5), _result("perfect")), { "credits": 500, "tension": 5 })

func test_clean_pays_face_value() -> void:
	assert_eq(HaulTurn.payout(_option(400, 5), _result("clean")), { "credits": 400, "tension": 5 })

func test_messy_loses_a_fifth_per_hit_and_strains_the_line() -> void:
	assert_eq(HaulTurn.payout(_option(500, 10), _result("messy", 1)), { "credits": 400, "tension": 15 })
	assert_eq(HaulTurn.payout(_option(500, 10), _result("messy", 2)), { "credits": 300, "tension": 20 })

func test_messy_never_drops_below_forty_percent() -> void:
	assert_eq(HaulTurn.payout(_option(500, 10), _result("messy", 5)).credits, 200)

func test_snap_loses_the_payload_and_jolts_the_line() -> void:
	assert_eq(HaulTurn.payout(_option(500, 10), _result("snap")), { "credits": 0, "tension": 35 })

# --- the haul nudge comes from strain ---

func test_heavy_strain_options_load_half_as_fast_again() -> void:
	var d := HaulTurn.dials(_catch(), _option(550, 15))
	assert_almost_eq(d.weight, 1.8, 0.0001)
	assert_eq(d.slip, 0.6)
	assert_eq(d.tempo, 1.0)
	assert_eq(d.erratic, false)

func test_lighter_options_use_the_contacts_own_dials() -> void:
	assert_almost_eq(HaulTurn.dials(_catch(), _option(200, 10)).weight, 1.2, 0.0001)

# --- card words ---

func test_strain_words() -> void:
	assert_eq(HaulTurn.strain_word(0), "")
	assert_eq(HaulTurn.strain_word(5), "LIGHT")
	assert_eq(HaulTurn.strain_word(8), "MODERATE")
	assert_eq(HaulTurn.strain_word(10), "MODERATE")
	assert_eq(HaulTurn.strain_word(15), "HEAVY")
	assert_eq(HaulTurn.strain_word(25), "HEAVY")

func test_value_bands_are_the_same_in_every_zone() -> void:
	assert_eq(HaulTurn.value_word(0), "")
	assert_eq(HaulTurn.value_word(150), "LOW")
	assert_eq(HaulTurn.value_word(300), "LOW")
	assert_eq(HaulTurn.value_word(301), "MID")
	assert_eq(HaulTurn.value_word(800), "MID")
	assert_eq(HaulTurn.value_word(801), "HIGH")
	assert_eq(HaulTurn.value_word(1500), "HIGH")
	assert_eq(HaulTurn.value_word(1501), "PRIME")
	assert_eq(HaulTurn.value_word(4000), "PRIME")

func test_haul_feel_reads_the_contacts_dials() -> void:
	var c := _catch()
	assert_eq(HaulTurn.feel(c), "steady · slips slowly")
	c.haul_erratic = true
	c.haul_slip = 1.6
	c.haul_weight = 1.9
	assert_eq(HaulTurn.feel(c), "erratic · slips fast · loads fast")
	c.haul_erratic = false
	c.haul_tempo = 0.6
	c.haul_slip = 1.0
	c.haul_weight = 0.7
	assert_eq(HaulTurn.feel(c), "slow hits · loads light")

func test_first_ever_dive_hauls_on_tutorial() -> void:
	assert_eq(HaulTurn.difficulty(0), "tutorial")
	assert_eq(HaulTurn.difficulty(1), "normal")

# --- in a real dive ---

func test_a_haul_in_a_real_dive_pays_its_result_and_clears_the_screen() -> void:
	GameState.selected_zone = "district7"
	var dive: Node = load("res://scenes/dive_run/DiveRun.tscn").instantiate()
	add_child_autofree(dive)
	await wait_process_frames(2)
	var pension: CatchData = (load(PENSION) as CatchData).duplicate()
	pension.haul_enabled = true
	var careful: CatchOption = pension.options[1]
	var credits_before: int = dive._run_credits
	var tension_before: float = dive.line_system.tension
	dive._resolve_haul(careful, pension, "careful_crack")
	await wait_process_frames(2)
	var runs := dive.get_children().filter(func(n: Node) -> bool: return n is HaulRun)
	assert_eq(runs.size(), 1, "the haul is on screen")
	if runs.is_empty():
		return
	var run: HaulRun = runs[0]
	run.finished.emit({ "outcome": "messy", "hits": 1, "fragments": [], "read": 0, "total": 0 })
	await wait_process_frames(2)
	assert_eq(dive._run_credits - credits_before, int(careful.credit_value * 0.8))
	assert_almost_eq(dive.line_system.tension - tension_before, float(careful.tension_delta + 5), 0.01)
	assert_false(is_instance_valid(run), "haul screen cleared")

# --- District 7 data ---

func _assert_zone_ready_to_haul(zone_path: String, min_hauled: int) -> void:
	var zone: ZoneData = load(zone_path)
	assert_true(zone.haul_enabled, zone_path + " hauls")
	var hauled := 0
	for c in zone.catches:
		if not c.haul_enabled:
			continue
		hauled += 1
		assert_ne(c.behavior, CatchData.BehaviorType.AGGRESSIVE, c.catch_name + " fights, it doesn't haul")
		assert_true(c.options.any(func(o: CatchOption) -> bool: return HaulTurn.hauls(zone, c, o)), c.catch_name + " has a hauled option")
		assert_between(c.fragments.size(), 6, 8, c.catch_name + " fragment pool")
		for w in c.fragments_always:
			assert_has(c.fragments, w, c.catch_name + " always-included fragment is in the pool")
		for seed in range(1, 21):
			var drawn := HaulFragments.draw(c.fragments, c.fragments_always, HaulSim.Lcg.new(seed))
			var block := HaulFragments.new(drawn, HaulView.ROWS, HaulSim.Lcg.new(seed))
			assert_eq(block.fragments.size(), drawn.size(), "%s fragments fit (seed %d)" % [c.catch_name, seed])
	assert_gt(hauled, min_hauled, zone_path + " hauled contacts")

func test_district7_hauls_and_its_haul_contacts_are_ready_to_haul() -> void:
	_assert_zone_ready_to_haul("res://resources/zones/district7.tres", 10)

func test_exchange_hauls_and_its_haul_contacts_are_ready_to_haul() -> void:
	_assert_zone_ready_to_haul("res://resources/zones/exchange.tres", 10)

func test_axiom_hauls_and_its_haul_contacts_are_ready_to_haul() -> void:
	_assert_zone_ready_to_haul("res://resources/zones/axiom.tres", 9)

func test_cargo_that_pays_and_strains_always_hauls() -> void:
	for path in ["res://resources/zones/district7.tres", "res://resources/zones/exchange.tres", "res://resources/zones/axiom.tres"]:
		var zone: ZoneData = load(path)
		for c in zone.catches:
			var tears := c.options.any(func(o: CatchOption) -> bool: return o.credit_value > 0 and o.tension_delta > 0)
			var exempt: bool = c.behavior == CatchData.BehaviorType.AGGRESSIVE or c.catch_type == CatchData.CatchType.ENTITY \
				or c.catch_name == "Rival Fisher's Line" # a person on the other end, not cargo
			if tears and not exempt:
				assert_true(c.haul_enabled, c.catch_name + " pays and strains, so it hauls")

## Without dice, an option that costs more strain and pays less than another on the same
## card is never worth picking.
func _beaten_options(zone_path: String) -> Array[String]:
	var zone: ZoneData = load(zone_path)
	var out: Array[String] = []
	for c in zone.catches:
		var paying := c.options.filter(func(o: CatchOption) -> bool: return o.credit_value > 0)
		for a in paying:
			for b in paying:
				if a != b and b.tension_delta <= a.tension_delta and b.credit_value >= a.credit_value \
						and (b.tension_delta != a.tension_delta or b.credit_value != a.credit_value):
					out.append("%s: %s loses to %s" % [c.catch_name, a.label, b.label])
	return out

func test_no_district7_option_is_strictly_beaten() -> void:
	assert_eq(_beaten_options("res://resources/zones/district7.tres"), [])

func test_no_exchange_option_is_strictly_beaten() -> void:
	assert_eq(_beaten_options("res://resources/zones/exchange.tres"), [])

func test_no_axiom_option_is_strictly_beaten() -> void:
	assert_eq(_beaten_options("res://resources/zones/axiom.tres"), [])
