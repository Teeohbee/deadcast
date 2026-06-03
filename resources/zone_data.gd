# resources/zone_data.gd
class_name ZoneData
extends Resource

@export var zone_id: String = ""
@export var display_name: String = ""
@export var passive_tension_drain: int = 0
@export var description: String = ""
@export var catches: Array[CatchData] = []
