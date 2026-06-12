class_name DiveColumn
extends RefCounted

const LAYER_ORDER: Array = [CatchData.Layer.SHALLOWS, CatchData.Layer.MID, CatchData.Layer.DEEP]
const LAYER_DEPTH_REQ: Dictionary = {
	CatchData.Layer.SHALLOWS: 0,
	CatchData.Layer.MID: 60,
	CatchData.Layer.DEEP: 150,
}
const LAYER_NAMES: Dictionary = {
	CatchData.Layer.SHALLOWS: "shallows",
	CatchData.Layer.MID: "mid layer",
	CatchData.Layer.DEEP: "deep layer",
}

var zone_id: String
var max_depth: int
var layer_index: int = 0
var slots: Array[CatchData] = []
var slot_in_layer: int = 0
var _resolved_before_layer: int = 0

func _init(p_zone_id: String, p_max_depth: int) -> void:
	zone_id = p_zone_id
	max_depth = p_max_depth

func current_layer() -> CatchData.Layer:
	return LAYER_ORDER[layer_index]

func generate_current_layer(corruption: float, lure_effect: LureData.LureEffect) -> void:
	slots = CatchPool.generate_layer(zone_id, current_layer(), corruption, lure_effect)
	slot_in_layer = 0

func current_catch() -> CatchData:
	return slots[slot_in_layer]

func advance() -> void:
	slot_in_layer += 1

func layer_cleared() -> bool:
	return slot_in_layer >= slots.size()

func can_descend() -> bool:
	if layer_index + 1 >= LAYER_ORDER.size():
		return false
	return max_depth >= LAYER_DEPTH_REQ[LAYER_ORDER[layer_index + 1]]

func descend(corruption: float, lure_effect: LureData.LureEffect) -> void:
	_resolved_before_layer += slots.size()
	layer_index += 1
	generate_current_layer(corruption, lure_effect)

func global_slot_index() -> int:
	return _resolved_before_layer + slot_in_layer

func next_layer_name() -> String:
	return LAYER_NAMES[LAYER_ORDER[layer_index + 1]]

func next_layer_slot_count() -> int:
	return CatchPool.LAYER_SLOTS[LAYER_ORDER[layer_index + 1]]

func reachable_layer_sizes() -> Array:
	var sizes: Array = []
	for layer in LAYER_ORDER:
		if max_depth >= LAYER_DEPTH_REQ[layer]:
			sizes.append(CatchPool.LAYER_SLOTS[layer])
	return sizes

func total_reachable_slots() -> int:
	var total := 0
	for s in reachable_layer_sizes():
		total += s
	return total
