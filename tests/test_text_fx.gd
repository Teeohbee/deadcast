# tests/test_text_fx.gd
extends GutTest

var rng_full: RandomNumberGenerator
var rng_zero: RandomNumberGenerator

func before_each() -> void:
	rng_full = RandomNumberGenerator.new()
	rng_full.seed = 42
	rng_zero = RandomNumberGenerator.new()
	rng_zero.seed = 99

func test_zero_intensity_returns_unchanged() -> void:
	var text := "TENSION: 45/80  ·  slot 1/3"
	assert_eq(TextFX.corrupt(text, 0.0, rng_zero), text)

func test_full_intensity_preserves_length() -> void:
	var text := "hud_label: ZONE axiom THREAT x1.50"
	var result := TextFX.corrupt(text, 1.0, rng_full)
	assert_eq(result.length(), text.length())

func test_full_intensity_preserves_spaces() -> void:
	var text := "slot 2 / 3  ·  threat x1.20"
	var result := TextFX.corrupt(text, 1.0, rng_full)
	for i in text.length():
		if text[i] == " ":
			assert_eq(result[i], " ", "space at index %d should be preserved" % i)

func test_full_intensity_preserves_newlines() -> void:
	var text := "line one\nline two"
	var result := TextFX.corrupt(text, 1.0, rng_full)
	for i in text.length():
		if text[i] == "\n":
			assert_eq(result[i], "\n", "newline at index %d should be preserved" % i)

func test_full_intensity_preserves_structural_chars() -> void:
	var structural := ["[", "]", "(", ")", "|", "-", "·", "/", "┌", "└", "─", "│", ":", "×", "%"]
	var text := "[ TENSION ] · (slot 1/3) | -15T ┌─│ ×1.50 50%"
	var result := TextFX.corrupt(text, 1.0, rng_full)
	for i in text.length():
		if text[i] in structural:
			assert_eq(result[i], text[i],
				"structural char '%s' at index %d should be preserved" % [text[i], i])

func test_corruption_chars_are_single_width() -> void:
	var text := "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var result := TextFX.corrupt(text, 1.0, rng_full)
	for ch in result:
		assert_true(ch.unicode_at(0) < 0x2500 or ch.unicode_at(0) > 0x257F,
			"char '%s' (U+%04X) should not be a box-drawing char" % [ch, ch.unicode_at(0)])
		assert_true(ch.unicode_at(0) < 0xFF00 or ch.unicode_at(0) > 0xFFEF,
			"char '%s' (U+%04X) should not be a full-width char" % [ch, ch.unicode_at(0)])

func test_deterministic_with_same_seed() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 7
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 7
	var text := "TENSION: 72/80"
	assert_eq(TextFX.corrupt(text, 0.5, rng_a), TextFX.corrupt(text, 0.5, rng_b))

func test_zero_intensity_no_corruption_in_practice() -> void:
	var text := "clean text no changes"
	for i in 100:
		assert_eq(TextFX.corrupt(text, 0.0, rng_zero), text)
