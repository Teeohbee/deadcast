# scenes/ui/HUD.gd
class_name HUD
extends CanvasLayer

@onready var credits_label: Label = $VBoxContainer/CreditsLabel
@onready var tension_label: Label = $VBoxContainer/TensionLabel
@onready var tension_bar: ProgressBar = $VBoxContainer/TensionBar
@onready var slot_label: Label = $VBoxContainer/SlotLabel
@onready var corruption_label: Label = $VBoxContainer/CorruptionLabel

func _ready() -> void:
	$VBoxContainer.theme = UIStyle.get_theme()
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.tension_changed.connect(_on_tension_changed)
	EventBus.slot_changed.connect(_on_slot_changed)
	EventBus.corruption_changed.connect(_on_corruption_changed)
	credits_label.text = "CR: %d" % GameState.credits
	tension_bar.value = 0.0
	_update_tension_label(0.0)
	UIStyle.apply_label(credits_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(tension_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(slot_label, UIStyle.COL_TEXT)
	UIStyle.apply_label(corruption_label, UIStyle.COL_WARNING)
	corruption_label.text = "NOISE:  0%"

func _on_credits_changed(value: int) -> void:
	credits_label.text = "CR: %d" % value

func _on_tension_changed(value: float) -> void:
	tension_bar.value = value
	_update_tension_label(value)

func _on_slot_changed(current: int, total: int) -> void:
	slot_label.text = "Catch %d of %d" % [current, total]

func _update_tension_label(value: float) -> void:
	tension_label.text = "Tension: %d / %d" % [int(value), int(tension_bar.max_value)]

func set_max_tension(max_val: int) -> void:
	tension_bar.max_value = float(max_val)
	_update_tension_label(tension_bar.value)

func _on_corruption_changed(value: float) -> void:
	var pct := int(value)
	corruption_label.text = "NOISE: %3d%%" % pct
	var color := UIStyle.COL_DEBT if value >= 50.0 else UIStyle.COL_WARNING
	UIStyle.apply_label(corruption_label, color)
