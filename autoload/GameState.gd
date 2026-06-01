# autoload/GameState.gd
extends Node

var credits: int = 0
var debt: int = 80000
var last_run_result: Dictionary = {}

func add_credits(amount: int) -> void:
    credits += amount
    EventBus.credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
    if credits < amount:
        return false
    credits -= amount
    EventBus.credits_changed.emit(credits)
    return true
