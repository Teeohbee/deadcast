# tests/test_unlocks.gd
extends GutTest

var _saved_run_count: int
var _saved_freezer_base: int

func before_each() -> void:
	_saved_run_count = GameState.run_count
	_saved_freezer_base = GameState.freezer_base
	GameState.freezer_base = 0

func after_each() -> void:
	GameState.run_count = _saved_run_count
	GameState.freezer_base = _saved_freezer_base

func _open_after(runs: int) -> Array[String]:
	GameState.run_count = runs
	return Unlocks.open_features()

func test_a_new_operator_sees_the_deck_bunk_relay_and_district_7() -> void:
	assert_eq(_open_after(0), ["deck", "bunk", "relay", "district7"] as Array[String])

func test_first_run_opens_workshop_and_vendors() -> void:
	var opened := Unlocks.newly_opened(_open_after(0), _open_after(1))
	assert_eq(opened, ["workshop", "vendors"] as Array[String])

func test_second_run_opens_the_exchange_and_the_freezer() -> void:
	var opened := Unlocks.newly_opened(_open_after(1), _open_after(2))
	assert_eq(opened, ["exchange", "freezer"] as Array[String])

func test_third_run_opens_decrypt() -> void:
	assert_eq(Unlocks.newly_opened(_open_after(2), _open_after(3)), ["decrypt"] as Array[String])

func test_fourth_run_opens_axiom() -> void:
	assert_eq(Unlocks.newly_opened(_open_after(3), _open_after(4)), ["axiom"] as Array[String])

func test_an_established_save_sees_everything() -> void:
	var features := _open_after(12)
	for feature in ["deck", "bunk", "workshop", "vendors", "relay", "decrypt",
			"district7", "exchange", "axiom", "freezer"]:
		assert_has(features, feature)

func test_freezer_opens_early_with_a_first_deposit() -> void:
	GameState.run_count = 1
	assert_false(Unlocks.is_freezer_open())
	GameState.freezer_base = 350
	assert_true(Unlocks.is_freezer_open())

func test_every_feature_that_opens_later_has_an_announcement() -> void:
	for feature in _open_after(12):
		if feature in ["deck", "bunk", "relay", "district7"]:
			continue
		assert_ne(Unlocks.announcement_for(feature), "", feature)

func test_unknown_ids_are_open() -> void:
	GameState.run_count = 0
	assert_true(Unlocks.is_tab_open("dive"))
