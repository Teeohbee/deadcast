# scenes/barge_hub/panels/cipher_log_panel.gd
class_name CipherLogPanel
extends TerminalPanel

const MAX_LINES := 8
const AMBIENT_LINES: Array[String] = [
	"ENTROPY: pool reseeded, 87% saturation.",
	"KEYGEN: brute-force scheduler idle.",
	"CIPHER: rotor sync verified against host clock.",
	"HEURISTIC: known-plaintext window widened.",
	"CHANNEL: payload checksum holding steady.",
	"VAULT: cold-storage index defragmented.",
	"SIGINT: stray carrier tone filtered out.",
]

var _lines: PackedStringArray = []
var _rtl: RichTextLabel
var _timer: Timer

func _ready() -> void:
	title = "cipher_log"
	ambient = true
	custom_minimum_size = Vector2(0, 110)

	_rtl = RichTextLabel.new()
	_rtl.bbcode_enabled = true
	_rtl.scroll_active = false
	_rtl.fit_content = false
	_rtl.clip_contents = true
	_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rtl.add_theme_color_override("default_color", DeckStyle.DIM)
	_rtl.add_theme_font_size_override("normal_font_size", DeckStyle.SIZE_AMBIENT)
	_rtl.resized.connect(_render)
	add_child(_rtl)

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_ambient_tick)
	add_child(_timer)
	_restart_timer()

func append_line(text: String) -> void:
	var stamp := Time.get_time_string_from_system()
	_lines.append("[color=#22c55e][%s][/color] %s" % [stamp, text])
	while _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	_render()

func _render() -> void:
	var cap := _fit_lines(_rtl.size.y, _line_height(), MAX_LINES)
	_rtl.text = "\n".join(_lines.slice(maxi(0, _lines.size() - cap)))

func _line_height() -> float:
	var font := _rtl.get_theme_font("normal_font")
	var fs := _rtl.get_theme_font_size("normal_font_size")
	return font.get_height(fs) if font else float(fs)

static func _fit_lines(height: float, line_height: float, cap: int) -> int:
	if height <= 0.0 or line_height <= 0.0:
		return cap
	return clampi(int(height / line_height), 1, cap)

func _on_ambient_tick() -> void:
	append_line(AMBIENT_LINES[randi() % AMBIENT_LINES.size()])
	_restart_timer()

func _restart_timer() -> void:
	_timer.wait_time = randf_range(6.0, 8.0)
	_timer.start()
