# tests/test_relay_dive_panel.gd
extends GutTest

const STATE_BACKUP := "user://relay_dive_state_backup.cfg"

func before_each() -> void:
	GameState._save_to(STATE_BACKUP)
	GameState.relay_entries = []
	GameState.selected_zone = "district7"
	GameState.first_dive_hints_done = true
	GameState.active_job_id = ""

func after_each() -> void:
	GameState._load_from(STATE_BACKUP)
	DirAccess.remove_absolute(STATE_BACKUP)

func _panel(first_dive: bool) -> RelayDivePanel:
	var panel := RelayDivePanel.new()
	panel.instant = true
	add_child_autofree(panel)
	panel.setup(first_dive, 3)
	return panel

func test_a_line_shows_in_the_panel_and_the_transcript() -> void:
	var panel := _panel(true)
	panel.on_moment("cast")
	assert_eq(panel.shown_lines(), [RelayDiveLines.DIVE_ONE.cast] as Array[String])
	assert_eq(panel.transcript, [{"who": "marta", "text": RelayDiveLines.DIVE_ONE.cast}] as Array[Dictionary])

func test_she_holds_while_the_winch_is_hauling() -> void:
	var panel := _panel(true)
	panel.hold()
	panel.on_moment("cast")
	assert_eq(panel.shown_lines().size(), 0)
	panel.release()
	assert_eq(panel.shown_lines(), [RelayDiveLines.DIVE_ONE.cast] as Array[String])

func test_the_dive_rail_has_relay_7_under_the_hydrophone() -> void:
	GameState.run_count = 0
	var dive: Node = load("res://scenes/dive_run/DiveRun.tscn").instantiate()
	add_child_autofree(dive)
	await get_tree().process_frame
	await get_tree().process_frame
	var rail: Node = dive.get_node("Margin/MainRow/Rail")
	var hydrophone_index: int = dive.hydrophone.get_index()
	assert_eq(rail.get_child(hydrophone_index + 1), dive.relay_dive_panel)
	assert_eq(dive.relay_dive_panel.transcript[0].text, RelayDiveLines.DIVE_ONE.cast)

func test_a_dive_files_what_she_said_as_one_read_entry() -> void:
	GameState.run_count = 0
	var dive: Node = load("res://scenes/dive_run/DiveRun.tscn").instantiate()
	add_child_autofree(dive)
	await get_tree().process_frame
	await get_tree().process_frame
	dive._file_relay_dive_lines(false)
	var filed: Array[Dictionary] = GameState.relay_entries_for("marta")
	assert_eq(filed.size(), 1)
	assert_eq(filed[0].kind, GameState.RELAY_ENTRY_DIVE_LINE)
	assert_true(filed[0].read)
	assert_eq(filed[0].lines.back().text, RelayDiveLines.DIVE_ONE.surfaced)
