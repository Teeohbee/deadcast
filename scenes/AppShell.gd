# scenes/AppShell.gd
extends Control

@onready var zone2_container: Control = $VBoxContainer/Zone2Container

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIController.initialize(zone2_container)
	UIController.navigate_to("deck")
