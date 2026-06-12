# autoload/CatchPool.gd
extends Node

var _loaded_catches: Array[CatchData] = []

func load_catches_for_zone(zone: String) -> void:
	_loaded_catches = []
	var zone_data: ZoneData = load("res://resources/zones/%s.tres" % zone)
	if not zone_data:
		push_warning("CatchPool: could not load zone resource for '%s'" % zone)
		return
	for catch in zone_data.catches:
		if catch is CatchData:
			_loaded_catches.append(catch)

const LAYER_SLOTS: Dictionary = {
	CatchData.Layer.SHALLOWS: 3,
	CatchData.Layer.MID: 3,
	CatchData.Layer.DEEP: 2,
}

func generate_layer(zone: String, layer: CatchData.Layer, corruption: float = 0.0,
		entity_bias: bool = false) -> Array[CatchData]:
	load_catches_for_zone(zone)
	var column: Array[CatchData] = []
	var seen_types: Array = []
	for i in LAYER_SLOTS[layer]:
		var catch = _draw_catch(layer, corruption, seen_types, entity_bias)
		if catch:
			catch = _apply_entity_substitution(catch)
			column.append(catch)
			seen_types.append(catch.catch_type)
	return column

func draw_replacement(zone: String, layer: CatchData.Layer, corruption: float) -> CatchData:
	load_catches_for_zone(zone)
	var pool = _loaded_catches.filter(func(c: CatchData) -> bool: return c.layer == layer)
	if pool.is_empty():
		return null
	var weights = pool.map(func(c: CatchData) -> float:
		var w: float = _calculate_weight(c, corruption, [])
		if c.catch_type == CatchData.CatchType.ENTITY or c.behavior == CatchData.BehaviorType.AGGRESSIVE:
			w *= 0.2
		return w)
	var picked: CatchData = _weighted_random(pool, weights)
	return _apply_entity_substitution(picked)

func _draw_catch(layer: CatchData.Layer, corruption: float, seen_types: Array,
		entity_bias: bool) -> CatchData:
	var pool = _loaded_catches.filter(func(c: CatchData) -> bool: return c.layer == layer)
	if pool.is_empty():
		return null
	var weights = pool.map(func(c: CatchData) -> float: return _calculate_weight(c, corruption, seen_types, entity_bias))
	return _weighted_random(pool, weights)

func _calculate_weight(catch: CatchData, corruption: float, seen_types: Array,
		entity_bias: bool = false) -> float:
	var weight: float = 1.0

	if catch.catch_type == CatchData.CatchType.ENTITY:
		weight += corruption * 0.02
		if entity_bias:
			weight *= 1.5

	if catch.catch_type in seen_types:
		weight *= 0.5

	return max(weight, 0.0)

func _apply_entity_substitution(catch: CatchData) -> CatchData:
	if catch.entity_id == "" or catch.returning_variants.is_empty():
		return catch
	var count: int = GameState.encountered_entities.get(catch.entity_id, 0)
	if count == 0:
		return catch
	return catch.returning_variants[min(count - 1, catch.returning_variants.size() - 1)]

func _weighted_random(items: Array, weights: Array) -> Variant:
	var total: float = 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return items[0]
	var roll = randf() * total
	var cumulative: float = 0.0
	for i in items.size():
		cumulative += float(weights[i])
		if roll <= cumulative:
			return items[i]
	return items[-1]
