# tests/test_deck_prompt_row.gd
extends GutTest

func before_each() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY

func _row(action: String, caption: String, trailing := false) -> DeckPromptRow:
	var r := DeckPromptRow.new(action, caption, DeckStyle.GREEN, DeckStyle.SIZE_BODY, trailing)
	add_child_autofree(r)
	return r

func test_keyboard_shows_keycap_then_caption_and_no_icon() -> void:
	var r := _row("cycle_lure", "CYCLE LURE")
	assert_eq(r.label.text, "[TAB] CYCLE LURE")
	assert_false(r.shows_icon())

func test_pad_shows_icon_and_bare_caption() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var r := _row("cycle_lure", "CYCLE LURE")
	assert_eq(r.label.text, "CYCLE LURE")
	assert_true(r.shows_icon())
	assert_same(r.icon_rect.texture, InputGlyphs.icon("cycle_lure"))

func test_icon_leads_unless_trailing() -> void:
	var lead := _row("accept", "GO")
	assert_lt(lead.icon_rect.get_index(), lead.label.get_index())
	var trail := _row("accept", "PRESS", true)
	assert_gt(trail.icon_rect.get_index(), trail.label.get_index())

func test_trailing_keycap_follows_caption() -> void:
	var r := _row("accept", "PRESS", true)
	assert_eq(r.label.text, "PRESS [ENTER]")

func test_empty_caption_on_a_pad_hides_the_label() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var r := _row("next", "")
	assert_false(r.label.visible)

func test_icon_is_tinted_and_sized_to_the_text() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var r := _row("accept", "GO")
	assert_eq(r.icon_rect.self_modulate, DeckStyle.GREEN)
	assert_gt(r.icon_rect.custom_minimum_size.y, float(DeckStyle.SIZE_BODY))

func test_swaps_on_device_change() -> void:
	var r := _row("accept", "GO")
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	InputGlyphs.device_changed.emit(InputGlyphs.Mode.PAD)
	assert_true(r.shows_icon())
	assert_eq(r.label.text, "GO")

func test_set_caption_rerenders() -> void:
	var r := _row("accept", "GO")
	r.set_caption("STOP")
	assert_eq(r.label.text, "[ENTER] STOP")

func test_disconnects_when_it_leaves_the_tree() -> void:
	var baseline := InputGlyphs.device_changed.get_connections().size()
	var r := DeckPromptRow.new("accept", "GO")
	add_child(r)
	assert_eq(InputGlyphs.device_changed.get_connections().size(), baseline + 1)
	r.queue_free()
	await get_tree().process_frame
	assert_eq(InputGlyphs.device_changed.get_connections().size(), baseline)
