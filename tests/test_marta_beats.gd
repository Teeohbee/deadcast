# tests/test_marta_beats.gd
extends GutTest

const STATE_BACKUP := "user://marta_beats_state_backup.cfg"
const OPENING_SCRIPTS := ["marta_first_call", "axiom_mortgage_notice", "marta_after_dive_one"]

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.run_logs = []
	GameState.victory = false
	GameState.pressure_level = 0
	for script_id in OPENING_SCRIPTS:
		GameState.relay_mark_played(script_id)

func after_each() -> void:
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func _due_text_ids() -> Array[String]:
	var ids: Array[String] = []
	for relay_script in RelayDirector.due_texts(RelayScripts.TRIGGER_HUB_ARRIVAL):
		ids.append(relay_script.id)
	return ids

func _log_dive_in(zone_display_name: String) -> void:
	GameState.run_logs.append({"run": 1, "zone": zone_display_name.to_lower(), "entries": []})

func test_the_five_dives_text_arrives_from_run_five() -> void:
	GameState.run_count = 4
	assert_false("marta_beat_five_dives" in _due_text_ids())
	GameState.run_count = 5
	assert_true("marta_beat_five_dives" in _due_text_ids())

func test_the_shard_text_waits_until_the_exchange_has_been_fished() -> void:
	GameState.run_count = 3
	assert_false("marta_beat_exchange_shard" in _due_text_ids())
	_log_dive_in("The Voss Exchange")
	assert_true("marta_beat_exchange_shard" in _due_text_ids())

func test_the_archive_text_waits_for_an_axiom_dive() -> void:
	GameState.run_count = 6
	_log_dive_in("District 7 Ruins")
	assert_false("marta_beat_archive_moved" in _due_text_ids())
	_log_dive_in("Axiom Tower Sub-Basement")
	assert_true("marta_beat_archive_moved" in _due_text_ids())

func test_the_transponder_call_rings_from_run_eight() -> void:
	GameState.run_count = 8
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_beat_transponder")

func test_the_offer_rings_after_the_transponder_has_been_heard() -> void:
	GameState.run_count = 12
	GameState.relay_mark_played("marta_beat_transponder")
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_beat_the_offer")

func test_victory_rings_marta_once_the_account_is_closed() -> void:
	GameState.run_count = 2
	assert_true(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).is_empty())
	GameState.victory = true
	assert_eq(RelayDirector.due_call(RelayScripts.TRIGGER_HUB_ARRIVAL).id, "marta_victory_call")

func test_an_old_save_at_run_ten_has_heard_the_old_beats_but_not_victory() -> void:
	var past := RelayDirector.script_ids_already_past(10)
	for script_id in ["marta_beat_five_dives", "marta_beat_transponder", "marta_beat_exchange_shard"]:
		assert_true(script_id in past, script_id)
	assert_false("marta_beat_the_offer" in past)
	assert_false("marta_victory_call" in past)

func test_each_beat_fires_once() -> void:
	GameState.run_count = 5
	GameState.relay_mark_played("marta_beat_five_dives")
	assert_false("marta_beat_five_dives" in _due_text_ids())
