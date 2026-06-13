# scenes/barge_hub/panels/maintenance_log_panel.gd
class_name MaintenanceLogPanel
extends TerminalPanel

const MAX_LINES := 8
const AMBIENT_LINES: Array[String] = [
	"TORQUE SENSOR: Calibration cycle complete. Baseline nominal.",
	"MATERIAL SCAN: Carbon-fibre composite batch integrity verified.",
	"THERMAL: Workshop bay temperature stable at 18.4°C.",
	"PARTS INVENTORY: Tension spring stock checked. 3 units available.",
	"DIAGNOSTIC: Reel motor draw within acceptable parameters.",
	"WELD CHECK: Micro-fracture scan returned no anomalies.",
	"LUBRICANT: Auto-dispense cycle triggered on rod housing mount.",
]

var _lines: PackedStringArray = []
var _rtl: RichTextLabel
var _timer: Timer

func _ready() -> void:
	title = "maintenance_log"
	custom_minimum_size = Vector2(0, 120)

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
