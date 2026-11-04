# scenes/barge_hub/panels/log_feed_panel.gd
extends TerminalPanel

const MAX_LINES := 8
const AMBIENT_LINES: Array[String] = [
	"NETWORK: Diver transceiver ping matched @ 42ms.",
	"SYS: Auto-purging memory registers to prevent packet overflow.",
	"DIAGNOSTIC: Thermoelectric transducer battery calibrated normal.",
	"DECK SENSOR: Pressure displacement detected inside district 7.",
	"RADIO COUPLING: Frequency drift noticed on telemetry line.",
	"MERC_NET: Deep-diving protocols updated by host administrator.",
	"SYS: Sector scanning sweep bypassed proxy servers successfully.",
]

var _lines: PackedStringArray = []
var _rtl: RichTextLabel
var _timer: Timer

func _ready() -> void:
	title = "system_log_feed"
	custom_minimum_size = Vector2(0, 120)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_rtl = RichTextLabel.new()
	_rtl.bbcode_enabled = true
	_rtl.scroll_active = false
	_rtl.fit_content = false
	_rtl.clip_contents = true
	_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rtl.add_theme_color_override("default_color", DeckStyle.DIM)
	_rtl.add_theme_font_size_override("normal_font_size", DeckStyle.SIZE_AMBIENT)
	# Re-render when the panel resizes (e.g. a taller zone card shrinks this
	# panel) so we only ever show whole lines, never a clipped final line.
	_rtl.resized.connect(_render)
	add_child(_rtl)

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_ambient_tick)
	add_child(_timer)
	_restart_timer()

	EventBus.deck_log.connect(append_line)
	EventBus.zone_changed.connect(_on_zone_changed)
	if GameState.run_count == 0:
		append_line("DECK COMM: New operator registered. Pick a ruin and cast a line.")
	else:
		append_line("DECK COMM: Welcome back, Diver. Keep your eye on the debt ledger.")

func append_line(text: String) -> void:
	var stamp := Time.get_time_string_from_system()
	_lines.append("[color=#22c55e][%s][/color] %s" % [stamp, text])
	while _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	_render()

# Show only as many of the newest lines as fit the panel's current height, so
# the most recent message is always whole rather than clipped at the bottom.
func _render() -> void:
	var cap := _fit_lines(_rtl.size.y, _line_height(), MAX_LINES)
	_rtl.text = "\n".join(_lines.slice(maxi(0, _lines.size() - cap)))

func _line_height() -> float:
	var font := _rtl.get_theme_font("normal_font")
	var fs := _rtl.get_theme_font_size("normal_font_size")
	return font.get_height(fs) if font else float(fs)

# Whole lines that fit `height`. Falls back to `cap` before the panel is laid
# out (height 0), which self-corrects on the first `resized` signal.
static func _fit_lines(height: float, line_height: float, cap: int) -> int:
	if height <= 0.0 or line_height <= 0.0:
		return cap
	return clampi(int(height / line_height), 1, cap)

func _on_zone_changed(zone_id: String) -> void:
	append_line("TRANS-RECEIVER: Realigned focus to [%s]. Sector payload analyzed." % zone_id.to_upper())

func _on_ambient_tick() -> void:
	append_line(AMBIENT_LINES[randi() % AMBIENT_LINES.size()])
	_restart_timer()

func _restart_timer() -> void:
	_timer.wait_time = randf_range(6.0, 8.0)
	_timer.start()
