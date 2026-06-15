# scenes/dive_run/dive_status_strip.gd
# Log-panel header readout: the stakes (HAUL) and the equipped LURE, right next to
# the choices. Tension reads off the biosign rail widget and SIG off hydrophone /
# the global header, so they are no longer duplicated here. Static formatter for
# testability; live values arrive over EventBus.
class_name DiveStatusStrip
extends Label

static func format_line(haul: int, lure_label: String) -> String:
	return "HAUL %dcr  ·  LURE %s" % [haul, lure_label]

var _haul: int = 0
var _lure_label: String = "—"

func _ready() -> void:
	DeckStyle.apply_label(self, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	EventBus.haul_changed.connect(_on_haul_changed)
	EventBus.lure_stock_changed.connect(_on_lure_stock_changed)

func setup(lure_label: String) -> void:
	_lure_label = lure_label
	_refresh()

func _on_haul_changed(value: int) -> void:
	_haul = value
	_refresh()

func _on_lure_stock_changed(lure_id: String, remaining: int) -> void:
	if GameState.current_lure and GameState.get_lure_id(GameState.current_lure) == lure_id:
		_lure_label = "%s x%d" % [lure_id, remaining]
	_refresh()

func _refresh() -> void:
	text = format_line(_haul, _lure_label)
