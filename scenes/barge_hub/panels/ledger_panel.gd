# scenes/barge_hub/panels/ledger_panel.gd
extends TerminalPanel

const SEGMENTS := 5
const SEGMENT_EMPTY := Color("#111c14")

var _wallet_value: Label
var _debt_value: Label
var _pressure_ratio: Label
var _segments: Array[ColorRect] = []
var _due_value: Label

func _ready() -> void:
	title = "⁴account_ledger"
	_build()
	EventBus.credits_changed.connect(_on_credits_changed)
	refresh()

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	_wallet_value = _add_row(root, "WALLET BALANCE:", DeckStyle.GREEN)
	_debt_value = _add_row(root, "OUTSTANDING DEBT:", DeckStyle.RED)

	var ratio_row := HBoxContainer.new()
	var plabel := Label.new()
	plabel.text = "DEBT ACCRUAL PRESSURE:"
	plabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DeckStyle.apply_label(plabel, DeckStyle.DIM, DeckStyle.FONT_SIZE_TINY)
	ratio_row.add_child(plabel)
	_pressure_ratio = Label.new()
	DeckStyle.apply_label(_pressure_ratio, DeckStyle.AMBER, DeckStyle.FONT_SIZE_TINY)
	ratio_row.add_child(_pressure_ratio)
	root.add_child(ratio_row)

	var seg_row := HBoxContainer.new()
	seg_row.add_theme_constant_override("separation", 2)
	for i in SEGMENTS:
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(0, 8)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg_row.add_child(seg)
		_segments.append(seg)
	root.add_child(seg_row)

	_due_value = _add_row(root, "NEXT REPOSSESSION DUE:", DeckStyle.AMBER)

func _add_row(parent: Container, caption: String, value_color: Color) -> Label:
	var row := HBoxContainer.new()
	var cap := Label.new()
	cap.text = caption
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DeckStyle.apply_label(cap, DeckStyle.DIM)
	row.add_child(cap)
	var val := Label.new()
	DeckStyle.apply_label(val, value_color, DeckStyle.FONT_SIZE_BODY)
	row.add_child(val)
	parent.add_child(row)
	return val

func _on_credits_changed(_value: int) -> void:
	refresh()

func refresh() -> void:
	_wallet_value.text = "%s cr" % _fmt(GameState.credits)
	_debt_value.text = "%s cr" % _fmt(GameState.debt)
	_pressure_ratio.text = "%d / %d" % [GameState.pressure_level, SEGMENTS]

	var fill := pressure_fill_color(GameState.pressure_level)
	DeckStyle.apply_label(_pressure_ratio, fill, DeckStyle.FONT_SIZE_TINY)
	for i in SEGMENTS:
		_segments[i].color = fill if i < GameState.pressure_level else SEGMENT_EMPTY

	var runs_left := 5 - GameState.runs_since_payment
	if runs_left > 0:
		_due_value.text = "in %d run%s" % [runs_left, "s" if runs_left != 1 else ""]
		DeckStyle.apply_label(_due_value, DeckStyle.AMBER, DeckStyle.FONT_SIZE_BODY)
	else:
		_due_value.text = "IMMEDIATE DANGER"
		DeckStyle.apply_label(_due_value, DeckStyle.RED, DeckStyle.FONT_SIZE_BODY)

static func pressure_fill_color(level: int) -> Color:
	if level >= 4:
		return DeckStyle.RED
	if level >= 2:
		return DeckStyle.AMBER
	return DeckStyle.GREEN

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
