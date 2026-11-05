# tests/test_rod_traits.gd
# Rods are a tension cap plus one trait (shop economy plan, PR B3).
extends GutTest

const SCRAP := preload("res://resources/rods/scrap_rod.tres")
const MONOCARBON := preload("res://resources/rods/monocarbon_rig.tres")
const GHOST_LINE := preload("res://resources/rods/ghost_line.tres")

func test_the_roster_is_cap_plus_one_trait() -> void:
	assert_eq([SCRAP.tension_cap, SCRAP.purchase_cost, SCRAP.line_trait], [80, 0, RodData.LineTrait.NONE])
	assert_eq([MONOCARBON.tension_cap, MONOCARBON.purchase_cost, MONOCARBON.line_trait], [100, 2500, RodData.LineTrait.BRAKE])
	assert_eq([GHOST_LINE.tension_cap, GHOST_LINE.purchase_cost, GHOST_LINE.line_trait], [110, 5500, RodData.LineTrait.QUIET])

func test_trait_words() -> void:
	assert_eq(SCRAP.trait_label(), "")
	assert_eq(MONOCARBON.trait_label(), "BRAKE")
	assert_eq(GHOST_LINE.trait_label(), "QUIET")

func test_only_the_ghost_line_quietens_signal_loss() -> void:
	assert_eq(SCRAP.sig_scale(), 1.0)
	assert_eq(MONOCARBON.sig_scale(), 1.0)
	assert_eq(GHOST_LINE.sig_scale(), 0.5)

func test_scaled_signal_loss_rounds_and_never_hides_a_cost() -> void:
	assert_eq(GHOST_LINE.scaled_sig(15), 8)
	assert_eq(GHOST_LINE.scaled_sig(1), 1)
	assert_eq(GHOST_LINE.scaled_sig(0), 0)
	assert_eq(SCRAP.scaled_sig(15), 15)

# --- brake ---

func test_the_brake_turns_a_snap_into_a_messy_haul() -> void:
	var braked := HaulTurn.apply_brake({"outcome": "snap", "hits": 2}, true)
	assert_true(braked.braked)
	assert_eq(braked.result.outcome, "messy")
	assert_eq(braked.result.hits, 2)

func test_a_braked_snap_counts_at_least_one_hit() -> void:
	var braked := HaulTurn.apply_brake({"outcome": "snap", "hits": 0}, true)
	assert_eq(braked.result.hits, 1)

func test_no_brake_leaves_the_snap() -> void:
	var braked := HaulTurn.apply_brake({"outcome": "snap", "hits": 2}, false)
	assert_false(braked.braked)
	assert_eq(braked.result.outcome, "snap")

func test_the_brake_ignores_hauls_that_landed() -> void:
	var braked := HaulTurn.apply_brake({"outcome": "clean", "hits": 0}, true)
	assert_false(braked.braked)
	assert_eq(braked.result.outcome, "clean")

# --- display ---

func test_contact_card_shows_the_quietened_signal_cost() -> void:
	var catch_data := CatchData.new()
	catch_data.catch_name = "x"
	catch_data.corruption_gain = 20
	assert_string_contains(DiveFormat.contact_card(catch_data, false, 10), "SIG IMPACT: -10%")
	assert_string_contains(DiveFormat.contact_card(catch_data), "SIG IMPACT: -20%")
