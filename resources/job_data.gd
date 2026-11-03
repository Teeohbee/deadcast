# resources/job_data.gd
# One of Marta's side jobs. Offered at her terminal before a dive; if the
# condition holds when the run ends (and the line didn't snap), debt drops
# by debt_relief directly.
class_name JobData
extends Resource

enum Condition { LAND_TYPE_IN_ZONE, NO_CUT_LINE, HIGH_CORRUPTION_STREAK, NO_ENTITY_ENGAGED }

@export var id: String = ""
@export var title: String = ""
@export_multiline var brief: String = ""   # Marta's voice, shown on her terminal
@export var condition: Condition = Condition.NO_CUT_LINE
@export var debt_relief: int = 0
@export var min_run: int = 1               # first run_count it can be offered on

# LAND_TYPE_IN_ZONE
@export var zone_id: String = ""
@export var catch_type: CatchData.CatchType = CatchData.CatchType.DATA

# HIGH_CORRUPTION_STREAK (corruption 0-100, i.e. SIG = 100 - corruption)
@export var corruption_threshold: float = 0.0
@export var streak_length: int = 0
