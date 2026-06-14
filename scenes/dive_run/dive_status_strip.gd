# scenes/dive_run/dive_status_strip.gd
# One-line dive readout in the log-panel header. Static formatter for testability;
# live values arrive over EventBus. Tension/SIG also visualised by the rail widgets
# (PR2) but the exact numbers live here next to the choices.
class_name DiveStatusStrip
extends Label

static func format_line(tension: int, max_tension: int, haul: int,
		corruption: float, lure_label: String) -> String:
	return "T %d/%d  ·  HAUL %dcr  ·  SIG %d%%  ·  LURE %s" % [
		tension, max_tension, haul, int(100.0 - corruption), lure_label]

var _max_tension: int = 80
var _tension: int = 0
var _haul: int = 0
var _corruption: float = 0.0
var _lure_label: String = "—"

func _ready() -> void:
	DeckStyle.apply_label(self, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	EventBus.tension_changed.connect(_on_tension_changed)
	EventBus.haul_changed.connect(_on_haul_changed)
	EventBus.corruption_changed.connect(_on_corruption_changed)
	EventBus.lure_stock_changed.connect(_on_lure_stock_changed)

func setup(max_tension: int, lure_label: String) -> void:
	_max_tension = max_tension
	_lure_label = lure_label
	_refresh()

func _on_tension_changed(value: float) -> void:
	_tension = int(value)
	_refresh()

func _on_haul_changed(value: int) -> void:
	_haul = value
	_refresh()

func _on_corruption_changed(value: float) -> void:
	_corruption = value
	_refresh()

func _on_lure_stock_changed(lure_id: String, remaining: int) -> void:
	if GameState.current_lure and GameState.get_lure_id(GameState.current_lure) == lure_id:
		_lure_label = "%s x%d" % [lure_id, remaining]
	_refresh()

func _refresh() -> void:
	text = format_line(_tension, _max_tension, _haul, _corruption, _lure_label)
	DeckStyle.apply_label(self, DeckStyle.RED if _corruption >= 50.0 else DeckStyle.DIM,
		DeckStyle.SIZE_AMBIENT)
