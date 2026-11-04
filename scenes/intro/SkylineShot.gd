# scenes/intro/SkylineShot.gd
# Drowned Skyline: the Sump at night in a storm, built from boxes and glowing
# quads. Everything comes from a fixed seed so the city looks the same on
# every launch. The Meridian rides the swell in the foreground, and the
# camera drifts in towards its green wheelhouse windows.
class_name SkylineShot
extends Node3D

signal drift_finished

const CITY_SEED := 7
const DRIFT_SECONDS := 6.0
const CAMERA_START := Vector3(16.0, 10.0, 26.0)
const CITY_LOOK_TARGET := Vector3(0.0, 80.0, -600.0)
const MERIDIAN_POSITION := Vector3(-6.0, 0.0, -32.0)
const MERIDIAN_HEADING_DEGREES := -14.0

const NEON_PINK := Color(1.0, 0.18, 0.55)
const NEON_CYAN := Color(0.1, 0.85, 1.0)
const NEON_AMBER := Color(1.0, 0.6, 0.15)
const NEON_RED := Color(1.0, 0.15, 0.12)
const NEON_GREEN := Color(0.2, 1.0, 0.45)
const NEON_VIOLET := Color(0.6, 0.3, 1.0)
const NEON_YELLOW := Color(1.0, 0.9, 0.25)
const SIGN_COLOURS := [NEON_PINK, NEON_CYAN, NEON_AMBER, NEON_RED, NEON_GREEN, NEON_VIOLET, NEON_YELLOW, NEON_CYAN]

# In-world signage. Names come from the boot text and the cast.
const SIGN_WORDS := [
	"VOSSCREDIT", "OKEKE", "DISTRICT7", "NOODLE", "DRYROOMS", "BIOFIX",
	"DEEPLINK", "RECALL", "HOTEL", "PAWN", "SUMPRADIO", "CLINIC", "SALVAGE",
	"KARAOKE", "SOMA", "24H", "BAR", "LOANS", "IMPLANTS", "EXCHANGE",
]

# Each wave: direction x, direction z, wavelength (m), height (m).
const WAVES := [
	Vector4(0.2, 1.0, 19.0, 0.45),
	Vector4(-0.55, 0.85, 11.0, 0.28),
	Vector4(0.7, 0.7, 6.5, 0.15),
	Vector4(-0.15, 1.0, 4.2, 0.08),
]
const GRAVITY := 9.8

const TOWER_SHADER := preload("res://scenes/intro/tower.gdshader")
const NEON_SIGN_SHADER := preload("res://scenes/intro/neon_sign.gdshader")
const HOLO_SHADER := preload("res://scenes/intro/holo.gdshader")
const BEAM_SHADER := preload("res://scenes/intro/beam.gdshader")
const WATER_SHADER := preload("res://scenes/intro/water.gdshader")
const SKY_SHADER := preload("res://scenes/intro/sky.gdshader")
const TRAIL_SHADER := preload("res://scenes/intro/trail.gdshader")
const SIGN_FONT := preload("res://fonts/IBMPlexMono-Regular.otf")

var camera: Camera3D
var meridian: MeridianBoat
var _random := RandomNumberGenerator.new()
var _city: Node3D
var _tower_material: ShaderMaterial
var _water_material: ShaderMaterial
var _normalised_waves: Array[Vector4] = []
var _flying_cars: Array[Dictionary] = []
var _trains: Array[Dictionary] = []
var _beams: Array[Dictionary] = []
var _blinkers: Array[MeshInstance3D] = []
var _elapsed := 0.0
var _camera_end := Vector3.ZERO
var _window_target := Vector3.ZERO

func _ready() -> void:
	_random.seed = CITY_SEED
	for wave in WAVES:
		var direction := Vector2(wave.x, wave.y).normalized()
		_normalised_waves.append(Vector4(direction.x, direction.y, wave.z, wave.w))
	_build_environment()
	_city = Node3D.new()
	_city.name = "City"
	add_child(_city)
	_tower_material = ShaderMaterial.new()
	_tower_material.shader = TOWER_SHADER
	_build_towers()
	_build_axiom_tower()
	_build_docks()
	_build_signs()
	_build_screens()
	_build_holo_billboards()
	_build_monorails()
	_build_flying_cars()
	_build_searchlights()
	_build_water()
	_build_meridian()
	_build_rain()
	_build_camera()

func start_drift() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_move_along_drift, 0.0, 1.0, DRIFT_SECONDS)
	tween.tween_callback(drift_finished.emit)

func _process(delta: float) -> void:
	_elapsed += delta
	_water_material.set_shader_parameter("wave_time", _elapsed)
	_ride_the_swell()
	meridian.radar.rotation.y += delta * 1.8
	for car in _flying_cars:
		var node: Node3D = car.node
		node.position += car.velocity * delta
		if absf(node.position.x) > 560.0:
			node.position.x = -signf(node.position.x) * 560.0
	for train in _trains:
		_place_train(train, delta)
	for beam in _beams:
		var pivot: Node3D = beam.pivot
		pivot.rotation.z = beam.lean + sin(_elapsed * beam.speed + beam.phase) * 0.35
	var blink_on := fmod(_elapsed, 1.6) < 0.25
	for blinker in _blinkers:
		blinker.visible = blink_on

# ---------------------------------------------------------------------- water

func wave_height_at(x: float, z: float, time: float) -> float:
	var height := 0.0
	for wave in _normalised_waves:
		var wave_number := TAU / wave.z
		var speed := sqrt(GRAVITY / wave_number)
		height += wave.w * sin(wave_number * (wave.x * x + wave.y * z - speed * time))
	return height

# Bob, pitch and roll the boat on the same waves the water shader draws.
func _ride_the_swell() -> void:
	var anchor := meridian.get_parent() as Node3D
	var forward := -anchor.global_transform.basis.z
	var right := anchor.global_transform.basis.x
	var centre := anchor.global_position
	var half_length := MeridianBoat.HULL_LENGTH * 0.4
	var half_width := MeridianBoat.HULL_WIDTH * 0.5
	var bow := centre + forward * half_length
	var stern := centre - forward * half_length
	var port := centre - right * half_width
	var starboard := centre + right * half_width
	var bow_height := wave_height_at(bow.x, bow.z, _elapsed)
	var stern_height := wave_height_at(stern.x, stern.z, _elapsed)
	var port_height := wave_height_at(port.x, port.z, _elapsed)
	var starboard_height := wave_height_at(starboard.x, starboard.z, _elapsed)
	meridian.position.y = (bow_height + stern_height + port_height + starboard_height) * 0.25 - 0.2
	meridian.rotation.x = atan2(bow_height - stern_height, half_length * 2.0) * 0.8
	meridian.rotation.z = atan2(port_height - starboard_height, half_width * 2.0) * 0.6

func _build_water() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2000, 1400)
	plane.subdivide_width = 700
	plane.subdivide_depth = 500
	_water_material = ShaderMaterial.new()
	_water_material.shader = WATER_SHADER
	_water_material.set_shader_parameter("wave_settings", _normalised_waves)
	_water_material.set_shader_parameter("calm_centre", Vector2(0, -20))
	_water_material.set_shader_parameter("boat_glow_position", MERIDIAN_POSITION)
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = plane
	water.material_override = _water_material
	water.position = Vector3(0, 0, -480)
	# The waves move vertices up and down; keep the plane from being culled.
	water.extra_cull_margin = 4.0
	add_child(water)

# ---------------------------------------------------------------- environment

func _build_environment() -> void:
	var sky_material := ShaderMaterial.new()
	sky_material.shader = SKY_SHADER
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.05, 0.08, 0.1)
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 1.0
	environment.glow_strength = 1.1
	environment.glow_bloom = 0.08
	environment.glow_hdr_threshold = 0.9
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	environment.set_glow_level(1, 0.6)
	environment.set_glow_level(2, 0.8)
	environment.set_glow_level(3, 1.0)
	environment.set_glow_level(4, 0.6)
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_color = Color(0.05, 0.11, 0.14)
	environment.fog_density = 0.0015
	environment.fog_sky_affect = 0.15
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

# --------------------------------------------------------------------- towers

# A tower is up to three stacked tiers, each narrower, sometimes with a mast.
func _add_tower(base: Vector3, width: float, depth: float, height: float) -> Node3D:
	var tower := Node3D.new()
	tower.position = base
	_city.add_child(tower)
	var tier_count := 1 + int(_random.randf() < 0.55) + int(_random.randf() < 0.3)
	var tier_bottom := -40.0  # foundations run under the water
	var tier_top := height * (0.62 if tier_count > 1 else 1.0)
	var tier_width := width
	var tier_depth := depth
	for tier in tier_count:
		var tier_height := tier_top - tier_bottom
		IntroBuild.add_box(tower, Vector3(tier_width, tier_height, tier_depth), Vector3(0, tier_bottom + tier_height * 0.5, 0), _tower_material)
		tier_bottom = tier_top
		tier_top = tier_bottom + (height - tier_bottom) * (0.6 if tier < tier_count - 2 else 1.0)
		tier_width *= _random.randf_range(0.55, 0.8)
		tier_depth *= _random.randf_range(0.55, 0.8)
	if _random.randf() < 0.4:
		var mast_height := _random.randf_range(8.0, 30.0)
		IntroBuild.add_box(tower, Vector3(0.5, mast_height, 0.5), Vector3(0, height + mast_height * 0.5, 0), _dark_material())
		_add_blinker(tower, Vector3(0, height + mast_height, 0))
	elif _random.randf() < 0.5:
		_add_blinker(tower, Vector3(tier_width * 0.4, height, 0))
	tower.set_meta("front_width", width)
	tower.set_meta("front_depth", depth)
	tower.set_meta("base_height", height * (0.62 if tier_count > 1 else 1.0))
	return tower

func _build_towers() -> void:
	# Rows from near to far: low blocks close in, a wall of towers far off.
	var rows := [
		{"z": -330.0, "spacing": 40.0, "min_height": 30.0, "max_height": 90.0, "skip": 0.45},
		{"z": -410.0, "spacing": 34.0, "min_height": 50.0, "max_height": 150.0, "skip": 0.25},
		{"z": -500.0, "spacing": 30.0, "min_height": 70.0, "max_height": 210.0, "skip": 0.15},
		{"z": -620.0, "spacing": 28.0, "min_height": 90.0, "max_height": 270.0, "skip": 0.1},
		{"z": -760.0, "spacing": 26.0, "min_height": 80.0, "max_height": 320.0, "skip": 0.05},
		{"z": -920.0, "spacing": 24.0, "min_height": 60.0, "max_height": 340.0, "skip": 0.05},
	]
	for row in rows:
		var half_span: float = 180.0 + abs(row.z) * 0.9
		var x: float = -half_span
		while x < half_span:
			if _random.randf() > row.skip:
				var width := _random.randf_range(14.0, 28.0)
				var depth := _random.randf_range(12.0, 26.0)
				var height := _random.randf_range(row.min_height, row.max_height)
				var z: float = row.z + _random.randf_range(-18.0, 18.0)
				# Keep the near rows clear in front of Axiom.
				if not (abs(row.z) < 600.0 and x > 0.0 and x < 70.0):
					_add_tower(Vector3(x, 0, z), width, depth, height)
			x += row.spacing + _random.randf_range(-6.0, 10.0)

func _build_axiom_tower() -> void:
	# The landmark: a black needle with a lit crown and its name down the side.
	var axiom := Node3D.new()
	axiom.name = "Axiom"
	axiom.position = Vector3(35.0, 0.0, -700.0)
	_city.add_child(axiom)
	IntroBuild.add_box(axiom, Vector3(46, 300, 46), Vector3(0, 110, 0), _tower_material)
	IntroBuild.add_box(axiom, Vector3(34, 120, 34), Vector3(0, 320, 0), _tower_material)
	IntroBuild.add_box(axiom, Vector3(22, 60, 22), Vector3(0, 410, 0), _tower_material)
	for ring in 3:
		var ring_y := 380.0 + ring * 14.0
		IntroBuild.add_box(axiom, Vector3(36, 1.2, 36), Vector3(0, ring_y, 0), IntroBuild.glow_material(NEON_CYAN, 3.0))
	IntroBuild.add_box(axiom, Vector3(1.2, 70, 1.2), Vector3(0, 475, 0), _dark_material())
	_add_blinker(axiom, Vector3(0, 510, 0))
	_add_vertical_sign(axiom, "AXIOM", Vector3(0, 250, 23.4), 11.0, NEON_CYAN, 0.0, false)

func _build_docks() -> void:
	# A dark band of wharves, sheds and cranes where the city meets the water.
	var x := -700.0
	while x < 700.0:
		var width := _random.randf_range(20.0, 60.0)
		var height := _random.randf_range(4.0, 16.0)
		var z := _random.randf_range(-300.0, -280.0)
		IntroBuild.add_box(_city, Vector3(width, height + 6.0, 18.0), Vector3(x, height * 0.5 - 3.0, z), _dark_material())
		if _random.randf() < 0.5:
			IntroBuild.add_lamp(_city, Vector3(x + _random.randf_range(-8, 8), height + 1.0, z + 9.5), Color(1.0, 0.62, 0.3), 0.0, 5.0)
		if _random.randf() < 0.15:
			_add_crane(Vector3(x, height, z))
		x += width + _random.randf_range(4.0, 30.0)

func _add_crane(base: Vector3) -> void:
	var dark := _dark_material()
	IntroBuild.add_box(_city, Vector3(2.0, 40.0, 2.0), base + Vector3(0, 20.0, 0), dark)
	var jib := IntroBuild.add_box(_city, Vector3(36.0, 1.4, 1.4), base + Vector3(8.0, 40.0, 0), dark)
	jib.rotation.y = _random.randf_range(-0.6, 0.6)
	_add_blinker(_city, base + Vector3(0, 41.5, 0))

# -------------------------------------------------------------------- signage

func _add_vertical_sign(parent: Node3D, word: String, centre: Vector3, letter_height: float, colour: Color, flicker: float, filled: bool) -> void:
	var stacked := "\n".join(word.split(""))
	var letter_count := word.length()
	var panel_size := Vector2(letter_height * 1.1, letter_height * 1.25 * letter_count + letter_height * 0.6)
	_add_sign_panel(parent, centre, panel_size, colour, flicker, filled)
	var text_colour := Color(0.03, 0.02, 0.04) if filled else colour
	var text_energy := 1.0 if filled else 2.4
	_add_sign_label(parent, stacked, centre + Vector3(0, 0, 0.15), letter_height, text_colour, text_energy, flicker)

func _add_sign_panel(parent: Node3D, centre: Vector3, size: Vector2, colour: Color, flicker: float, filled: bool) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := ShaderMaterial.new()
	material.shader = NEON_SIGN_SHADER
	material.set_shader_parameter("neon_color", colour)
	material.set_shader_parameter("border", clampf(0.6 / min(size.x, size.y), 0.01, 0.2))
	material.set_shader_parameter("flicker_seed", _random.randf())
	material.set_shader_parameter("flicker_amount", flicker)
	material.set_shader_parameter("fill", 1.1 if filled else 0.07)
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = material
	mesh.position = centre
	parent.add_child(mesh)

func _add_sign_label(parent: Node3D, text: String, centre: Vector3, letter_height: float, colour: Color, energy: float, flicker: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = SIGN_FONT
	label.font_size = 96
	label.pixel_size = letter_height / 96.0
	label.line_spacing = -24.0
	label.modulate = Color(colour.r * energy, colour.g * energy, colour.b * energy)
	label.outline_size = 0
	label.shaded = false
	label.double_sided = true
	label.position = centre
	parent.add_child(label)
	if flicker > 0.0:
		_flicker_label(label, flicker)

func _flicker_label(label: Label3D, amount: float) -> void:
	var lit := label.modulate
	var tween := create_tween().set_loops()
	tween.tween_interval(_random.randf_range(1.5, 4.0))
	tween.tween_property(label, "modulate", lit * (1.0 - amount), 0.05)
	tween.tween_property(label, "modulate", lit, 0.05)
	tween.tween_property(label, "modulate", lit * (1.0 - amount), 0.08)
	tween.tween_property(label, "modulate", lit, 0.04)

func _towers_nearer_than(z_limit: float) -> Array[Node3D]:
	var towers: Array[Node3D] = []
	for child in _city.get_children():
		if child.has_meta("front_width") and child.position.z > z_limit:
			towers.append(child)
	return towers

func _build_signs() -> void:
	# Vertical signs on the faces of the nearer towers: neon tubes or lightboxes.
	var placed := 0
	for tower in _towers_nearer_than(-700.0):
		if _random.randf() > 0.6:
			continue
		var front_width: float = tower.get_meta("front_width")
		var front_depth: float = tower.get_meta("front_depth")
		var base_height: float = tower.get_meta("base_height")
		var word: String = SIGN_WORDS[placed % SIGN_WORDS.size()]
		var letter_height := _random.randf_range(3.0, 5.5)
		var sign_height := letter_height * 1.25 * word.length()
		if sign_height > base_height - 10.0:
			word = word.substr(0, 4)
			sign_height = letter_height * 1.25 * word.length()
		var lowest := sign_height * 0.5 + 6.0
		var highest := maxf(lowest, base_height - sign_height * 0.5 - 2.0)
		var sign_y := _random.randf_range(lowest, highest)
		var side := -1.0 if _random.randf() < 0.5 else 1.0
		var front := Vector3(side * front_width * 0.32, sign_y, front_depth * 0.5 + letter_height * 0.6)
		var colour: Color = SIGN_COLOURS[placed % SIGN_COLOURS.size()]
		var flicker := 0.7 if placed % 4 == 1 else 0.0
		var filled := _random.randf() < 0.4
		_add_vertical_sign(tower, word, front, letter_height, colour, flicker, filled)
		placed += 1

func _build_screens() -> void:
	# Big video screens on tower faces, cycling colour like adverts.
	for tower in _towers_nearer_than(-680.0):
		if tower.position.z > -380.0 or _random.randf() > 0.3:
			continue
		var front_width: float = tower.get_meta("front_width")
		var front_depth: float = tower.get_meta("front_depth")
		var base_height: float = tower.get_meta("base_height")
		var screen_size := Vector2(front_width * 0.8, front_width * _random.randf_range(0.6, 1.3))
		if screen_size.y > base_height * 0.5:
			continue
		var centre := Vector3(0, base_height - screen_size.y * 0.5 - 4.0, front_depth * 0.5 + 0.3)
		var colour_a: Color = SIGN_COLOURS[_random.randi() % SIGN_COLOURS.size()]
		var colour_b: Color = SIGN_COLOURS[_random.randi() % SIGN_COLOURS.size()]
		_add_holo_quad(tower, centre, screen_size, colour_a, colour_b, 1.4)

func _add_holo_quad(parent: Node3D, centre: Vector3, size: Vector2, colour_a: Color, colour_b: Color, energy: float) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := ShaderMaterial.new()
	material.shader = HOLO_SHADER
	material.set_shader_parameter("colour_a", colour_a)
	material.set_shader_parameter("colour_b", colour_b)
	material.set_shader_parameter("energy", energy)
	material.set_shader_parameter("scroll_speed", _random.randf_range(0.08, 0.2))
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = material
	mesh.position = centre
	parent.add_child(mesh)

func _build_holo_billboards() -> void:
	var spots := [
		{"centre": Vector3(-90, 120, -460), "size": Vector2(44, 26), "a": NEON_CYAN, "b": NEON_PINK, "text": "REMEMBER\nANYTHING"},
		{"centre": Vector3(150, 150, -560), "size": Vector2(34, 48), "a": NEON_PINK, "b": NEON_VIOLET, "text": "VOSS\nCREDIT\nNO\nQUESTIONS"},
		{"centre": Vector3(-260, 170, -680), "size": Vector2(60, 34), "a": NEON_AMBER, "b": NEON_PINK, "text": "DRY LAND\nIS A LIE"},
	]
	for spot in spots:
		_add_holo_quad(_city, spot.centre, spot.size, spot.a, spot.b, 1.2)
		var size: Vector2 = spot.size
		var line_count: int = String(spot.text).count("\n") + 1
		_add_sign_label(_city, spot.text, spot.centre + Vector3(0, 0, 0.3), min(size.y / (line_count * 1.6), size.x / 9.0), Color(1, 1, 1), 2.4, 0.0)

# ------------------------------------------------------------------ monorails

func _build_monorails() -> void:
	# Two elevated lines sweep in from either side towards the city centre.
	var left := [Vector3(-340, 52, -40), Vector3(-200, 50, -140), Vector3(-115, 54, -300), Vector3(-60, 58, -480)]
	var right := [Vector3(350, 60, -30), Vector3(210, 58, -130), Vector3(125, 60, -290), Vector3(70, 64, -470)]
	_build_monorail(left, 26.0)
	_build_monorail(right, -22.0)

func _build_monorail(points: Array, train_speed: float) -> void:
	var curve := Curve3D.new()
	curve.bake_interval = 2.0
	for index in points.size():
		var previous: Vector3 = points[max(index - 1, 0)]
		var following: Vector3 = points[min(index + 1, points.size() - 1)]
		var handle := (following - previous) * 0.2
		curve.add_point(points[index], -handle, handle)
	var length := curve.get_baked_length()
	var track_material := _flat_dark(Color(0.05, 0.06, 0.07))
	var strip_material := IntroBuild.glow_material(NEON_CYAN, 2.0)
	var segment_length := 8.0
	var segment_index := 0
	var offset := 0.0
	while offset < length:
		var here := curve.sample_baked(offset)
		var ahead := curve.sample_baked(minf(offset + segment_length, length))
		if here.distance_to(ahead) < 0.5:
			break
		var middle := (here + ahead) * 0.5
		var segment := Node3D.new()
		_city.add_child(segment)
		segment.position = middle
		segment.look_at_from_position(middle, ahead, Vector3.UP)
		var piece_length := here.distance_to(ahead) + 0.2
		IntroBuild.add_box(segment, Vector3(4.0, 1.6, piece_length), Vector3.ZERO, track_material)
		IntroBuild.add_box(segment, Vector3(4.1, 0.18, piece_length), Vector3(0, -0.85, 0), strip_material)
		if segment_index % 5 == 0:
			var pylon_height := middle.y + 6.0
			IntroBuild.add_box(_city, Vector3(2.4, pylon_height, 2.4), Vector3(middle.x, middle.y - pylon_height * 0.5 - 0.8, middle.z), track_material)
		segment_index += 1
		offset += segment_length
	# One train per line, looping along it.
	var cars: Array[Node3D] = []
	var body := _flat_dark(Color(0.12, 0.13, 0.15))
	var windows := IntroBuild.glow_material(Color(0.75, 0.95, 1.0), 2.2)
	for car_index in 7:
		var car := Node3D.new()
		_city.add_child(car)
		IntroBuild.add_box(car, Vector3(3.4, 2.8, 9.0), Vector3(0, 2.2, 0), body)
		IntroBuild.add_box(car, Vector3(3.5, 0.8, 8.2), Vector3(0, 2.6, 0), windows)
		cars.append(car)
	_trains.append({"curve": curve, "length": length, "cars": cars, "speed": train_speed, "offset": _random.randf() * length})

func _place_train(train: Dictionary, delta: float) -> void:
	var curve: Curve3D = train.curve
	var length: float = train.length
	train.offset = fposmod(train.offset + train.speed * delta, length + 120.0)
	var cars: Array[Node3D] = train.cars
	for car_index in cars.size():
		var car := cars[car_index]
		var car_offset: float = train.offset - car_index * 9.6 * signf(train.speed)
		var on_track := car_offset >= 0.0 and car_offset <= length
		car.visible = on_track
		if not on_track:
			continue
		var here := curve.sample_baked(car_offset)
		var ahead := curve.sample_baked(clampf(car_offset + 1.0, 0.0, length))
		if here.distance_to(ahead) < 0.01:
			ahead = here + (here - curve.sample_baked(car_offset - 1.0))
		car.look_at_from_position(here, ahead, Vector3.UP)

# ---------------------------------------------------------------- flying cars

func _build_flying_cars() -> void:
	# Hover traffic crossing the skyline, each with a light trail behind it.
	for car_index in 34:
		var depth := _random.randf_range(-560.0, -150.0)
		var height := _random.randf_range(35.0, 190.0)
		var heading_right := _random.randf() < 0.5
		var speed := _random.randf_range(28.0, 55.0) * (1.0 if heading_right else -1.0)
		var drift := _random.randf_range(-6.0, 6.0)
		var car := Node3D.new()
		_city.add_child(car)
		car.position = Vector3(_random.randf_range(-540, 540), height, depth)
		var velocity := Vector3(speed, 0, drift)
		car.look_at_from_position(car.position, car.position + velocity, Vector3.UP)
		IntroBuild.add_box(car, Vector3(2.0, 0.9, 4.2), Vector3.ZERO, _flat_dark(Color(0.08, 0.08, 0.1)))
		var light_colour := Color(1.0, 0.95, 0.85) if heading_right else Color(1.0, 0.2, 0.15)
		IntroBuild.add_box(car, Vector3(1.8, 0.3, 0.1), Vector3(0, 0, -2.15), IntroBuild.glow_material(light_colour, 3.0))
		var trail_colour := NEON_CYAN if _random.randf() < 0.6 else NEON_PINK
		_add_trail(car, trail_colour)
		_flying_cars.append({"node": car, "velocity": velocity})

func _add_trail(car: Node3D, colour: Color) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(26.0, 0.7)
	var material := ShaderMaterial.new()
	material.shader = TRAIL_SHADER
	material.set_shader_parameter("trail_color", colour)
	var trail := MeshInstance3D.new()
	trail.mesh = quad
	trail.material_override = material
	trail.position = Vector3(0, 0, 13.0)
	trail.rotation.y = PI * 0.5
	car.add_child(trail)

func _build_searchlights() -> void:
	var lamps := [Vector3(-220, 150, -780), Vector3(10, 230, -860), Vector3(270, 180, -800)]
	for lamp in lamps:
		var pivot := Node3D.new()
		pivot.position = lamp
		_city.add_child(pivot)
		var cone := CylinderMesh.new()
		cone.top_radius = 22.0
		cone.bottom_radius = 0.6
		cone.height = 420.0
		cone.cap_top = false
		cone.cap_bottom = false
		cone.radial_segments = 16
		var material := ShaderMaterial.new()
		material.shader = BEAM_SHADER
		material.set_shader_parameter("beam_color", Color(0.6, 0.85, 1.0))
		var beam := MeshInstance3D.new()
		beam.mesh = cone
		beam.material_override = material
		beam.position = Vector3(0, cone.height * 0.5, 0)
		pivot.add_child(beam)
		_beams.append({"pivot": pivot, "lean": _random.randf_range(-0.3, 0.3), "speed": _random.randf_range(0.15, 0.3), "phase": _random.randf() * TAU})

# -------------------------------------------------------------- the Meridian

func _build_meridian() -> void:
	var anchor := Node3D.new()
	anchor.name = "MeridianAnchor"
	anchor.position = MERIDIAN_POSITION
	anchor.rotation.y = deg_to_rad(MERIDIAN_HEADING_DEGREES)
	add_child(anchor)
	meridian = MeridianBoat.new()
	meridian.name = "Meridian"
	anchor.add_child(meridian)
	_blinkers.append(meridian.mast_light)

# ---------------------------------------------------------------------- rain

func _build_rain() -> void:
	var rain := GPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 7000
	rain.lifetime = 1.2
	rain.preprocess = 2.0
	rain.visibility_aabb = AABB(Vector3(-70, -50, -90), Vector3(140, 100, 180))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(60, 2, 70)
	process.direction = Vector3(0.35, -1, 0.05)
	process.spread = 3.0
	process.initial_velocity_min = 40.0
	process.initial_velocity_max = 50.0
	process.gravity = Vector3.ZERO
	process.particle_flag_align_y = true
	rain.process_material = process
	var streak := QuadMesh.new()
	streak.size = Vector2(0.03, 1.3)
	var streak_material := StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.albedo_color = Color(0.7, 0.82, 0.9, 0.28)
	streak_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	streak_material.billboard_keep_scale = true
	streak.material = streak_material
	rain.draw_pass_1 = streak
	rain.position = Vector3(0, 26, -10)
	add_child(rain)

# --------------------------------------------------------------------- camera

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 52.0
	camera.far = 3000.0
	add_child(camera)
	camera.make_current()
	# The drift ends behind and above the port quarter, looking down past the
	# funnel at the wheelhouse windows.
	_window_target = meridian.green_window_position()
	var anchor_basis: Basis = (meridian.get_parent() as Node3D).global_transform.basis
	_camera_end = _window_target + anchor_basis.z * 19.0 - anchor_basis.x * 9.0 + Vector3(0.0, 5.0, 0.0)
	_move_along_drift(0.0)

# Start wide on the city across the water, end close on the green windows.
func _move_along_drift(progress: float) -> void:
	camera.position = CAMERA_START.lerp(_camera_end, progress)
	var target := CITY_LOOK_TARGET.lerp(_window_target, smoothstep(0.3, 1.0, progress))
	camera.look_at(target)

# ------------------------------------------------------------------ materials

func _flat_dark(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	return material

func _dark_material() -> StandardMaterial3D:
	return _flat_dark(Color(0.015, 0.02, 0.025))

func _add_blinker(parent: Node3D, at: Vector3) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.8
	sphere.radial_segments = 8
	sphere.rings = 4
	var blinker := MeshInstance3D.new()
	blinker.mesh = sphere
	blinker.material_override = IntroBuild.glow_material(Color(2.4, 0.15, 0.1), 1.0)
	blinker.position = at
	parent.add_child(blinker)
	_blinkers.append(blinker)
