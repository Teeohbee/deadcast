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

var _label: Label
var _scroll := 0.0

func _ready() -> void:
	title = "market_ticker"
	custom_minimum_size = Vector2(0, 40)
	clip_contents = true

	_label = Label.new()
	_label.text = ticker_text()
	DeckStyle.apply_label(_label, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	add_child(_label)

func _process(delta: float) -> void:
	_scroll += delta * 40.0
	if _label and _label.size.x > 0 and _scroll > _label.size.x:
		_scroll = -size.x
	if _label:
		_label.position.x = -_scroll

# Builds the scrolling string from live purchase costs. Tested directly.
func ticker_text() -> String:
	var parts: Array[String] = []
	for path in GOODS:
		var res := load(path)
		var name := ""
		var cost := 0
		if res is RodData:
			name = (res as RodData).rod_name
			cost = (res as RodData).purchase_cost
		elif res is LureData:
			name = (res as LureData).lure_name
			cost = (res as LureData).purchase_cost
		parts.append("%s %dcr" % [name.to_lower().replace(" ", "_"), cost])
	return "     ".join(parts) + "     "
