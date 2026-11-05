extends GutTest
# The hex word-search under the haul payload: fragments hide across or down in the
# hex block, light up as rows rise past the decode line, and a hit taken while hauling
# scrambles the latest one you'd read.

const ROWS := 18
const D7_SETS := [
	["PAYROLL", "0447-K", "TRANSFER", "KESSLER", "VOID"],
	["LOT 17", "COLD", "VIABLE", "4C", "SEALED"],
	["MK II", "PATROL", "PING", "GATE 9"],
	["FLOOD NIGHT", "GATE 9 OPEN", "EVAC LIST", "247 NAMES", "M. VOSS"],
]

func _block(words: Array, seed := 1) -> HaulFragments:
	return HaulFragments.new(PackedStringArray(words), ROWS, HaulSim.Lcg.new(seed))

func _spelled(b: HaulFragments, f: Dictionary) -> String:
	var out := ""
	for cell: Vector2i in f.cells:
		out += b.letters[cell.x][cell.y]
	return out

func test_every_fragment_is_hidden_across_or_down_and_spells_itself() -> void:
	for seed in range(1, 41):
		for words in D7_SETS:
			var b := _block(words, seed)
			assert_eq(b.fragments.size(), words.size(), "all placed (seed %d)" % seed)
			for f in b.fragments:
				assert_eq(_spelled(b, f), HaulFragments.clean(f.word), f.word)
				var first: Vector2i = f.cells[0]
				var last: Vector2i = f.cells[-1]
				var across := first.x == last.x
				for k in f.cells.size():
					var want := first + (Vector2i(0, k) if across else Vector2i(k, 0))
					assert_eq(f.cells[k], want, "%s is one straight run" % f.word)
				assert_lt(last.x, ROWS)
				assert_lt(last.y, HaulFragments.COLS)

func test_fragments_start_in_story_order_from_the_top() -> void:
	for seed in range(1, 41):
		var b := _block(D7_SETS[3], seed)
		for i in range(1, b.fragments.size()):
			assert_true(b.fragments[i].cells[0].x >= b.fragments[i - 1].cells[0].x,
				"fragment %d starts no higher than %d (seed %d)" % [i, i - 1, seed])

func test_filler_is_hex() -> void:
	var b := _block(D7_SETS[0])
	for r in ROWS:
		for c in HaulFragments.COLS:
			assert_true("0123456789ABCDEF".contains(b.filler[r][c]))

func test_a_fragment_decodes_once_all_its_rows_have_risen_past_the_line() -> void:
	var b := _block(["PAYROLL"])
	var f: Dictionary = b.fragments[0]
	var bottom: int = f.cells[-1].x
	assert_eq(b.update(0.1, bottom, false), [], "one row short")
	assert_false(b.is_read(f))
	assert_eq(b.update(0.1, bottom + 1, false), [0], "reports the newly decoded index")
	assert_true(b.is_read(f))
	assert_eq(b.update(0.1, ROWS, false), [], "only reported once")
	assert_eq(b.read_count(), 1)

func test_lit_rows_stay_lit_if_the_block_slips_back() -> void:
	var b := _block(["PAYROLL"])
	b.update(0.1, ROWS, false)
	b.update(0.1, 0, false)
	assert_true(b.lit[ROWS - 1])
	assert_eq(b.read_count(), 1)

func test_a_hit_scrambles_only_the_latest_fragment_read() -> void:
	for seed in range(1, 21):
		var b := _block(D7_SETS[0], seed)
		var upto: int = b.fragments[2].cells[-1].x + 1
		b.update(0.1, upto, false)
		var latest := -1
		for i in b.fragments.size():
			if b.fragments[i].cells.any(func(c: Vector2i) -> bool: return c.x < upto):
				latest = i
		b.update(0.1, upto, true)
		for i in b.fragments.size():
			assert_eq(b.fragments[i].lost, i == latest, "fragment %d (seed %d)" % [i, seed])

func test_a_hit_before_anything_is_read_costs_nothing() -> void:
	var b := _block(D7_SETS[0])
	b.update(0.1, 0, true)
	for f in b.fragments:
		assert_false(f.lost)

func test_a_scrambled_fragment_never_decodes() -> void:
	var b := _block(["PAYROLL"])
	var f: Dictionary = b.fragments[0]
	b.update(0.1, f.cells[0].x + 1, true) # partly risen, then hit
	assert_true(f.lost)
	assert_eq(b.update(0.1, ROWS, false), [])
	assert_eq(b.read_count(), 0)

func test_recovered_lists_read_lost_and_unread_in_story_order() -> void:
	var b := _block(D7_SETS[2])
	b.fragments[1].lost = true
	b.update(0.1, b.fragments[0].cells[-1].x + 1, false) # only the first fragment has risen
	var rec := b.recovered(false)
	assert_eq(rec.map(func(r: Dictionary) -> String: return r.word), ["MK II", "PATROL", "PING", "GATE 9"])
	assert_eq(rec[0].state, HaulFragments.READ)
	assert_eq(rec[1].state, HaulFragments.LOST)
	assert_eq(rec[3].state, HaulFragments.UNREAD)

func test_a_snapped_line_recovers_nothing() -> void:
	var b := _block(D7_SETS[0])
	b.update(0.1, ROWS, false)
	for r in b.recovered(true):
		assert_eq(r.state, HaulFragments.LOST)

func test_no_words_is_a_plain_hex_block() -> void:
	var b := _block([])
	assert_eq(b.fragments.size(), 0)
	assert_eq(b.update(0.1, ROWS, true), [])
