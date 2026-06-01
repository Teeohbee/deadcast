# autoload/EventBus.gd
extends Node

signal run_ended(result: Dictionary)  # consumed by analytics/achievement layers in future phases
signal tension_changed(value: float)
signal credits_changed(value: int)
