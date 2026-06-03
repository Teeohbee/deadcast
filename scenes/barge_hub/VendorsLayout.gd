# scenes/barge_hub/VendorsLayout.gd
extends Control

const OKEKE_DISCOUNT: float = 0.8
const ROD_PATHS: Array[String] = [
	"res://resources/rods/scrap_rod.tres",
	"res://resources/rods/monocarbon_rig.tres",
	"res://resources/rods/ghost_line.tres",
]
const LURE_PATHS: Array[String] = [
	"res://resources/lures/shock_lure.tres",
	"res://resources/lures/decoy_swarm.tres",
	"res://resources/lures/deep_pulse.tres",
	"res://resources/lures/ghost_bait.tres",
]
const OKEKE_LURE_PATHS: Array[String] = [
	"res://resources/lures/shock_lure.tres",
	"res://resources/lures/decoy_swarm.tres",
	"res://resources/lures/deep_pulse.tres",
	"res://resources/lures/ghost_bait.tres",
]

@onready var header_label: Label = $VBoxContainer/HeaderLabel
@onready var okeke_btn: Button = $VBoxContainer/VendorButtons/OkekeBtn
@onready var vendor_btn: Button = $VBoxContainer/VendorButtons/VendorBtn
@onready var stock_container: VBoxContainer = $VBoxContainer/StockContainer
@onready var message_label: Label = $VBoxContainer/MessageLabel

var _active: String = "vendor"

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_label(header_label, UIStyle.COL_DIM)
	UIStyle.apply_label(message_label, UIStyle.COL_DIM)

	for btn in [okeke_btn, vendor_btn]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIStyle.apply_button(btn)
		for st: String in ["normal", "hover", "focus", "pressed"]:
			(btn.get_theme_stylebox(st) as StyleBoxFlat).content_margin_left = 0

	okeke_btn.pressed.connect(func(): _select("okeke"))
	vendor_btn.pressed.connect(func(): _select("vendor"))

	_refresh_vendor_tabs()
	_build_stock()
	okeke_btn.grab_focus()

func _select(vendor: String) -> void:
	_active = vendor
	message_label.text = ""
	_refresh_vendor_tabs()
	_build_stock()

func _refresh_vendor_tabs() -> void:
	okeke_btn.text = "│  > okeke" if _active == "okeke" else "│    okeke"
	vendor_btn.text = "│  > the vendor" if _active == "vendor" else "│    the vendor"

func _build_stock() -> void:
	for child in stock_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	if _active == "okeke":
		_build_okeke_stock()
	else:
		_build_vendor_stock()

func _build_okeke_stock() -> void:
	if GameState.pressure_level >= 3:
		var msg := Label.new()
		msg.text = "\"marta's people came by. i can't help you right now. sorry.\"\n— okeke"
		UIStyle.apply_label(msg, UIStyle.COL_DEBT)
		stock_container.add_child(msg)
		return

	_add_dim_label("\"better prices than whoever else you're buying from.\ndon't ask where i get them.\"\n— okeke")

	for path in OKEKE_LURE_PATHS:
		var lure: LureData = load(path)
		var price := int(lure.purchase_cost * OKEKE_DISCOUNT)
		var qty: int = GameState.lure_inventory.get(GameState.get_lure_id(lure), 0)
		var btn := _make_stock_btn(
			"%s — x%d in stock — %dcr" % [lure.lure_name.to_lower(), qty, price],
			GameState.credits < price)
		var lure_ref := lure
		btn.pressed.connect(func(): _buy_lure(lure_ref, price))
		stock_container.add_child(btn)

func _build_vendor_stock() -> void:
	_add_dim_label("\"i don't ask where it came from. you shouldn't ask either.\"\n— the vendor")

	var multiplier := GameState.get_vendor_price_multiplier()
	if multiplier > 1.0:
		var warn := Label.new()
		warn.text = "pressure surcharge: prices +20%"
		UIStyle.apply_label(warn, UIStyle.COL_WARNING)
		stock_container.add_child(warn)

	_add_stock_header("── rods ─────────────────────────────────────────────────")
	for path in ROD_PATHS:
		var rod: RodData = load(path)
		var price := int(rod.purchase_cost * multiplier)
		var equipped := GameState.current_rod and GameState.current_rod.rod_name == rod.rod_name
		var label := "%s%s — %dT cap / %dft — %dcr" % [
			"[equipped] " if equipped else "", rod.rod_name.to_lower(),
			rod.tension_cap, rod.max_depth, price]
		var btn := _make_stock_btn(label, equipped or price == 0 or GameState.credits < price)
		var rod_ref := rod
		btn.pressed.connect(func(): _buy_rod(rod_ref, price))
		stock_container.add_child(btn)
		if rod.description != "":
			_add_dim_label("  " + rod.description.to_lower())

	_add_stock_header("── lures ────────────────────────────────────────────────")
	for path in LURE_PATHS:
		var lure: LureData = load(path)
		var price := int(lure.purchase_cost * multiplier)
		var qty: int = GameState.lure_inventory.get(GameState.get_lure_id(lure), 0)
		var stock_str := "∞" if qty == GameState.INFINITE_STOCK else "x%d" % qty
		var btn := _make_stock_btn(
			"%s — %s in stock — %dcr" % [lure.lure_name.to_lower(), stock_str, price],
			price == 0 or GameState.credits < price)
		var lure_ref := lure
		btn.pressed.connect(func(): _buy_lure(lure_ref, price))
		stock_container.add_child(btn)
		if lure.description != "":
			_add_dim_label("  " + lure.description.to_lower())

func _make_stock_btn(text: String, disabled: bool) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_ALL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text = text
	btn.disabled = disabled
	UIStyle.apply_button(btn)
	return btn

func _add_stock_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	UIStyle.apply_label(lbl, UIStyle.COL_SEP)
	stock_container.add_child(lbl)

func _add_dim_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	UIStyle.apply_label(lbl, UIStyle.COL_DIM)
	stock_container.add_child(lbl)

func _buy_rod(rod: RodData, price: int) -> void:
	if GameState.spend_credits(price):
		GameState.equip_rod(rod)
		GameState.save()
		message_label.text = "%s equipped." % rod.rod_name.to_lower()
		_build_stock()
	else:
		message_label.text = "not enough credits."

func _buy_lure(lure: LureData, price: int) -> void:
	if GameState.spend_credits(price):
		var lure_id := GameState.get_lure_id(lure)
		GameState.lure_inventory[lure_id] = GameState.lure_inventory.get(lure_id, 0) + 1
		GameState.save()
		message_label.text = "%s purchased." % lure.lure_name.to_lower()
		_build_stock()
	else:
		message_label.text = "not enough credits."
