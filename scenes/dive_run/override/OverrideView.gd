# scenes/dive_run/override/OverrideView.gd
# The encounter frame for a hostile: portrait, anchor, intent, the charging lock with its
# timer, the battle log and the rig's codes. Ported from the look book
# (planning/deadcast/2026-11-05-override-combo-v2.html). Draws in a 964x686 design
# space, scaled to fit. Reads OverrideRun's state and owns no rules.
class_name OverrideView
extends Control

const DESIGN := Vector2(964, 686)
const CX := DESIGN.x / 2.0
const ARROW := { "u": "↑", "d": "↓", "l": "←", "r": "→" }
const NAMES := { "break": "BREAK", "splice": "SPLICE", "shock": "SHOCK", "decoy": "DECOY", "isolate": "ISOLATE" }
const STAGE_TOP := 236.0
const STAGE_BOTTOM := 478.0
const LOG_TOP := 500.0
const CODES_TOP := 590.0
const BOX := 60.0
const SMALL_BOX := 24.0

var sim: OverrideSim
var title := ""
var class_line := ""
## HostileWireframe model name (drone, ghost, ...).
var art := ""
var hint := ""
## Rig command id -> effect text for the code list.
var fx := {}
## [{ text, color }], newest last.
var log_lines: Array[Dictionary] = []
var hit_t := 9.0     # since the hostile's attack landed
var deal_t := 9.0    # since we hurt it
var wrong_t := 9.0   # since a wrong press
var null_t := 9.0    # since a lock went in
var requote_t := 9.0 # since a re-quote
var fired_id := ""
var fired_t := 9.0

var _font: Font = preload("res://fonts/IBMPlexMono-Regular.otf")
var _wireframe: HostileWireframe
const PORTRAIT := Rect2(24, 30, 276, 190)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wireframe = HostileWireframe.new()
	_wireframe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wireframe.set_hostile(art)
	add_child(_wireframe)
	resized.connect(_layout_portrait)
	_layout_portrait()

func _layout_portrait() -> void:
	if _wireframe == null:
		return
	var k := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	_wireframe.position = (size - DESIGN * k) / 2.0 + PORTRAIT.position * k
	_wireframe.size = PORTRAIT.size * k

func hurt() -> void:
	deal_t = 0.0
	if _wireframe != null:
		_wireframe.hurt()

func advance(dt: float) -> void:
	hit_t += dt
	deal_t += dt
	wrong_t += dt
	null_t += dt
	requote_t += dt
	fired_t += dt
	queue_redraw()

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
	var shake := Vector2.ZERO
	if hit_t < 0.35:
		var s := (1.0 - hit_t / 0.35) * 10.0
		shake = Vector2(randf_range(-s, s), randf_range(-s, s) * 0.5)
	draw_set_transform((size - DESIGN * k) / 2.0 + shake, 0.0, Vector2(k, k))

	# frame: red border, title on the line
	draw_rect(Rect2(Vector2(1, 12), DESIGN - Vector2(2, 13)), DeckStyle.PANEL_BG)
	draw_rect(Rect2(Vector2(1, 12), DESIGN - Vector2(2, 13)), DeckStyle.RED, false, 1.0)
	var frame_title := "encounter // hostile"
	var tw := _font.get_string_size(frame_title, HORIZONTAL_ALIGNMENT_LEFT, -1, DeckStyle.SIZE_BODY).x
	draw_rect(Rect2(10, 2, tw + 8, 20), DeckStyle.BG)
	_text(frame_title, Vector2(14, 17), DeckStyle.RED, DeckStyle.SIZE_BODY)

	_draw_info()
	draw_line(Vector2(10, STAGE_TOP), Vector2(DESIGN.x - 10, STAGE_TOP), DeckStyle.BORDER)
	draw_line(Vector2(10, STAGE_BOTTOM), Vector2(DESIGN.x - 10, STAGE_BOTTOM), DeckStyle.BORDER)
	_draw_stage()
	_draw_log()
	_draw_codes()
	draw_set_transform(Vector2.ZERO)

func _draw_info() -> void:
	var x := 330.0
	_text(title, Vector2(x, 56), DeckStyle.RED, DeckStyle.SIZE_VALUE)
	_text(class_line, Vector2(x, 80), DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	_text("ANCHOR", Vector2(x, 110), DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	var bar_x := x + 70.0
	var seg_w := minf(26.0, 500.0 / float(sim.anchor_max)) - 3.0
	for i in sim.anchor_max:
		var c := DeckStyle.RED if i < sim.anchor else Color(DeckStyle.RED, 0.15)
		draw_rect(Rect2(bar_x + i * (seg_w + 3.0), 100, seg_w, 12), c)
	_text("%d / %d" % [sim.anchor, sim.anchor_max], Vector2(bar_x + sim.anchor_max * (seg_w + 3.0) + 8.0, 111), DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	_text("INTENT", Vector2(x, 140), DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	_text(_intent(), Vector2(x + 70, 140), DeckStyle.AMBER if sim.exposed() else DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	if sim.buffer != "":
		_text("input  " + _arrows(sim.buffer), Vector2(x, 172), DeckStyle.DIM, DeckStyle.SIZE_BODY)

func _intent() -> String:
	match sim.phase:
		OverrideSim.CHARGE:
			return "charging %s · EXPOSED" % sim.lock.name
		OverrideSim.GAP:
			var next: Dictionary = sim.attacks[sim.round_number % sim.attacks.size()]
			return "next: %s" % next.name
	return "-"

func _arrows(code: String) -> String:
	var out: Array[String] = []
	for d in code:
		out.append(ARROW[d])
	return " ".join(out)

func _draw_stage() -> void:
	match sim.phase:
		OverrideSim.CHARGE:
			_draw_charge()
		OverrideSim.GAP:
			if null_t < 0.8:
				_text("NULLED", Vector2(CX, 330), DeckStyle.GREEN, 24, HORIZONTAL_ALIGNMENT_CENTER)
			else:
				_text("...", Vector2(CX, 330), DeckStyle.DIM, DeckStyle.SIZE_VALUE, HORIZONTAL_ALIGNMENT_CENTER)
				_text("it's winding up", Vector2(CX, 356), DeckStyle.DIM, DeckStyle.SIZE_BODY, HORIZONTAL_ALIGNMENT_CENTER)
	if hint != "" and sim.phase != OverrideSim.DONE:
		_text(hint, Vector2(CX, STAGE_BOTTOM - 12), DeckStyle.SKY, DeckStyle.SIZE_AMBIENT, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_charge() -> void:
	var lock := sim.lock
	var left := clampf(1.0 - sim.t / sim.dur, 0.0, 1.0)
	_text("!! INCOMING · %s" % lock.name, Vector2(CX, 270), DeckStyle.AMBER, DeckStyle.SIZE_VALUE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("EXPOSED: BREAK x2 now · start the override before it fires (%dT)" % sim.hit_damage,
		Vector2(CX, 294), DeckStyle.DIM, DeckStyle.SIZE_BODY, HORIZONTAL_ALIGNMENT_CENTER)
	var bar := Rect2(CX - 320, 308, 640, 10)
	draw_rect(bar, Color(DeckStyle.GREEN, 0.08))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * left, bar.size.y)), DeckStyle.RED if left < 0.35 else DeckStyle.AMBER)

	var code: String = lock.code
	var n := code.length()
	var progress := sim.lock_progress()
	var reversed_mode: bool = lock.mode == OverrideSim.MODE_REVERSED
	# Boxes in the order shown; a reversed lock fills from the right.
	var shown := OverrideSim.reversed(lock.expected) if reversed_mode else str(lock.expected)
	var total_w := n * BOX + (n - 1) * 12.0
	var x0 := CX - total_w / 2.0
	var wrong := wrong_t < 0.26
	for i in n:
		var done := i >= n - progress if reversed_mode else i < progress
		var is_next := i == (n - progress - 1 if reversed_mode else progress)
		var glyph: String = ARROW[shown[i]]
		var border := DeckStyle.AMBER
		var fill := Color.TRANSPARENT
		var ink := DeckStyle.AMBER
		if done:
			fill = DeckStyle.GREEN
			border = DeckStyle.GREEN
			ink = DeckStyle.BG
		elif is_next:
			border = DeckStyle.TEXT
			ink = DeckStyle.TEXT
		if lock.mode == OverrideSim.MODE_HIDDEN and not done and not is_next:
			glyph = "?"
			border = DeckStyle.DIM
			ink = DeckStyle.DIM
		if lock.requoted and not done and i >= int(lock.requote_from) and requote_t < 0.6:
			border = DeckStyle.SKY
			ink = DeckStyle.SKY
		if i == int(lock.garble_index) and not done and sin(Time.get_ticks_msec() / 90.0) > 0.3:
			glyph = "░"
		if wrong and not done:
			border = DeckStyle.RED
			ink = DeckStyle.RED
		var r := Rect2(x0 + i * (BOX + 12.0), 336, BOX, BOX)
		if fill.a > 0.0:
			draw_rect(r, fill)
		draw_rect(r, border, false, 2.0)
		_text(glyph, Vector2(r.get_center().x, r.position.y + 42), ink, 30, HORIZONTAL_ALIGNMENT_CENTER)
	var twist := ""
	var twist_color := DeckStyle.DIM
	match lock.mode:
		OverrideSim.MODE_REVERSED:
			twist = "REVERSED · enter right to left"
			twist_color = DeckStyle.AMBER
		OverrideSim.MODE_HIDDEN:
			twist = "HIDDEN · each arrow shows as you reach it"
		OverrideSim.MODE_REQUOTE:
			twist = "RE-QUOTED · read it again" if lock.requoted else "VOLATILE · may re-quote"
			twist_color = DeckStyle.SKY
	if twist != "":
		_text(twist, Vector2(CX, 424), twist_color, DeckStyle.SIZE_AMBIENT, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_log() -> void:
	for i in log_lines.size():
		var line: Dictionary = log_lines[i]
		var c: Color = line.color if i == log_lines.size() - 1 else Color(line.color, 0.6)
		_text(line.text, Vector2(20, LOG_TOP + 14 + i * 20), c, DeckStyle.SIZE_BODY)

func _draw_codes() -> void:
	var cands := {}
	if sim.buffer != "":
		for c in sim.candidates():
			cands[c.id] = true
	var shown: Array[String] = []
	for id in OverrideSim.RIG_ORDER:
		if sim.uses.has(id):
			shown.append(id)
	var col_w := (DESIGN.x - 40.0 - 14.0) / 2.0
	for i in shown.size():
		var id := shown[i]
		var x := 20.0 + (i % 2) * (col_w + 14.0)
		var y := CODES_TOP + (i / 2) * 32.0
		var ok := sim.available(id)
		var alpha := 1.0 if ok else 0.3
		var r := Rect2(x, y, col_w, 28)
		if fired_id == id and fired_t < 0.35:
			draw_rect(r, Color(DeckStyle.GREEN, 0.25))
		draw_rect(r, DeckStyle.GREEN if cands.has(id) else DeckStyle.BORDER, false, 1.0)
		_text(NAMES[id], Vector2(x + 10, y + 19), Color(DeckStyle.GREEN, alpha), DeckStyle.SIZE_BODY)
		var code: String = OverrideSim.RIG[id]
		var matched := sim.buffer.length() if cands.has(id) else 0
		for j in code.length():
			var b := Rect2(x + 110 + j * (SMALL_BOX + 4.0), y + 2, SMALL_BOX, SMALL_BOX)
			if j < matched:
				draw_rect(b, DeckStyle.GREEN)
			draw_rect(b, Color(DeckStyle.DIM, alpha), false, 1.0)
			_text(ARROW[code[j]], Vector2(b.get_center().x, y + 20), Color(DeckStyle.BG if j < matched else DeckStyle.TEXT, alpha), 15, HORIZONTAL_ALIGNMENT_CENTER)
		var text: String = fx.get(id, "") if ok or not sim.guided else "unlocks next round"
		var text_x := x + 110 + 4 * (SMALL_BOX + 4.0) + 10
		_text(_fit(text, col_w - (text_x - x) - 8.0, DeckStyle.SIZE_AMBIENT), Vector2(text_x, y + 19), Color(DeckStyle.DIM, alpha), DeckStyle.SIZE_AMBIENT)

## Cut text to a width, ending in an ellipsis.
func _fit(text: String, width: float, font_size: int) -> String:
	if _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return text
	var cut := text
	while cut.length() > 1 and _font.get_string_size(cut + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		cut = cut.substr(0, cut.length() - 1)
	return cut.strip_edges() + "…"
