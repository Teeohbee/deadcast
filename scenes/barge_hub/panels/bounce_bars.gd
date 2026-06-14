# scenes/barge_hub/panels/bounce_bars.gd
class_name BounceBars
extends Control

# btop/VU-style spectrum: a row of bars bouncing on their own phases with a
# peak-hold cap that drifts back down. Reads as live audio off the transmission.

const BARS := 16
const PEAK_FALL := 0.4

var bar_color := DeckStyle.SKY
var _phase := 0.0
var _peaks: PackedFloat32Array = PackedFloat32Array()

func _ready() -> void:
	clip_contents = true
	for i in BARS:
		_peaks.append(0.0)

# Pure: bar height fraction for a given bar at a given time. Tested directly.
func bar_level(index: int, t: float) -> float:
	var a := 0.5 + 0.5 * sin(t * 2.3 + index * 0.7)
	var b := 0.5 + 0.5 * sin(t * 5.1 + index * 1.9)
	return clampf(a * 0.6 + b * 0.4, 0.0, 1.0)

func _process(delta: float) -> void:
	_phase += delta
	for i in BARS:
		var lvl := bar_level(i, _phase)
		_peaks[i] = maxf(lvl, _peaks[i] - PEAK_FALL * delta)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 4.0 or h < 4.0:
		return
	var gap := 2.0
	var bar_w := (w - gap * (BARS - 1)) / float(BARS)
	var dim := Color(bar_color.r, bar_color.g, bar_color.b, 0.18)
	for i in BARS:
		var x := i * (bar_w + gap)
		var lvl := bar_level(i, _phase)
		var bh := maxf(1.0, lvl * h)
		draw_rect(Rect2(x, 0.0, bar_w, h), dim)            # track
		draw_rect(Rect2(x, h - bh, bar_w, bh), bar_color)  # live bar
		var py: float = clampf(h - _peaks[i] * h, 0.0, h - 1.0)
		draw_rect(Rect2(x, py, bar_w, 1.0),
			Color(bar_color.r, bar_color.g, bar_color.b, 0.8))  # peak-hold cap
