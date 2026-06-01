# scenes/dive_run/LineSystem.gd
class_name LineSystem
extends Node

const MAX_CORRUPTION: float = 100.0

@export var max_tension: int = 80
@export var max_depth: int = 100  # feet; fixed at Scrap Rod cap for Phase 1

var tension: float = 0.0
var corruption: float = 0.0
var depth: float = 0.0  # tracked but not yet used for gating (Phase 2)

signal snapped
signal tension_updated(value: float)

func apply_tension(delta: int) -> void:
    tension = clampf(tension + delta, 0.0, float(max_tension))
    tension_updated.emit(tension)
    if tension >= float(max_tension):
        snapped.emit()

func add_corruption(delta: int) -> void:
    corruption = clampf(corruption + delta, 0.0, MAX_CORRUPTION)

func reset() -> void:
    tension = 0.0
    corruption = 0.0
    tension_updated.emit(tension)
