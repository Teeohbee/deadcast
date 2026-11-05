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
# Hostiles (AGGRESSIVE) fight the override combo - see scenes/dive_run/override/OverrideSim.gd.
@export var anchor_strength: int = 12 # the hostile's anchor: BREAK damage needed to land it
# Attacks it charges, cycled: "NAME|code", code in u/d/l/r (never a prefix of a rig code).
@export var override_attacks: PackedStringArray = []
@export var override_twist: String = "" # "", "ghost" (reversed/hidden), "requote"
@export var override_art: String = ""   # HostileWireframe model: drone, ghost, engine, core, swarm, payload, building
@export var override_hit: int = 12      # T a landed attack puts on the line
@export var entity_id: String = ""
@export var returning_variants: Array[CatchData] = []

# Winch haul: when this is on, picking an option that hauls (HaulTurn.hauls) runs the
# haul instead of the resist/fail dice. Dials are multipliers on the
# haul's base rates - see scenes/dive_run/haul/HaulSim.gd.
@export var haul_enabled: bool = false
@export var haul_weight: float = 1.0  # how fast load builds while hauling
@export var haul_slip: float = 1.0    # how fast it sinks back when you let go
@export var haul_tempo: float = 1.0   # how often hits come
@export var haul_erratic: bool = false # unpredictable hit timing
# Fragment pool: each haul draws 3-4 (HaulFragments.draw) and hides them in the hex
# block, so two hauls of the same contact read differently. Hints, not sentences.
@export var fragments: PackedStringArray = []
# Pool entries every haul carries, e.g. a thread that runs across zones.
@export var fragments_always: PackedStringArray = []
