# scenes/barge_hub/BargeHub.gd
extends Control

@onready var debt_label: Label = $VBoxContainer/DebtLabel
@onready var credits_label: Label = $VBoxContainer/CreditsLabel
@onready var dive_button: Button = $VBoxContainer/DiveButton

func _ready() -> void:
    dive_button.pressed.connect(_on_dive_pressed)
    EventBus.credits_changed.connect(_refresh_labels)
    _refresh_labels(GameState.credits)
    debt_label.text = "DEBT: %d CR" % GameState.debt

func _refresh_labels(_ignored: int = 0) -> void:
    credits_label.text = "CREDITS: %d CR" % GameState.credits

func _on_dive_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/dive_run/DiveRun.tscn")
