# scenes/barge_hub/VendorShop.gd
extends Control

const ROD_PATHS: Array[String] = [
	"res://resources/rods/scrap_rod.tres",
	"res://resources/rods/monocarbon_rig.tres",
	"res://resources/rods/ghost_line.tres",
]
const LURE_PATHS: Array[String] = [
	"res://resources/lures/basic_hook.tres",
	"res://resources/lures/shock_lure.tres",
	"res://resources/lures/decoy_swarm.tres",
	"res://resources/lures/deep_pulse.tres",
	"res://resources/lures/ghost_bait.tres",
]

@onready var stock_container: VBoxContainer = $VBoxContainer/StockContainer
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))
	_build_stock()
	back_button.grab_focus()

func _build_stock() -> void:
	for child in stock_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var multiplier = GameState.get_vendor_price_multiplier()
	if multiplier > 1.0:
		var warning = Label.new()
		warning.text = "PRESSURE SURCHARGE: prices +20%"
		stock_container.add_child(warning)

	# Rods
	var rod_header = Label.new()
	rod_header.text = "-- RODS --"
	stock_container.add_child(rod_header)

	for path in ROD_PATHS:
		var rod: RodData = load(path)
		var price = int(rod.purchase_cost * multiplier)
		var btn = Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		var equipped = GameState.current_rod and GameState.current_rod.rod_name == rod.rod_name
		btn.text = "%s%s — %dT cap / %dft — %dcr" % [
			"[EQUIPPED] " if equipped else "",
			rod.rod_name, rod.tension_cap, rod.max_depth, price]
		btn.disabled = price == 0 or equipped or GameState.credits < price
		var rod_ref = rod
		var price_ref = price
		btn.pressed.connect(func(): _buy_rod(rod_ref, price_ref))
		stock_container.add_child(btn)

	# Lures
	var lure_header = Label.new()
	lure_header.text = "-- LURES --"
	stock_container.add_child(lure_header)

	for path in LURE_PATHS:
		var lure: LureData = load(path)
		var price = int(lure.purchase_cost * multiplier)
		var qty = GameState.lure_inventory.get(GameState.get_lure_id(lure), 0)
		var btn = Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.text = "%s — x%d in stock — %dcr" % [lure.lure_name, qty, price]
		btn.disabled = price == 0 or GameState.credits < price
		var lure_ref = lure
		var price_ref = price
		btn.pressed.connect(func(): _buy_lure(lure_ref, price_ref))
		stock_container.add_child(btn)

func _buy_rod(rod: RodData, price: int) -> void:
	if GameState.spend_credits(price):
		GameState.equip_rod(rod)
		GameState.save()
		message_label.text = "%s equipped." % rod.rod_name
		_build_stock()
	else:
		message_label.text = "Not enough credits."

func _buy_lure(lure: LureData, price: int) -> void:
	if GameState.spend_credits(price):
		var lure_id = GameState.get_lure_id(lure)
		GameState.lure_inventory[lure_id] = GameState.lure_inventory.get(lure_id, 0) + 1
		GameState.save()
		message_label.text = "%s purchased." % lure.lure_name
		_build_stock()
	else:
		message_label.text = "Not enough credits."
