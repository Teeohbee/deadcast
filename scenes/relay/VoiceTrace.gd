# scenes/relay/VoiceTrace.gd
# The caller's voice as a trace, drawn like the sonar wave: a flat green line
# on a faint grid while the line is quiet, a lively sky trace while someone speaks.
class_name VoiceTrace
extends Control

var speaking := false
var _time := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 64)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var width := size.x
	var height := size.y
	if width < 2.0 or height < 2.0:
		return
	var grid_x := 0.0
	while grid_x < width:
		draw_line(Vector2(grid_x, 0), Vector2(grid_x, height), DeckStyle.BORDER, 1.0)
		grid_x += 24.0
	var points := PackedVector2Array()
	var x := 0.0
	while x <= width:
		var envelope := 0.05
		if speaking:
			envelope = 0.3 + 0.7 * absf(sin(_time * 3.0 + x * 0.02))
		var wave := sin(x * 0.24 + _time * 18.0) * sin(x * 0.04 - _time * 4.0)
		points.append(Vector2(x, height * 0.5 + wave * envelope * height * 0.42))
		x += 2.0
	draw_polyline(points, DeckStyle.SKY if speaking else DeckStyle.GREEN, 1.5)
