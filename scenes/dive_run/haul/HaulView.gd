# scenes/dive_run/haul/HaulView.gd
# Signal trace: the winch line drawn as an oscilloscope trace from the winch head down
# to the payload, with the payload's hex block hanging under it. Load is the bar on the
# winch head and the trace's amplitude; an incoming hit is an amber packet climbing the
# trace (distance to the winch = time to impact); fragments decode as the block rises
# through the DECODE line. Ported from planning/deadcast/2026-11-05-haul-poc.html.
#
# Draws in the prototype's 1280x800 design space, scaled to fit. Reads HaulRun's state
# and owns no rules - only cosmetic bits (hex riding up the line, filler shimmer).
class_name HaulView
extends Control

const DESIGN := Vector2(1280, 800)
const X := 640.0
const TOP := 110.0
const DOCK := TOP + 70.0
const BOT := DESIGN.y - 90.0
const SCAN_Y := DESIGN.y - 36.0
const BLOCK_GAP := 58.0 # payload centre to the block's first row
const ROW_H := 28.0
## Enough rows that the whole block has passed the decode line by the time the payload lands.
const ROWS := int((SCAN_Y - (DOCK + BLOCK_GAP)) / ROW_H)
const HEX_SIZE := 19
const SCRAMBLE := "█▓▒░"
## Text on the left stops short of the trace's widest wobble.
const LEFT_COLUMN_W := 520.0

var sim: HaulSim
var fragments: HaulFragments
var held := false
var hit_t := 9.0 # seconds since the last hit taken
var glyph := "[?]"
var title := ""
var status := ""
var status_color := DeckStyle.TEXT
var hint := ""

var _font: Font = preload("res://fonts/IBMPlexMono-Regular.otf")
var _ups: Array[Dictionary] = [] # hex riding up the line while you haul

static func payload_y(s: HaulSim) -> float:
	return BOT - s.progress() * (BOT - DOCK)

## How many block rows have risen past the decode line.
static func rows_risen(s: HaulSim) -> int:
	var above := SCAN_Y - (payload_y(s) + BLOCK_GAP)
	return clampi(ceili(above / ROW_H), 0, ROWS) if above > 0.0 else 0

static func load_color(load_pct: float) -> Color:
	if load_pct >= HaulSim.RED_ZONE:
		return DeckStyle.RED
	if load_pct >= 60.0:
		return DeckStyle.AMBER
	return DeckStyle.GREEN

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Cosmetic motion that isn't part of the rules.
func advance(dt: float) -> void:
	if sim == null:
		return
	var py := payload_y(sim)
	if held and sim.phase == HaulSim.LIVE and randf() < 0.3:
		_ups.append({ "y": py - 30.0, "txt": _rhex() + _rhex(), "side": -1 if randf() < 0.5 else 1 })
	for u in _ups:
		u.y -= dt * 300.0
	_ups = _ups.filter(func(u: Dictionary) -> bool: return u.y > TOP - 10.0)
	if fragments:
		for r in fragments.rows:
			for c in HaulFragments.COLS:
				if randf() < 0.004:
					fragments.filler[r][c] = _rhex()
	queue_redraw()

func _rhex() -> String:
	return HaulFragments.HEX[randi() % 16]

func _text(s: String, pos: Vector2, color: Color, font_size: int, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x := pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= w / 2.0
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= w
	draw_string(_font, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), DeckStyle.BG)
	if sim == null:
		return
	var k := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	draw_set_transform((size - DESIGN * k) / 2.0, 0.0, Vector2(k, k))
	var t := Time.get_ticks_msec() / 1000.0
	var live_held := held and sim.phase == HaulSim.LIVE
	var py := payload_y(sim)

	# faint grid
	var grid := Color(DeckStyle.GREEN, 0.06)
	for gx in range(0, int(DESIGN.x), 40):
		draw_line(Vector2(gx, 0), Vector2(gx, DESIGN.y), grid)
	for gy in range(0, int(DESIGN.y), 40):
		draw_line(Vector2(0, gy), Vector2(DESIGN.x, gy), grid)

	_draw_block(py)
	_draw_winch_head(live_held)
	_draw_trace(py, t, live_held)
	_draw_packet(py)
	_draw_payload(py)

	# left column, clear of the winch head and the trace
	if title != "":
		draw_multiline_string(_font, Vector2(40, 52), title, HORIZONTAL_ALIGNMENT_LEFT, LEFT_COLUMN_W, 16, -1, DeckStyle.DIM)
	if status != "":
		draw_multiline_string(_font, Vector2(40, 150), status, HORIZONTAL_ALIGNMENT_LEFT, LEFT_COLUMN_W, 20, -1, status_color)
	if hint != "":
		draw_multiline_string(_font, Vector2(40, 190), hint, HORIZONTAL_ALIGNMENT_LEFT, LEFT_COLUMN_W, 16, -1, DeckStyle.GREEN)
	draw_set_transform(Vector2.ZERO)

func _draw_block(py: float) -> void:
	if fragments == null:
		return
	var char_w := _font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, HEX_SIZE).x
	var pair_w := char_w * 3.0
	var left := X - (HaulFragments.PAIRS * pair_w - char_w) / 2.0
	var top := py + BLOCK_GAP
	for r in fragments.rows:
		var y := top + r * ROW_H
		if y < TOP + 30.0 or y > DESIGN.y + ROW_H:
			continue
		var lit: bool = fragments.lit[r]
		for c in HaulFragments.COLS:
			var ch: String = fragments.filler[r][c]
			var col := Color(DeckStyle.GREEN, 0.2 if lit else 0.11)
			var owner := fragments.owner_at(r, c)
			if owner >= 0 and lit:
				var f: Dictionary = fragments.fragments[owner]
				if f.lost:
					ch = SCRAMBLE[randi() % SCRAMBLE.length()]
					col = Color(DeckStyle.RED, 0.85)
				else:
					ch = fragments.letters[r][c]
					var fresh: bool = fragments.lit_t[r] < 0.35 and sin(fragments.lit_t[r] * 50.0) > 0.0
					var flash: bool = f.read_t >= 0.0 and f.read_t < 0.6 and sin(f.read_t * 30.0) > 0.0
					col = DeckStyle.TEXT if fresh or flash else DeckStyle.GREEN
			draw_char(_font, Vector2(left + (c >> 1) * pair_w + (c & 1) * char_w, y), ch, HEX_SIZE, col)
	# decode line the block rises through
	var x0 := left - 30.0
	var x1 := left + HaulFragments.PAIRS * pair_w + 10.0
	var dash := Color(DeckStyle.SKY, 0.6)
	var x := x0
	while x < x1:
		draw_line(Vector2(x, SCAN_Y), Vector2(minf(x + 10.0, x1), SCAN_Y), dash, 2.0)
		x += 16.0
	_text("DECODE", Vector2(left - 40.0, SCAN_Y + 6.0), DeckStyle.SKY, 15, HORIZONTAL_ALIGNMENT_RIGHT)

func _draw_winch_head(live_held: bool) -> void:
	var lc := load_color(sim.line_load)
	var bx := X - 198.0
	var bw := 396.0
	draw_rect(Rect2(X - 210, TOP - 66, 420, 52), DeckStyle.BG)
	draw_rect(Rect2(X - 200, TOP - 60, 400, 40), DeckStyle.PANEL_BG)
	draw_rect(Rect2(X - 200, TOP - 60, 400, 40), DeckStyle.BORDER, false, 1.0)
	draw_rect(Rect2(bx, TOP - 58, bw * sim.line_load / 100.0, 36), lc)
	draw_rect(Rect2(bx + bw * HaulSim.RED_ZONE / 100.0, TOP - 58, bw * (1.0 - HaulSim.RED_ZONE / 100.0), 36), Color(DeckStyle.RED, 0.25))
	# ghost: where the load lands if the coming hit catches you hauling
	if sim.telling() and live_held:
		var g0 := bw * sim.line_load / 100.0
		var g1 := bw * minf(99.0, sim.line_load + sim.hit_size) / 100.0
		draw_rect(Rect2(bx + g0, TOP - 58, g1 - g0, 36), Color(DeckStyle.RED, 0.35))
		draw_dashed_line(Vector2(bx + g1, TOP - 60), Vector2(bx + g1, TOP - 20), DeckStyle.RED, 2.0, 5.0)
	# light text with a dark outline reads over both the filled and the empty bar
	var label := "WINCH  %d%%" % roundi(sim.line_load)
	var lw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var lpos := Vector2(X - lw / 2.0, TOP - 32)
	draw_string_outline(_font, lpos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 6, DeckStyle.BG)
	draw_string(_font, lpos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, DeckStyle.TEXT)
	if sim.line_load >= HaulSim.RED_ZONE:
		_text("LET GO", Vector2(X + 220, TOP - 32), DeckStyle.RED, 24)

func _draw_trace(py: float, t: float, live_held: bool) -> void:
	var lc := load_color(sim.line_load)
	var red := sim.line_load >= HaulSim.RED_ZONE
	var amp := 1.5 + pow(sim.line_load / 100.0, 2.0) * 18.0 + (maxf(0.0, 0.35 - hit_t) * 90.0)
	var pts := PackedVector2Array()
	var y := TOP - 20.0
	while y <= py - 26.0:
		var xo := sin(y * 0.13 + t * (38.0 if live_held else 10.0)) * amp * (0.6 + 0.4 * sin(y * 0.031 + t * 3.0))
		pts.append(Vector2(X + xo, y))
		y += 3.0
	if pts.size() >= 2:
		draw_polyline(pts, DeckStyle.TEXT if red and sin(t * 40.0) > 0.0 else lc, 3.0)
	for u in _ups:
		var ux: float = X + u.side * 20.0 - (18.0 if u.side < 0 else 0.0)
		_text(u.txt, Vector2(ux, u.y), Color(DeckStyle.GREEN, 0.55), 16)

func _draw_packet(py: float) -> void:
	var f := sim.tell_progress()
	if f < 0.0:
		return
	var yk := py - 26.0 + (TOP - 20.0 - (py - 26.0)) * f
	draw_line(Vector2(X, yk + 16), Vector2(X, py - 26), Color(DeckStyle.AMBER, 0.4), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(X, yk - 16), Vector2(X + 16, yk), Vector2(X, yk + 16), Vector2(X - 16, yk)]), DeckStyle.AMBER)
	_text("%.1fs" % (sim.next_hit - sim.t), Vector2(X + 28, yk + 8), DeckStyle.AMBER, 24)

func _draw_payload(py: float) -> void:
	var edge := DeckStyle.GREEN
	if hit_t < 0.25:
		edge = DeckStyle.RED
	elif sim.telling():
		edge = DeckStyle.AMBER
	draw_rect(Rect2(X - 60, py - 26, 120, 52), DeckStyle.PANEL_BG)
	draw_rect(Rect2(X - 60, py - 26, 120, 52), edge, false, 2.0)
	_text(glyph, Vector2(X, py + 10), DeckStyle.TEXT, 30, HORIZONTAL_ALIGNMENT_CENTER)
	_text("%dft" % roundi(sim.depth), Vector2(X + 76, py + 8), DeckStyle.DIM, 22)
	if fragments and fragments.fragments.size() > 0:
		_text("%d/%d decoded" % [fragments.read_count(), fragments.fragments.size()], Vector2(X - 76, py + 8), DeckStyle.DIM, 18, HORIZONTAL_ALIGNMENT_RIGHT)
