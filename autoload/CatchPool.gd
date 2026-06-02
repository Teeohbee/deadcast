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
        if not dir.current_is_dir() and file_name.ends_with(".tres"):
            var resource = load(path.path_join(file_name))
            if resource is CatchData:
                _loaded_catches.append(resource)
        file_name = dir.get_next()
    dir.list_dir_end()

func generate_column(zone: String, corruption: float = 0.0, max_depth: int = 100, lure_effect: LureData.LureEffect = LureData.LureEffect.NONE) -> Array[CatchData]:
    load_catches_for_zone(zone)
    var column: Array[CatchData] = []
    var seen_types: Array = []

    # Shallows: always 3 slots
    for i in 3:
        var catch = _draw_catch(CatchData.Layer.SHALLOWS, corruption, seen_types, lure_effect)
        if catch:
            column.append(catch)
            seen_types.append(catch.catch_type)

    # Mid: 3 slots if max_depth >= 60
    if max_depth >= 60:
        for i in 3:
            var catch = _draw_catch(CatchData.Layer.MID, corruption, seen_types, lure_effect)
            if catch:
                column.append(catch)
                seen_types.append(catch.catch_type)

    # Deep: 2 slots if max_depth >= 150
    if max_depth >= 150:
        for i in 2:
            var catch = _draw_catch(CatchData.Layer.DEEP, corruption, seen_types, lure_effect)
            if catch:
                column.append(catch)
                seen_types.append(catch.catch_type)

    return column

func _draw_catch(layer: CatchData.Layer, corruption: float, seen_types: Array, lure_effect: LureData.LureEffect) -> CatchData:
    var pool = _loaded_catches.filter(func(c: CatchData) -> bool: return c.layer == layer)
    if pool.is_empty():
        return null
    var weights = pool.map(func(c: CatchData) -> float: return _calculate_weight(c, corruption, seen_types, lure_effect))
    return _weighted_random(pool, weights)

func _calculate_weight(catch: CatchData, corruption: float, seen_types: Array, lure_effect: LureData.LureEffect) -> float:
    var weight: float = 1.0

    if catch.catch_type == CatchData.CatchType.ENTITY:
        weight += corruption * 0.02

    if catch.catch_type in seen_types:
        weight *= 0.5

    # Lure effects
    match lure_effect:
        LureData.LureEffect.DECOY:
            if catch.catch_type == CatchData.CatchType.ENTITY:
                weight *= 0.2
        LureData.LureEffect.GHOST_BAIT:
            if catch.catch_type == CatchData.CatchType.ENTITY:
                weight *= 1.5

    return max(weight, 0.0)

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
