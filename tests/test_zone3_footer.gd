# tests/test_zone3_footer.gd
extends GutTest

const FOOTER := preload("res://scenes/ui/Zone3Footer.tscn")

var _saved_run_count: int

func before_each() -> void:
	_saved_run_count = GameState.run_count
	UIController.fresh_tabs.clear()

func after_each() -> void:
	GameState.run_count = _saved_run_count

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
	assert_same(f._next_hint.icon_rect.texture, InputGlyphs.icon("next"))
	assert_same(f._prev_hint.icon_rect.texture, InputGlyphs.icon("prev"))

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

func _visible_tab_labels(f: Node) -> Array[String]:
	var labels: Array[String] = []
	for btn in f._tab_buttons:
		if btn.visible:
			labels.append(btn.text)
	return labels

func _visible_dividers(f: Node) -> int:
	var count := 0
	for child in f.tab_row.get_children():
		if child is Label and child.text == "│" and child.visible:
			count += 1
	return count

func test_a_new_operator_sees_deck_bunk_and_relay() -> void:
	GameState.run_count = 0
	var f := _make()
	await get_tree().process_frame
	assert_eq(_visible_tab_labels(f), ["DECK", "BUNK", "RELAY"] as Array[String])
	assert_eq(_visible_dividers(f), 2)

func test_tabs_appear_as_runs_complete() -> void:
	GameState.run_count = 0
	var f := _make()
	await get_tree().process_frame
	GameState.run_count = 1
	UIController.screen_changed.emit("deck")
	assert_eq(_visible_tab_labels(f), ["DECK", "WORKSHOP", "BUNK", "RELAY", "VENDORS"] as Array[String])
	assert_eq(_visible_dividers(f), 4)

func test_fresh_tabs_are_marked_new_until_visited() -> void:
	GameState.run_count = 1
	var f := _make()
	await get_tree().process_frame
	UIController.fresh_tabs = ["workshop"] as Array[String]
	UIController.screen_changed.emit("deck")
	var workshop: Button = f._tab_buttons[1]
	assert_eq(workshop.text, "WORKSHOP NEW")
	UIController.fresh_tabs.clear()
	UIController.screen_changed.emit("workshop")
	assert_eq(workshop.text, "WORKSHOP")
