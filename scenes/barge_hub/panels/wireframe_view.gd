# scenes/barge_hub/panels/wireframe_view.gd
class_name WireframeView
extends Control

# Rotating 3D angular wireframe of a purchasable item. This is a cyberpunk
# data-salvage rig, so items render as abstract faceted constructs (probes,
# packet clusters, gyros) rather than literal tackle. Models are built as
# vertex/edge meshes, spun with a Basis and projected with light perspective.

const CAM_DIST := 4.2     # camera distance along +Z
const FOCAL := 3.2        # perspective focal length
const PITCH := -0.42      # fixed downward tilt - the angular iso look
const YAW_SPEED := 0.6    # radians/sec turntable spin

# A part is one wireframe object: { verts: PackedVector3Array, edges: Array[Vector2i],
# color: Color, dashed: bool }. Items can be several parts.
var kind := ""      # "rod" | "lure" | ""
var variant := 0
var _parts: Array = []
var _yaw := 0.0

func _ready() -> void:
	clip_contents = true

func set_item(item_kind: String, item_variant: int) -> void:
	kind = item_kind
	variant = item_variant
	_rebuild()
	queue_redraw()

func _process(delta: float) -> void:
	_yaw += delta * YAW_SPEED
	queue_redraw()

# --- primitives -------------------------------------------------------------

func _part(verts: PackedVector3Array, edges: Array, color := DeckStyle.GREEN, dashed := false) -> Dictionary:
	return {"verts": verts, "edges": edges, "color": color, "dashed": dashed}

# Closed n-gon ring centred at `c`. plane: 0=YZ (normal X), 1=XZ (normal Y), 2=XY (normal Z).
func _ngon(c: Vector3, r: float, sides: int, plane := 0) -> PackedVector3Array:
	var v := PackedVector3Array()
	for i in sides:
		var a := TAU * float(i) / float(sides)
		var u := cos(a) * r
		var w := sin(a) * r
		match plane:
			0: v.append(c + Vector3(0, u, w))
			1: v.append(c + Vector3(u, 0, w))
			_: v.append(c + Vector3(u, w, 0))
	return v

func _ring_edges(base: int, n: int) -> Array:
	var e := []
	for i in n:
		e.append(Vector2i(base + i, base + (i + 1) % n))
	return e

func _long_edges(a: int, b: int, n: int) -> Array:
	var e := []
	for i in n:
		e.append(Vector2i(a + i, b + i))
	return e

func _box(center: Vector3, half: Vector3, color := DeckStyle.GREEN) -> Dictionary:
	var v := PackedVector3Array()
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				v.append(center + Vector3(sx * half.x, sy * half.y, sz * half.z))
	var e := [
		Vector2i(0, 1), Vector2i(2, 3), Vector2i(4, 5), Vector2i(6, 7),
		Vector2i(0, 2), Vector2i(1, 3), Vector2i(4, 6), Vector2i(5, 7),
		Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7)]
	return _part(v, e, color)

func _octahedron(s: float, color := DeckStyle.GREEN) -> Dictionary:
	var v := PackedVector3Array([
		Vector3(s, 0, 0), Vector3(-s, 0, 0), Vector3(0, s, 0),
		Vector3(0, -s, 0), Vector3(0, 0, s), Vector3(0, 0, -s)])
	var e := [
		Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 5),
		Vector2i(2, 4), Vector2i(4, 3), Vector2i(3, 5), Vector2i(5, 2)]
	return _part(v, e, color)

func _tetra(center: Vector3, s: float, color := DeckStyle.GREEN) -> Dictionary:
	var v := PackedVector3Array([
		center + Vector3(1, 1, 1) * s, center + Vector3(1, -1, -1) * s,
		center + Vector3(-1, 1, -1) * s, center + Vector3(-1, -1, 1) * s])
	var e := [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 3)]
	return _part(v, e, color)

# Edges of a regular solid = the shortest vertex pairs. Robust for icosahedra etc.
func _shortest_edges(v: PackedVector3Array) -> Array:
	var mind := INF
	for i in v.size():
		for j in range(i + 1, v.size()):
			mind = minf(mind, v[i].distance_to(v[j]))
	var e := []
	for i in v.size():
		for j in range(i + 1, v.size()):
			if v[i].distance_to(v[j]) < mind * 1.1:
				e.append(Vector2i(i, j))
	return e

func _icosahedron(s: float, color := DeckStyle.GREEN, dashed := false) -> Dictionary:
	var p := 1.618034
	var raw := PackedVector3Array([
		Vector3(0, 1, p), Vector3(0, 1, -p), Vector3(0, -1, p), Vector3(0, -1, -p),
		Vector3(1, p, 0), Vector3(1, -p, 0), Vector3(-1, p, 0), Vector3(-1, -p, 0),
		Vector3(p, 0, 1), Vector3(-p, 0, 1), Vector3(p, 0, -1), Vector3(-p, 0, -1)])
	var v := PackedVector3Array()
	var norm := s / 1.902  # |raw| = sqrt(1+p^2)
	for pt in raw:
		v.append(pt * norm)
	return _part(v, _shortest_edges(v), color, dashed)

# --- model construction -----------------------------------------------------

func _rebuild() -> void:
	match kind:
		"rod": _parts = _build_rod()
		"lure": _parts = _build_lure()
		_: _parts = []

# Extraction hardware - one distinct construct per rod tier.
func _build_rod() -> Array:
	match variant:
		1: return [_spindle(6)]                         # monocarbon_rig: sleek probe
		2: return [_ring_stack(4, 6)]                    # ghost_line: phased coil
		_: return [_tetra(Vector3.ZERO, 0.7),           # scrap_rod: jagged scrap
			_tetra(Vector3(0.45, 0.3, -0.25), 0.4)]

# Hex-section probe spindle along X with pointed nose and tail.
func _spindle(sides: int) -> Dictionary:
	var verts := PackedVector3Array()
	var edges := []
	verts.append(Vector3(-1.05, 0, 0))                  # nose apex (idx 0)
	var b1 := verts.size()
	verts.append_array(_ngon(Vector3(-0.4, 0, 0), 0.34, sides))
	var b2 := verts.size()
	verts.append_array(_ngon(Vector3(0.4, 0, 0), 0.34, sides))
	var tail := verts.size()
	verts.append(Vector3(1.05, 0, 0))                   # tail apex
	for i in sides:
		edges.append(Vector2i(0, b1 + i))
		edges.append(Vector2i(b2 + i, tail))
	edges.append_array(_ring_edges(b1, sides))
	edges.append_array(_ring_edges(b2, sides))
	edges.append_array(_long_edges(b1, b2, sides))
	return _part(verts, edges)

# Coaxial ring stack - a hollow coil tube.
func _ring_stack(stations: int, sides: int) -> Dictionary:
	var verts := PackedVector3Array()
	var edges := []
	var prev := -1
	for i in stations:
		var x := lerpf(-0.9, 0.9, float(i) / float(stations - 1))
		var base := verts.size()
		verts.append_array(_ngon(Vector3(x, 0, 0), 0.42, sides))
		edges.append_array(_ring_edges(base, sides))
		if prev >= 0:
			edges.append_array(_long_edges(prev, base, sides))
		prev = base
	return _part(verts, edges)

# Data-bait constructs - one per lure effect.
func _build_lure() -> Array:
	match variant:
		LureData.LureEffect.SHOCK:
			return [_spike_core()]                       # electric burst, amber
		LureData.LureEffect.DECOY:
			var main := DeckStyle.GREEN
			var echo := Color(main.r, main.g, main.b, 0.45)
			return [_box(Vector3.ZERO, Vector3(0.4, 0.4, 0.4), main),
				_box(Vector3(0.55, 0.4, -0.25), Vector3(0.2, 0.2, 0.2), echo),
				_box(Vector3(-0.5, -0.35, 0.3), Vector3(0.16, 0.16, 0.16), echo)]
		LureData.LureEffect.DEEP_PULSE:
			return _gyro(12)                             # nested gyro rings, sky
		LureData.LureEffect.GHOST_BAIT:
			return [_icosahedron(0.85, DeckStyle.DIM, true)]  # dashed phantom
		_:
			return [_octahedron(0.85)]                   # plain payload

# Asterisk of spikes around a small octahedral core - reads as an electric burst.
func _spike_core() -> Dictionary:
	var verts := PackedVector3Array([Vector3.ZERO])      # origin (idx 0)
	var dirs := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0),
		Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var edges := []
	for d: Vector3 in dirs:
		verts.append(d * 0.95)
		edges.append(Vector2i(0, verts.size() - 1))      # spike
	var core := verts.size()
	for d: Vector3 in dirs:
		verts.append(d * 0.3)                            # inner octa shell
	edges.append_array([
		Vector2i(core, core + 2), Vector2i(core + 2, core + 1), Vector2i(core + 1, core + 3),
		Vector2i(core + 3, core), Vector2i(core, core + 4), Vector2i(core + 4, core + 1),
		Vector2i(core + 1, core + 5), Vector2i(core + 5, core)])
	return _part(verts, edges, DeckStyle.AMBER)

# Three perpendicular rings - a slow gyroscope.
func _gyro(sides: int) -> Array:
	var c := DeckStyle.SKY
	var parts := []
	for plane in 3:
		var r := 0.85 - plane * 0.12
		parts.append(_part(_ngon(Vector3.ZERO, r, sides, plane), _ring_edges(0, sides), c))
	return parts

# --- projection + draw ------------------------------------------------------

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8.0 or h < 8.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#040705"))

	var grid := Color(DeckStyle.BORDER.r, DeckStyle.BORDER.g, DeckStyle.BORDER.b, 0.4)
	for x in range(0, int(w), 16):
		draw_line(Vector2(x, 0), Vector2(x, h), grid)
	for y in range(0, int(h), 16):
		draw_line(Vector2(0, y), Vector2(w, y), grid)

	if _parts.is_empty():
		return

	var center := size * 0.5
	var scale := minf(w, h) * 0.40
	var basis := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, PITCH)

	for part: Dictionary in _parts:
		var verts: PackedVector3Array = part.verts
		var col: Color = part.color
		for e: Vector2i in part.edges:
			var pa := _project(basis * verts[e.x], center, scale)
			var pb := _project(basis * verts[e.y], center, scale)
			if part.dashed:
				draw_dashed_line(pa, pb, col, 1.0, 4.0)
			else:
				draw_line(pa, pb, col, 1.5)

func _project(v: Vector3, center: Vector2, scale: float) -> Vector2:
	var f := FOCAL / (v.z + CAM_DIST)
	return center + Vector2(v.x, -v.y) * f * scale
