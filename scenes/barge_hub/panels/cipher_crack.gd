# scenes/barge_hub/panels/cipher_crack.gd
extends TerminalPanel
class_name CipherCrackPanel

const HEX := "0123456789ABCDEF"
const STREAM_ROWS := 3

var _active := false
var _progress := 0.0
var _graph: HistoryGraph
var _hex: RichTextLabel
var _bar: Label
var _timer: Timer

func _ready() -> void:
	title = "cipher_crack"
	custom_minimum_size = Vector2(0, 150)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	var graph_holder := Control.new()
	graph_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_holder.custom_minimum_size = Vector2(0, 56)
	root.add_child(graph_holder)

	_graph = HistoryGraph.new()
	_graph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	graph_holder.add_child(_graph)

	_hex = RichTextLabel.new()
	_hex.bbcode_enabled = true
	_hex.scroll_active = false
	_hex.fit_content = true
	_hex.add_theme_font_size_override("normal_font_size", DeckStyle.SIZE_AMBIENT)
	root.add_child(_hex)

	_bar = Label.new()
	DeckStyle.apply_label(_bar, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_bar)

	_timer = Timer.new()
	_timer.wait_time = 0.4
	_timer.timeout.connect(_tick)
	add_child(_timer)
	_timer.start()

	set_state(false, 0.0)
	_tick()  # initialise hex text immediately on first frame

# active: a payload is queued and decrypting. progress: 0..1 toward the threshold.
func set_state(active: bool, progress: float) -> void:
	_active = active
	_progress = clampf(progress, 0.0, 1.0)
	# graph throughput climbs as the crack nears completion
	_graph.set_source(active, 0.4 + 0.6 * _progress)
	_render_bar()

func _render_bar() -> void:
	var filled := int(round(_progress * 16.0))
	var bar := "█".repeat(filled) + "░".repeat(16 - filled)
	if _active:
		_bar.text = "%s  %d%%  cracking key" % [bar, int(round(_progress * 100.0))]
		DeckStyle.apply_label(_bar, DeckStyle.AMBER, DeckStyle.SIZE_AMBIENT)
	else:
		_bar.text = "%s  awaiting payload" % ("░".repeat(16))
		DeckStyle.apply_label(_bar, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)

func _tick() -> void:
	if not _active:
		_hex.text = "[color=#16251d]%s[/color]" % _dead_rows()
		return
	var rows: Array[String] = []
	for i in STREAM_ROWS:
		rows.append("[color=#22c55e]%s[/color]  [color=#6b8f7a]%s[/color]" % [
			_hex_word(), _hex_word()])
	_hex.text = "\n".join(rows)

func _hex_word() -> String:
	var s := ""
	for i in 8:
		s += HEX[randi() % HEX.length()]
		if i == 3:
			s += ".."
	return s

func _dead_rows() -> String:
	var rows: Array[String] = []
	for i in STREAM_ROWS:
		rows.append("---- .. ----  ---- .. ----")
	return "\n".join(rows)
