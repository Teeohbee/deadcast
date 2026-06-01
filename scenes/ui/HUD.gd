# scenes/ui/HUD.gd
class_name HUD
extends CanvasLayer

@onready var credits_label: Label = $VBoxContainer/CreditsLabel
@onready var tension_bar: ProgressBar = $VBoxContainer/TensionBar

func _ready() -> void:
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.tension_changed.connect(_on_tension_changed)
	credits_label.text = "CR: %d" % GameState.credits
	tension_bar.value = 0.0

func _on_credits_changed(value: int) -> void:
	credits_label.text = "CR: %d" % value

func _on_tension_changed(value: float) -> void:
	tension_bar.value = value

func set_max_tension(max_val: int) -> void:
	tension_bar.max_value = float(max_val)
