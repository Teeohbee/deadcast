# scenes/dive_run/depth_column.gd
# Rail widget: vertical wireframe of the dive column. Reskins the old ASCII depth
# track (DiveHUD.format_depth_track) as a stacked, sky-thermocline column with a
# climbing pressure readout. Pure column_cells() for testability; live wiring over
# EventBus.slot_changed / slot_revealed.
class_name DepthColumnPanel
extends TerminalPanel

const GLYPH_PAST := "✓"
const GLYPH_CURRENT := "▶"
const GLYPH_UNKNOWN := "?"

# Returns one entry per reachable slot, top->bottom:
#   {"glyph": "✓"|"▶"|"?"|<marker>, "first_in_layer": bool}
static func column_cells(layer_sizes: Array, current_slot: int, markers: Dictionary) -> Array:
	var cells: Array = []
	var idx := 0
	for layer_size: int in layer_sizes:
		for i in layer_size:
			var glyph: String
			if idx < current_slot:
				glyph = GLYPH_PAST
			elif idx == current_slot:
				glyph = GLYPH_CURRENT
			elif markers.has(idx):
				glyph = str(markers[idx])
			else:
				glyph = GLYPH_UNKNOWN
			cells.append({"glyph": glyph, "first_in_layer": i == 0})
			idx += 1
	return cells

var _rows: VBoxContainer
var _pressure: Label
var _layer_sizes: Array = []
var _current_slot: int = 0
var _markers: Dictionary = {}

func _ready() -> void:
	title = "depth_column"
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	_pressure = Label.new()
	DeckStyle.apply_label(_pressure, DeckStyle.SKY, DeckStyle.SIZE_AMBIENT)
	root.add_child(_pressure)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 1)
	root.add_child(_rows)

	EventBus.slot_changed.connect(_on_slot_changed)
	EventBus.slot_revealed.connect(_on_slot_revealed)

func setup(layer_sizes: Array) -> void:
	_layer_sizes = layer_sizes
	_refresh()

func _on_slot_changed(current: int, _total: int) -> void:
	_current_slot = current - 1  # slot_changed is 1-based
	_refresh()

func _on_slot_revealed(index: int, marker: String) -> void:
	_markers[index] = marker
	_refresh()

func _refresh() -> void:
	_pressure.text = "PRESSURE %s · THERMOCLINE 4.1°C" % _pressure_label()
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var cells := column_cells(_layer_sizes, _current_slot, _markers)
	for i in cells.size():
		var cell: Dictionary = cells[i]
		if cell["first_in_layer"] and i > 0:
			var div := Label.new()
			div.text = "├─ thermocline ─"
			DeckStyle.apply_label(div, DeckStyle.SKY, DeckStyle.SIZE_AMBIENT)
			_rows.add_child(div)
		var row := Label.new()
		row.text = "  [%s]" % cell["glyph"]
		var col := DeckStyle.DIM
		if cell["glyph"] == GLYPH_CURRENT:
			col = DeckStyle.GREEN
		elif cell["glyph"] == GLYPH_PAST:
			col = DeckStyle.DIM
		elif cell["glyph"] != GLYPH_UNKNOWN:
			col = DeckStyle.AMBER
		DeckStyle.apply_label(row, col, DeckStyle.SIZE_BODY)
		_rows.add_child(row)

func _pressure_label() -> String:
	var rod := GameState.current_rod
	var ceiling := rod.max_depth if rod else 100
	return "%dft" % ceiling
