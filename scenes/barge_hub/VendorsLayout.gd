# scenes/barge_hub/VendorsLayout.gd
extends Control

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
@onready var stock_container: VBoxContainer = $MarginContainer/VBoxContainer/StockRow/LeftColumn/StockPanel/VBox/StockContainer
@onready var message_label: Label = $MarginContainer/VBoxContainer/StockRow/LeftColumn/StockPanel/VBox/MessageLabel
@onready var _ticker: MarketTicker = $MarginContainer/VBoxContainer/MarketTicker
@onready var _vendor_link: VendorLink = $MarginContainer/VBoxContainer/StockRow/RightColumn/VendorLink
@onready var _schematic: ItemSchematic = $MarginContainer/VBoxContainer/StockRow/RightColumn/ItemSchematic

func _ready() -> void:
	DeckStyle.apply_label(message_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	_vendor_link.refresh()
	_build_stock()

func on_screen_shown() -> void:
	_vendor_link.refresh()
	_build_stock()

# Okeke is the deck's sole dealer: rods and lures, base price, always open.
func _build_stock() -> void:
	# Detach old rows immediately rather than awaiting a frame: an await here let
	# _ready's build and on_screen_shown's build interleave and stack two copies.
	for child in stock_container.get_children():
		stock_container.remove_child(child)
		child.queue_free()
	_schematic.clear()

	if GameState.is_under_the_counter():
		_add_dim_label("\"axiom's list says i can't sell to you. so this is under the counter, and the counter costs.\"\n— okeke")
	else:
		_add_dim_label("\"if you need it, i can get it. don't ask where from.\"\n— okeke")

	_add_stock_header("── rods ─────────────────────────────────────────────────")
	for path in ROD_PATHS:
		var rod: RodData = load(path)
		var price := GameState.vendor_price(rod.purchase_cost)
		var equipped := GameState.current_rod and GameState.current_rod.rod_name == rod.rod_name
		var label := "%s%s — %dT cap / %dft — %dcr%s" % [
			"[equipped] " if equipped else "", rod.rod_name.to_lower(),
			rod.tension_cap, rod.max_depth, price, _markup(price)]
		var btn := _make_stock_btn(label, equipped or price == 0 or GameState.credits < price)
		var rod_ref := rod
		btn.pressed.connect(func(): _buy_rod(rod_ref, price))
		_wire_inspect(btn, "rod", ROD_PATHS.find(path), rod.rod_name, rod.description)
		stock_container.add_child(btn)

	_add_stock_header("── lures ────────────────────────────────────────────────")
	for path in LURE_PATHS:
		var lure: LureData = load(path)
		var price := GameState.vendor_price(lure.purchase_cost)
		var qty: int = GameState.lure_inventory.get(GameState.get_lure_id(lure), 0)
		var stock_str := "∞" if qty == GameState.INFINITE_STOCK else "x%d" % qty
		var btn := _make_stock_btn(
			"%s — %s in stock — %dcr%s" % [lure.lure_name.to_lower(), stock_str, price, _markup(price)],
			price == 0 or GameState.credits < price)
		var lure_ref := lure
		btn.pressed.connect(func(): _buy_lure(lure_ref, price))
		_wire_inspect(btn, "lure", lure.effect, lure.lure_name, lure.description)
		stock_container.add_child(btn)

	# Hand keyboard/controller focus to the first buyable item so nav works on load.
	_focus_first_buyable()

func _focus_first_buyable() -> void:
	var target := default_focus()
	if target != null:
		target.grab_focus()

func default_focus() -> Control:
	for child in stock_container.get_children():
		if child is Button and not (child as Button).disabled and not child.is_queued_for_deletion():
			return child
	return null

func _wire_inspect(btn: Button, kind: String, variant: int, item_name: String, description: String = "") -> void:
	btn.focus_entered.connect(func(): _schematic.show_item(kind, variant, item_name, description))
	btn.mouse_entered.connect(func(): _schematic.show_item(kind, variant, item_name, description))

func _markup(price: int) -> String:
	return GameState.vendor_markup_suffix() if price > 0 else ""

func _make_stock_btn(text: String, disabled: bool) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_ALL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text = text
	btn.disabled = disabled
	DeckStyle.apply_action_button(btn, DeckStyle.AMBER if GameState.get_vendor_price_multiplier() > 1.0 else DeckStyle.GREEN)
	return btn

func _add_stock_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	DeckStyle.apply_label(lbl, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	stock_container.add_child(lbl)

func _add_dim_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	# Wrap so long item descriptions can't blow the panel out past the screen edge.
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DeckStyle.apply_label(lbl, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	stock_container.add_child(lbl)

func _buy_rod(rod: RodData, price: int) -> void:
	if GameState.spend_credits(price):
		GameState.equip_rod(rod)
		GameState.save()
		message_label.text = "%s equipped." % rod.rod_name.to_lower()
		message_label.add_theme_color_override("font_color", DeckStyle.GREEN)
		_build_stock()
	else:
		message_label.text = "not enough credits."
		message_label.add_theme_color_override("font_color", DeckStyle.RED)

func _buy_lure(lure: LureData, price: int) -> void:
	if GameState.spend_credits(price):
		var lure_id := GameState.get_lure_id(lure)
		GameState.lure_inventory[lure_id] = GameState.lure_inventory.get(lure_id, 0) + 1
		GameState.save()
		message_label.text = "%s purchased." % lure.lure_name.to_lower()
		message_label.add_theme_color_override("font_color", DeckStyle.GREEN)
		_build_stock()
	else:
		message_label.text = "not enough credits."
		message_label.add_theme_color_override("font_color", DeckStyle.RED)
