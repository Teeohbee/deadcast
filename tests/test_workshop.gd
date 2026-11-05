# tests/test_workshop.gd
extends GutTest

const SCREEN := preload("res://scenes/barge_hub/Workshop.tscn")

var _saved_rod: RodData
var _saved_damaged: bool

func before_each() -> void:
	_saved_rod = GameState.current_rod
	_saved_damaged = GameState.rod_damaged

func after_each() -> void:
	GameState.current_rod = _saved_rod
	GameState.rod_damaged = _saved_damaged

func _make() -> Node:
	var screen := SCREEN.instantiate()
	add_child_autofree(screen)
	return screen

func test_schematic_shows_equipped_rod() -> void:
	GameState.current_rod = load("res://resources/rods/monocarbon_rig.tres")
	GameState.rod_damaged = false
	var screen := _make()
	assert_string_contains(screen._schematic._caption.text, "monocarbon")
	assert_eq(screen._schematic._view.kind, "rod")
	assert_eq(screen._schematic._view.variant, 1)

func test_schematic_finds_upgraded_rod_by_name() -> void:
	var upgraded: RodData = load("res://resources/rods/ghost_line.tres").duplicate()
	upgraded.max_depth += 50
	GameState.current_rod = upgraded
	var screen := _make()
	assert_eq(screen._schematic._view.variant, 2)

func test_schematic_flags_damage() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	GameState.rod_damaged = true
	var screen := _make()
	assert_string_contains(screen._schematic._caption.text, "damaged")

func test_schematic_updates_when_screen_shown() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	var screen := _make()
	GameState.current_rod = load("res://resources/rods/ghost_line.tres")
	screen.on_screen_shown()
	assert_string_contains(screen._schematic._caption.text, "ghost")

func test_repair_costs_more_under_pressure() -> void:
	var saved_pressure := GameState.pressure_level
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	GameState.rod_damaged = true
	GameState.pressure_level = 2
	var screen := _make()
	assert_string_contains(screen.repair_button.text, "600cr")
	GameState.pressure_level = saved_pressure
