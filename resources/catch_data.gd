# resources/catch_data.gd
class_name CatchData
extends Resource

enum CatchType { DATA, BIO, MECH, ENTITY }
enum BehaviorType { PASSIVE, RESISTANT, AGGRESSIVE, NEGOTIATING }
enum Layer { SHALLOWS, MID, DEEP }

@export var catch_name: String = ""
@export var catch_type: CatchType = CatchType.DATA
@export var behavior: BehaviorType = BehaviorType.PASSIVE
@export var corruption_gain: int = 0
@export var options: Array[CatchOption] = []
@export var zone_weights: Dictionary = {}
@export var flavor_text: String = ""
@export var layer: Layer = Layer.SHALLOWS
