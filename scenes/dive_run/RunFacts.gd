# scenes/dive_run/RunFacts.gd
# What happened on one dive, in the terms Marta's jobs care about. DiveRun
# feeds it as contacts resolve; MartaJobs.is_met reads it when the run ends.
class_name RunFacts
extends RefCounted

var zone_id: String
var snapped: bool = false
var cut_line: bool = false
var entity_engaged: bool = false
var landed_types: Array[int] = []            # CatchType of each contact that paid out
var corruption_per_contact: Array[float] = [] # corruption when each contact resolved

func _init(dive_zone_id: String) -> void:
	zone_id = dive_zone_id

func note_slot(catch_type: CatchData.CatchType, credits: int, engaged: bool, corruption: float) -> void:
	corruption_per_contact.append(corruption)
	if credits > 0:
		landed_types.append(catch_type)
	if engaged or (catch_type == CatchData.CatchType.ENTITY and credits > 0):
		entity_engaged = true
