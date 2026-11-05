# resources/lure_data.gd
class_name LureData
extends Resource

# WARNING: do not reorder — integer values are baked into .tres files
enum LureEffect { NONE, SHOCK, DECOY, DEEP_PULSE, GHOST_BAIT, SPLICE }
const SPLICE_VENT_T: int = 20

func role_label() -> String:
	match effect:
		LureEffect.DEEP_PULSE: return "SCOUT"
		LureEffect.DECOY: return "ESCAPE"
		LureEffect.SHOCK: return "FIGHT"
		LureEffect.SPLICE: return "SURVIVE"
		LureEffect.GHOST_BAIT: return "BAIT"
	return ""

@export var lure_name: String = ""
@export var effect: LureEffect = LureEffect.NONE
@export var purchase_cost: int = 0
@export var description: String = ""
