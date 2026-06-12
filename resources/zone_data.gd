# resources/zone_data.gd
class_name ZoneData
extends Resource

@export var zone_id: String = ""
@export var display_name: String = ""
@export var passive_tension_drain: int = 0
@export var description: String = ""
@export var catches: Array[CatchData] = []

# Display-only fields for the deck zone cards (no gameplay effect)
@export var tag_label: String = ""
@export var tag_tier: int = 0  # 0 = green, 1 = amber, 2 = red
@export var density: String = ""
@export var threat: String = ""
