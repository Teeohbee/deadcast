# scenes/AppShell.gd
extends Control

@onready var zone2_container: Control = $VBoxContainer/Zone2Container
@onready var _crt_overlay: ColorRect = $CRTOverlay

func _ready() -> void:
	self.theme = DeckStyle.get_theme()
	var crt_mat := (_crt_overlay.material as ShaderMaterial).duplicate() as ShaderMaterial
	Settings.apply_crt(crt_mat, Settings.crt_enabled)
	_crt_overlay.material = crt_mat
	Settings.crt_changed.connect(_on_crt_changed)
	self.modulate = Color(0.25, 0.25, 0.25)
	UIController.initialize(zone2_container)
	UIController.navigate_to("deck")
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

# Named method so Godot drops the connection when the shell frees.
func _on_crt_changed(enabled: bool) -> void:
	Settings.apply_crt(_crt_overlay.material as ShaderMaterial, enabled)
