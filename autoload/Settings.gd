# autoload/Settings.gd
extends Node

signal crt_changed(enabled: bool)

const PATH := "user://settings.cfg"
# Where settings are read and written; the test pre-run hook redirects it.
var path: String = PATH

var crt_enabled: bool = true
var audio_muted: bool = false

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		crt_enabled = cfg.get_value("video", "crt_enabled", true)
		audio_muted = cfg.get_value("audio", "muted", false)

# Points a CRT overlay material at the current setting: the shader's own
# scanline default when on, none when off.
static func apply_crt(material: ShaderMaterial, enabled: bool) -> void:
	material.set_shader_parameter("scan_alpha", null if enabled else 0.0)

func set_crt_enabled(value: bool) -> void:
	crt_enabled = value
	crt_changed.emit(value)
	var cfg := ConfigFile.new()
	cfg.load(path)  # ignore error; fresh file is fine
	cfg.set_value("video", "crt_enabled", value)
	var err := cfg.save(path)
	if err != OK:
		push_warning("Settings: failed to save %s (error %d)" % [path, err])

func set_audio_muted(value: bool) -> void:
	audio_muted = value
	var cfg := ConfigFile.new()
	cfg.load(path)  # ignore error; fresh file is fine
	cfg.set_value("audio", "muted", value)
	var err := cfg.save(path)
	if err != OK:
		push_warning("Settings: failed to save %s (error %d)" % [path, err])
