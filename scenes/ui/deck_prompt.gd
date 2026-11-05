# scenes/ui/deck_prompt.gd
# Device-aware prompt binding for buttons. On a keyboard the text reads
# "[GLYPH] LABEL"; on a pad the button shows the Steam button as its icon,
# tinted to follow the button's own text colour in every state, and the text is
# just LABEL. For prompts that aren't buttons, use DeckPromptRow.
# The refresh is disconnected on tree_exited so navigating between screens does
# not pile up dead connections on the InputGlyphs autoload.
class_name DeckPrompt

const _STATES := ["normal", "focus", "hover", "pressed", "hover_pressed", "disabled"]

static func bind(target: Button, action: String, label: String) -> void:
	var refresh := func(_mode: int = 0) -> void:
		if is_instance_valid(target):
			_apply(target, action, label)
	refresh.call(InputGlyphs.mode)
	InputGlyphs.device_changed.connect(refresh)
	target.tree_exited.connect(func() -> void:
		if InputGlyphs.device_changed.is_connected(refresh):
			InputGlyphs.device_changed.disconnect(refresh))

static func _apply(target: Button, action: String, label: String) -> void:
	var tex := InputGlyphs.icon(action)
	target.icon = tex
	if tex == null:
		target.text = "%s %s" % [InputGlyphs.glyph(action), label]
		return
	target.text = label
	var font_size := target.get_theme_font_size("font_size")
	target.add_theme_constant_override("icon_max_width", DeckPromptRow.icon_px(font_size))
	for state in _STATES:
		var font_key := "font_color" if state == "normal" else "font_%s_color" % state
		target.add_theme_color_override("icon_%s_color" % state, target.get_theme_color(font_key))
