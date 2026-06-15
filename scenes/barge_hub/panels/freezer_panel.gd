# scenes/barge_hub/panels/freezer_panel.gd
extends TerminalPanel

var _count_label: Label
var _vacant: Label
var _strip: PanelContainer
var _value_label: Label
var _market_chip: Label
var _chip: Label
var _sell_btn: Button

func _ready() -> void:
	title = "freezer_storage"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build()
	refresh()

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	var header := HBoxContainer.new()
	var caption := Label.new()
	caption.text = "COLLECTED GHOST DATA REGISTRY"
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DeckStyle.apply_label(caption, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	header.add_child(caption)
	_count_label = Label.new()
	DeckStyle.apply_label(_count_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	header.add_child(_count_label)
	root.add_child(header)

	_vacant = Label.new()
	_vacant.text = "FREEZER VACANT"
	_vacant.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vacant.custom_minimum_size = Vector2(0, 48)
	_vacant.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	DeckStyle.apply_label(_vacant, DeckStyle.DIM, DeckStyle.SIZE_BODY)
	var vsb := StyleBoxFlat.new()
	vsb.bg_color = Color(0, 0, 0, 0)
	vsb.border_color = DeckStyle.BORDER
	vsb.set_border_width_all(1)
	_vacant.add_theme_stylebox_override("normal", vsb)
	root.add_child(_vacant)

	_strip = PanelContainer.new()
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = DeckStyle.BG
	ssb.border_color = DeckStyle.BORDER
	ssb.set_border_width_all(1)
	ssb.content_margin_left = 8
	ssb.content_margin_right = 8
	ssb.content_margin_top = 6
	ssb.content_margin_bottom = 6
	_strip.add_theme_stylebox_override("panel", ssb)
	var srow := HBoxContainer.new()
	var sleft := VBoxContainer.new()
	sleft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fname := Label.new()
	fname.text = "BIO_ARCHIVE_BUNDLE.dat"
	DeckStyle.apply_label(fname, DeckStyle.TEXT, DeckStyle.SIZE_AMBIENT)
	sleft.add_child(fname)
	_value_label = Label.new()
	DeckStyle.apply_label(_value_label, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	sleft.add_child(_value_label)
	srow.add_child(sleft)
	_market_chip = Label.new()
	_market_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	srow.add_child(_market_chip)
	_chip = Label.new()
	_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	srow.add_child(_chip)
	_strip.add_child(srow)
	root.add_child(_strip)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(filler)

	_sell_btn = Button.new()
	_sell_btn.text = "SELL ALL ARCHIVES TO BLACK MARKET"
	_sell_btn.focus_mode = Control.FOCUS_ALL
	DeckStyle.apply_action_button(_sell_btn, DeckStyle.RED)
	_sell_btn.pressed.connect(_on_sell)
	root.add_child(_sell_btn)

func refresh() -> void:
	var sale := GameState.freezer_sale_value()
	var has_stock := GameState.freezer_base > 0
	_count_label.text = "%s cr STORED" % _fmt(GameState.freezer_base)
	_vacant.visible = not has_stock
	_strip.visible = has_stock
	_sell_btn.visible = has_stock
	_market_chip.visible = has_stock
	if has_stock:
		_value_label.text = "%s cr" % _fmt(sale)
		_apply_chip()
		_apply_market_chip()

func spoil_chip_text() -> String:
	if GameState.freezer_runs == 0:
		return "FRESH"
	var runs_left: int = GameState.FREEZER_SPOIL_RUNS - GameState.freezer_runs
	return "SPOILS IN %d RUN%s" % [runs_left, "S" if runs_left != 1 else ""]

func _apply_chip() -> void:
	var runs_left: int = GameState.FREEZER_SPOIL_RUNS - GameState.freezer_runs
	var tier := 0
	if GameState.freezer_runs > 0:
		tier = 2 if runs_left <= 1 else 1
	var styled := DeckStyle.make_chip(spoil_chip_text(), tier, DeckStyle.SIZE_BODY)
	_chip.text = styled.text
	_chip.add_theme_stylebox_override("normal", styled.get_theme_stylebox("normal"))
	_chip.add_theme_color_override("font_color", styled.get_theme_color("font_color"))
	_chip.add_theme_font_size_override("font_size", DeckStyle.SIZE_BODY)
	styled.free()

func _apply_market_chip() -> void:
	var m := GameState.freezer_multiplier
	var tier := 0 if m >= 1.0 else 2
	# No +/- sign: it misreads as a delta on a multiplier; colour + magnitude carry direction.
	var styled := DeckStyle.make_chip("MARKET %.2fx" % m, tier, DeckStyle.SIZE_BODY)
	_market_chip.text = styled.text
	_market_chip.add_theme_stylebox_override("normal", styled.get_theme_stylebox("normal"))
	_market_chip.add_theme_color_override("font_color", styled.get_theme_color("font_color"))
	_market_chip.add_theme_font_size_override("font_size", DeckStyle.SIZE_BODY)
	styled.free()

func focus_targets() -> Array[Control]:
	return [_sell_btn]

func _on_sell() -> void:
	var sale := GameState.freezer_sale_value()
	GameState.add_credits(sale)
	GameState.freezer_base = 0
	GameState.freezer_runs = 0
	GameState.freezer_multiplier = 1.0
	GameState.save()
	EventBus.deck_log.emit("COMMERCE: Disposed all cached archives. +%s cr." % _fmt(sale))
	refresh()

static func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
