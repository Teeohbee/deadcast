# scenes/barge_hub/panels/history_graph.gd
class_name HistoryGraph
extends Control

# btop-style scrolling history graph: a ring buffer of samples drawn as columns
# that march right-to-left, brightest at the leading edge. Feeds itself from an
# (active, level) source so callers just describe the signal, not each sample.

const CAPACITY := 64
const PUSH_INTERVAL := 0.08

var line_color := DeckStyle.GREEN
var _samples: PackedFloat32Array = PackedFloat32Array()
var _active := false
var _level := 0.0
var _accum := 0.0

func _ready() -> void:
	clip_contents = true
	for i in CAPACITY:
		_samples.append(0.0)

func set_source(active: bool, level: float) -> void:
	_active = active
	_level = clampf(level, 0.0, 1.0)

# Push a sample, dropping the oldest. Ring buffer never exceeds CAPACITY.
func push(value: float) -> void:
	_samples.append(clampf(value, 0.0, 1.0))
	if _samples.size() > CAPACITY:
		_samples.remove_at(0)

func _next_sample() -> float:
	if _active:
		# throughput jitters around the level with the odd burst
		var burst := 0.25 if randf() < 0.12 else 0.0
		return _level * (0.55 + randf() * 0.45) + burst
	return randf() * 0.06  # idle noise floor

func _process(delta: float) -> void:
	_accum += delta
	while _accum >= PUSH_INTERVAL:
		_accum -= PUSH_INTERVAL
		push(_next_sample())
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#040705"))

	var grid := Color(DeckStyle.BORDER.r, DeckStyle.BORDER.g, DeckStyle.BORDER.b, 0.5)
	for y in range(0, int(h), 14):
		draw_line(Vector2(0, y), Vector2(w, y), grid)

	var n := _samples.size()
	if n < 2:
		return
	var col_w := w / float(n)
	var base := line_color if _active else DeckStyle.BORDER
	for i in n:
		var v: float = _samples[i]
		var bh := maxf(1.0, v * (h - 2.0))
		var x := i * col_w
		# leading edge (newest, on the right) is brightest; older columns fade
		var fade := 0.25 + 0.75 * (float(i) / float(n - 1))
		var col := Color(base.r, base.g, base.b, fade)
		draw_rect(Rect2(x, h - bh, maxf(1.0, col_w - 1.0), bh), col)
		draw_rect(Rect2(x, h - bh, maxf(1.0, col_w - 1.0), 1.0),
			Color(base.r, base.g, base.b, fade))  # bright cap
