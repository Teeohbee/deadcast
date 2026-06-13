# tests/test_app_shell.gd
extends GutTest

const SHELL := preload("res://scenes/AppShell.tscn")

func _make_shell() -> Node:
	var s := SHELL.instantiate()
	add_child_autofree(s)
	return s

func test_crt_overlay_exists() -> void:
	var s := _make_shell()
	await get_tree().process_frame
	assert_not_null(s.get_node("CRTOverlay"))

func test_crt_disabled_zeroes_scan_alpha() -> void:
	Settings.crt_enabled = false
	var s := _make_shell()
	await get_tree().process_frame
	var overlay := s.get_node("CRTOverlay") as ColorRect
	assert_eq(overlay.material.get_shader_parameter("scan_alpha"), 0.0)
	Settings.crt_enabled = true

func test_crt_enabled_leaves_shader_default() -> void:
	Settings.crt_enabled = true
	var s := _make_shell()
	await get_tree().process_frame
	var overlay := s.get_node("CRTOverlay") as ColorRect
	assert_null(overlay.material.get_shader_parameter("scan_alpha"))
