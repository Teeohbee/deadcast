# autoload/Settings.gd
extends Node

const PATH := "user://settings.cfg"

var crt_enabled: bool = true
var audio_muted: bool = false

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		crt_enabled = cfg.get_value("video", "crt_enabled", true)
		audio_muted = cfg.get_value("audio", "muted", false)

func set_crt_enabled(value: bool) -> void:
	crt_enabled = value
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # ignore error; fresh file is fine
	cfg.set_value("video", "crt_enabled", value)
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("Settings: failed to save %s (error %d)" % [PATH, err])

func set_audio_muted(value: bool) -> void:
	audio_muted = value
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # ignore error; fresh file is fine
	cfg.set_value("audio", "muted", value)
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("Settings: failed to save %s (error %d)" % [PATH, err])
