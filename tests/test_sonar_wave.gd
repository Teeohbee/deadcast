# tests/test_sonar_wave.gd
extends GutTest

func _make_wave() -> SonarWave:
	var w := SonarWave.new()
	add_child_autofree(w)
	return w

func test_default_line_color_is_green() -> void:
	assert_eq(_make_wave().line_color, DeckStyle.GREEN)

func test_default_speed_is_three() -> void:
	assert_eq(_make_wave().speed, 3.0)

func test_line_color_is_settable() -> void:
	var w := _make_wave()
	w.line_color = DeckStyle.SKY
	assert_eq(w.line_color, DeckStyle.SKY)
