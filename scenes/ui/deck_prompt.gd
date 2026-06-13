# scenes/ui/deck_prompt.gd
# Device-aware prompt binding. Sets a control's text to the canonical
# "[GLYPH] LABEL" form and keeps it in sync as the input device changes.
# The refresh is disconnected on tree_exited so navigating between screens does
# not pile up dead connections on the InputGlyphs autoload.
class_name DeckPrompt

static func bind(target: Control, action: String, label: String) -> void:
	var refresh := func(_mode: int = 0) -> void:
		if is_instance_valid(target):
			target.set("text", "%s %s" % [InputGlyphs.glyph(action), label])
	refresh.call(InputGlyphs.mode)
	InputGlyphs.device_changed.connect(refresh)
	target.tree_exited.connect(func() -> void:
		if InputGlyphs.device_changed.is_connected(refresh):
			InputGlyphs.device_changed.disconnect(refresh))
