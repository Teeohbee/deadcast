# scenes/dive_run/override/HostileWireframe.gd
# A hostile in the encounter frame: a low-poly wireframe spinning on the same turntable
# as the shop's item schematics (WireframeView), drawn in the hostile's red. A hostile
# names its model in CatchData.override_art; anything unnamed falls back by type.
class_name HostileWireframe
extends WireframeView

const MODELS: Array[String] = ["drone", "ghost", "engine", "core", "swarm", "payload", "building"]

var model := ""
## Seconds since the hostile was hurt: it flashes and its mesh jitters.
var hurt_t := 9.0

static func model_for(art_name: String, catch_type: CatchData.CatchType) -> String:
	if art_name in MODELS:
		return art_name
	return "ghost" if catch_type == CatchData.CatchType.ENTITY else "drone"

func set_hostile(model_name: String) -> void:
	model = model_name
	kind = "hostile"
	_parts = _build_hostile(model_name)
	queue_redraw()

func hurt() -> void:
	hurt_t = 0.0

func _process(delta: float) -> void:
	hurt_t += delta
	super._process(delta)

func _rebuild() -> void:
	_parts = _build_hostile(model)

func _draw() -> void:
	if hurt_t < 0.3:
		var s := (1.0 - hurt_t / 0.3) * 6.0
		draw_set_transform(Vector2(randf_range(-s, s), randf_range(-s, s)))
		modulate = DeckStyle.TEXT
	else:
		modulate = Color.WHITE
	super._draw()
	draw_set_transform(Vector2.ZERO)

# --- models (Y up, about a unit across) --------------------------------------

func _build_hostile(model_name: String) -> Array:
	var red := DeckStyle.RED
	var echo := Color(red, 0.45)
	match model_name:
		"drone":
			return [_squashed_octa(Vector3.ZERO, Vector3(0.55, 0.32, 0.55), red),
				_box(Vector3(0.82, 0.05, 0), Vector3(0.16, 0.12, 0.3), red),
				_box(Vector3(-0.82, 0.05, 0), Vector3(0.16, 0.12, 0.3), red),
				_strut(Vector3(0.55, 0, 0), Vector3(0.66, 0.05, 0), red),
				_strut(Vector3(-0.55, 0, 0), Vector3(-0.66, 0.05, 0), red),
				_ring(Vector3(0, 0, 0.56), 0.14, 6, 2, echo),
				_legs(Vector3(0, -0.32, 0), 3, 0.35, 0.5, echo)]
		"ghost":
			var parts := [_icosahedron(0.5, red, true)]
			for i in 4:
				var y := -0.55 - i * 0.18
				var r := 0.42 - i * 0.09
				parts.append(_ring(Vector3(sin(i * 1.3) * 0.08, y, 0), r, 7, 1, Color(red, 0.6 - i * 0.12)))
			for p in parts:
				p.verts = _shift(p.verts, Vector3(0, 0.35, 0))
			return parts
		"engine":
			return [_box(Vector3(0, -0.45, 0), Vector3(0.5, 0.18, 0.4), red),
				_box(Vector3(0, -0.05, 0), Vector3(0.42, 0.18, 0.34), red),
				_box(Vector3(0, 0.35, 0), Vector3(0.34, 0.18, 0.28), red),
				_ring(Vector3(0, -0.05, 0), 0.78, 10, 1, echo),
				_strut(Vector3(0, 0.53, 0), Vector3(0, 0.9, 0), red)]
		"core":
			return [_icosahedron(0.95, echo, true),
				_octahedron(0.42, red),
				_ring(Vector3.ZERO, 0.7, 12, 1, red),
				_ring(Vector3.ZERO, 0.7, 12, 0, echo)]
		"swarm":
			var parts := []
			var spots := [Vector3(0.5, 0.3, 0.1), Vector3(-0.45, 0.4, -0.2), Vector3(0.1, -0.1, 0.55),
				Vector3(-0.3, -0.45, 0.2), Vector3(0.55, -0.4, -0.3), Vector3(-0.1, 0.65, 0.35), Vector3(0.0, 0.0, -0.6)]
			for i in spots.size():
				parts.append(_tetra(spots[i], 0.16 + (i % 3) * 0.04, red if i % 2 == 0 else echo))
			return parts
		"payload":
			var spikes := _spike_core()
			spikes.color = red
			return [spikes, _box(Vector3.ZERO, Vector3(0.62, 0.62, 0.62), echo)]
		"building":
			var parts := [_box(Vector3(0, 0, 0), Vector3(0.36, 0.85, 0.36), red),
				_strut(Vector3(0, 0.85, 0), Vector3(0, 1.1, 0), red)]
			for i in 4:
				parts.append(_ring(Vector3(0, -0.55 + i * 0.36, 0), 0.51, 4, 1, echo))
			return parts
	return [_octahedron(0.8, red)]

# Closed ring as a part. plane: 0=YZ, 1=XZ (horizontal), 2=XY (facing the camera).
func _ring(c: Vector3, r: float, sides: int, plane: int, color: Color) -> Dictionary:
	return _part(_ngon(c, r, sides, plane), _ring_edges(0, sides), color)

func _strut(a: Vector3, b: Vector3, color: Color) -> Dictionary:
	return _part(PackedVector3Array([a, b]), [Vector2i(0, 1)], color)

# An octahedron stretched per axis: a drone's hull.
func _squashed_octa(c: Vector3, half: Vector3, color: Color) -> Dictionary:
	var part := _octahedron(1.0, color)
	var v := PackedVector3Array()
	for p in part.verts:
		v.append(c + Vector3(p.x * half.x, p.y * half.y, p.z * half.z))
	part.verts = v
	return part

# Splayed legs hanging from a point.
func _legs(top: Vector3, count: int, spread: float, length: float, color: Color) -> Dictionary:
	var v := PackedVector3Array([top])
	var e := []
	for i in count:
		var a := TAU * float(i) / float(count)
		v.append(top + Vector3(cos(a) * spread, -length, sin(a) * spread))
		e.append(Vector2i(0, i + 1))
	return _part(v, e, color)

func _shift(verts: PackedVector3Array, by: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in verts:
		out.append(p + by)
	return out
