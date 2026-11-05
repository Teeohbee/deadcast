# tests/test_relay_dive_lines.gd
extends GutTest

var _random: RandomNumberGenerator

func before_each() -> void:
	_random = RandomNumberGenerator.new()
	_random.seed = 7

func _pick(moment: String, context: Dictionary, first_dive: bool, said: Array = []) -> String:
	return RelayDiveLines.pick(moment, context, first_dive, said, _random)

func test_the_first_dive_always_speaks_at_the_cast() -> void:
	assert_eq(_pick("cast", {"zone_id": "district7"}, true), RelayDiveLines.DIVE_ONE.cast)

func test_the_first_contact_of_the_first_dive_is_named_by_type() -> void:
	assert_string_contains(_pick("contact", {"first_contact": true, "catch_type": CatchData.CatchType.ENTITY, "catch_name": "Tenant Echo"}, true), "echo.")
	assert_string_contains(_pick("contact", {"first_contact": true, "catch_type": CatchData.CatchType.ENTITY, "catch_name": "Mariana"}, true), "ghost.")
	assert_string_contains(_pick("contact", {"first_contact": true, "catch_type": CatchData.CatchType.DATA, "catch_name": "Ledger"}, true), "first one's always ugly")

func test_later_contacts_on_the_first_dive_are_quiet() -> void:
	assert_eq(_pick("contact", {"first_contact": false, "catch_type": CatchData.CatchType.DATA}, true), "")

func test_first_dive_hauls_react_to_how_they_landed() -> void:
	assert_eq(_pick("haul", {"outcome": "messy"}, true), RelayDiveLines.DIVE_ONE.haul_messy)
	assert_eq(_pick("haul", {"outcome": "perfect"}, true), RelayDiveLines.DIVE_ONE.haul_clean)

func test_the_first_dive_never_repeats_a_line() -> void:
	assert_eq(_pick("haul", {"outcome": "clean"}, true, [RelayDiveLines.DIVE_ONE.haul_clean]), "")

func test_later_dives_speak_only_sometimes() -> void:
	var spoken := 0
	for attempt in 200:
		if _pick("contact", {}, false) != "":
			spoken += 1
	assert_between(spoken, 30, 90)

func test_later_dives_stop_after_the_cap() -> void:
	var said := ["a", "b", "c", "d"]
	for attempt in 50:
		assert_eq(_pick("snapped", {}, false, said), "")

func test_later_cast_lines_can_name_the_zone() -> void:
	var heard := {}
	for attempt in 300:
		heard[_pick("cast", {"zone_id": "axiom"}, false)] = true
	assert_true(heard.has(RelayDiveLines.POOLS.cast_axiom[0]))
	assert_false(heard.has(RelayDiveLines.POOLS.cast_exchange[0]))

func test_a_light_checkpoint_or_small_haul_says_nothing_on_later_dives() -> void:
	for attempt in 50:
		assert_eq(_pick("checkpoint", {"tension_ratio": 0.2}, false), "")
		assert_eq(_pick("surfaced", {"credits": 200}, false), "")
