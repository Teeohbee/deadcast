# autoload/EventBus.gd
extends Node

signal run_ended(result: Dictionary)
signal tension_changed(value: float)
signal corruption_changed(value: float)
signal credits_changed(value: int)
signal zone_changed(zone_id: String)
signal slot_changed(current: int, total: int)
signal haul_changed(value: int)
signal slot_revealed(index: int, marker: String)
signal lure_stock_changed(lure_id: String, remaining: int)
signal deck_log(text: String)
