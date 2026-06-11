# scenes/AppShell.gd
extends Control

@onready var zone2_container: Control = $VBoxContainer/Zone2Container

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	self.modulate = Color(0.25, 0.25, 0.25)
	UIController.initialize(zone2_container)
	UIController.navigate_to("deck")
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
