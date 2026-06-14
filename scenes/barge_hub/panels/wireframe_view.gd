# scenes/barge_hub/panels/wireframe_view.gd
class_name WireframeView
extends Control

# Blueprint-style line-art of a purchasable item, drawn procedurally from a
# (kind, variant) descriptor so we get distinct schematics without authoring a
# bitmap per item. A faint grid and a slow scan line sell the "schematic" read.

var kind := ""      # "rod" | "lure" | ""
var variant := 0
var _scan := 0.0

func _ready() -> void:
	clip_contents = true

func set_item(item_kind: String, item_variant: int) -> void:
	kind = item_kind
	variant = item_variant
	queue_redraw()

func _process(delta: float) -> void:
	_scan = fmod(_scan + delta * 0.35, 1.0)
	queue_redraw()

# Map normalised [0,1] coords into the padded draw area. Y is down.
func _p(nx: float, ny: float) -> Vector2:
	var pad := 14.0
	var w := size.x - pad * 2.0
	var h := size.y - pad * 2.0
	return Vector2(pad + nx * w, pad + ny * h)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8.0 or h < 8.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#040705"))

	var grid := Color(DeckStyle.BORDER.r, DeckStyle.BORDER.g, DeckStyle.BORDER.b, 0.45)
	for x in range(0, int(w), 16):
		draw_line(Vector2(x, 0), Vector2(x, h), grid)
	for y in range(0, int(h), 16):
		draw_line(Vector2(0, y), Vector2(w, y), grid)

	match kind:
		"rod": _draw_rod()
		"lure": _draw_lure()
		_: _draw_empty()

	# scan line sweeping top to bottom
	var sy := _scan * h
	draw_line(Vector2(0, sy), Vector2(w, sy),
		Color(DeckStyle.SKY.r, DeckStyle.SKY.g, DeckStyle.SKY.b, 0.25), 1.0)

func _draw_empty() -> void:
	var c := Color(DeckStyle.BORDER.r, DeckStyle.BORDER.g, DeckStyle.BORDER.b, 0.8)
	draw_line(_p(0.2, 0.5), _p(0.8, 0.5), c, 1.0)
	draw_line(_p(0.5, 0.2), _p(0.5, 0.8), c, 1.0)

func _draw_rod() -> void:
	var c := DeckStyle.GREEN
	# shaft: lower-left handle up to upper-right tip
	var handle := _p(0.1, 0.85)
	var tip := _p(0.92, 0.12)
	draw_line(handle, tip, c, 1.5)
	# handle grip: a short parallel doubling near the butt
	var grip_dir := (tip - handle).normalized()
	var perp := Vector2(-grip_dir.y, grip_dir.x) * 4.0
	draw_line(handle + perp, handle + grip_dir * 28.0 + perp, c, 1.5)
	# reel: circle hung beneath the shaft near the handle
	var reel_c := handle + grip_dir * 34.0 + perp * 2.2
	draw_arc(reel_c, 9.0, 0, TAU, 24, c, 1.5)
	draw_arc(reel_c, 3.0, 0, TAU, 12, c, 1.5)
	# guide rings along the shaft; more rings on higher-tier variants
	var rings := 3 + variant
	for i in range(1, rings + 1):
		var t := float(i) / float(rings + 1)
		var pos := handle.lerp(tip, t)
		draw_arc(pos - perp * 0.5, 3.0, 0, TAU, 12, c, 1.0)

func _draw_lure() -> void:
	var c := DeckStyle.GREEN
	var nose := _p(0.18, 0.5)
	var tail := _p(0.74, 0.5)
	# teardrop body
	var body := PackedVector2Array()
	var steps := 28
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := lerpf(nose.x, tail.x, t)
		var girth := sin(t * PI) * (size.y * 0.16) * (0.7 + 0.3 * (1.0 - t))
		body.append(Vector2(x, nose.y - girth))
	for i in range(steps + 1):
		var t := 1.0 - float(i) / float(steps)
		var x := lerpf(nose.x, tail.x, t)
		var girth := sin(t * PI) * (size.y * 0.16) * (0.7 + 0.3 * (1.0 - t))
		body.append(Vector2(x, nose.y + girth))
	draw_polyline(body, c, 1.5, true)
	# eye
	draw_arc(_p(0.26, 0.5), 3.0, 0, TAU, 12, c, 1.0)
	# treble hook off the tail
	draw_line(tail, tail + Vector2(22, 0), c, 1.5)
	var hook := tail + Vector2(22, 0)
	for ang in [-0.5, 0.0, 0.5]:
		var dir := Vector2(cos(ang), sin(ang)) * 9.0
		draw_line(hook, hook + dir, c, 1.5)
		draw_line(hook + dir, hook + dir + Vector2(-3, -3), c, 1.5)
	_draw_lure_accent(nose, tail)

func _draw_lure_accent(nose: Vector2, tail: Vector2) -> void:
	var mid := nose.lerp(tail, 0.5)
	match variant:
		LureData.LureEffect.SHOCK:
			var c := DeckStyle.AMBER
			var z := PackedVector2Array([
				mid + Vector2(-10, -2), mid + Vector2(-2, -2),
				mid + Vector2(-6, 4), mid + Vector2(6, -4),
				mid + Vector2(2, 2), mid + Vector2(10, 2)])
			draw_polyline(z, c, 1.5)
		LureData.LureEffect.DECOY:
			var c := Color(DeckStyle.GREEN.r, DeckStyle.GREEN.g, DeckStyle.GREEN.b, 0.4)
			draw_arc(mid + Vector2(0, -22), 6.0, 0, TAU, 12, c, 1.0)
			draw_arc(mid + Vector2(0, 22), 6.0, 0, TAU, 12, c, 1.0)
		LureData.LureEffect.DEEP_PULSE:
			var c := Color(DeckStyle.SKY.r, DeckStyle.SKY.g, DeckStyle.SKY.b, 0.5)
			draw_arc(mid, 16.0, -0.6, 0.6, 12, c, 1.0)
			draw_arc(mid, 24.0, -0.6, 0.6, 12, c, 1.0)
		LureData.LureEffect.GHOST_BAIT:
			var c := Color(DeckStyle.DIM.r, DeckStyle.DIM.g, DeckStyle.DIM.b, 0.5)
			draw_dashed_line(nose, tail, c, 1.0, 4.0)
