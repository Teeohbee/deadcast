# scenes/ui/HUD.gd
class_name HUD
extends CanvasLayer

@onready var credits_label: Label = $VBoxContainer/CreditsLabel
@onready var tension_label: Label = $VBoxContainer/TensionLabel
@onready var slot_label: Label = $VBoxContainer/SlotLabel
@onready var corruption_label: Label = $VBoxContainer/CorruptionLabel

var _max_tension: int = 80
var _current_tension: float = 0.0

func _ready() -> void:
	$VBoxContainer.theme = UIStyle.get_theme()
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.tension_changed.connect(_on_tension_changed)
	EventBus.max_tension_changed.connect(_on_max_tension_changed)
	EventBus.slot_changed.connect(_on_slot_changed)
	EventBus.corruption_changed.connect(_on_corruption_changed)
	credits_label.text = "CR: %d" % GameState.credits
	_update_tension_label(0.0)
	UIStyle.apply_label(credits_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(slot_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(corruption_label, UIStyle.COL_WARNING)
	corruption_label.text = "NOISE:  0%"

func _on_credits_changed(value: int) -> void:
	credits_label.text = "CR: %d" % value

func _on_max_tension_changed(value: int) -> void:
	_max_tension = value
	_update_tension_label(_current_tension)

func _on_tension_changed(value: float) -> void:
	_current_tension = value
	_update_tension_label(value)

func _on_slot_changed(current: int, total: int) -> void:
	slot_label.text = "Catch %d of %d" % [current, total]

func _update_tension_label(value: float) -> void:
	var pct := value / float(_max_tension) if _max_tension > 0 else 0.0
	var filled := int(pct * 12.0)
	var bar := "█".repeat(filled) + "░".repeat(12 - filled)
	tension_label.text = "T [%s] %d/%d" % [bar, int(value), _max_tension]
	var color := UIStyle.COL_DEBT if pct >= 0.75 else (UIStyle.COL_WARNING if pct >= 0.5 else UIStyle.COL_TEXT)
	UIStyle.apply_label(tension_label, color)

func _on_corruption_changed(value: float) -> void:
	var pct := int(value)
	corruption_label.text = "NOISE: %3d%%" % pct
	var color := UIStyle.COL_DEBT if value >= 50.0 else UIStyle.COL_WARNING
	UIStyle.apply_label(corruption_label, color)
