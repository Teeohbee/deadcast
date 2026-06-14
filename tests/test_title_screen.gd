extends GutTest

const SCREEN := preload("res://scenes/title_screen/TitleScreen.tscn")

var _save_backup_exists: bool = false
var _save_backup_data: PackedByteArray = PackedByteArray()

func before_each() -> void:
	_save_backup_exists = FileAccess.file_exists(GameState.SAVE_PATH)
	_save_backup_data = PackedByteArray()
	if _save_backup_exists:
		var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.READ)
		if f:
			_save_backup_data = f.get_buffer(f.get_length())
	_remove_save()

func after_each() -> void:
	_remove_save()
	if _save_backup_exists:
		var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_buffer(_save_backup_data)

func _remove_save() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("save.cfg"):
		dir.remove("save.cfg")

func _create_save() -> void:
	var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string("test")

func _make() -> Node:
	var s := SCREEN.instantiate()
	add_child_autofree(s)
	return s

func test_continue_hidden_without_save() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_false(s.continue_button.visible)
	assert_true(s.new_game_button.visible)
	assert_false(s.confirm_panel.visible)

func test_continue_visible_with_save() -> void:
	_create_save()
	var s := _make()
	await get_tree().process_frame
	assert_true(s.continue_button.visible)

func test_crt_overlay_exists() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_not_null(s.get_node("CRTOverlay"))

func test_crt_disabled_zeroes_scan_alpha() -> void:
	Settings.crt_enabled = false
	var s := _make()
	await get_tree().process_frame
	var overlay := s.get_node("CRTOverlay") as ColorRect
	assert_eq(overlay.material.get_shader_parameter("scan_alpha"), 0.0)
	Settings.crt_enabled = true

func test_crt_enabled_uses_legible_scan_alpha() -> void:
	Settings.crt_enabled = true
	var s := _make()
	await get_tree().process_frame
	var overlay := s.get_node("CRTOverlay") as ColorRect
	assert_eq(overlay.material.get_shader_parameter("scan_alpha"), 0.03)

func test_new_game_with_existing_save_shows_confirm_prompt() -> void:
	_create_save()
	var s := _make()
	await get_tree().process_frame
	s.new_game_button.pressed.emit()
	await get_tree().process_frame
	assert_true(s.confirm_panel.visible)
	assert_false(s.continue_button.visible)
	assert_false(s.new_game_button.visible)
	assert_eq(s.get_viewport().gui_get_focus_owner(), s.yes_button)

func test_confirm_no_restores_main_actions() -> void:
	_create_save()
	var s := _make()
	await get_tree().process_frame
	s.new_game_button.pressed.emit()
	await get_tree().process_frame
	s.no_button.pressed.emit()
	await get_tree().process_frame
	assert_false(s.confirm_panel.visible)
	assert_true(s.continue_button.visible)
	assert_true(s.new_game_button.visible)
	assert_eq(s.get_viewport().gui_get_focus_owner(), s.continue_button)
