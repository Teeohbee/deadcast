# autoload/Lifecycle.gd
# A flushed-per-line breadcrumb trail in user://lifecycle.log: start, a heartbeat with
# the current scene, frame stalls, and every step of shutdown. Added to chase a hang on
# quit from the Steam menu; after a hang the last lines show how far shutdown got
# (no "close request" = the game never got the quit; "exit_tree" but no "predelete" =
# stuck while freeing autoloads; and so on). Appends across runs, capped in size.
extends Node

const HEARTBEAT_SECONDS := 30.0
const STALL_SECONDS := 1.0
const MAX_BYTES := 200_000

var log_path := "user://lifecycle.log"
var _file: FileAccess
var _since_heartbeat := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_open()
	write("---- start pid=%d version=%s godot=%s renderer=%s" % [OS.get_process_id(),
		ProjectSettings.get_setting("application/config/version", "?"),
		Engine.get_version_info().string,
		RenderingServer.get_video_adapter_name()])

func _process(delta: float) -> void:
	if delta > STALL_SECONDS:
		write("stall %.1fs scene=%s" % [delta, scene_name()])
	_since_heartbeat += delta
	if _since_heartbeat >= HEARTBEAT_SECONDS:
		_since_heartbeat = 0.0
		write("alive scene=%s" % scene_name())

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			write("close request scene=%s" % scene_name())
		NOTIFICATION_WM_GO_BACK_REQUEST:
			write("go back request")
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			write("focus out")
		NOTIFICATION_APPLICATION_FOCUS_IN:
			write("focus in")
		NOTIFICATION_PREDELETE:
			write("predelete (autoloads freed, engine shutting down)")

func _exit_tree() -> void:
	write("exit_tree (scene tree leaving)")

func scene_name() -> String:
	var scene := get_tree().current_scene if is_inside_tree() else null
	return scene.name if scene != null else "-"

func write(message: String) -> void:
	if _file == null:
		return
	_file.store_line("%s  t=%.2f  %s" % [Time.get_datetime_string_from_system(), Time.get_ticks_msec() / 1000.0, message])
	_file.flush()

func _open() -> void:
	if FileAccess.file_exists(log_path):
		var existing := FileAccess.open(log_path, FileAccess.READ)
		var too_big := existing != null and existing.get_length() > MAX_BYTES
		existing = null
		if too_big:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(log_path))
	_file = FileAccess.open(log_path, FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE)
	if _file != null:
		_file.seek_end()
