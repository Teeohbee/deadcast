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
		"[3] abort_connection  ·  resets tension  ·  no reward")

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
