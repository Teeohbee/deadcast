# scenes/barge_hub/panels/rig_panel.gd
extends TerminalPanel

const LURE_ORDER: Array[String] = ["basic_hook", "shock_lure", "decoy_swarm", "deep_pulse", "ghost_bait"]

var _rod_name: Label
var _rod_meta: Label
var _rod_damage: Label
var _lure_button: Button
var _effect_value: Label
var _cycle_hint: DeckPromptRow

func _ready() -> void:
	title = "active_rig_module"
	_build()
	refresh()

func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var rod_row := HBoxContainer.new()
	rod_row.add_theme_constant_override("separation", 8)
	_rod_name = Label.new()
	DeckStyle.apply_label(_rod_name, DeckStyle.GREEN, DeckStyle.SIZE_BODY)
	rod_row.add_child(_rod_name)
	_rod_damage = Label.new()
	_rod_damage.text = "[DAMAGED]"
	DeckStyle.apply_label(_rod_damage, DeckStyle.RED, DeckStyle.SIZE_BODY)
	rod_row.add_child(_rod_damage)
	root.add_child(rod_row)

	_rod_meta = Label.new()
	DeckStyle.apply_label(_rod_meta, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	root.add_child(_rod_meta)

	# Not focusable: lure cycling is a global hotkey (see _input), not a focus
	# stop. Mouse click still cycles for desktop convenience.
	_lure_button = Button.new()
	_lure_button.focus_mode = Control.FOCUS_NONE
	_lure_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	DeckStyle.apply_action_button(_lure_button, DeckStyle.TEXT)
	_lure_button.pressed.connect(cycle_lure)
	root.add_child(_lure_button)

	_cycle_hint = DeckPromptRow.new("cycle_lure", "CYCLE LURE", DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	root.add_child(_cycle_hint)

	var cells := HBoxContainer.new()
	cells.add_theme_constant_override("separation", 6)
	_effect_value = _add_cell(cells, "EFFECT:")
	root.add_child(cells)

func _add_cell(parent: Container, caption: String) -> Label:
	var cell := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0b120d")
	sb.border_color = Color("#142319")
	sb.set_border_width_all(1)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	cell.add_theme_stylebox_override("panel", sb)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	var cap := Label.new()
	cap.text = caption
	DeckStyle.apply_label(cap, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	box.add_child(cap)
	var val := Label.new()
	DeckStyle.apply_label(val, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	box.add_child(val)
	cell.add_child(box)
	parent.add_child(cell)
	return val

func refresh() -> void:
	var rod: RodData = GameState.current_rod
	if rod:
		_rod_name.text = rod.rod_name
		_rod_meta.text = "DEPTH RATING: %dft  ·  TENSION CAP: %d" % [GameState.line_rating_ft(), rod.tension_cap]
	_rod_damage.visible = GameState.rod_damaged

	var lure: LureData = GameState.current_lure
	if lure:
		var lure_id := GameState.get_lure_id(lure)
		var qty: int = GameState.lure_inventory.get(lure_id, 0)
		var stock := "∞" if qty == GameState.INFINITE_STOCK else "x%d" % qty
		_lure_button.text = "LURE: %s (%s)" % [lure.lure_name.to_upper(), stock]
		_effect_value.text = LureData.LureEffect.keys()[lure.effect]

func owned_lure_ids() -> Array[String]:
	var out: Array[String] = []
	for id in LURE_ORDER:
		var qty: int = GameState.lure_inventory.get(id, 0)
		if qty == GameState.INFINITE_STOCK or qty > 0:
			out.append(id)
	return out

func cycle_lure() -> void:
	var owned := owned_lure_ids()
	if owned.is_empty():
		return
	var current_id := GameState.get_lure_id(GameState.current_lure) if GameState.current_lure else ""
	var next_id: String = owned[(owned.find(current_id) + 1) % owned.size()]
	if next_id == current_id:
		return
	GameState.equip_lure(load("res://resources/lures/%s.tres" % next_id))
	EventBus.deck_log.emit("RIGS: Lure module swapped to %s." % next_id.to_upper().replace("_", " "))
	refresh()

# Lure cycling is a global deck hotkey (X / Tab), not a focusable control. We
# handle it in _input and consume the event so Tab does not also move UI focus.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("cycle_lure"):
		cycle_lure()
		get_viewport().set_input_as_handled()

# Rig is now a read-only readout - no focus stops (lure cycles via hotkey).
func focus_targets() -> Array[Control]:
	return []
