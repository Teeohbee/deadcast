# tests/test_relay_tab.gd
extends GutTest

const RELAY_TAB := preload("res://scenes/relay/RelayTab.tscn")
const STATE_BACKUP := "user://relay_tab_state_backup.cfg"

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.relay_played_script_ids = []
	GameState.relay_entries = []
	GameState.run_count = 1
	GameState.active_job_id = ""
	GameState.job_declined_run = -1
	GameState.victory = false
	GameState.debt = 80000
	GameState.runs_since_payment = 0
	GameState.pressure_level = 0

func after_each() -> void:
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func _tab() -> RelayTab:
	var tab: RelayTab = RELAY_TAB.instantiate()
	add_child_autofree(tab)
	return tab

func _lines(who: String, text: String) -> Array[Dictionary]:
	return [{"who": who, "text": text}]

# --- contacts and threads ---

func test_marta_and_axiom_credit_are_always_listed_okeke_once_he_calls() -> void:
	var tab := _tab()
	assert_eq(tab.listed_contacts(), ["marta", "axiom_credit"] as Array[String])
	GameState.relay_file_entry("okeke", GameState.RELAY_ENTRY_CALL, "okeke_intro_call", _lines("okeke", "meridian."))
	assert_eq(tab.listed_contacts(), ["marta", "axiom_credit", "okeke"] as Array[String])

func test_a_call_shows_in_the_thread_under_its_heading() -> void:
	GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_CALL, "marta_first_call", _lines("marta", "the keys worked."))
	var tab := _tab()
	var thread := tab.render_thread("marta")
	assert_string_contains(thread, "── call · run 1 ──")
	assert_string_contains(thread, "marta ›")
	assert_string_contains(thread, "the keys worked.")

func test_missed_calls_and_texts_have_their_own_headings() -> void:
	assert_eq(RelayTab.entry_heading({"kind": GameState.RELAY_ENTRY_MISSED_CALL, "run": 2}), "missed call · run 2")
	assert_eq(RelayTab.entry_heading({"kind": GameState.RELAY_ENTRY_TEXT, "run": 2}), "run 2")

func test_showing_the_tab_opens_the_newest_unread_thread_and_marks_it_read() -> void:
	GameState.relay_file_entry("axiom_credit", GameState.RELAY_ENTRY_TEXT, "axiom_mortgage_notice", _lines("axiom_credit", "NOTICE"))
	var tab := _tab()
	tab.on_screen_shown()
	assert_eq(tab.selected_contact, "axiom_credit")
	assert_eq(GameState.relay_unread_count("axiom_credit"), 0)

func test_unread_counts_show_on_the_contact_list() -> void:
	GameState.relay_file_entry("axiom_credit", GameState.RELAY_ENTRY_TEXT, "a", _lines("axiom_credit", "one"))
	GameState.relay_file_entry("axiom_credit", GameState.RELAY_ENTRY_TEXT, "b", _lines("axiom_credit", "two"))
	GameState.active_job_id = "steady_hands"  # no offer open, so marta stays selected
	var tab := _tab()
	assert_true(tab.contact_button_labels()[1].contains("2 new"), str(tab.contact_button_labels()))

func test_the_footer_badge_follows_unread_relay_entries() -> void:
	assert_false(GameState.relay_has_unread())
	GameState.relay_file_entry("marta", GameState.RELAY_ENTRY_TEXT, "a", _lines("marta", "hi"))
	assert_true(GameState.relay_has_unread())
	GameState.relay_mark_read("marta")
	assert_false(GameState.relay_has_unread())

# --- job offers ---

func test_an_open_offer_arrives_as_a_marta_text_with_replies() -> void:
	var tab := _tab()
	var offer := MartaJobs.offer_for(GameState.run_count)
	assert_string_contains(tab.render_thread("marta"), RelayScripts.JOB_OFFER_COPY[offer.id].offer[0])
	assert_eq(tab.job_offer_options(), ["[1] i'll take it.", "[2] pass.", "[3] …say nothing"] as Array[String])

func test_taking_the_offer_accepts_the_job_and_fills_the_case_file() -> void:
	var tab := _tab()
	var offer := MartaJobs.offer_for(GameState.run_count)
	tab.answer_job_offer(0)
	assert_eq(GameState.active_job_id, offer.id)
	assert_string_contains(tab.case_file_text(), offer.title.to_upper())
	assert_string_contains(tab.case_file_text(), RelayScripts.job_condition_text(offer.id))
	assert_eq(tab.job_offer_options().size(), 0)
	var filed := GameState.relay_entries_for("marta")
	assert_eq(filed.back().lines[-2], {"who": "you", "text": "i'll take it."})

func test_passing_or_saying_nothing_declines() -> void:
	var tab := _tab()
	tab.answer_job_offer(2)
	assert_eq(GameState.active_job_id, "")
	assert_false(GameState.job_offer_open())
	assert_eq(GameState.relay_entries_for("marta").back().lines[-2], {"who": "you", "text": "…"})

func test_no_offer_before_the_first_dive() -> void:
	GameState.run_count = 0
	var tab := _tab()
	assert_eq(tab.job_offer_options().size(), 0)
	assert_string_contains(tab.case_file_text(), "first dive's on marta")

func test_every_job_has_offer_copy_that_plays_to_the_end() -> void:
	for job in MartaJobs.all_jobs():
		var offer_script := RelayScripts.job_offer_script(job.id)
		assert_false(offer_script.is_empty(), job.id)
		var runner := RelayRunner.new(offer_script)
		runner.run_to_end_without_replies()
		assert_eq(runner.actions_taken, [RelayScripts.ACTION_DECLINE_JOB], job.id)
		assert_ne(RelayScripts.job_condition_text(job.id), "", job.id)

# --- axiom credit ---

func test_the_account_shows_balance_instalment_and_due_dives() -> void:
	GameState.runs_since_payment = 4
	var tab := _tab()
	assert_string_contains(tab.account_text(), "80,000 cr")
	assert_string_contains(tab.account_text(), "10,000 cr")
	assert_string_contains(tab.account_text(), "in 1 dive")

func test_the_account_updates_when_the_tab_is_shown_again() -> void:
	var tab := _tab()
	assert_string_contains(tab.account_text(), "in 5 dives")
	GameState.runs_since_payment = 3
	tab.on_screen_shown()
	assert_string_contains(tab.account_text(), "in 2 dives")

func test_a_cleared_account_reads_closed() -> void:
	GameState.victory = true
	var tab := _tab()
	assert_string_contains(tab.account_text(), "ACCOUNT CLOSED")

func _contact_button(tab: RelayTab, contact: String) -> Button:
	var display: Dictionary = RelayScripts.CONTACT_DISPLAY.get(contact, {})
	var caller: String = display.get("caller_id", contact).to_lower()
	for b in tab._contact_list.get_children():
		if (b as Button).text.contains(caller):
			return b
	return null

func test_default_focus_is_the_selected_contact() -> void:
	GameState.active_job_id = "steady_hands"  # no offer open
	var tab := _tab()
	assert_eq(tab.default_focus(), _contact_button(tab, tab.selected_contact))

func test_default_focus_prefers_a_pending_reply_to_marta() -> void:
	var tab := _tab()
	assert_false(tab.job_offer_options().is_empty())
	assert_eq(tab.default_focus(), tab._reply_block.get_child(0))

func test_screen_shown_focuses_the_selected_contact() -> void:
	GameState.active_job_id = "steady_hands"
	var tab := _tab()
	tab.on_screen_shown()
	assert_true(_contact_button(tab, tab.selected_contact).has_focus())

func test_selecting_a_contact_keeps_pad_focus_on_it() -> void:
	GameState.active_job_id = "steady_hands"
	var tab := _tab()
	var contacts := tab.listed_contacts()
	var other: String = contacts[contacts.size() - 1]
	_contact_button(tab, contacts[0]).grab_focus()
	tab.select_contact(other)
	await get_tree().process_frame
	assert_true(_contact_button(tab, other).has_focus())

func test_thread_is_the_scroll_target() -> void:
	var tab := _tab()
	assert_eq(tab.scroll_target(), tab._thread)
