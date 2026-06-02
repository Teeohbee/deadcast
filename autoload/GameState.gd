# autoload/GameState.gd
extends Node

var credits: int = 0
var debt: int = 80000
var last_run_result: Dictionary = {}

var current_rod: RodData = null
var current_lure: LureData = null
var selected_zone: String = "district7"

# Lure inventory: lure_id (String) → quantity (int)
var lure_inventory: Dictionary = {
    "basic_hook": 99,
    "shock_lure": 3,
    "decoy_swarm": 2,
    "deep_pulse": 2,
    "ghost_bait": 2,
}

func _ready() -> void:
    # Deferred so all class_name scripts are parsed before loading typed resources
    call_deferred("_load_defaults")

func _load_defaults() -> void:
    current_rod = load("res://resources/rods/scrap_rod.tres")
    current_lure = load("res://resources/lures/basic_hook.tres")

func add_credits(amount: int) -> void:
    credits += amount
    EventBus.credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
    if credits < amount:
        return false
    credits -= amount
    EventBus.credits_changed.emit(credits)
    return true

func select_zone(zone_id: String) -> void:
    selected_zone = zone_id
    EventBus.zone_changed.emit(zone_id)

func equip_lure(lure: LureData) -> void:
    current_lure = lure

func get_lure_id(lure: LureData) -> String:
    # Only works for disk-loaded resources; LureData.new() has an empty path
    assert(lure.resource_path != "", "LureData must be loaded from a .tres file to derive an ID")
    return lure.resource_path.get_file().get_basename()

func has_lure_stock(lure: LureData) -> bool:
    var lure_id = get_lure_id(lure)
    return lure_inventory.get(lure_id, 0) > 0

func consume_lure_use() -> void:
    if current_lure == null:
        return
    var lure_id = get_lure_id(current_lure)
    if lure_inventory.has(lure_id):
        lure_inventory[lure_id] = max(0, lure_inventory[lure_id] - 1)
