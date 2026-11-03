# scenes/ui/screen_fx.gd
# Short, terminal-flavoured screen effects. Each one adds a temporary overlay
# or tween to the Control it is given and cleans up after itself.
class_name ScreenFX

const WIPE_NODE_NAME := "ScreenWipe"
const WIPE_SECONDS := 0.22
const WIPE_EDGE_HEIGHT := 2.0

# Redraw the screen top to bottom: a background-coloured cover slides down off
# the screen with a bright scanline on its leading edge, like a CRT repaint.
static func wipe_in(screen: Control) -> void:
	var previous_wipe := screen.get_node_or_null(WIPE_NODE_NAME)
	if previous_wipe != null:
		screen.remove_child(previous_wipe)
		previous_wipe.queue_free()

	var cover := ColorRect.new()
	cover.name = WIPE_NODE_NAME
	cover.color = DeckStyle.BG
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scanline := ColorRect.new()
	scanline.color = Color(DeckStyle.GREEN, 0.7)
	scanline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanline.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	scanline.offset_bottom = WIPE_EDGE_HEIGHT
	cover.add_child(scanline)

	screen.add_child(cover)
	var wipe := cover.create_tween()
	wipe.tween_property(cover, "anchor_top", 1.0, WIPE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	wipe.tween_callback(cover.queue_free)

# Jolt the target around its resting position, decaying to nothing.
static func shake(target: Control, strength: float, duration: float) -> void:
	var resting_position := target.position
	var jolt_count := 8
	var jolt_seconds := duration / jolt_count
	var shaking := target.create_tween()
	for jolt_number in jolt_count:
		var remaining_strength := strength * (1.0 - float(jolt_number) / jolt_count)
		var jolt := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * remaining_strength
		shaking.tween_property(target, "position", resting_position + jolt, jolt_seconds)
	shaking.tween_property(target, "position", resting_position, jolt_seconds)

# Fill the target with a colour that fades out: a hit, a warning.
static func flash(target: Control, color: Color, duration: float) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(color, 0.35)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target.add_child(overlay)
	var fade := overlay.create_tween()
	fade.tween_property(overlay, "color:a", 0.0, duration)
	fade.tween_callback(overlay.queue_free)

# Briefly cover the target with a message, as if the feed dropped out.
static func message_flash(target: Control, message: String, color: Color, duration: float) -> void:
	var overlay := ColorRect.new()
	overlay.color = DeckStyle.BG
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DeckStyle.apply_label(label, color, DeckStyle.SIZE_VALUE)
	overlay.add_child(label)
	target.add_child(overlay)
	var hold := overlay.create_tween()
	hold.tween_interval(duration)
	hold.tween_callback(overlay.queue_free)
