# tests/test_deck_prompt.gd
extends GutTest

func before_each() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY

func _button() -> Button:
	var b := Button.new()
	add_child_autofree(b)
	return b

func test_bind_sets_initial_text_in_current_mode() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	var b := _button()
	DeckPrompt.bind(b, "accept", "INITIATE DIVE")
	assert_eq(b.text, "[A] INITIATE DIVE")

func test_bind_updates_text_on_device_change() -> void:
	InputGlyphs.mode = InputGlyphs.Mode.KEY
	var b := _button()
	DeckPrompt.bind(b, "accept", "INITIATE DIVE")
	assert_eq(b.text, "[ENTER] INITIATE DIVE")
	InputGlyphs.mode = InputGlyphs.Mode.PAD
	InputGlyphs.device_changed.emit(InputGlyphs.Mode.PAD)
	assert_eq(b.text, "[A] INITIATE DIVE")

func test_bind_disconnects_when_target_leaves_tree() -> void:
	var baseline := InputGlyphs.device_changed.get_connections().size()
	var b := Button.new()
	add_child(b)
	DeckPrompt.bind(b, "accept", "GO")
	assert_eq(InputGlyphs.device_changed.get_connections().size(), baseline + 1)
	b.queue_free()
	await get_tree().process_frame
	assert_eq(InputGlyphs.device_changed.get_connections().size(), baseline)
