# scenes/barge_hub/panels/sonar_wave.gd
class_name SonarWave
extends Control

var amplitude := 15.0
var frequency := 0.02
var line_color := DeckStyle.GREEN
var speed := 3.0
var _offset := 0.0

func _ready() -> void:
	clip_contents = true

func _process(delta: float) -> void:
	_offset += delta * speed
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#040705"))

	var grid := Color(DeckStyle.BORDER.r, DeckStyle.BORDER.g, DeckStyle.BORDER.b, 0.5)
	for x in range(0, int(w), 40):
		draw_line(Vector2(x, 0), Vector2(x, h), grid)
	for y in range(0, int(h), 30):
		draw_line(Vector2(0, y), Vector2(w, y), grid)

	var amp := minf(amplitude, h * 0.4)
	var points := PackedVector2Array()
	for x in int(w):
		var y := h / 2.0 + sin(x * frequency + _offset) * amp + sin(x * 0.08 - _offset) * (amp / 3.0)
		points.append(Vector2(x, y))
	if points.size() >= 2:
		draw_polyline(points, line_color, 1.5, true)

	var ty := h / 2.0 + sin(_offset) * 5.0
	draw_dashed_line(Vector2(0, ty), Vector2(w, ty),
		Color(DeckStyle.RED.r, DeckStyle.RED.g, DeckStyle.RED.b, 0.3), 1.0, 5.0)
