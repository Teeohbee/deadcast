# scenes/barge_hub/panels/market_ticker.gd
extends TerminalPanel
class_name MarketTicker

const GOODS: Array[String] = [
	"res://resources/rods/scrap_rod.tres",
	"res://resources/rods/monocarbon_rig.tres",
	"res://resources/rods/ghost_line.tres",
	"res://resources/lures/shock_lure.tres",
	"res://resources/lures/decoy_swarm.tres",
	"res://resources/lures/deep_pulse.tres",
	"res://resources/lures/ghost_bait.tres",
]

# Market chatter woven between the live price feed. ASCII only - the deck font
# (IBM Plex Mono) has no arrow/triangle glyphs, so price moves use +/-%.
const NEWS: Array[String] = [
	"MERIDIAN_EXCHANGE 1,204.8 +2.4%",
	"salvage futures climb on deep-sector finds",
	"marta_holdings absorbs three dock leases",
	"kelp_index slips as surface demand cools",
	"pressure-rated alloy shortage drives rig costs up",
	"ghost-net recoveries post record quarter",
	"abyssal_freight halts after lost convoy",
	"lure-tech IPO oversubscribed 6x",
	"credit liquidity tight below 200ft",
	"port authority flags black-market sonar parts",
	"deep_pulse demand spikes on swarm sightings",
	"insurers hike premiums for sub-250ft runs",
]

const SCROLL_SPEED: float = 70.0  # px/sec
const GAP: String = "        "    # spacing between the looped copies

var _scroll := 0.0
var _text := ""
# The scrolling text lives in its own clipped Control so the panel title can
# still overhang the top border (clipping the whole panel would chop the title).
var _view: Control

func _ready() -> void:
	title = "market_ticker"
	custom_minimum_size = Vector2(0, 50)
	_text = ticker_text()

	_view = Control.new()
	_view.clip_contents = true
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_ticker)
	add_child(_view)

func _process(delta: float) -> void:
	_scroll += delta * SCROLL_SPEED
	if _view:
		_view.queue_redraw()

func _draw_ticker() -> void:
	if _text.is_empty():
		return

	var font := get_theme_font("font", "Label")
	var fsize := DeckStyle.SIZE_BODY
	var ascent := font.get_ascent(fsize)
	var baseline := (_view.size.y - ascent - font.get_descent(fsize)) / 2.0 + ascent

	var unit := _text + GAP
	var unit_w := font.get_string_size(unit, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	if unit_w <= 0.0:
		return

	# Seamless loop: draw the unit repeatedly from a wrapped offset until the
	# view width is covered. _view's clip_contents trims the overflow.
	var x := -fmod(_scroll, unit_w)
	while x < _view.size.x:
		_view.draw_string(font, Vector2(x, baseline), unit,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, DeckStyle.TEXT)
		x += unit_w

# Builds the scrolling string from live purchase costs interleaved with market
# chatter. Tested directly.
func ticker_text() -> String:
	var parts: Array[String] = []
	for i in GOODS.size():
		var res := load(GOODS[i])
		var name := ""
		var cost := 0
		if res is RodData:
			name = (res as RodData).rod_name
			cost = (res as RodData).purchase_cost
		elif res is LureData:
			name = (res as LureData).lure_name
			cost = (res as LureData).purchase_cost
		parts.append("%s %dcr %s" % [
			name.to_lower().replace(" ", "_"), cost, _price_move(name, cost)])
		# Slot a headline in after every couple of goods so news keeps scrolling by.
		if i % 2 == 1:
			parts.append("// %s //" % NEWS[(i / 2) % NEWS.size()])
	return "        ".join(parts) + "        "

# Deterministic pseudo-random price move per item, e.g. "+1.8%" / "-0.6%".
func _price_move(name: String, cost: int) -> String:
	var h: int = abs(name.hash() + cost)
	var tenths := h % 50             # 0.0 .. 4.9
	var sign := "+" if (h / 50) % 2 == 0 else "-"
	return "%s%d.%d%%" % [sign, tenths / 10, tenths % 10]
