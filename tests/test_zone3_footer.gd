# tests/test_zone3_footer.gd
extends GutTest

const FOOTER := preload("res://scenes/ui/Zone3Footer.tscn")

func _make() -> Node:
	var f := FOOTER.instantiate()
	add_child_autofree(f)
	return f

func test_tabs_have_no_function_key_labels() -> void:
	var f := _make()
	await get_tree().process_frame
	for btn in f._tab_buttons:
		assert_false(btn.text.contains("[F"), "tab should not show fake F-keys")

func test_tabs_are_not_pad_focusable() -> void:
	var f := _make()
	await get_tree().process_frame
	for btn in f._tab_buttons:
		assert_eq(btn.focus_mode, Control.FOCUS_NONE)

func test_bumper_hints_use_glyphs() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var f := _make()
	await get_tree().process_frame
	assert_string_contains(f._next_hint.text, "[R1]")
	assert_string_contains(f._prev_hint.text, "[L1]")
