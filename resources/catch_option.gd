# resources/catch_option.gd
class_name CatchOption
extends Resource

@export var label: String = ""
@export var tension_delta: int = 0
@export var credit_value: int = 0
@export var cuts_line: bool = false
@export var flavor_text: String = ""
@export var narrative_text: String = ""

# RESISTANT behavior: if resist_chance > 0, roll against it on selection.
# On resist: apply resist_tension_penalty instead of tension_delta; credit_value still applies.
@export var resist_chance: float = 0.0
@export var resist_tension_penalty: int = 0

# NEGOTIATING behavior: if roll_difficulty > 0, roll randf() against it.
# On fail: apply fail_tension_delta and fail_credit_value instead of the normal fields.
@export var roll_difficulty: float = 0.0
@export var fail_tension_delta: int = 0
@export var fail_credit_value: int = 0
