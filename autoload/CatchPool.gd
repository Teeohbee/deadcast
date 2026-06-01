# autoload/CatchPool.gd
extends Node

var _loaded_catches: Array[CatchData] = []

func load_catches_for_zone(zone: String) -> void:
    _loaded_catches = []
    var path = "res://resources/catches/%s/" % zone
    var dir = DirAccess.open(path)
    if not dir:
        push_warning("CatchPool: no directory found at %s" % path)
        return
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
        if file_name.ends_with(".tres"):
            var resource = load(path + file_name)
            if resource is CatchData:
                _loaded_catches.append(resource)
        file_name = dir.get_next()
    dir.list_dir_end()

func generate_column(zone: String, corruption: float = 0.0) -> Array[CatchData]:
    load_catches_for_zone(zone)
    var column: Array[CatchData] = []
    var seen_types: Array = []
    # Phase 1: one shallows slot only. Phase 2 expands to full column.
    var catch = _draw_catch(CatchData.Layer.SHALLOWS, corruption, seen_types)
    if catch:
        column.append(catch)
        seen_types.append(catch.catch_type)
    return column

func _draw_catch(layer: CatchData.Layer, corruption: float, seen_types: Array) -> CatchData:
    var pool = _loaded_catches.filter(func(c: CatchData) -> bool: return c.layer == layer)
    if pool.is_empty():
        return null
    var weights = pool.map(func(c: CatchData) -> float: return _calculate_weight(c, corruption, seen_types))
    return _weighted_random(pool, weights)

func _calculate_weight(catch: CatchData, corruption: float, seen_types: Array) -> float:
    var weight: float = 1.0
    if catch.catch_type == CatchData.CatchType.ENTITY:
        weight += corruption * 0.02
    if catch.catch_type in seen_types:
        weight *= 0.5
    return weight

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
