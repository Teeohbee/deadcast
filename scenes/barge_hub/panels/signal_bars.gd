# scenes/barge_hub/panels/signal_bars.gd
extends Control
class_name SignalBars

const BARS := 5
var _phase := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(54, 16)

func _process(delta: float) -> void:
	_phase += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return
	var bar_w := w / float(BARS) - 2.0
	for i in BARS:
		var lvl: float
		if i == BARS - 1:
			lvl = 0.3  # last bar always weak - reads as "reaching"
		else:
			lvl = 0.45 + 0.45 * (0.5 + 0.5 * sin(_phase + i * 1.3))
		var bh := h * lvl
		var x := i * (bar_w + 2.0)
		var col := DeckStyle.GREEN if i < BARS - 1 else DeckStyle.BORDER
		draw_rect(Rect2(x, h - bh, bar_w, bh), col)
