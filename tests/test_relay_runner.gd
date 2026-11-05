# tests/test_relay_runner.gd
extends GutTest

const SCRIPT_WITH_REPLIES := {
	"id": "test_call",
	"contact": "marta",
	"channel": "call",
	"steps": [
		{"say": "first line."},
		{"replies": [
			{"text": "option one.", "then": [{"say": "after one."}]},
			{"text": "option two.", "then": [{"say": "after two."}, {"do": "accept_job"}]},
		], "silent": [{"say": "after silence."}]},
		{"say": "last line."},
	],
}

func _events_until_replies_or_end(runner: RelayRunner) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	while true:
		var event := runner.next_event()
		events.append(event)
		if event.kind == RelayRunner.EVENT_REPLIES or event.kind == RelayRunner.EVENT_END:
			return events
	return events

func test_say_steps_come_out_in_order_spoken_by_the_script_contact() -> void:
	var runner := RelayRunner.new(SCRIPT_WITH_REPLIES)
	var first := runner.next_event()
	assert_eq(first.kind, RelayRunner.EVENT_SAY)
	assert_eq(first.who, "marta")
	assert_eq(first.text, "first line.")

func test_replies_offer_every_option_plus_say_nothing() -> void:
	var runner := RelayRunner.new(SCRIPT_WITH_REPLIES)
	var events := _events_until_replies_or_end(runner)
	var replies: Dictionary = events.back()
	assert_eq(replies.kind, RelayRunner.EVENT_REPLIES)
	assert_eq(replies.options, ["option one.", "option two.", RelayRunner.SAY_NOTHING])

func test_choosing_an_option_plays_its_branch_then_rejoins_the_script() -> void:
	var runner := RelayRunner.new(SCRIPT_WITH_REPLIES)
	_events_until_replies_or_end(runner)
	runner.choose(0)
	assert_eq(runner.next_event().text, "after one.")
	assert_eq(runner.next_event().text, "last line.")
	assert_eq(runner.next_event().kind, RelayRunner.EVENT_END)
	assert_true(runner.is_finished())

func test_choosing_say_nothing_plays_the_silent_branch() -> void:
	var runner := RelayRunner.new(SCRIPT_WITH_REPLIES)
	_events_until_replies_or_end(runner)
	runner.choose(2)
	assert_eq(runner.next_event().text, "after silence.")

func test_do_steps_surface_as_events_and_are_collected() -> void:
	var runner := RelayRunner.new(SCRIPT_WITH_REPLIES)
	_events_until_replies_or_end(runner)
	runner.choose(1)
	runner.next_event()
	var do_event := runner.next_event()
	assert_eq(do_event.kind, RelayRunner.EVENT_DO)
	assert_eq(do_event.action, "accept_job")
	assert_eq(runner.actions_taken, ["accept_job"])

func test_transcript_records_both_sides_with_silence_as_an_ellipsis() -> void:
	var runner := RelayRunner.new(SCRIPT_WITH_REPLIES)
	_events_until_replies_or_end(runner)
	runner.choose(2)
	runner.run_to_end_without_replies()
	assert_eq(runner.transcript, [
		{"who": "marta", "text": "first line."},
		{"who": "you", "text": "…"},
		{"who": "marta", "text": "after silence."},
		{"who": "marta", "text": "last line."},
	])

func test_next_event_repeats_the_open_replies_until_one_is_chosen() -> void:
	var runner := RelayRunner.new(SCRIPT_WITH_REPLIES)
	_events_until_replies_or_end(runner)
	assert_eq(runner.next_event().kind, RelayRunner.EVENT_REPLIES)

func test_run_to_end_without_replies_takes_every_silent_branch() -> void:
	var runner := RelayRunner.new(SCRIPT_WITH_REPLIES)
	runner.run_to_end_without_replies()
	assert_true(runner.is_finished())
	assert_true({"who": "marta", "text": "after silence."} in runner.transcript)
	assert_eq(runner.actions_taken, [])

func test_only_if_steps_play_when_their_flag_is_set() -> void:
	var script := {"id": "flagged", "contact": "marta", "channel": "call", "steps": [
		{"say": "you surfaced.", "only_if": "last_dive_snapped", "is": false},
		{"say": "you snapped.", "only_if": "last_dive_snapped", "is": true},
	]}
	var snapped := RelayRunner.new(script, {"last_dive_snapped": true})
	assert_eq(snapped.next_event().text, "you snapped.")
	var surfaced := RelayRunner.new(script, {"last_dive_snapped": false})
	assert_eq(surfaced.next_event().text, "you surfaced.")

func test_say_text_fills_named_values() -> void:
	var script := {"id": "valued", "contact": "axiom_credit", "channel": "text", "steps": [
		{"say": "{amount}cr collected."},
	]}
	var runner := RelayRunner.new(script, {}, {"amount": "10,000"})
	assert_eq(runner.next_event().text, "10,000cr collected.")

func test_a_step_can_name_a_different_speaker() -> void:
	var script := {"id": "two_voices", "contact": "marta", "channel": "call", "steps": [
		{"say": "it's me.", "who": "okeke"},
	]}
	assert_eq(RelayRunner.new(script).next_event().who, "okeke")

func test_attach_steps_are_spoken_and_marked() -> void:
	var script := {"id": "attached", "contact": "marta", "channel": "text", "steps": [
		{"attach": "CASE FILE · TEST"},
	]}
	var runner := RelayRunner.new(script)
	var event := runner.next_event()
	assert_eq(event.kind, RelayRunner.EVENT_ATTACH)
	assert_eq(runner.transcript, [{"who": "marta", "text": "CASE FILE · TEST", "attachment": true}])
