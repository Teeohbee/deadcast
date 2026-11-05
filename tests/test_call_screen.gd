# tests/test_call_screen.gd
extends GutTest

const CALL_SCREEN := preload("res://scenes/relay/CallScreen.tscn")
const STATE_BACKUP := "user://call_screen_state_backup.cfg"

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.run_count = 0
	GameState.last_run_result = {}

func after_each() -> void:
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func _call_screen() -> CallScreen:
	var screen: CallScreen = CALL_SCREEN.instantiate()
	screen.instant = true
	add_child_autofree(screen)
	return screen

# Answers the first option at every reply until the call is over.
func _answer_through(screen: CallScreen, option_index: int = 0) -> void:
	for safety in 50:
		await get_tree().process_frame
		if screen.visible_options().is_empty():
			continue
		var options := screen.visible_options()
		if options[0].ends_with("hang up"):
			screen.choose_option(0)
			return
		screen.choose_option(mini(option_index, options.size() - 1))

func test_a_forced_call_can_only_be_answered() -> void:
	var screen := _call_screen()
	screen.start({"script_id": "marta_first_call", "answered": false})
	await get_tree().process_frame
	assert_eq(screen.visible_options(), ["[1] answer"] as Array[String])

func test_a_normal_call_can_be_let_ring() -> void:
	var screen := _call_screen()
	screen.start({"script_id": "okeke_intro_call", "answered": false})
	await get_tree().process_frame
	assert_eq(screen.visible_options(), ["[1] answer", "[2] let it ring"] as Array[String])

func test_an_answered_call_opens_connected_and_plays_the_first_line() -> void:
	var screen := _call_screen()
	screen.start({"script_id": "marta_first_call", "answered": true})
	await get_tree().process_frame
	assert_string_contains(screen.feed_text(), "connected.")
	assert_string_contains(screen.feed_text(), "marta ›")
	assert_string_contains(screen.feed_text(), "the keys worked.")

func test_replies_offer_say_nothing_and_echo_the_choice_as_you() -> void:
	var screen := _call_screen()
	screen.start({"script_id": "marta_first_call", "answered": true})
	await get_tree().process_frame
	assert_eq(screen.visible_options(), ["[1] i own this boat.", "[2] what work?", "[3] …say nothing"] as Array[String])
	screen.choose_option(1)
	await get_tree().process_frame
	assert_string_contains(screen.feed_text(), "you ›")
	assert_string_contains(screen.feed_text(), "what work?")

func test_finishing_a_call_files_its_transcript_and_marks_it_played() -> void:
	var screen := _call_screen()
	watch_signals(screen)
	screen.start({"script_id": "marta_first_call", "answered": true})
	await _answer_through(screen)
	assert_signal_emitted(screen, "call_over")
	assert_true(GameState.relay_has_played("marta_first_call"))
	var thread := GameState.relay_entries_for("marta")
	assert_eq(thread.size(), 1)
	assert_eq(thread[0].kind, GameState.RELAY_ENTRY_CALL)
	assert_eq(thread[0].lines[0].text, "you're on the meridian's terminal. good. the keys worked.")
	assert_string_contains(screen.feed_text(), "call ended")

func test_a_call_quit_midway_is_not_marked_played() -> void:
	var screen := _call_screen()
	screen.start({"script_id": "marta_first_call", "answered": true})
	await get_tree().process_frame
	assert_false(GameState.relay_has_played("marta_first_call"))

func test_letting_a_call_ring_files_it_as_a_missed_call_with_the_silent_branches() -> void:
	var screen := _call_screen()
	watch_signals(screen)
	screen.start({"script_id": "okeke_intro_call", "answered": false})
	await get_tree().process_frame
	screen.choose_option(1)
	await get_tree().process_frame
	assert_signal_emitted(screen, "call_over")
	assert_true(GameState.relay_has_played("okeke_intro_call"))
	var thread := GameState.relay_entries_for("okeke")
	assert_eq(thread[0].kind, GameState.RELAY_ENTRY_MISSED_CALL)
	assert_true({"who": "okeke", "text": "a quiet customer. i like those. they come back."} in thread[0].lines)

func test_the_dive_one_call_opens_on_how_the_dive_ended() -> void:
	GameState.last_run_result = {"snapped": true}
	var screen := _call_screen()
	screen.start({"script_id": "marta_after_dive_one", "answered": true})
	await get_tree().process_frame
	assert_string_contains(screen.feed_text(), "without the haul")

func test_an_unknown_script_ends_the_call_at_once_rather_than_trapping_the_player() -> void:
	var screen := _call_screen()
	watch_signals(screen)
	screen.start({"script_id": "no_such_script", "answered": true})
	assert_signal_emitted(screen, "call_over")
	assert_push_error("no relay script")

func test_durations_read_as_minutes_and_seconds() -> void:
	assert_eq(CallScreen.format_duration(192), "3:12")
	assert_eq(CallScreen.format_duration(5), "0:05")
