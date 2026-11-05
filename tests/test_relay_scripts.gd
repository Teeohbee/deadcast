# tests/test_relay_scripts.gd
# Guards the script data: every script is well formed, and every path through
# every script reaches its end. A script that can't finish would softlock a
# forced call, which on a new game means the player never reaches the deck.
extends GutTest

const MAX_EVENTS_PER_PATH := 200

func test_script_ids_are_unique() -> void:
	var seen := {}
	for relay_script in RelayScripts.all_scripts():
		assert_false(seen.has(relay_script.id), "duplicate id %s" % relay_script.id)
		seen[relay_script.id] = true

func test_every_script_names_a_known_contact_channel_and_trigger() -> void:
	for relay_script in RelayScripts.all_scripts():
		assert_true(relay_script.contact in RelayScripts.CONTACTS, "%s contact" % relay_script.id)
		assert_true(relay_script.channel in RelayScripts.CHANNELS, "%s channel" % relay_script.id)
		assert_true(relay_script.trigger.moment in RelayScripts.TRIGGERS, "%s trigger" % relay_script.id)

func test_every_step_is_one_known_kind_with_known_actions_and_flags() -> void:
	for relay_script in RelayScripts.all_scripts():
		_check_steps(relay_script.id, relay_script.steps)

func test_only_calls_can_be_forced() -> void:
	for relay_script in RelayScripts.all_scripts():
		if RelayScripts.is_forced(relay_script):
			assert_eq(relay_script.channel, RelayScripts.CHANNEL_CALL, relay_script.id)

func test_scripts_that_can_go_unanswered_have_a_silent_branch_on_every_reply() -> void:
	for relay_script in RelayScripts.all_scripts():
		if RelayScripts.is_forced(relay_script):
			continue
		var runner := RelayRunner.new(relay_script)
		runner.run_to_end_without_replies()
		assert_true(runner.is_finished(), relay_script.id)

func test_every_path_through_every_script_reaches_the_end() -> void:
	for relay_script in RelayScripts.all_scripts():
		for flags in _flag_combinations():
			var paths := _walk_every_path(relay_script, flags, [])
			assert_gt(paths, 0, relay_script.id)

func test_every_path_says_something_from_the_contact() -> void:
	for relay_script in RelayScripts.all_scripts():
		var runner := RelayRunner.new(relay_script)
		if RelayScripts.is_forced(relay_script):
			_answer_first_every_time(runner)
		else:
			runner.run_to_end_without_replies()
		var contact_lines := runner.transcript.filter(func(line): return line.who == relay_script.contact)
		assert_gt(contact_lines.size(), 0, relay_script.id)

func test_find_returns_a_script_by_id_or_empty() -> void:
	assert_eq(RelayScripts.find("marta_first_call").id, "marta_first_call")
	assert_true(RelayScripts.find("no_such_script").is_empty())

func test_the_first_call_is_forced_and_fires_on_a_new_game() -> void:
	var first_call := RelayScripts.find("marta_first_call")
	assert_true(RelayScripts.is_forced(first_call))
	assert_eq(first_call.trigger.moment, RelayScripts.TRIGGER_NEW_GAME)

func test_after_dive_one_opens_differently_after_a_snap() -> void:
	var after_dive := RelayScripts.find("marta_after_dive_one")
	var snapped := RelayRunner.new(after_dive, {RelayScripts.FLAG_LAST_DIVE_SNAPPED: true})
	var surfaced := RelayRunner.new(after_dive, {RelayScripts.FLAG_LAST_DIVE_SNAPPED: false})
	assert_string_contains(snapped.next_event().text, "without the haul")
	assert_eq(surfaced.next_event().text, "you came back. that's above average.")

# --- helpers ---

func _check_steps(script_id: String, steps: Array) -> void:
	for step in steps:
		var kinds := ["say", "attach", "replies", "do"].filter(func(kind): return step.has(kind))
		assert_eq(kinds.size(), 1, "%s step %s" % [script_id, step])
		if step.has("do"):
			assert_true(step.do in RelayScripts.ACTIONS, "%s action %s" % [script_id, step.do])
		if step.has("only_if"):
			assert_true(step.only_if in RelayScripts.FLAGS, "%s flag %s" % [script_id, step.only_if])
		if step.has("who"):
			assert_true(step.who in RelayScripts.CONTACTS, "%s who %s" % [script_id, step.who])
		if step.has("replies"):
			assert_gt(step.replies.size(), 0, script_id)
			for option in step.replies:
				assert_true(option.has("text") and option.text != "", "%s reply text" % script_id)
				_check_steps(script_id, option.get("then", []))
			_check_steps(script_id, step.get("silent", []))

# Replays the choices so far, then branches on every option at the next reply.
# Returns how many complete paths were found; fails the test on a runaway path.
func _walk_every_path(relay_script: Dictionary, flags: Dictionary, choices_so_far: Array) -> int:
	var runner := RelayRunner.new(relay_script, flags)
	var choice_index := 0
	for event_count in MAX_EVENTS_PER_PATH:
		var event := runner.next_event()
		if event.kind == RelayRunner.EVENT_END:
			return 1
		if event.kind != RelayRunner.EVENT_REPLIES:
			continue
		if choice_index < choices_so_far.size():
			runner.choose(choices_so_far[choice_index])
			choice_index += 1
			continue
		var paths := 0
		for option_index in event.options.size():
			paths += _walk_every_path(relay_script, flags, choices_so_far + [option_index])
		return paths
	fail_test("%s path %s never ended" % [relay_script.id, choices_so_far])
	return 0

func _answer_first_every_time(runner: RelayRunner) -> void:
	for event_count in MAX_EVENTS_PER_PATH:
		var event := runner.next_event()
		if event.kind == RelayRunner.EVENT_END:
			return
		if event.kind == RelayRunner.EVENT_REPLIES:
			runner.choose(0)

func _flag_combinations() -> Array[Dictionary]:
	var combinations: Array[Dictionary] = [{}]
	for flag in RelayScripts.FLAGS:
		var with_flag: Array[Dictionary] = []
		for combination in combinations:
			var flag_on := combination.duplicate()
			flag_on[flag] = true
			var flag_off := combination.duplicate()
			flag_off[flag] = false
			with_flag.append(flag_on)
			with_flag.append(flag_off)
		combinations = with_flag
	return combinations
