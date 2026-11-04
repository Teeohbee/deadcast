# scenes/intro/MeridianBoat.gd
# The Meridian: a battered harbour tug turned data trawler. Built from boxes.
# The bow points down local -z. The wheelhouse glows warm; the green comes
# from the trawl terminal on the aft deck, which never goes off.
class_name MeridianBoat
extends Node3D

const HULL_LENGTH := 23.0
const HULL_WIDTH := 7.0
const DECK_HEIGHT := 1.7
const WARM_LAMP := Color(1.0, 0.62, 0.3)
const TERMINAL_GREEN := Color(0.13, 0.9, 0.4)
const NAV_RED := Color(1.0, 0.1, 0.08)
const NAV_GREEN := Color(0.1, 1.0, 0.3)
# 16:9 so a camera filling the frame with it matches the full-screen title.
const SCREEN_SIZE := Vector2(1.0, 0.5625)
const SIGN_FONT := preload("res://fonts/IBMPlexMono-Regular.otf")
const TERMINAL_SCREEN_SHADER := preload("res://scenes/intro/terminal_screen.gdshader")

var mast_light: MeshInstance3D
var radar: Node3D
var _wheelhouse_window: MeshInstance3D
var _terminal_screen: MeshInstance3D

func _ready() -> void:
	var hull_paint := IntroBuild.lit_material(Color(0.07, 0.075, 0.08))
	var rust_band := IntroBuild.lit_material(Color(0.2, 0.08, 0.05))
	var superstructure_paint := IntroBuild.lit_material(Color(0.2, 0.22, 0.21))
	var trim_paint := IntroBuild.lit_material(Color(0.3, 0.3, 0.28))
	var dark_metal := IntroBuild.lit_material(Color(0.05, 0.05, 0.055))
	_build_hull(hull_paint, rust_band, trim_paint, dark_metal)
	_build_superstructure(superstructure_paint, trim_paint, dark_metal)
	_build_aft_deck(dark_metal)
	_build_deck_terminal(dark_metal, trim_paint)
	_build_lights()

func terminal_screen_position() -> Vector3:
	return _terminal_screen.global_position

func terminal_screen_transform() -> Transform3D:
	return _terminal_screen.global_transform

func _build_hull(hull_paint: Material, rust_band: Material, trim_paint: Material, dark_metal: Material) -> void:
	# Main hull runs from the stern (z = +10) to where the bow starts (z = -7).
	IntroBuild.add_box(self, Vector3(HULL_WIDTH, 3.2, 17.0), Vector3(0, 0.1, 1.5), hull_paint)
	_add_bow_wedge(Vector3(HULL_WIDTH, 6.0, 3.2), Vector3(0, 0.1, -10.0), hull_paint)
	# Raised foredeck: the bow sits higher than the working deck.
	IntroBuild.add_box(self, Vector3(HULL_WIDTH, 1.0, 3.0), Vector3(0, 2.2, -5.5), hull_paint)
	_add_bow_wedge(Vector3(HULL_WIDTH, 6.0, 1.0), Vector3(0, 2.2, -10.0), hull_paint)
	# Rust-red boot stripe at the waterline and a pale rubbing strake.
	IntroBuild.add_box(self, Vector3(HULL_WIDTH + 0.04, 0.5, 17.02), Vector3(0, -0.6, 1.5), rust_band)
	IntroBuild.add_box(self, Vector3(HULL_WIDTH + 0.3, 0.3, 17.2), Vector3(0, 1.45, 1.5), trim_paint)
	# Old tyres hung over the sides as fenders.
	for fender_z in [-4.0, -0.5, 3.0, 6.5]:
		for side in [-1.0, 1.0]:
			var tyre := TorusMesh.new()
			tyre.inner_radius = 0.3
			tyre.outer_radius = 0.65
			tyre.rings = 12
			tyre.ring_segments = 6
			var fender := MeshInstance3D.new()
			fender.mesh = tyre
			fender.material_override = dark_metal
			fender.position = Vector3(side * (HULL_WIDTH * 0.5 + 0.25), 0.8, fender_z)
			fender.rotation.z = PI * 0.5
			add_child(fender)
	# Name on the transom.
	var name_plate := Label3D.new()
	name_plate.text = "MERIDIAN   D7"
	name_plate.font = SIGN_FONT
	name_plate.font_size = 64
	name_plate.pixel_size = 0.55 / 64.0
	name_plate.modulate = Color(0.75, 0.75, 0.7)
	name_plate.position = Vector3(0, 0.7, 10.02)
	add_child(name_plate)

# A triangular prism lying flat with its point facing forward (-z).
func _add_bow_wedge(size: Vector3, centre: Vector3, material: Material) -> void:
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x, size.y, size.z)
	var wedge := MeshInstance3D.new()
	wedge.mesh = prism
	wedge.material_override = material
	wedge.position = centre
	wedge.rotation.x = -PI * 0.5
	add_child(wedge)

func _build_superstructure(paint: Material, trim_paint: Material, dark_metal: Material) -> void:
	# Deckhouse on the main deck, wheelhouse on top of it.
	IntroBuild.add_box(self, Vector3(5.2, 2.6, 7.0), Vector3(0, DECK_HEIGHT + 1.3, -1.5), paint)
	var wheelhouse_centre := Vector3(0, DECK_HEIGHT + 2.6 + 1.2, -2.2)
	IntroBuild.add_box(self, Vector3(4.6, 2.4, 4.2), wheelhouse_centre, paint)
	IntroBuild.add_box(self, Vector3(5.4, 0.25, 5.0), wheelhouse_centre + Vector3(0, 1.3, 0), trim_paint)
	# Warm window band all round the wheelhouse: someone lives in here.
	var warm_glass := IntroBuild.glow_material(WARM_LAMP, 1.9)
	var window_y := wheelhouse_centre.y + 0.25
	_wheelhouse_window = IntroBuild.add_box(self, Vector3(3.9, 0.95, 0.06), Vector3(0, window_y, wheelhouse_centre.z + 2.12), warm_glass)
	IntroBuild.add_box(self, Vector3(3.9, 0.95, 0.06), Vector3(0, window_y, wheelhouse_centre.z - 2.12), warm_glass)
	for side in [-1.0, 1.0]:
		IntroBuild.add_box(self, Vector3(0.06, 0.95, 3.5), Vector3(side * 2.32, window_y, wheelhouse_centre.z), warm_glass)
	# Warm portholes along the deckhouse.
	var porthole := IntroBuild.glow_material(WARM_LAMP, 1.8)
	for porthole_z in [-4.0, -2.2, -0.4, 1.2]:
		for side in [-1.0, 1.0]:
			IntroBuild.add_box(self, Vector3(0.06, 0.45, 0.45), Vector3(side * 2.62, DECK_HEIGHT + 1.5, porthole_z), porthole)
	# Mast with a yard, a radar bar and a masthead light.
	var mast_base := wheelhouse_centre + Vector3(0, 1.4, -0.4)
	IntroBuild.add_box(self, Vector3(0.25, 6.0, 0.25), mast_base + Vector3(0, 3.0, 0), dark_metal)
	IntroBuild.add_box(self, Vector3(2.8, 0.14, 0.14), mast_base + Vector3(0, 4.6, 0), dark_metal)
	radar = Node3D.new()
	radar.position = mast_base + Vector3(0, 2.2, 0)
	add_child(radar)
	IntroBuild.add_box(radar, Vector3(2.2, 0.18, 0.4), Vector3.ZERO, trim_paint)
	var whip_antenna := mast_base + Vector3(0.9, 4.6, 0)
	IntroBuild.add_box(self, Vector3(0.06, 2.4, 0.06), whip_antenna + Vector3(0, 1.2, 0), dark_metal)
	mast_light = IntroBuild.add_box(self, Vector3(0.35, 0.35, 0.35), mast_base + Vector3(0, 6.15, 0), IntroBuild.glow_material(NAV_RED, 3.0))
	# Funnel behind the deckhouse, with a faded red band.
	IntroBuild.add_box(self, Vector3(1.5, 3.2, 1.8), Vector3(0, DECK_HEIGHT + 1.6 + 1.2, 3.0), dark_metal)
	IntroBuild.add_box(self, Vector3(1.55, 0.45, 1.85), Vector3(0, DECK_HEIGHT + 3.4, 3.0), IntroBuild.lit_material(Color(0.4, 0.07, 0.05)))

func _build_aft_deck(dark_metal: Material) -> void:
	# Towing bitt and the trawl gantry (an A-frame) over the stern.
	var bitt := CylinderMesh.new()
	bitt.top_radius = 0.35
	bitt.bottom_radius = 0.35
	bitt.height = 0.9
	bitt.radial_segments = 8
	var bitt_mesh := MeshInstance3D.new()
	bitt_mesh.mesh = bitt
	bitt_mesh.material_override = dark_metal
	bitt_mesh.position = Vector3(0, DECK_HEIGHT + 0.45, 6.0)
	add_child(bitt_mesh)
	for side in [-1.0, 1.0]:
		var post := IntroBuild.add_box(self, Vector3(0.35, 5.2, 0.35), Vector3(side * 2.9, DECK_HEIGHT + 2.5, 9.0), dark_metal)
		post.rotation.x = deg_to_rad(12.0)
	IntroBuild.add_box(self, Vector3(6.2, 0.4, 0.4), Vector3(0, DECK_HEIGHT + 5.0, 9.5), dark_metal)
	# Cable drum on the deck.
	var drum := CylinderMesh.new()
	drum.top_radius = 0.7
	drum.bottom_radius = 0.7
	drum.height = 3.0
	drum.radial_segments = 10
	var drum_mesh := MeshInstance3D.new()
	drum_mesh.mesh = drum
	drum_mesh.material_override = IntroBuild.lit_material(Color(0.25, 0.18, 0.08))
	drum_mesh.position = Vector3(0, DECK_HEIGHT + 0.7, 4.6)
	drum_mesh.rotation.z = PI * 0.5
	add_child(drum_mesh)

# The trawl terminal: a weatherproof console on a post by the starboard rail,
# screen tilted back and turned towards the stern, under a little rain hood.
func _build_deck_terminal(dark_metal: Material, trim_paint: Material) -> void:
	var terminal := Node3D.new()
	terminal.name = "DeckTerminal"
	terminal.position = Vector3(2.2, DECK_HEIGHT, 7.0)
	terminal.rotation.y = deg_to_rad(35.0)
	add_child(terminal)
	IntroBuild.add_box(terminal, Vector3(0.18, 1.0, 0.18), Vector3(0, 0.5, 0), dark_metal)
	var head := Node3D.new()
	head.position = Vector3(0, 1.35, 0)
	head.rotation.x = deg_to_rad(-18.0)
	terminal.add_child(head)
	IntroBuild.add_box(head, Vector3(1.2, 0.85, 0.45), Vector3.ZERO, trim_paint)
	IntroBuild.add_box(head, Vector3(1.3, 0.08, 0.7), Vector3(0, 0.48, 0.1), dark_metal)
	var screen_quad := QuadMesh.new()
	screen_quad.size = SCREEN_SIZE
	var screen_material := ShaderMaterial.new()
	screen_material.shader = TERMINAL_SCREEN_SHADER
	_terminal_screen = MeshInstance3D.new()
	_terminal_screen.name = "Screen"
	_terminal_screen.mesh = screen_quad
	_terminal_screen.material_override = screen_material
	_terminal_screen.position = Vector3(0, 0, 0.231)
	head.add_child(_terminal_screen)
	# A soft halo so the screen reads from the wide shot, and green light on the deck.
	IntroBuild.add_lamp(head, Vector3(0, 0, 0.3), TERMINAL_GREEN, 0.0, 1.8, false)
	var glow := OmniLight3D.new()
	glow.light_color = TERMINAL_GREEN
	glow.light_energy = 2.2
	glow.omni_range = 5.0
	glow.position = Vector3(0, 0, 0.8)
	head.add_child(glow)

func _build_lights() -> void:
	# Work lamps: gantry, deckhouse back wall, bow. Nav lights port and starboard.
	IntroBuild.add_lamp(self, Vector3(-2.6, DECK_HEIGHT + 4.7, 9.5), WARM_LAMP, 10.0)
	IntroBuild.add_lamp(self, Vector3(2.6, DECK_HEIGHT + 4.7, 9.5), WARM_LAMP, 0.0)
	IntroBuild.add_lamp(self, Vector3(0, DECK_HEIGHT + 2.4, 2.05), WARM_LAMP, 9.0)
	IntroBuild.add_lamp(self, Vector3(0, DECK_HEIGHT + 1.6, -11.5), WARM_LAMP, 8.0)
	IntroBuild.add_lamp(self, Vector3(-2.75, DECK_HEIGHT + 3.6, -3.0), NAV_RED, 0.0, 1.4)
	IntroBuild.add_lamp(self, Vector3(2.75, DECK_HEIGHT + 3.6, -3.0), NAV_GREEN, 0.0, 1.4)
	# The wheelhouse glow spills warm onto the deck behind it.
	var spill := OmniLight3D.new()
	spill.light_color = WARM_LAMP
	spill.light_energy = 2.5
	spill.omni_range = 9.0
	spill.position = _wheelhouse_window.position + Vector3(0, 0, 1.5)
	add_child(spill)
