# tests/test_audio.gd
extends GutTest

# Audio is an autoload. These tests check the wiring (cue table, buses,
# ambience, mute, event hooks), not what anything sounds like.

var _muted_before: bool

func before_each() -> void:
	_muted_before = Settings.audio_muted
	Audio.clear_cue_history()

func after_each() -> void:
	# Write back, not just assign: the toggle test saves to the real settings file.
	Settings.set_audio_muted(_muted_before)
	Audio.apply_mute_setting()

func test_every_cue_file_exists_and_loads() -> void:
	for cue_name in Audio.CUES:
		var cue: Dictionary = Audio.CUES[cue_name]
		assert_gt(cue.files.size(), 0, "cue %s should list at least one file" % cue_name)
		for file_path in cue.files:
			assert_true(ResourceLoader.exists(file_path), "%s: missing %s" % [cue_name, file_path])

func test_every_cue_routes_to_an_existing_bus() -> void:
	for cue_name in Audio.CUES:
		var bus_name: String = Audio.CUES[cue_name].bus
		assert_ne(AudioServer.get_bus_index(bus_name), -1, "%s: no bus %s" % [cue_name, bus_name])

func test_play_cue_records_the_cue() -> void:
	Audio.play_cue("checkpoint")
	assert_eq(Audio.cue_history, ["checkpoint"])

func test_unknown_cue_is_ignored_without_crashing() -> void:
	Audio.play_cue("no_such_cue")
	assert_eq(Audio.cue_history, [])

func test_ambience_switches_between_hub_and_dive() -> void:
	Audio.set_ambience("dive")
	assert_eq(Audio.current_ambience, "dive")
	Audio.set_ambience("hub")
	assert_eq(Audio.current_ambience, "hub")

func test_every_ambience_file_exists_and_loads() -> void:
	for ambience_name in Audio.AMBIENCES:
		var file: String = Audio.AMBIENCES[ambience_name].file
		assert_true(ResourceLoader.exists(file), "%s: missing %s" % [ambience_name, file])
		assert_not_null(load(file), "%s: %s did not load" % [ambience_name, file])

func test_title_music_is_an_ambience() -> void:
	assert_true(Audio.AMBIENCES.has("title"))

func test_entering_the_dive_screen_switches_to_dive_ambience() -> void:
	UIController.screen_changed.emit("dive")
	assert_eq(Audio.current_ambience, "dive")
	UIController.screen_changed.emit("deck")
	assert_eq(Audio.current_ambience, "hub")

func test_a_button_moved_between_parents_is_hooked_once() -> void:
	var first_parent := Node.new()
	var second_parent := Node.new()
	add_child_autofree(first_parent)
	add_child_autofree(second_parent)
	var button := Button.new()
	first_parent.add_child(button)
	first_parent.remove_child(button)
	second_parent.add_child(button)
	# play_cue drops repeats inside a few milliseconds, which would hide a
	# double hook, so count the connections instead.
	assert_eq(button.pressed.get_connections().size(), 1)

func test_mute_setting_mutes_the_master_bus() -> void:
	Settings.audio_muted = true
	Audio.apply_mute_setting()
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")))
	Settings.audio_muted = false
	Audio.apply_mute_setting()
	assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")))

func test_dive_events_play_their_cues() -> void:
	EventBus.dive_cast.emit()
	EventBus.checkpoint_reached.emit()
	EventBus.line_snapped.emit()
	assert_eq(Audio.cue_history, ["dive_cast", "checkpoint", "line_snap", "signal_lost"])

func test_entity_contact_plays_entity_cue_and_others_ping() -> void:
	var entity := CatchData.new()
	entity.catch_type = CatchData.CatchType.ENTITY
	var data := CatchData.new()
	data.catch_type = CatchData.CatchType.DATA
	EventBus.contact_presented.emit(entity)
	EventBus.contact_presented.emit(data)
	assert_eq(Audio.cue_history, ["contact_entity", "contact_ping"])

func test_rising_tension_creaks_but_falling_tension_does_not() -> void:
	EventBus.tension_changed.emit(10.0)
	Audio.clear_cue_history()
	EventBus.tension_changed.emit(30.0)
	EventBus.tension_changed.emit(15.0)
	assert_eq(Audio.cue_history, ["line_strain"])

func test_firing_a_lure_plays_the_lure_cue() -> void:
	EventBus.lure_stock_changed.emit("shock_lure", 2)
	assert_eq(Audio.cue_history, ["lure_fire"])

func test_banking_a_run_plays_coins_but_a_snapped_run_does_not() -> void:
	EventBus.run_ended.emit({"snapped": false, "credits": 500})
	EventBus.run_ended.emit({"snapped": true, "credits": 0})
	assert_eq(Audio.cue_history, ["haul_banked"])

func test_toggle_mute_action_flips_the_setting_and_the_bus() -> void:
	Settings.audio_muted = false
	Audio.apply_mute_setting()
	var press := InputEventAction.new()
	press.action = "toggle_mute"
	press.pressed = true
	Audio._unhandled_input(press)
	assert_true(Settings.audio_muted)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")))
