# resources/rod_data.gd
class_name RodData
extends Resource

@export var rod_name: String = ""
@export var tension_cap: int = 80
@export var repair_cost: int = 500
@export var purchase_cost: int = 0
@export var description: String = ""
# One verb per rod (shop economy plan): BRAKE turns the first haul snap of a
# dive into a messy haul; QUIET halves signal loss from contacts.
enum LineTrait { NONE, BRAKE, QUIET }
@export var line_trait: LineTrait = LineTrait.NONE

func trait_label() -> String:
	match line_trait:
		LineTrait.BRAKE: return "BRAKE"
		LineTrait.QUIET: return "QUIET"
	return ""

func has_brake() -> bool:
	return line_trait == LineTrait.BRAKE

func sig_scale() -> float:
	return 0.5 if line_trait == LineTrait.QUIET else 1.0

# A contact's signal cost on this line. Rounds up so a cost never vanishes.
func scaled_sig(corruption_gain: int) -> int:
	if corruption_gain <= 0:
		return corruption_gain
	return ceili(corruption_gain * sig_scale())
