# scenes/intro/IntroBuild.gd
# Small helpers for building intro scenes out of boxes and glowing materials.
class_name IntroBuild
extends RefCounted

const LAMP_HALO_SHADER := preload("res://scenes/intro/lamp_halo.gdshader")

static func add_box(parent: Node3D, size: Vector3, centre: Vector3, material: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = centre
	parent.add_child(mesh)
	return mesh

static func glow_material(colour: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(colour.r * energy, colour.g * energy, colour.b * energy)
	return material

static func lit_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	return material

# A small glowing bulb with a soft halo that still reads from far away,
# plus a real light so it shows up on the surfaces around it.
static func add_lamp(parent: Node3D, at: Vector3, colour: Color, light_range: float, halo_size: float = 2.4) -> void:
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.16
	bulb_mesh.height = 0.32
	bulb_mesh.radial_segments = 8
	bulb_mesh.rings = 4
	var bulb := MeshInstance3D.new()
	bulb.mesh = bulb_mesh
	bulb.material_override = glow_material(colour, 4.0)
	bulb.position = at
	parent.add_child(bulb)
	var halo_quad := QuadMesh.new()
	halo_quad.size = Vector2(halo_size, halo_size)
	var halo_material := ShaderMaterial.new()
	halo_material.shader = LAMP_HALO_SHADER
	halo_material.set_shader_parameter("halo_color", colour)
	var halo := MeshInstance3D.new()
	halo.mesh = halo_quad
	halo.material_override = halo_material
	halo.position = at
	parent.add_child(halo)
	if light_range > 0.0:
		var light := OmniLight3D.new()
		light.light_color = colour
		light.light_energy = 3.0
		light.omni_range = light_range
		light.omni_attenuation = 1.4
		light.position = at
		parent.add_child(light)
