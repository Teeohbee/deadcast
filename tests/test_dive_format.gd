extends GutTest

func test_result_line_all_parts() -> void:
	assert_eq(DiveFormat.result_line(200, 5, 8), ">>> +200cr  ·  +5T  ·  SIG -8%")

func test_result_line_omits_zero_fields() -> void:
	assert_eq(DiveFormat.result_line(300, 0, 0), ">>> +300cr")

func test_result_line_negative_tension() -> void:
	assert_eq(DiveFormat.result_line(0, -10, 0), ">>> -10T")

func test_result_line_no_change() -> void:
	assert_eq(DiveFormat.result_line(0, 0, 0), ">>> no change")

func _make_option(label: String, t: int, cr: int) -> CatchOption:
	var o := CatchOption.new()
	o.label = label
	o.tension_delta = t
	o.credit_value = cr
	return o

func test_option_label_passive() -> void:
	var o := _make_option("Reel In", 15, 800)
	assert_eq(DiveFormat.option_label(1, o, CatchData.BehaviorType.PASSIVE),
		"[1] reel_in  ·  +15T  ·  +800cr")

func test_option_label_cuts_line() -> void:
	var o := CatchOption.new()
	o.cuts_line = true
	assert_eq(DiveFormat.option_label(3, o, CatchData.BehaviorType.PASSIVE),
		"[3] abort_connection  ·  vents half tension  ·  SIG -10%  ·  no reward")

func test_command_label_isolate_keeps_tension() -> void:
	assert_string_contains(DiveFormat.command_label(4, {"id": "ISOLATE_FEED"}), "keep tension")

func test_option_label_resistant_shows_odds() -> void:
	var o := _make_option("Brute Decrypt", 15, 550)
	o.resist_chance = 0.45
	o.resist_tension_penalty = 35
	var label := DiveFormat.option_label(1, o, CatchData.BehaviorType.RESISTANT)
	assert_string_contains(label, "45% resist (+35T)")

func test_option_label_negotiating_shows_odds() -> void:
	var o := _make_option("Negotiate Access", 10, 800)
	o.fail_chance = 0.3
	o.fail_tension_delta = 25
	o.fail_credit_value = 0
	var label := DiveFormat.option_label(2, o, CatchData.BehaviorType.NEGOTIATING)
	assert_string_contains(label, "30% fail (+25T, +0cr)")

func test_contact_card_contains_identity_and_sig() -> void:
	var c := CatchData.new()
	c.catch_name = "Encrypted Pension Record"
	c.catch_type = CatchData.CatchType.DATA
	c.behavior = CatchData.BehaviorType.RESISTANT
	c.corruption_gain = 5
	c.flavor_text = "locked accounts and frozen payments"
	var card := DiveFormat.contact_card(c)
	assert_string_contains(card, "contact: Encrypted Pension Record")
	assert_string_contains(card, "[DATA_CONTAINER]")
	assert_string_contains(card, "[ENC_RESISTANT]")
	assert_string_contains(card, "locked accounts")
	assert_string_contains(card, "SIG IMPACT: -5%")

func test_contact_card_no_corruption_says_none() -> void:
	var c := CatchData.new()
	c.catch_name = "Emergency Medical Cache"
	var card := DiveFormat.contact_card(c)
	assert_string_contains(card, "SIG IMPACT: none")

func test_overload_status_line() -> void:
	var line := DiveFormat.overload_status(2, 3, 1.15, 4)
	assert_eq(line, "│  anchor ◆◆◇  2/3  ·  threat ×1.15  ·  turn 4")

func test_command_label_known_command() -> void:
	assert_string_contains(DiveFormat.command_label(1, {"id": "DECRYPT_NODE"}), "DECRYPT_NODE")
	assert_string_contains(DiveFormat.command_label(4, {"id": "ISOLATE_FEED"}), "emergency disconnect")

func test_narrative_entry_indents_lines() -> void:
	var entry := DiveFormat.narrative_entry("SOLACE-7", "line one\nline two")
	assert_string_contains(entry, "LOG_ENTRY: SOLACE-7")
	assert_string_contains(entry, "│  line one\n│  line two")

func test_glitch_intensity_tiers() -> void:
	assert_eq(DiveFormat.glitch_intensity(0.0), 0.0)
	assert_eq(DiveFormat.glitch_intensity(29.9), 0.0)
	assert_eq(DiveFormat.glitch_intensity(30.0), 0.02)
	assert_eq(DiveFormat.glitch_intensity(50.0), 0.05)
	assert_eq(DiveFormat.glitch_intensity(70.0), 0.10)
	assert_eq(DiveFormat.glitch_intensity(90.0), 0.18)

func test_archive_result_plain() -> void:
	assert_eq(DiveFormat.archive_result("", 800, 15, 3), "+800cr  ·  +15T  ·  SIG -3%")

func test_archive_result_labelled() -> void:
	assert_eq(DiveFormat.archive_result("resisted", 0, 35, 0), "resisted  ·  +35T")

func test_archive_result_label_only() -> void:
	assert_eq(DiveFormat.archive_result("feed isolated  ·  catch lost", 0, 0, 0),
		"feed isolated  ·  catch lost")

func _surfaced_record() -> Dictionary:
	return {
		"run": 7,
		"zone": "district 7 ruins",
		"entries": [
			{"kind": "slot", "slot": 1, "name": "Corrupted Finance Archive",
				"type_tag": "[DATA_CONTAINER]", "echo": "extract --careful",
				"result": "", "credits": 800, "tension": 15, "sig": 3},
			{"kind": "lure", "text": "deep_pulse: 2 contacts ahead — [DATA] [HOSTILE]"},
			{"kind": "checkpoint", "layer": "shallows", "haul": 800, "choice": "surface"},
		],
		"banked": 800, "forfeited": 0, "outcome": "surfaced",
	}

func test_run_log_text_surfaced() -> void:
	var text := DiveFormat.run_log_text(_surfaced_record())
	assert_string_contains(text, "RUN_007.LOG  ·  district 7 ruins")
	assert_string_contains(text, "[S1] Corrupted Finance Archive  [DATA_CONTAINER]")
	assert_string_contains(text, "> extract --careful")
	assert_string_contains(text, ">>> +800cr  ·  +15T  ·  SIG -3%")
	assert_string_contains(text, ">>> deep_pulse: 2 contacts ahead")
	assert_string_contains(text, "[CP] shallows cleared  ·  haul 800cr")
	assert_string_contains(text, "> surface")
	assert_string_contains(text, ">>> surfaced  ·  banked 800cr  ·  contacts resolved: 1")

func test_run_log_text_snapped() -> void:
	var record := {
		"run": 8,
		"zone": "the exchange",
		"entries": [
			{"kind": "slot", "slot": 1, "name": "Salvage Drone",
				"type_tag": "[MECH_SYSTEM]", "echo": "strip --parts",
				"result": "resisted", "credits": 0, "tension": 35, "sig": 0},
			{"kind": "snapped"},
		],
		"banked": 0, "forfeited": 450, "outcome": "snapped",
	}
	var text := DiveFormat.run_log_text(record)
	assert_string_contains(text, "RUN_008.LOG")
	assert_string_contains(text, ">>> resisted  ·  +35T")
	assert_string_contains(text, "[!!! TENSION EXCEEDED !!!]")
	assert_string_contains(text, ">>> session terminated  ·  haul forfeited: 450cr")

func test_fake_signal_loss_only_at_ninety_corruption_and_above() -> void:
	assert_false(DiveFormat.should_fake_signal_loss(89.0, 0.0))
	assert_true(DiveFormat.should_fake_signal_loss(90.0, 0.0))

func test_fake_signal_loss_is_a_chance_not_a_certainty() -> void:
	assert_true(DiveFormat.should_fake_signal_loss(95.0, DiveFormat.FAKE_SIGNAL_LOSS_CHANCE - 0.01))
	assert_false(DiveFormat.should_fake_signal_loss(95.0, DiveFormat.FAKE_SIGNAL_LOSS_CHANCE + 0.01))
