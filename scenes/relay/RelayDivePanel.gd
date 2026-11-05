# scenes/relay/RelayDivePanel.gd
# relay_7 on the dive rail, under the hydrophone: Marta on the line. Her lines
# type in and the panel lights while she speaks, then recedes. While the winch
# is hauling she holds: lines queue and play once the haul resolves.
class_name RelayDivePanel
extends TerminalPanel

const MAX_LINES_SHOWN := 6
const SECONDS_PER_CHARACTER := 0.024
const SECONDS_LIT_AFTER_TYPING := 1.7

# Everything she said this dive, for the RELAY thread: [{"who", "text"}].
var transcript: Array[Dictionary] = []
# Test seam: lines appear whole, with no typing or lighting.
var instant := false

var _first_dive := false
var _holding := false
var _queued: Array[String] = []
var _rows: VBoxContainer
var _random := RandomNumberGenerator.new()

func _ready() -> void:
	title = "relay_7"
	ambient = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows = VBoxContainer.new()
	_rows.alignment = BoxContainer.ALIGNMENT_END
	_rows.add_theme_constant_override("separation", 10)
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_rows)

func setup(first_dive: bool, random_seed: int = -1) -> void:
	_first_dive = first_dive
	if random_seed >= 0:
		_random.seed = random_seed

# A moment in the dive happened; Marta may have something to say about it.
func on_moment(moment: String, context: Dictionary = {}) -> void:
	var said: Array = transcript.map(func(line: Dictionary) -> String: return line.text)
	var line := RelayDiveLines.pick(moment, context, _first_dive, said, _random)
	if line == "":
		return
	transcript.append({"who": RelayScripts.CONTACT_MARTA, "text": line})
	if _holding:
		_queued.append(line)
	else:
		_show(line)

func hold() -> void:
	_holding = true

func release() -> void:
	_holding = false
	for line in _queued:
		_show(line)
	_queued.clear()

func shown_lines() -> Array[String]:
	var lines: Array[String] = []
	for row in _rows.get_children():
		lines.append((row.get_child(1) as Label).text)
	return lines

func _show(line: String) -> void:
	for row in _rows.get_children():
		(row.get_child(1) as Label).add_theme_color_override("font_color", DeckStyle.DIM)
	var row := VBoxContainer.new()
	var speaker := Label.new()
	speaker.text = "marta ›"
	DeckStyle.apply_label(speaker, DeckStyle.SKY, DeckStyle.SIZE_AMBIENT)
	row.add_child(speaker)
	var text := Label.new()
	text.text = line
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DeckStyle.apply_label(text, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	row.add_child(text)
	_rows.add_child(row)
	while _rows.get_child_count() > MAX_LINES_SHOWN:
		var oldest := _rows.get_child(0)
		_rows.remove_child(oldest)
		oldest.queue_free()
	if instant:
		return
	text.visible_characters = 0
	modulate = Color.WHITE
	var typing := create_tween()
	typing.tween_property(text, "visible_characters", line.length(), line.length() * SECONDS_PER_CHARACTER)
	typing.tween_interval(SECONDS_LIT_AFTER_TYPING)
	typing.tween_callback(func() -> void: modulate = resting_modulate())
