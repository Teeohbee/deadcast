extends GutTest

const SCREEN := preload("res://scenes/title_screen/TitleScreen.tscn")

var _save_backup_exists: bool = false
var _save_backup_data: PackedByteArray = PackedByteArray()
var _backup_ready: bool = false

func before_each() -> void:
	_backup_ready = true
	_save_backup_exists = FileAccess.file_exists(GameState.save_path)
	_save_backup_data = PackedByteArray()
	if _save_backup_exists:
		var f := FileAccess.open(GameState.save_path, FileAccess.READ)
		if not f:
			_backup_ready = false
			return
		_save_backup_data = f.get_buffer(f.get_length())
	_remove_save()

func after_each() -> void:
	if not _backup_ready:
		return
	_remove_save()
	if _save_backup_exists:
		var f := FileAccess.open(GameState.save_path, FileAccess.WRITE)
		if f:
			f.store_buffer(_save_backup_data)

func _remove_save() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists(GameState.save_path.get_file()):
		dir.remove(GameState.save_path.get_file())

func _create_save() -> void:
	var f := FileAccess.open(GameState.save_path, FileAccess.WRITE)
	if f:
		f.store_string("test")

func _make() -> Node:
	var s := SCREEN.instantiate()
	add_child_autofree(s)
	return s

func _skip_when_backup_unavailable() -> bool:
	if _backup_ready:
		return false
	return true

func test_continue_hidden_without_save() -> void:
	if _skip_when_backup_unavailable():
		return
	var s := _make()
	await get_tree().process_frame
	assert_false(s.continue_button.visible)
	assert_true(s.new_game_button.visible)
	assert_false(s.confirm_panel.visible)

func test_continue_visible_with_save() -> void:
	if _skip_when_backup_unavailable():
		return
	_create_save()
	var s := _make()
	await get_tree().process_frame
	assert_true(s.continue_button.visible)

func test_crt_overlay_exists() -> void:
	if _skip_when_backup_unavailable():
		return
	var s := _make()
	await get_tree().process_frame
	assert_not_null(s.get_node("CRTOverlay"))

func test_crt_disabled_zeroes_scan_alpha() -> void:
	if _skip_when_backup_unavailable():
		return
	Settings.crt_enabled = false
	var s := _make()
	await get_tree().process_frame
	var overlay := s.get_node("CRTOverlay") as ColorRect
	assert_eq(overlay.material.get_shader_parameter("scan_alpha"), 0.0)
	Settings.crt_enabled = true

func test_crt_enabled_keeps_shader_default_scan_alpha() -> void:
	if _skip_when_backup_unavailable():
		return
	Settings.crt_enabled = true
	var s := _make()
	await get_tree().process_frame
	var overlay := s.get_node("CRTOverlay") as ColorRect
	assert_null(overlay.material.get_shader_parameter("scan_alpha"))

func test_new_game_with_existing_save_shows_confirm_prompt() -> void:
	if _skip_when_backup_unavailable():
		return
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
	if _skip_when_backup_unavailable():
		return
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

func test_title_shows_block_letter_wordmark() -> void:
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s.title_label.text, "█")
	assert_gt(s.title_label.text.split("\n").size(), 4, "wordmark should be several lines tall")

func test_sound_toggle_flips_mute_and_its_label() -> void:
	var muted_before := Settings.audio_muted
	Settings.set_audio_muted(false)
	var s := _make()
	await get_tree().process_frame
	assert_string_contains(s.sound_button.text, "SOUND: ON")
	s.sound_button.pressed.emit()
	assert_true(Settings.audio_muted)
	assert_string_contains(s.sound_button.text, "SOUND: OFF")
	Settings.set_audio_muted(muted_before)
	Audio.apply_mute_setting()

func test_crt_toggle_switches_the_overlay_live() -> void:
	var crt_before := Settings.crt_enabled
	Settings.set_crt_enabled(true)
	var s := _make()
	await get_tree().process_frame
	var overlay := s.get_node("CRTOverlay") as ColorRect
	s.crt_button.pressed.emit()
	assert_false(Settings.crt_enabled)
	assert_eq(overlay.material.get_shader_parameter("scan_alpha"), 0.0)
	assert_string_contains(s.crt_button.text, "CRT: OFF")
	s.crt_button.pressed.emit()
	assert_null(overlay.material.get_shader_parameter("scan_alpha"))
	Settings.set_crt_enabled(crt_before)

func test_confirm_prompt_hides_settings_toggles() -> void:
	if _skip_when_backup_unavailable():
		return
	_create_save()
	var s := _make()
	await get_tree().process_frame
	s.new_game_button.pressed.emit()
	await get_tree().process_frame
	assert_false(s.sound_button.visible)
	assert_false(s.crt_button.visible)

func test_boot_flicker_hides_the_menu_until_it_finishes() -> void:
	if _skip_when_backup_unavailable():
		return
	var s := _make()
	await get_tree().process_frame
	s.play_boot_flicker()
	assert_true(s.is_booting)
	assert_true(s.boot_label.visible)
	s.finish_boot_flicker()
	assert_false(s.is_booting)
	assert_false(s.boot_label.visible)
	assert_almost_eq(s.get_node("OuterMargin").modulate.a, 1.0, 0.01)

func test_title_is_not_booting_when_opened_directly() -> void:
	if _skip_when_backup_unavailable():
		return
	var s := _make()
	await get_tree().process_frame
	assert_false(s.is_booting)
	assert_false(s.boot_label.visible)
