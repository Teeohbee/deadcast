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

func test_tabs_use_readable_size() -> void:
	var f := _make()
	await get_tree().process_frame
	for btn in f._tab_buttons:
		assert_eq(btn.get_theme_font_size("font_size"), DeckStyle.SIZE_BODY)

func test_tabs_are_separated_by_dividers() -> void:
	var f := _make()
	await get_tree().process_frame
	# One divider between each pair of tabs (tabs - 1).
	var dividers := 0
	for child in f.tab_row.get_children():
		if child is Label and child.text == "│":
			dividers += 1
	assert_eq(dividers, f._tab_buttons.size() - 1)
