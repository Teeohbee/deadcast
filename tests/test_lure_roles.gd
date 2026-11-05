# tests/test_lure_roles.gd
# Each lure answers one question (shop economy plan, PR B4):
# scout / escape / fight / survive / bait.
extends GutTest

const DT := 1.0 / 60.0
const DIALS := { "weight": 1.0, "slip": 1.0, "tempo": 1.0, "erratic": false }

func _lure(id: String) -> LureData:
	return load("res://resources/lures/%s.tres" % id)

func test_the_roster_prices() -> void:
	assert_eq(_lure("deep_pulse").purchase_cost, 300)
	assert_eq(_lure("decoy_swarm").purchase_cost, 400)
	assert_eq(_lure("shock_lure").purchase_cost, 400)
	assert_eq(_lure("splice_kit").purchase_cost, 500)
	assert_eq(_lure("ghost_bait").purchase_cost, 600)

func test_the_splice_kit_vents_strain() -> void:
	assert_eq(_lure("splice_kit").effect, LureData.LureEffect.SPLICE)
	assert_eq(LureData.SPLICE_VENT_T, 20)

func test_okeke_stocks_the_splice_kit() -> void:
	assert_true("res://resources/lures/splice_kit.tres" in preload("res://scenes/barge_hub/VendorsLayout.gd").LURE_PATHS)

# --- fight: shock ---

func _haul_until_first_hit(sim: HaulSim) -> Array[String]:
	for i in 60 * 10:
		var events := sim.step(DT, true)
		if events.has("hit") or events.has("shocked"):
			return events
	return []

func test_a_shock_charge_absorbs_a_hit_taken_while_hauling() -> void:
	var sim := HaulSim.new(DIALS, "normal", HaulSim.Lcg.new(7))
	sim.shield = 1
	var events := _haul_until_first_hit(sim)
	assert_true(events.has("shocked"))
	assert_eq(sim.hits, 0)
	assert_eq(sim.shocked, 1)
	assert_eq(sim.shield, 0)

func test_without_a_charge_the_hit_lands() -> void:
	var sim := HaulSim.new(DIALS, "normal", HaulSim.Lcg.new(7))
	var events := _haul_until_first_hit(sim)
	assert_true(events.has("hit"))
	assert_eq(sim.hits, 1)

func test_shock_always_offers_overload_core_in_a_fight() -> void:
	var fight := OverloadFight.new(80, 20, 3, 0.0, true)
	for i in 30:
		var ids := fight.pick_commands().map(func(cmd: Dictionary) -> String: return cmd.id)
		assert_true("OVERLOAD_CORE" in ids)
		assert_eq(ids.size(), 4)
		assert_eq(ids[-1], "ISOLATE_FEED")

# --- escape: decoy ---

func test_a_decoy_replacement_is_never_hostile() -> void:
	for i in 60:
		var c := CatchPool.draw_replacement("axiom", CatchData.Layer.DEEP, 50.0)
		assert_ne(c.behavior, CatchData.BehaviorType.AGGRESSIVE, c.catch_name)

func test_the_decoy_command_reads_as_an_escape() -> void:
	var label := DiveFormat.command_label(4, OverloadFight.DECOY_SLIP)
	assert_string_contains(label, "DECOY_SLIP")
	assert_string_contains(label, "uses a decoy")

# --- scout: deep pulse at the checkpoint ---

func test_scanning_the_next_layer_is_what_you_descend_into() -> void:
	var column := DiveColumn.new("district7", 150)
	column.generate_current_layer(0.0)
	var scanned := column.preview_next_layer(0.0)
	assert_eq(scanned.size(), 3, "mid layer has three slots")
	column.descend(0.0)
	assert_eq(column.slots, scanned)

func test_a_cleared_preview_draws_fresh() -> void:
	var column := DiveColumn.new("district7", 150)
	column.generate_current_layer(0.0)
	column.preview_next_layer(0.0)
	column.clear_preview()
	assert_eq(column.preview_slots(), [] as Array[CatchData])
