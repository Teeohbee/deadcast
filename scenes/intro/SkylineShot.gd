# scenes/intro/SkylineShot.gd
# Drowned Skyline: the Sump at night, built from boxes and glowing quads.
# Everything is generated from a fixed seed so the city looks the same on
# every launch. The camera drifts towards the Meridian's green window.
class_name SkylineShot
extends Node3D

signal drift_finished

const CITY_SEED := 7
const DRIFT_SECONDS := 6.0
const CAMERA_START := Vector3(6.0, 5.0, 40.0)
const CAMERA_END := Vector3(-8.0, 3.4, -26.0)
const MERIDIAN_POSITION := Vector3(-16.0, 0.0, -48.0)

const NEON_PINK := Color(1.0, 0.18, 0.55)
const NEON_CYAN := Color(0.1, 0.85, 1.0)
const NEON_AMBER := Color(1.0, 0.6, 0.15)
const NEON_GREEN := Color(0.13, 0.77, 0.37)
const NEON_VIOLET := Color(0.6, 0.3, 1.0)

# In-world signage. Names come from the boot text and the cast.
const SIGN_WORDS := [
	"VOSS CREDIT", "OKEKE SALVAGE", "DISTRICT 7", "NOODLE 24H", "DRY ROOMS",
	"BIOFIX", "DEEP LINK", "RECALL", "HOTEL", "PAWN", "SUMP RADIO", "CLINIC",
]

const TOWER_SHADER := preload("res://scenes/intro/tower.gdshader")
const NEON_SIGN_SHADER := preload("res://scenes/intro/neon_sign.gdshader")
const HOLO_SHADER := preload("res://scenes/intro/holo.gdshader")
const BEAM_SHADER := preload("res://scenes/intro/beam.gdshader")
const WATER_SHADER := preload("res://scenes/intro/water.gdshader")
const SKY_SHADER := preload("res://scenes/intro/sky.gdshader")
const SIGN_FONT := preload("res://fonts/IBMPlexMono-Regular.otf")

var camera: Camera3D
var _random := RandomNumberGenerator.new()
var _city: Node3D
var _tower_material: ShaderMaterial
var _air_traffic: Array[Dictionary] = []
var _beams: Array[Dictionary] = []
var _blinkers: Array[MeshInstance3D] = []
var _meridian: Node3D
var _elapsed := 0.0

func _ready() -> void:
	_random.seed = CITY_SEED
	_build_environment()
	_city = Node3D.new()
	_city.name = "City"
	add_child(_city)
	_tower_material = ShaderMaterial.new()
	_tower_material.shader = TOWER_SHADER
	_build_towers()
	_build_axiom_tower()
	_build_exchange()
	_build_signs()
	_build_holo_billboards()
	# Mirror the still city before the moving parts are added.
	_build_reflection()
	_build_air_traffic()
	_build_searchlights()
	_build_water()
	_build_meridian()
	_build_rain()
	_build_camera()

func start_drift() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", CAMERA_END, DRIFT_SECONDS)
	tween.parallel().tween_method(_look_along_drift, 0.0, 1.0, DRIFT_SECONDS)
	tween.tween_callback(drift_finished.emit)

func _process(delta: float) -> void:
	_elapsed += delta
	for car in _air_traffic:
		var node: Node3D = car.node
		node.position.x += car.speed * delta
		if node.position.x > 520.0:
			node.position.x = -520.0
		elif node.position.x < -520.0:
			node.position.x = 520.0
	for beam in _beams:
		var pivot: Node3D = beam.pivot
		pivot.rotation.z = beam.lean + sin(_elapsed * beam.speed + beam.phase) * 0.35
	var blink_on := fmod(_elapsed, 1.6) < 0.25
	for blinker in _blinkers:
		blinker.visible = blink_on
	if _meridian:
		_meridian.position.y = sin(_elapsed * 0.9) * 0.12
		_meridian.rotation.z = sin(_elapsed * 0.6) * 0.02

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
	environment.ambient_light_color = Color(0.05, 0.03, 0.06)
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
	environment.fog_light_color = Color(0.11, 0.03, 0.1)
	environment.fog_density = 0.0016
	environment.fog_sky_affect = 0.2
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

# --------------------------------------------------------------------- towers

func _add_box(parent: Node3D, size: Vector3, centre: Vector3, material: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = centre
	parent.add_child(mesh)
	return mesh

# A tower is up to three stacked tiers, each narrower, sometimes with a mast.
func _add_tower(base: Vector3, width: float, depth: float, height: float) -> void:
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
		_add_box(tower, Vector3(tier_width, tier_height, tier_depth), Vector3(0, tier_bottom + tier_height * 0.5, 0), _tower_material)
		tier_bottom = tier_top
		tier_top = tier_bottom + (height - tier_bottom) * (0.6 if tier < tier_count - 2 else 1.0)
		tier_width *= _random.randf_range(0.55, 0.8)
		tier_depth *= _random.randf_range(0.55, 0.8)
	if _random.randf() < 0.4:
		var mast_height := _random.randf_range(8.0, 30.0)
		_add_box(tower, Vector3(0.5, mast_height, 0.5), Vector3(0, height + mast_height * 0.5, 0), _dark_material())
		_add_blinker(tower, Vector3(0, height + mast_height, 0))
	elif _random.randf() < 0.5:
		_add_blinker(tower, Vector3(tier_width * 0.4, height, 0))

func _build_towers() -> void:
	# Rows from near to far: fewer, shorter towers close in, a wall far off.
	var rows := [
		{"z": -240.0, "spacing": 44.0, "min_height": 25.0, "max_height": 80.0, "skip": 0.5},
		{"z": -320.0, "spacing": 36.0, "min_height": 40.0, "max_height": 130.0, "skip": 0.3},
		{"z": -420.0, "spacing": 30.0, "min_height": 60.0, "max_height": 190.0, "skip": 0.2},
		{"z": -560.0, "spacing": 28.0, "min_height": 80.0, "max_height": 250.0, "skip": 0.1},
		{"z": -720.0, "spacing": 26.0, "min_height": 70.0, "max_height": 300.0, "skip": 0.05},
		{"z": -900.0, "spacing": 24.0, "min_height": 60.0, "max_height": 340.0, "skip": 0.05},
	]
	for row in rows:
		var half_span: float = 140.0 + abs(row.z) * 0.9
		var x: float = -half_span
		while x < half_span:
			if _random.randf() > row.skip:
				var width := _random.randf_range(12.0, 26.0)
				var depth := _random.randf_range(12.0, 26.0)
				var height := _random.randf_range(row.min_height, row.max_height)
				var z: float = row.z + _random.randf_range(-18.0, 18.0)
				# Keep a gap in the near rows so the eye runs to Axiom.
				if not (abs(row.z) < 450.0 and x > 30.0 and x < 120.0):
					_add_tower(Vector3(x, 0, z), width, depth, height)
			x += row.spacing + _random.randf_range(-6.0, 10.0)

func _build_axiom_tower() -> void:
	# The landmark: a black needle with a lit crown and its name down the side.
	var axiom := Node3D.new()
	axiom.name = "Axiom"
	axiom.position = Vector3(80.0, 0.0, -520.0)
	_city.add_child(axiom)
	_add_box(axiom, Vector3(46, 300, 46), Vector3(0, 110, 0), _tower_material)
	_add_box(axiom, Vector3(34, 120, 34), Vector3(0, 320, 0), _tower_material)
	_add_box(axiom, Vector3(22, 60, 22), Vector3(0, 410, 0), _tower_material)
	# Crown rings.
	for ring in 3:
		var ring_y := 380.0 + ring * 14.0
		_add_box(axiom, Vector3(36, 1.2, 36), Vector3(0, ring_y, 0), _glow_material(NEON_CYAN, 3.0))
	_add_box(axiom, Vector3(1.2, 70, 1.2), Vector3(0, 475, 0), _dark_material())
	_add_blinker(axiom, Vector3(0, 510, 0))
	_add_vertical_sign(axiom, "AXIOM", Vector3(0, 250, 23.2), 11.0, NEON_CYAN, 0.0)

func _build_exchange() -> void:
	# The Exchange: a wide stepped block, half drowned, its trading floor still lit.
	var exchange := Node3D.new()
	exchange.name = "Exchange"
	exchange.position = Vector3(-150.0, 0.0, -360.0)
	_city.add_child(exchange)
	var width := 120.0
	var top := 0.0
	for step in 5:
		var step_height := 22.0
		_add_box(exchange, Vector3(width, step_height + 40.0, 50.0 - step * 6.0), Vector3(0, top + step_height * 0.5 - 20.0, 0), _tower_material)
		_add_box(exchange, Vector3(width + 0.2, 0.8, 50.2 - step * 6.0), Vector3(0, top + step_height, 0), _glow_material(NEON_AMBER, 2.2))
		top += step_height
		width *= 0.78
	_add_horizontal_sign(exchange, "THE EXCHANGE", Vector3(0, top - 30.0, 34.0), 5.0, NEON_AMBER)

# -------------------------------------------------------------------- signage

func _add_vertical_sign(parent: Node3D, word: String, centre: Vector3, letter_height: float, colour: Color, flicker: float) -> void:
	var stacked := "\n".join(word.split(""))
	var letter_count := word.length()
	var panel_size := Vector2(letter_height * 1.1, letter_height * 1.25 * letter_count + letter_height * 0.6)
	_add_sign_panel(parent, centre, panel_size, colour, flicker)
	_add_sign_label(parent, stacked, centre + Vector3(0, 0, 0.15), letter_height, colour, flicker)

func _add_horizontal_sign(parent: Node3D, word: String, centre: Vector3, letter_height: float, colour: Color) -> void:
	var panel_size := Vector2(letter_height * 0.72 * word.length() + letter_height, letter_height * 1.8)
	_add_sign_panel(parent, centre, panel_size, colour, 0.0)
	_add_sign_label(parent, word, centre + Vector3(0, 0, 0.15), letter_height, colour, 0.0)

func _add_sign_panel(parent: Node3D, centre: Vector3, size: Vector2, colour: Color, flicker: float) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := ShaderMaterial.new()
	material.shader = NEON_SIGN_SHADER
	material.set_shader_parameter("neon_color", colour)
	material.set_shader_parameter("border", clampf(0.6 / min(size.x, size.y), 0.01, 0.2))
	material.set_shader_parameter("flicker_seed", _random.randf())
	material.set_shader_parameter("flicker_amount", flicker)
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = material
	mesh.position = centre
	parent.add_child(mesh)

func _add_sign_label(parent: Node3D, text: String, centre: Vector3, letter_height: float, colour: Color, flicker: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = SIGN_FONT
	label.font_size = 96
	label.pixel_size = letter_height / 96.0
	label.line_spacing = -24.0
	label.modulate = Color(colour.r * 2.4, colour.g * 2.4, colour.b * 2.4)
	label.outline_size = 0
	label.shaded = false
	label.double_sided = true
	label.no_depth_test = false
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

func _build_signs() -> void:
	# Vertical signs bolted to the faces of the nearer towers.
	var colours := [NEON_PINK, NEON_CYAN, NEON_AMBER, NEON_VIOLET, NEON_PINK, NEON_CYAN]
	var placed := 0
	for tower in _city.get_children():
		if placed >= SIGN_WORDS.size():
			break
		if tower.name in ["Axiom", "Exchange"]:
			continue
		if tower.position.z < -460.0 or _random.randf() > 0.6:
			continue
		var base_box := tower.get_child(0) as MeshInstance3D
		var box_size: Vector3 = (base_box.mesh as BoxMesh).size
		var top_of_base := base_box.position.y + box_size.y * 0.5
		var word: String = SIGN_WORDS[placed]
		var letter_height := _random.randf_range(2.6, 4.2)
		var sign_height := letter_height * 1.25 * word.length()
		var sign_y := clampf(_random.randf_range(sign_height * 0.6 + 6.0, top_of_base - sign_height * 0.6), sign_height * 0.6 + 4.0, 400.0)
		var side := -1.0 if _random.randf() < 0.5 else 1.0
		var front := Vector3(side * box_size.x * 0.35, sign_y, box_size.z * 0.5 + letter_height * 0.8)
		var colour: Color = colours[placed % colours.size()]
		var flicker := 0.7 if placed % 3 == 1 else 0.0
		var display_word := word.replace(" ", "")
		_add_vertical_sign(tower, display_word, front, letter_height, colour, flicker)
		placed += 1

func _build_holo_billboards() -> void:
	var spots := [
		{"centre": Vector3(-40, 70, -300), "size": Vector2(40, 22), "a": NEON_CYAN, "b": NEON_PINK, "text": "REMEMBER\nANYTHING"},
		{"centre": Vector3(200, 120, -430), "size": Vector2(34, 48), "a": NEON_PINK, "b": NEON_VIOLET, "text": "VOSS\nCREDIT\nNO\nQUESTIONS"},
		{"centre": Vector3(-300, 160, -600), "size": Vector2(60, 34), "a": NEON_AMBER, "b": NEON_PINK, "text": "DRY LAND\nIS A LIE"},
	]
	for spot in spots:
		var quad := QuadMesh.new()
		quad.size = spot.size
		var material := ShaderMaterial.new()
		material.shader = HOLO_SHADER
		material.set_shader_parameter("colour_a", spot.a)
		material.set_shader_parameter("colour_b", spot.b)
		material.set_shader_parameter("scroll_speed", _random.randf_range(0.08, 0.2))
		var mesh := MeshInstance3D.new()
		mesh.mesh = quad
		mesh.material_override = material
		mesh.position = spot.centre
		_city.add_child(mesh)
		var size: Vector2 = spot.size
		var line_count: int = String(spot.text).count("\n") + 1
		_add_sign_label(_city, spot.text, spot.centre + Vector3(0, 0, 0.3), min(size.y / (line_count * 1.6), size.x / 9.0), Color(1, 1, 1), 0.0)

# ---------------------------------------------------------------- air traffic

func _build_air_traffic() -> void:
	# Lanes of hover traffic: white heading one way, red the other.
	var lanes := [
		{"y": 45.0, "z": -280.0, "count": 9, "speed": 26.0},
		{"y": 50.0, "z": -286.0, "count": 8, "speed": -22.0},
		{"y": 110.0, "z": -380.0, "count": 12, "speed": 34.0},
		{"y": 116.0, "z": -388.0, "count": 10, "speed": -30.0},
		{"y": 180.0, "z": -500.0, "count": 14, "speed": 40.0},
		{"y": 240.0, "z": -650.0, "count": 16, "speed": -36.0},
	]
	for lane in lanes:
		for car_index in lane.count:
			var heading_right: bool = lane.speed > 0.0
			var colour := Color(3.0, 2.8, 2.4) if heading_right else Color(3.5, 0.35, 0.3)
			var length := absf(lane.speed) * 0.18
			var car := _add_box(_city, Vector3(length, 1.0, 1.0), Vector3(_random.randf_range(-500, 500), lane.y + _random.randf_range(-4, 4), lane.z + _random.randf_range(-3, 3)), _glow_material(colour, 1.0))
			_air_traffic.append({"node": car, "speed": lane.speed * _random.randf_range(0.85, 1.15)})

func _build_searchlights() -> void:
	var lamps := [Vector3(-200, 140, -620), Vector3(10, 220, -700), Vector3(260, 180, -660)]
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
		var beam := MeshInstance3D.new()
		beam.mesh = cone
		beam.material_override = material
		beam.position = Vector3(0, cone.height * 0.5, 0)
		pivot.add_child(beam)
		_beams.append({"pivot": pivot, "lean": _random.randf_range(-0.3, 0.3), "speed": _random.randf_range(0.15, 0.3), "phase": _random.randf() * TAU})

# --------------------------------------------------------- water + reflection

func _build_reflection() -> void:
	# The mirrored city sits under the translucent water as its reflection.
	var reflection := _city.duplicate() as Node3D
	reflection.name = "Reflection"
	reflection.scale = Vector3(1, -1, 1)
	add_child(reflection)

func _build_water() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2400, 2400)
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = plane
	water.material_override = material
	water.position = Vector3(0, 0, -500)
	add_child(water)

# -------------------------------------------------------------- the Meridian

func _build_meridian() -> void:
	_meridian = Node3D.new()
	_meridian.name = "Meridian"
	var hull_material := _flat_material(Color(0.03, 0.035, 0.04))
	var anchor := Node3D.new()
	anchor.position = MERIDIAN_POSITION
	anchor.rotation.y = deg_to_rad(-18.0)
	add_child(anchor)
	anchor.add_child(_meridian)
	_add_box(_meridian, Vector3(14, 1.6, 4.6), Vector3(0, 0.4, 0), hull_material)
	_add_box(_meridian, Vector3(4, 1.2, 3.6), Vector3(6.5, 0.6, 0), hull_material)
	_add_box(_meridian, Vector3(5, 2.4, 3.4), Vector3(-1.5, 2.4, 0), hull_material)
	_add_box(_meridian, Vector3(0.2, 7, 0.2), Vector3(-3.0, 5.5, 0), hull_material)
	_add_box(_meridian, Vector3(4, 0.12, 0.12), Vector3(1.0, 1.6, 2.3), hull_material)
	# The one green window: the terminal is on.
	var window := _add_box(_meridian, Vector3(1.6, 0.9, 0.05), Vector3(-0.6, 2.6, 1.72), _glow_material(Color(NEON_GREEN.r * 3.0, NEON_GREEN.g * 3.0, NEON_GREEN.b * 3.0), 1.0))
	window.name = "GreenWindow"
	var lamp := OmniLight3D.new()
	lamp.light_color = NEON_GREEN
	lamp.light_energy = 2.0
	lamp.omni_range = 9.0
	lamp.position = Vector3(-0.6, 2.6, 3.0)
	_meridian.add_child(lamp)
	_add_blinker(_meridian, Vector3(-3.0, 9.0, 0))

func meridian_window_position() -> Vector3:
	return _meridian.get_node("GreenWindow").global_position

# ---------------------------------------------------------------------- rain

func _build_rain() -> void:
	var rain := GPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 4000
	rain.lifetime = 1.4
	rain.preprocess = 2.0
	rain.visibility_aabb = AABB(Vector3(-60, -40, -80), Vector3(120, 80, 160))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(50, 2, 60)
	process.direction = Vector3(0.12, -1, 0)
	process.spread = 2.0
	process.initial_velocity_min = 38.0
	process.initial_velocity_max = 46.0
	process.gravity = Vector3.ZERO
	process.particle_flag_align_y = true
	rain.process_material = process
	var streak := QuadMesh.new()
	streak.size = Vector2(0.025, 0.9)
	var streak_material := StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.albedo_color = Color(0.7, 0.75, 0.9, 0.22)
	streak_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	streak_material.billboard_keep_scale = true
	streak.material = streak_material
	rain.draw_pass_1 = streak
	rain.position = Vector3(0, 22, 0)
	add_child(rain)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 52.0
	camera.far = 3000.0
	camera.position = CAMERA_START
	add_child(camera)
	_look_along_drift(0.0)
	camera.make_current()

# Start looking at the city across the water, end looking at the green window.
func _look_along_drift(progress: float) -> void:
	var city_target := Vector3(10, 95, -500)
	var window_target := MERIDIAN_POSITION + Vector3(0, 2.6, 0)
	var target := city_target.lerp(window_target, smoothstep(0.35, 1.0, progress))
	camera.look_at(target)

# ------------------------------------------------------------------ materials

func _glow_material(colour: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(colour.r * energy, colour.g * energy, colour.b * energy)
	return material

func _flat_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	return material

func _dark_material() -> StandardMaterial3D:
	return _flat_material(Color(0.02, 0.02, 0.025))

func _add_blinker(parent: Node3D, at: Vector3) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.8
	sphere.radial_segments = 8
	sphere.rings = 4
	var blinker := MeshInstance3D.new()
	blinker.mesh = sphere
	blinker.material_override = _glow_material(Color(2.4, 0.15, 0.1), 1.0)
	blinker.position = at
	parent.add_child(blinker)
	_blinkers.append(blinker)
