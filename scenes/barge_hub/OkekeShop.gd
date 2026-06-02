# scenes/barge_hub/OkekeShop.gd
extends Control

# Okeke sells lures at 20% cheaper than vendor base price
const OKEKE_DISCOUNT: float = 0.8
const LURE_PATHS: Array[String] = [
	"res://resources/lures/shock_lure.tres",
	"res://resources/lures/decoy_swarm.tres",
	"res://resources/lures/deep_pulse.tres",
	"res://resources/lures/ghost_bait.tres",
]

@onready var dialogue_label: Label = $VBoxContainer/DialogueLabel
@onready var stock_container: VBoxContainer = $VBoxContainer/StockContainer
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready() -> void:
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/barge_hub/BargeHub.tscn"))

	if GameState.pressure_level >= 3:
		dialogue_label.text = "\"Marta's people came by.\nI can't help you right now. Sorry.\"\n— Okeke"
	else:
		dialogue_label.text = "\"Better prices than whoever else you're buying from.\nDon't ask where I get them.\"\n— Okeke"
		_build_stock()

	back_button.grab_focus()

func _build_stock() -> void:
	for child in stock_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	for path in LURE_PATHS:
		var lure: LureData = load(path)
		var price = int(lure.purchase_cost * OKEKE_DISCOUNT)
		var qty = GameState.lure_inventory.get(GameState.get_lure_id(lure), 0)
		var btn = Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.text = "%s — x%d in stock — %dcr" % [lure.lure_name, qty, price]
		btn.disabled = GameState.credits < price
		var lure_ref = lure
		var price_ref = price
		btn.pressed.connect(func(): _buy_lure(lure_ref, price_ref))
		stock_container.add_child(btn)

func _buy_lure(lure: LureData, price: int) -> void:
	if GameState.spend_credits(price):
		var lure_id = GameState.get_lure_id(lure)
		GameState.lure_inventory[lure_id] = GameState.lure_inventory.get(lure_id, 0) + 1
		GameState.save()
		message_label.text = "%s purchased." % lure.lure_name
		_build_stock()
	else:
		message_label.text = "Not enough credits."
