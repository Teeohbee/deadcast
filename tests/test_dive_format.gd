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
		"[1] reel_in  ·  strain: HEAVY  ·  value: MID")

func test_option_label_cuts_line() -> void:
	var o := CatchOption.new()
	o.cuts_line = true
	assert_eq(DiveFormat.option_label(3, o, CatchData.BehaviorType.PASSIVE),
		"[3] abort_connection  ·  vents half the strain  ·  costs signal  ·  no reward")

func _cmd(id: String) -> Dictionary:
	for c in OverloadFight.BASE_COMMANDS:
		if c.id == id:
			return c
	return OverloadFight.ISOLATE_FEED if id == "ISOLATE_FEED" else OverloadFight.OVERLOAD_CORE

func test_command_label_isolate_keeps_tension() -> void:
	assert_string_contains(DiveFormat.command_label(4, _cmd("ISOLATE_FEED")), "keep the strain")

func test_command_labels_are_words_not_odds() -> void:
	assert_eq(DiveFormat.command_label(1, _cmd("DECRYPT_NODE")), "[1] DECRYPT_NODE  ·  strain: MODERATE  ·  breaks 1  ·  SURE")
	assert_eq(DiveFormat.command_label(2, _cmd("BRUTE_FORCE_OVERRIDE")), "[2] BRUTE_FORCE_OVERRIDE  ·  strain: HEAVY  ·  breaks 2  ·  RISKY")
	assert_eq(DiveFormat.command_label(3, _cmd("SYNGAS_FLOOD")), "[3] SYNGAS_FLOOD  ·  breaks 1  ·  COIN FLIP")
	assert_eq(DiveFormat.command_label(4, _cmd("SIGNAL_DAMPEN")), "[4] SIGNAL_DAMPEN  ·  eases strain  ·  SURE")
	assert_string_contains(DiveFormat.command_label(5, _cmd("OVERLOAD_CORE")), "shock lure")
	for c in OverloadFight.BASE_COMMANDS:
		assert_false(DiveFormat.command_label(1, c).contains("%"))

func test_a_dice_option_says_uncertain_not_its_odds() -> void:
	var o := _make_option("Brute Decrypt", 15, 550)
	o.resist_chance = 0.45
	o.resist_tension_penalty = 35
	var label := DiveFormat.option_label(1, o, CatchData.BehaviorType.RESISTANT)
	assert_eq(label, "[1] brute_decrypt  ·  strain: HEAVY  ·  value: MID  ·  UNCERTAIN")
	var n := _make_option("Negotiate Access", 10, 800)
	n.fail_chance = 0.3
	assert_string_ends_with(DiveFormat.option_label(2, n, CatchData.BehaviorType.NEGOTIATING), "UNCERTAIN")

func test_a_hauled_option_is_never_uncertain() -> void:
	var o := _make_option("Brute Decrypt", 15, 550)
	o.resist_chance = 0.45
	assert_false(DiveFormat.option_label(1, o, CatchData.BehaviorType.RESISTANT, true).contains("UNCERTAIN"))

func test_no_option_label_prints_numbers() -> void:
	var o := _make_option("Harvest", 20, 1800)
	o.fail_chance = 0.4
	o.fail_tension_delta = 30
	for hauled in [false, true]:
		var label := DiveFormat.option_label(1, o, CatchData.BehaviorType.NEGOTIATING, hauled)
		var digits := RegEx.create_from_string("\\d")
		assert_eq(digits.search_all(label.trim_prefix("[1]")).size(), 0, label)

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
	assert_string_contains(DiveFormat.command_label(1, _cmd("DECRYPT_NODE")), "DECRYPT_NODE")
	assert_string_contains(DiveFormat.command_label(4, _cmd("ISOLATE_FEED")), "emergency disconnect")

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

# --- haul cards: tells, not sums (District 7 spike) ---

func _haul_catch() -> CatchData:
	var c := CatchData.new()
	c.catch_name = "Encrypted Pension Record"
	c.flavor_text = "locked accounts."
	c.haul_enabled = true
	c.haul_slip = 0.6
	return c

func test_haul_card_says_how_the_contact_hauls() -> void:
	var card := DiveFormat.contact_card(_haul_catch(), true)
	assert_string_contains(card, "hauls: steady · slips slowly")

func test_card_without_a_haul_has_no_haul_line() -> void:
	assert_false(DiveFormat.contact_card(_haul_catch()).contains("hauls:"))

func test_haul_option_shows_strain_and_worth_not_numbers() -> void:
	var label := DiveFormat.option_label(1, _make_option("Brute Force", 15, 550), CatchData.BehaviorType.PASSIVE, true)
	assert_eq(label, "[1] brute_force  ·  strain: HEAVY  ·  value: MID")

func test_haul_option_without_strain_leaves_it_off() -> void:
	assert_eq(DiveFormat.option_label(2, _make_option("Skim", 0, 150), CatchData.BehaviorType.PASSIVE, true), "[2] skim  ·  value: LOW")

func test_haul_contact_release_is_just_its_name() -> void:
	assert_eq(DiveFormat.option_label(3, _make_option("Release", 0, 0), CatchData.BehaviorType.PASSIVE, true), "[3] release")

func test_haul_contact_cut_line_keeps_its_warning() -> void:
	var o := _make_option("Cut Line", 0, 0)
	o.cuts_line = true
	assert_string_starts_with(DiveFormat.option_label(3, o, CatchData.BehaviorType.PASSIVE, true), "[3] abort_connection")

func test_recovered_fragments_mask_lost_and_unread() -> void:
	var text := DiveFormat.recovered_fragments([
		{ "word": "LOT 17", "state": HaulFragments.READ },
		{ "word": "COLD", "state": HaulFragments.LOST },
		{ "word": "4C", "state": HaulFragments.UNREAD },
	])
	assert_eq(text, "LOT 17  ·  ▓▓▓▓  ·  ░░")

# Lure options are numbered like every other choice, not tagged [L], so the
# list never reads as a key prompt next to real button glyphs.
func test_lure_label_is_numbered_after_the_options() -> void:
	assert_eq(DiveFormat.lure_label(3, "fire decoy (x2)  ·  slip this contact"),
		"[3] fire decoy (x2)  ·  slip this contact")
