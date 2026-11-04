# scenes/dive_run/hydrophone.gd
# Rail widget: passive-listen feed. Ambient deep-line chatter that degrades as the
# signal corrupts - clean sonar returns at high SIG, garbled entity whispers at high
# corruption. Pure atmosphere (no tells); reskins EventBus.corruption_changed and
# reuses TextFX.corrupt at the current glitch intensity.
class_name HydrophonePanel
extends TerminalPanel

const MAX_LINES := 6

# Tier 0: clean / 1: noisy / 2: whispers. Selected by corruption (see tier_for).
const LINES := {
	0: [
		"sonar return: 1 contact, bearing 040",
		"thermal vent, 40ft starboard",
		"current steady, 0.3kn",
		"ballast nominal",
		"hull pressure holding",
	],
	1: [
		"sonar return: ...partial echo",
		"signal scatter on the low band",
		"something moved. no contact.",
		"carrier drift +4ms",
		"...repeating sequence on 80hz",
	],
	2: [
		"it knows the line is here",
		"...it sings...",
		"d o n t   s u r f a c e",
		"the haul is listening",
		"WE HAVE BEEN HERE BEFORE",
	],
}

static func tier_for(corruption: float) -> int:
	if corruption >= 70.0:
		return 2
	if corruption >= 30.0:
		return 1
	return 0

var _feed: VBoxContainer
var _timer: Timer
var _corruption: float = 0.0

func _ready() -> void:
	title = "hydrophone"
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_feed = VBoxContainer.new()
	_feed.add_theme_constant_override("separation", 2)
	add_child(_feed)

	_timer = Timer.new()
	_timer.wait_time = 2.5
	_timer.timeout.connect(_emit_line)
	add_child(_timer)
	_timer.start()

	EventBus.corruption_changed.connect(_on_corruption_changed)

func _on_corruption_changed(value: float) -> void:
	_corruption = value

func _emit_line() -> void:
	var tier := tier_for(_corruption)
	var pool: Array = LINES[tier]
	var raw: String = pool[randi() % pool.size()]
	var intensity := DiveFormat.glitch_intensity(_corruption)
	var line := Label.new()
	line.text = "· " + TextFX.corrupt(raw, intensity)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var col := DeckStyle.DIM
	if tier == 2:
		col = DeckStyle.RED
	elif tier == 1:
		col = DeckStyle.AMBER
	DeckStyle.apply_label(line, col, DeckStyle.SIZE_AMBIENT)
	_feed.add_child(line)
	if _feed.get_child_count() > MAX_LINES:
		var old := _feed.get_child(0)
		_feed.remove_child(old)
		old.queue_free()
