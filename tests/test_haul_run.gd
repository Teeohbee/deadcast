extends GutTest
# HaulRun is one haul on screen: input, sim, fragments, view, sounds and the result
# card. Tests drive tick() with scripted button states instead of real input.

const DT := 1.0 / 60.0
const STEADY := { "weight": 1.0, "slip": 0.6, "tempo": 1.0, "erratic": false }
const WORDS := ["PAYROLL", "0447-K", "TRANSFER", "KESSLER", "VOID"]

var _results: Array = []

func before_each() -> void:
	_results.clear()
	Audio.clear_cue_history()

func _run(difficulty := "normal", dials := STEADY) -> HaulRun:
	var run := HaulRun.new()
	run.setup(dials, difficulty, PackedStringArray(WORDS), "[#]", "encrypted pension record", HaulSim.Lcg.new(3))
	add_child_autofree(run)
	run.set_process(false)
	run.finished.connect(func(r: Dictionary) -> void: _results.append(r))
	return run

## Plays until the haul is over, letting go 0.3s into each amber warning (what the game teaches).
func _play(run: HaulRun, bot := HaulSim.prompt) -> void:
	var m := {}
	var steps := 0
	run.tick(DT, false) # a haul only starts on a fresh press
	while run.sim.phase != HaulSim.DONE and steps < 3600:
		run.tick(DT, bot.call(run.sim, m))
		steps += 1

func _continue(run: HaulRun) -> void:
	for i in 30:
		run.tick(DT, false)
	run.tick(DT, true)

func test_a_prompt_player_lands_clean_and_reads_every_fragment() -> void:
	var run := _run()
	_play(run)
	assert_eq(run.sim.outcome, HaulSim.CLEAN)
	_continue(run)
	assert_eq(_results.size(), 1)
	var r: Dictionary = _results[0]
	assert_true(r.outcome in ["clean", "perfect"])
	assert_eq(r.hits, 0)
	assert_eq(r.read, WORDS.size())
	assert_eq(r.total, WORDS.size())
	assert_eq(r.par, HaulSim.par(STEADY, "normal"))

func test_landing_under_par_is_perfect() -> void:
	var run := _run()
	_play(run, HaulSim.expert)
	_continue(run)
	assert_eq(_results[0].outcome, "perfect")

func test_hauling_through_the_hits_is_messy_and_costs_fragments() -> void:
	var run := _run("tutorial", { "weight": 0.5, "slip": 0.6, "tempo": 1.0, "erratic": false })
	_play(run, func(_s: HaulSim, _m: Dictionary) -> bool: return true)
	_continue(run)
	var r: Dictionary = _results[0]
	assert_eq(r.outcome, "messy")
	assert_gt(r.hits, 0)
	assert_lt(r.read, WORDS.size(), "hits scrambled something")
	assert_has(Audio.cue_history, "haul_hit")

func test_holding_forever_snaps_and_recovers_nothing() -> void:
	var run := _run()
	_play(run, func(_s: HaulSim, _m: Dictionary) -> bool: return true)
	_continue(run)
	var r: Dictionary = _results[0]
	assert_eq(r.outcome, "snap")
	assert_eq(r.read, 0)
	for f in r.fragments:
		assert_eq(f.state, HaulFragments.LOST)
	assert_has(Audio.cue_history, "line_snap")

func test_a_button_still_held_from_the_card_does_not_start_the_haul() -> void:
	var run := _run()
	for i in 30:
		run.tick(DT, true) # A still down from picking the option
	assert_eq(run.sim.phase, HaulSim.READY)
	run.tick(DT, false)
	run.tick(DT, true)
	assert_eq(run.sim.phase, HaulSim.LIVE)

func test_the_result_waits_for_a_fresh_press() -> void:
	var run := _run()
	_play(run, HaulSim.expert)
	for i in 60:
		run.tick(DT, true) # still holding as it lands
	assert_eq(_results.size(), 0, "holding through the landing doesn't skip the result")
	run.tick(DT, false)
	run.tick(DT, true)
	assert_eq(_results.size(), 1)
	run.tick(DT, false)
	run.tick(DT, true)
	assert_eq(_results.size(), 1, "finished emits once")

func test_warnings_and_landing_play_their_cues() -> void:
	var run := _run()
	_play(run)
	assert_has(Audio.cue_history, "haul_tell")
	assert_has(Audio.cue_history, "haul_land")
	assert_has(Audio.cue_history, "haul_decode")

func test_the_view_draws_every_phase_without_errors() -> void:
	var run := _run("tutorial")
	await wait_process_frames(1)
	run.tick(DT, false)
	run.tick(DT, true)
	for i in 90:
		run.tick(DT, true)
	await wait_process_frames(1)
	_play(run)
	await wait_process_frames(1)
	assert_true(run.result_card.visible)
	assert_eq(HaulView.ROWS, 18)

func test_opening_prompt_leads_with_the_pad_button() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var run := _run("tutorial")
	assert_eq(run.view.status, "hold to haul")
	assert_same(run.view.status_icon, InputGlyphs.icon("haul"))
	assert_eq(run.view.hint, "hold to haul the payload up")
	assert_same(run.view.hint_icon, InputGlyphs.icon("haul"))

func test_opening_prompt_uses_the_keycap_on_a_keyboard() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY
	var run := _run("tutorial")
	assert_eq(run.view.status, "[SPACE] hold to haul")
	assert_null(run.view.status_icon)

func test_later_status_lines_drop_the_icon() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var run := _run()
	run.tick(DT, false)
	run.tick(DT, true)
	assert_eq(run.view.status, "hauling")
	assert_null(run.view.status_icon)

func test_result_card_continue_prompt_is_device_aware() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var run := _run()
	_play(run)
	var rows := run.result_card.find_children("*", "DeckPromptRow", true, false)
	assert_eq(rows.size(), 1)
	var row: DeckPromptRow = rows[0]
	assert_eq(row.label.text, "continue")
	assert_true(row.shows_icon())
