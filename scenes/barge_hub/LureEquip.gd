# scenes/barge_hub/LureEquip.gd
extends VBoxContainer

const LURE_IDS: Array[String] = ["basic_hook", "shock_lure", "decoy_swarm", "deep_pulse", "ghost_bait"]
const _FOOTER := "└────────────────────────────────────────────────────────────"

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	UIStyle.apply_label($LureLabel, UIStyle.COL_DIM)
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		if child.name != "LureLabel":
			child.queue_free()

	await get_tree().process_frame

	var focus_btn: Button = null
	for lure_id in LURE_IDS:
		var lure: LureData = load("res://resources/lures/%s.tres" % lure_id)
		var qty := GameState.lure_inventory.get(lure_id, 0)
		var is_equipped := GameState.current_lure != null and GameState.get_lure_id(GameState.current_lure) == lure_id
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		UIStyle.apply_button(btn)
		btn.text = "%s%s (%s)" % [
			"│  > " if is_equipped else "│    ",
			lure.lure_name.to_lower(),
			_stock_display(qty)]
		btn.disabled = not GameState.INFINITE_STOCK == qty and qty == 0
		btn.pressed.connect(func() -> void: _on_lure_selected(lure))
		add_child(btn)
		if lure.description != "":
			var desc := Label.new()
			desc.text = "│    " + lure.description.to_lower()
			UIStyle.apply_label(desc, UIStyle.COL_DIM)
			add_child(desc)
		if is_equipped:
			focus_btn = btn

	var footer := Label.new()
	footer.text = _FOOTER
	UIStyle.apply_label(footer, UIStyle.COL_DIM)
	add_child(footer)

	if focus_btn:
		focus_btn.grab_focus()

func _stock_display(qty: int) -> String:
	return "∞" if qty == GameState.INFINITE_STOCK else "x%d" % qty

func _on_lure_selected(lure: LureData) -> void:
	GameState.equip_lure(lure)
	_rebuild()
