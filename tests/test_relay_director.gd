# tests/test_relay_director.gd
extends GutTest

var _saved := {}

func before_each() -> void:
	for key in ["relay_played_script_ids", "relay_entries", "run_count"]:
		_saved[key] = GameState.get(key)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.run_count = 0

func after_each() -> void:
	for key in _saved:
		GameState.set(key, _saved[key])

func _ids(scripts: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for relay_script in scripts:
		ids.append(relay_script.id)
	return ids

# --- new game ---

func test_a_new_game_rings_the_first_call() -> void:
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_NEW_GAME).id, "marta_first_call")

func test_a_new_game_delivers_the_axiom_mortgage_notice() -> void:
	assert_eq(_ids(RelayDirector.due_texts(RelayScripts.TRIGGER_NEW_GAME)), ["axiom_mortgage_notice"])

func test_an_unfinished_first_call_rings_again_on_arriving_at_the_hub() -> void:
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_first_call")

func test_a_played_first_call_never_rings_again() -> void:
	GameState.relay_mark_played("marta_first_call")
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_NEW_GAME).is_empty())
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).is_empty())

# --- hub arrival ---

func test_the_dive_one_call_waits_for_the_first_dive() -> void:
	GameState.relay_mark_played("marta_first_call")
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).is_empty())
	GameState.run_count = 1
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_after_dive_one")

func test_a_hub_call_that_was_missed_still_comes_on_a_later_run() -> void:
	GameState.relay_mark_played("marta_first_call")
	GameState.run_count = 3
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_after_dive_one")

func test_the_forced_call_comes_before_any_other_call_due_at_the_same_time() -> void:
	GameState.run_count = 1
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_first_call")

# --- tabs ---

func test_okeke_calls_the_first_time_vendors_opens() -> void:
	GameState.relay_mark_played("marta_first_call")
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_TAB_OPENED, "vendors").id, "okeke_intro_call")
	GameState.relay_mark_played("okeke_intro_call")
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_TAB_OPENED, "vendors").is_empty())

func test_other_tabs_ring_nothing() -> void:
	GameState.relay_mark_played("marta_first_call")
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_TAB_OPENED, "workshop").is_empty())

func test_a_tab_call_doesnt_ring_on_hub_arrival() -> void:
	GameState.relay_mark_played("marta_first_call")
	GameState.relay_mark_played("marta_after_dive_one")
	GameState.run_count = 4
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).is_empty())

# --- saves from before the relay ---

func test_nothing_is_past_for_a_player_who_hasnt_dived() -> void:
	assert_eq(RelayDirector.script_ids_already_past(0), [] as Array[String])

func test_after_one_dive_only_the_new_game_scripts_are_past() -> void:
	assert_eq(RelayDirector.script_ids_already_past(1), ["marta_first_call", "axiom_mortgage_notice"] as Array[String])

func test_after_two_dives_the_dive_one_call_is_past_too_but_okeke_isnt() -> void:
	var past := RelayDirector.script_ids_already_past(2)
	assert_true("marta_after_dive_one" in past)
	assert_false("okeke_intro_call" in past)
