# scenes/dive_run/DiveHUD.gd
# Persistent dive status strip. All formatting is static for testability.
class_name DiveHUD
extends Control

static func format_depth_track(layer_sizes: Array, current_slot: int, markers: Dictionary) -> String:
	var groups: Array[String] = []
	var idx := 0
	for layer_size: int in layer_sizes:
		var glyphs := ""
		for i in layer_size:
			if idx < current_slot:
				glyphs += "[✓]"
			elif idx == current_slot:
				glyphs += "[▶]"
			elif markers.has(idx):
				glyphs += "[%s]" % markers[idx]
			else:
				glyphs += "[?]"
			idx += 1
		groups.append(glyphs)
	return "DEPTH  " + " ── ".join(groups)

static func format_status(haul: int, corruption: float, lure_label: String) -> String:
	return "HAUL %dcr  ·  SIG %d%%  ·  LURE %s" % [haul, int(100.0 - corruption), lure_label]

static func format_tension(tension: int, max_tension: int) -> String:
	return "T  %d/%d" % [tension, max_tension]

@onready var tension_label: Label = $VBoxContainer/TensionRow/TensionLabel
@onready var tension_bar: ProgressBar = $VBoxContainer/TensionRow/TensionBar
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var depth_label: Label = $VBoxContainer/DepthLabel
@onready var sep_label: Label = $VBoxContainer/SepLabel

var _max_tension: int = 80
var _layer_sizes: Array = []
var _current_slot: int = 0
var _markers: Dictionary = {}
var _haul: int = 0
var _corruption: float = 0.0
var _lure_label: String = "—"
var _tension_fill: StyleBoxFlat = null

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_label(tension_label, UIStyle.COL_DIM)
	UIStyle.apply_label(status_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(depth_label, UIStyle.COL_DIM)
	UIStyle.apply_label(sep_label, UIStyle.COL_SEP)

	_tension_fill = StyleBoxFlat.new()
	_tension_fill.bg_color = UIStyle.COL_TEXT
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = UIStyle.COL_BAR_BG
	tension_bar.add_theme_stylebox_override("background", bar_bg)
	tension_bar.add_theme_stylebox_override("fill", _tension_fill)

	EventBus.tension_changed.connect(_on_tension_changed)
	EventBus.corruption_changed.connect(_on_corruption_changed)
	EventBus.slot_changed.connect(_on_slot_changed)
	EventBus.haul_changed.connect(_on_haul_changed)
	EventBus.slot_revealed.connect(_on_slot_revealed)
	EventBus.lure_stock_changed.connect(_on_lure_stock_changed)

func setup(max_tension: int, layer_sizes: Array, lure_label: String) -> void:
	_max_tension = max_tension
	tension_bar.max_value = max_tension
	_layer_sizes = layer_sizes
	_lure_label = lure_label
	_refresh()

func _on_tension_changed(value: float) -> void:
	tension_bar.value = value
	tension_label.text = format_tension(int(value), _max_tension)
	if _tension_fill:
		_tension_fill.bg_color = UIStyle.COL_TEXT.lerp(UIStyle.COL_DEBT, value / float(_max_tension))

func _on_corruption_changed(value: float) -> void:
	_corruption = value
	_refresh()

func _on_slot_changed(current: int, _total: int) -> void:
	_current_slot = current - 1  # slot_changed is 1-based
	_refresh()

func _on_haul_changed(value: int) -> void:
	_haul = value
	_refresh()

func _on_slot_revealed(index: int, marker: String) -> void:
	_markers[index] = marker
	_refresh()

func _on_lure_stock_changed(lure_id: String, remaining: int) -> void:
	if GameState.current_lure and GameState.get_lure_id(GameState.current_lure) == lure_id:
		_lure_label = "%s x%d" % [lure_id, remaining]
	_refresh()

func _refresh() -> void:
	status_label.text = format_status(_haul, _corruption, _lure_label)
	depth_label.text = format_depth_track(_layer_sizes, _current_slot, _markers)
	var warn := _corruption >= 50.0
	UIStyle.apply_label(status_label, UIStyle.COL_DEBT if warn else UIStyle.COL_TEXT)
