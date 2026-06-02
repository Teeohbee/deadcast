# scenes/barge_hub/LureEquip.gd
extends VBoxContainer

const LURE_IDS: Array[String] = ["basic_hook", "shock_lure", "decoy_swarm", "deep_pulse", "ghost_bait"]

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		if child.name != "LureLabel":
			child.queue_free()

	await get_tree().process_frame

	for lure_id in LURE_IDS:
		var lure_path = "res://resources/lures/%s.tres" % lure_id
		var lure: LureData = load(lure_path)
		var qty = GameState.lure_inventory.get(lure_id, 0)
		var btn = Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		var is_equipped = GameState.current_lure != null and GameState.get_lure_id(GameState.current_lure) == lure_id
		btn.text = "%s%s (x%d)" % ["▶ " if is_equipped else "", lure.lure_name, qty]
		btn.disabled = qty == 0
		btn.pressed.connect(func() -> void: _on_lure_selected(lure))
		add_child(btn)

func _on_lure_selected(lure: LureData) -> void:
	GameState.equip_lure(lure)
	_rebuild()
