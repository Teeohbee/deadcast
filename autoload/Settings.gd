# autoload/Settings.gd
extends Node

const PATH := "user://settings.cfg"

var crt_enabled: bool = true

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		crt_enabled = cfg.get_value("video", "crt_enabled", true)

func set_crt_enabled(value: bool) -> void:
	crt_enabled = value
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # ignore error; fresh file is fine
	cfg.set_value("video", "crt_enabled", value)
	cfg.save(PATH)
