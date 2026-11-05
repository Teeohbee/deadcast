extends GutTest
# The winch haul rules are a port of the HTML prototype's haul-sim.js, which stays the
# tuning source. tests/fixtures/haul_golden.json was produced by that JS with the same
# seeded LCG and bots, so these tests catch any drift in the port.

const GOLDEN_PATH := "res://tests/fixtures/haul_golden.json"
const DT := 1.0 / 60.0
const EPS := 1e-6

var _golden: Dictionary

func before_all() -> void:
	_golden = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))

func _dials(d: Dictionary) -> Dictionary:
	return { "weight": float(d.weight), "slip": float(d.slip), "tempo": float(d.tempo), "erratic": bool(d.erratic) }

func _policy(name: String) -> Callable:
	match name:
		"prompt": return HaulSim.prompt
		"expert": return HaulSim.expert
	return func(_s: HaulSim, _m: Dictionary) -> bool: return true

func _run(c: Dictionary) -> Dictionary:
	var s := HaulSim.new(_dials(c.dials), c.difficulty, HaulSim.Lcg.new(int(c.seed)))
	var m := {}
	var events := {}
	var steps := 0
	var bot := _policy(c.policy)
	while s.phase != HaulSim.DONE and steps < 3600:
		for e in s.step(DT, bot.call(s, m)):
			events[e] = events.get(e, 0) + 1
		steps += 1
	return { "s": s, "steps": steps, "events": events }

func test_golden_cases_match_the_prototype() -> void:
	assert_gt(_golden.cases.size(), 0, "golden fixture loaded")
	for c in _golden.cases:
		var label := "%s/%s/%s" % [c.contact, c.difficulty, c.policy]
		var r := _run(c)
		var s: HaulSim = r.s
		assert_eq(s.outcome, c.outcome, label + " outcome")
		assert_eq(r.steps, int(c.steps), label + " steps")
		assert_eq(s.hits, int(c.hits), label + " hits")
		assert_eq(s.absorbed, int(c.absorbed), label + " absorbed")
		assert_almost_eq(s.t, float(c.t), EPS, label + " time")
		assert_almost_eq(s.peak, float(c.peak), EPS, label + " peak load")
		assert_almost_eq(s.depth, float(c.depth), EPS, label + " depth")
		for e in c.events:
			assert_eq(r.events.get(e, 0), int(c.events[e]), label + " '%s' events" % e)

func test_par_matches_the_prototype() -> void:
	for c in _golden.cases:
		if c.policy != "hold":
			continue
		var key: String = "%s/%s" % [c.contact, c.difficulty]
		assert_almost_eq(HaulSim.par(_dials(c.dials), c.difficulty), float(_golden.par[key]), EPS, key + " par")

func test_holding_only_never_lands_clean() -> void:
	for c in _golden.cases:
		if c.policy == "hold":
			assert_ne(_run(c).s.outcome, HaulSim.CLEAN, "%s/%s" % [c.contact, c.difficulty])

func test_nothing_happens_until_you_haul() -> void:
	var s := HaulSim.new({ "weight": 1.0, "slip": 1.0, "tempo": 1.0, "erratic": false }, "normal")
	for i in 120:
		assert_eq(s.step(DT, false), [])
	assert_eq(s.phase, HaulSim.READY)
	assert_eq(s.t, 0.0)
	assert_eq(s.step(DT, true)[0], "start")
	assert_eq(s.phase, HaulSim.LIVE)

func test_a_hit_alone_never_snaps_the_line() -> void:
	var s := HaulSim.new({ "weight": 1.0, "slip": 1.0, "tempo": 1.0, "erratic": false }, "hard")
	s.step(DT, true)
	s.line_load = 98.0
	s.next_hit = s.t + DT / 2.0
	var ev := s.step(DT, true)
	assert_has(ev, "hit")
	assert_eq(s.line_load, 99.0, "hits cap at 99")
	assert_ne(s.phase, HaulSim.DONE)

func test_letting_go_in_the_red_saves_the_line() -> void:
	var s := HaulSim.new({ "weight": 1.0, "slip": 1.0, "tempo": 0.4, "erratic": false }, "normal")
	s.step(DT, true)
	s.line_load = 95.0
	for i in int(s.grace / DT) - 2:
		s.step(DT, true)
	assert_eq(s.phase, HaulSim.LIVE, "still inside grace")
	for i in 30:
		s.step(DT, false)
	assert_eq(s.strain, 0.0, "strain recovers once you let go")
	assert_eq(s.phase, HaulSim.LIVE)
