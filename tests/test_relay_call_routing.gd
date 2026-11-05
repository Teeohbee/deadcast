# tests/test_relay_call_routing.gd
# UIController hands the screen to a due relay call on hub arrival or when a
# tab opens, then back to where the player was going.
extends GutTest

const STATE_BACKUP := "user://relay_routing_state_backup.cfg"
var _zone2: Control

class FakeScreen:
	extends Control

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.run_count = 0
	GameState.pressure_level = 0
	_zone2 = Control.new()
	add_child_autofree(_zone2)
	UIController._scene_factory = func(_id: String) -> Node: return FakeScreen.new()
	UIController.initialize(_zone2)
	UIController.relay_calls_enabled = true
	UIController.answer_next_call = false
	UIController.pending_call = {}

func after_each() -> void:
	UIController.relay_calls_enabled = false
	UIController._scene_factory = UIController._default_scene_factory
	UIController.pending_call = {}
	UIController.answer_next_call = false
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func test_a_new_game_lands_on_the_first_call_not_the_deck() -> void:
	UIController.navigate_to("deck")
	assert_eq(UIController.current_screen, "call")
	assert_eq(UIController.pending_call.script_id, "marta_first_call")
	assert_eq(UIController.pending_call.return_to, "deck")

func test_answering_on_the_boot_opens_the_call_connected() -> void:
	UIController.answer_next_call = true
	UIController.navigate_to("deck")
	assert_true(UIController.pending_call.answered)
	assert_false(UIController.answer_next_call)

func test_finishing_the_call_shows_the_deck_without_ringing_again() -> void:
	UIController.navigate_to("deck")
	GameState.relay_mark_played("marta_first_call")
	UIController.finish_call()
	assert_eq(UIController.current_screen, "deck")
	assert_true(UIController.pending_call.is_empty())

func test_the_axiom_notice_lands_in_the_relay_on_hub_arrival() -> void:
	UIController.navigate_to("deck")
	assert_true(GameState.relay_has_played("axiom_mortgage_notice"))
	var thread := GameState.relay_entries_for("axiom_credit")
	assert_eq(thread.size(), 1)
	assert_eq(thread[0].kind, GameState.RELAY_ENTRY_TEXT)
	assert_string_contains(thread[0].lines[0].text, "AXIOM CREDIT")

func test_an_unfinished_first_call_rings_again_on_continue() -> void:
	GameState.run_count = 1
	UIController.navigate_to("deck")
	assert_eq(UIController.pending_call.script_id, "marta_first_call")

func test_coming_back_from_a_dive_rings_the_dive_one_call() -> void:
	GameState.relay_mark_played("marta_first_call")
	UIController.navigate_to("dive")
	GameState.run_count = 1
	UIController.navigate_to("deck")
	assert_eq(UIController.pending_call.script_id, "marta_after_dive_one")

func test_moving_between_tabs_is_not_a_hub_arrival() -> void:
	GameState.relay_mark_played("marta_first_call")
	UIController.navigate_to("deck")
	GameState.run_count = 1
	UIController.navigate_to("bunk")
	assert_eq(UIController.current_screen, "bunk")

func test_opening_vendors_the_first_time_rings_okeke_then_shows_vendors() -> void:
	GameState.relay_mark_played("marta_first_call")
	GameState.relay_mark_played("marta_after_dive_one")
	GameState.run_count = 2
	UIController.navigate_to("deck")
	UIController.navigate_to("vendors")
	assert_eq(UIController.pending_call.script_id, "okeke_intro_call")
	assert_eq(UIController.pending_call.return_to, "vendors")
	GameState.relay_mark_played("okeke_intro_call")
	UIController.finish_call()
	assert_eq(UIController.current_screen, "vendors")

func test_no_tab_cycling_during_a_call() -> void:
	UIController.navigate_to("deck")
	var press := InputEventAction.new()
	press.action = "tab_next"
	press.pressed = true
	UIController._unhandled_input(press)
	assert_eq(UIController.current_screen, "call")

func test_repossession_wins_over_any_call() -> void:
	GameState.pressure_level = 5
	UIController.navigate_to("deck")
	assert_eq(UIController.current_screen, "gameover")

func test_after_okekes_call_he_is_a_relay_contact_with_the_transcript() -> void:
	GameState.relay_mark_played("marta_first_call")
	GameState.relay_mark_played("marta_after_dive_one")
	GameState.run_count = 2
	UIController.navigate_to("deck")
	UIController.navigate_to("vendors")
	var screen: CallScreen = load("res://scenes/relay/CallScreen.tscn").instantiate()
	screen.instant = true
	add_child_autofree(screen)
	screen.start(UIController.pending_call)
	for safety in 30:
		await get_tree().process_frame
		if not screen.visible_options().is_empty():
			screen.choose_option(0)
		if GameState.relay_has_played("okeke_intro_call"):
			break
	var relay_tab: RelayTab = load("res://scenes/relay/RelayTab.tscn").instantiate()
	add_child_autofree(relay_tab)
	assert_true("okeke" in relay_tab.listed_contacts())
	assert_string_contains(relay_tab.render_thread("okeke"), "i'm saying count.")
