# scenes/barge_hub/panels/bar_meter.gd
class_name BarMeter
extends Control

# btop-style segmented load bar: filled blocks up to the live value, dim blocks
# after, a peak-hold tick and a redline marker. The live value eases toward a
# target with a little jitter so it breathes like real telemetry.

const SEGMENTS := 28

var target := 0.6           # 0..1 value the meter settles toward
var redline := 0.85         # 0..1 position of the danger marker
var fill_color := DeckStyle.GREEN
var _value := 0.6
var _peak := 0.6
var _jitter := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 18)
	_value = target

func _process(delta: float) -> void:
	_jitter += delta * 6.0
	var wobble := sin(_jitter) * 0.015 + sin(_jitter * 2.7) * 0.008
	var goal := clampf(target + wobble, 0.0, 1.0)
	_value = lerpf(_value, goal, clampf(delta * 4.0, 0.0, 1.0))
	_peak = maxf(_peak * 0.999, _value) if _value < _peak else _value
	queue_redraw()

# Pure: how many segments light up for a given fraction. Tested directly.
func lit_segments(frac: float) -> int:
	return int(round(clampf(frac, 0.0, 1.0) * SEGMENTS))

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 4.0 or h < 4.0:
		return

	var gap := 2.0
	var seg_w := (w - gap * (SEGMENTS - 1)) / float(SEGMENTS)
	var lit := lit_segments(_value)
	var peak_seg := lit_segments(_peak)
	var redline_seg := lit_segments(redline)
	var dim := Color(fill_color.r, fill_color.g, fill_color.b, 0.16)

	for i in SEGMENTS:
		var x := i * (seg_w + gap)
		var col := dim
		if i < lit:
			# segments past the redline burn red regardless of base colour
			col = DeckStyle.RED if i >= redline_seg else fill_color
		elif i == peak_seg - 1 and peak_seg > lit:
			col = Color(fill_color.r, fill_color.g, fill_color.b, 0.7)  # peak-hold tick
		draw_rect(Rect2(x, 0.0, seg_w, h), col)

	# redline marker: thin vertical tick at the danger threshold
	var rx := redline_seg * (seg_w + gap) - gap * 0.5
	draw_line(Vector2(rx, -1.0), Vector2(rx, h + 1.0),
		Color(DeckStyle.RED.r, DeckStyle.RED.g, DeckStyle.RED.b, 0.6), 1.0)
