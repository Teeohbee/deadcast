# scenes/barge_hub/panels/rig_panel.gd
extends TerminalPanel

var _rod_name: Label
var _rod_meta: Label
var _rod_damage: Label
var _slot_buttons: Array[Button] = []
var _effect_value: Label

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

	# Provision slots: press to cycle through owned lures (and empty). They are
	# the rig's focus stops, so the pad reaches them from the zone list.
	for slot in GameState.LOADOUT_SLOTS:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_action_button(button, DeckStyle.TEXT)
		var slot_index := slot
		button.pressed.connect(func() -> void: cycle_slot(slot_index))
		root.add_child(button)
		_slot_buttons.append(button)

	var cells := HBoxContainer.new()
	cells.add_theme_constant_override("separation", 6)
	_effect_value = _add_cell(cells, "PROVISIONS:")
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

	var roles: Array[String] = []
	for slot in _slot_buttons.size():
		var lure_id: String = GameState.loadout[slot]
		if lure_id == "":
			_slot_buttons[slot].text = "SLOT %d: empty" % (slot + 1)
			continue
		var lure := GameState.lure_data(lure_id)
		_slot_buttons[slot].text = "SLOT %d: [%s] %s x%d" % [
			slot + 1, lure.role_label(), lure.lure_name.to_upper(), GameState.lure_stock(lure_id)]
		roles.append(lure.role_label())
	_effect_value.text = " · ".join(roles) if not roles.is_empty() else "none loaded"

func slot_buttons() -> Array[Button]:
	return _slot_buttons

func cycle_slot(slot: int) -> void:
	var before: String = GameState.loadout[slot]
	GameState.cycle_loadout_slot(slot)
	var after: String = GameState.loadout[slot]
	if after != before:
		EventBus.deck_log.emit("RIGS: Slot %d %s." % [slot + 1,
			"loaded with " + after.to_upper().replace("_", " ") if after != "" else "emptied"])
	refresh()

func focus_targets() -> Array[Control]:
	var targets: Array[Control] = []
	targets.assign(_slot_buttons)
	return targets
