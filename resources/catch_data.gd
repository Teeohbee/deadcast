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
@export var flavor_text: String = ""
@export var layer: Layer = Layer.SHALLOWS
@export var anchor_strength: int = 3  # Used by AGGRESSIVE behavior: turns needed to reel in
@export var entity_id: String = ""
@export var returning_variants: Array[CatchData] = []

# Winch haul (District 7 spike): when the zone hauls and this is on, picking a paying
# option runs the haul instead of the resist/fail dice. Dials are multipliers on the
# haul's base rates - see scenes/dive_run/haul/HaulSim.gd.
@export var haul_enabled: bool = false
@export var haul_weight: float = 1.0  # how fast load builds while hauling
@export var haul_slip: float = 1.0    # how fast it sinks back when you let go
@export var haul_tempo: float = 1.0   # how often hits come
@export var haul_erratic: bool = false # unpredictable hit timing
# Hidden in the hex block; read as the payload rises. Hints, not always sentences.
@export var fragments: PackedStringArray = []
