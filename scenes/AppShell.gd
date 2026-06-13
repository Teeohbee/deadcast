# scenes/AppShell.gd
extends Control

@onready var zone2_container: Control = $VBoxContainer/Zone2Container
@onready var _crt_overlay: ColorRect = $CRTOverlay

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	var crt_mat := (_crt_overlay.material as ShaderMaterial).duplicate() as ShaderMaterial
	if not Settings.crt_enabled:
		crt_mat.set_shader_parameter("scan_alpha", 0.0)
	_crt_overlay.material = crt_mat
	self.modulate = Color(0.25, 0.25, 0.25)
	UIController.initialize(zone2_container)
	UIController.navigate_to("deck")
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
