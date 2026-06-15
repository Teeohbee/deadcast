# tests/test_screen_reveal_refresh.gd
extends GutTest

const DECK := preload("res://scenes/barge_hub/BargeHub.tscn")

func before_each() -> void:
	GameState.credits = 0
	GameState.debt = 0
	GameState.freezer_value = 0
	GameState.freezer_runs = 0
	GameState.pressure_level = 0
	GameState.selected_zone = "district7"

func _make(scene: PackedScene) -> Node:
	var s := scene.instantiate()
	add_child_autofree(s)
	return s

func test_deck_reveal_refreshes_freezer() -> void:
	var deck := _make(DECK)
	await get_tree().process_frame
	GameState.freezer_value = 1400
	deck.on_screen_shown()
	assert_string_contains(deck._freezer_panel._value_label.text, "1,400")

const WORKSHOP := preload("res://scenes/barge_hub/Workshop.tscn")

func test_workshop_reveal_reflects_rod_damage() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	GameState.rod_damaged = false
	var w := _make(WORKSHOP)
	await get_tree().process_frame
	GameState.rod_damaged = true
	w.on_screen_shown()
	assert_string_contains(w.rod_label.text, "[damaged]")

const VENDORS := preload("res://scenes/barge_hub/VendorsLayout.tscn")

func _has_enabled_stock(v: Node) -> bool:
	for c in v.stock_container.get_children():
		if c is Button and not (c as Button).disabled:
			return true
	return false

func test_vendors_reveal_rebuilds_stock_for_credits() -> void:
	GameState.credits = 0
	GameState.lure_inventory = {}
	var v := _make(VENDORS)
	await get_tree().process_frame
	await get_tree().process_frame
	GameState.credits = 999999
	v.on_screen_shown()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(_has_enabled_stock(v), "raising credits should enable at least one item")

const BUNK := preload("res://scenes/barge_hub/Bunk.tscn")

func test_bunk_reveal_picks_up_new_run_log() -> void:
	GameState.run_logs = [] as Array[Dictionary]
	var b := _make(BUNK)
	await get_tree().process_frame
	b._set_mode(b.Mode.LOG)
	assert_string_contains(b.content_label.text, "no archived runs")
	GameState.run_logs = [{
		"run": 1, "zone": "axiom depths", "entries": [],
		"banked": 250, "forfeited": 0, "outcome": "surfaced",
	}] as Array[Dictionary]
	b.on_screen_shown()
	assert_string_contains(b.content_label.text, "axiom")

const MARTA := preload("res://scenes/barge_hub/MartaTerminal.tscn")

func test_marta_reveal_updates_payment_countdown() -> void:
	GameState.victory = false
	GameState.runs_since_payment = 0
	var m := _make(MARTA)
	await get_tree().process_frame
	assert_string_contains(m.payment_label.text, "5 run")
	GameState.runs_since_payment = 4
	m.on_screen_shown()
	assert_string_contains(m.payment_label.text, "1 run")

const DECRYPT := preload("res://scenes/barge_hub/DecryptBox.tscn")

func test_decrypt_reveal_reflects_queue() -> void:
	GameState.credits = 50000
	GameState.decrypt_box_queue = 0
	GameState.decrypt_box_runs = 0
	var d := _make(DECRYPT)
	await get_tree().process_frame
	assert_string_contains(d.status_label.text, "box is empty")
	GameState.decrypt_box_queue = 1000
	GameState.decrypt_box_runs = 1
	d.on_screen_shown()
	assert_string_contains(d.status_label.text, "queued")
