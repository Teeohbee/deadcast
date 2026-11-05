# scenes/dive_run/haul/HaulDebug.gd
# Dev tool: play any real hauled contact on its own, without a dive - for tuning dials
# by feel. Not reachable from the game.
#   godot --path . res://scenes/dive_run/haul/HaulDebug.tscn
# LEFT/RIGHT contact · Z zone · H next hauled option (heavy-strain options haul heavier)
# T tutorial. Each haul loops into the next.
# Frame checks: `-- --bot --shot=/tmp/haul.png@4.0 --zone=axiom --contact=2` lets a
# prompt bot play and saves a screenshot after that many seconds.
extends Control

const ZONES := ["district7", "exchange", "axiom"]

## Every hauled option of every contact: [{ zone, catch, option }], in zone then card order.
var entries: Array[Dictionary] = []
var index := 0
var run: HaulRun
var _difficulty := "normal"
var _info: Label
var _bot := false
var _bot_mem := {}
var _shot_path := ""
var _shot_at := -1.0
var _clock := 0.0

func _ready() -> void:
	theme = DeckStyle.get_theme()
	for zone_id in ZONES:
		var zone: ZoneData = load("res://resources/zones/%s.tres" % zone_id)
		for c in zone.catches:
			for o in c.options:
				if HaulTurn.hauls(c, o):
					entries.append({ "zone": zone_id, "catch": c, "option": o })
	_info = Label.new()
	_info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_info.position = Vector2(16, -28)
	DeckStyle.apply_label(_info, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	var zone_arg := ""
	var contact_arg := 0
	for arg in OS.get_cmdline_user_args():
		if arg == "--bot":
			_bot = true
		elif arg.begins_with("--shot="):
			var parts := arg.trim_prefix("--shot=").split("@")
			_shot_path = parts[0]
			_shot_at = float(parts[1])
		elif arg.begins_with("--zone="):
			zone_arg = arg.trim_prefix("--zone=")
		elif arg.begins_with("--contact="):
			contact_arg = int(arg.trim_prefix("--contact="))
	if zone_arg != "":
		_jump_to_zone(zone_arg)
	for i in contact_arg:
		step_contact(1, false)
	_start()

func current() -> Dictionary:
	return entries[index]

## Next or previous contact (its first hauled option).
func step_contact(dir: int, restart := true) -> void:
	var c: CatchData = current().catch
	while current().catch == c:
		index = posmod(index + dir, entries.size())
	if dir < 0: # land on the contact's first option
		var here: CatchData = current().catch
		while entries[posmod(index - 1, entries.size())].catch == here and posmod(index - 1, entries.size()) != index:
			index = posmod(index - 1, entries.size())
	if restart:
		_start()

## The same contact's next hauled option.
func step_option() -> void:
	var c: CatchData = current().catch
	var next := posmod(index + 1, entries.size())
	if entries[next].catch == c:
		index = next
	else:
		while entries[posmod(index - 1, entries.size())].catch == c:
			index = posmod(index - 1, entries.size())
	_start()

func _jump_to_zone(zone_id: String) -> void:
	for i in entries.size():
		if entries[i].zone == zone_id:
			index = i
			return

func _start() -> void:
	if run:
		run.queue_free()
	var e := current()
	var c: CatchData = e.catch
	var o: CatchOption = e.option
	run = HaulRun.new()
	run.setup(HaulTurn.dials(c, o), _difficulty, HaulFragments.draw(c.fragments, c.fragments_always),
		HaulTurn.glyph(c.catch_type), c.catch_name.to_lower())
	run.finished.connect(func(_r: Dictionary) -> void: _start())
	add_child(run)
	if _info.get_parent():
		move_child(_info, -1)
	else:
		add_child(_info)
	var strain := HaulTurn.strain_word(o.tension_delta)
	_info.text = "%s · %s · %s%s · %s   [</>] contact  [Z] zone  [H] option  [T] tutorial" % [
		e.zone, o.label.to_lower(), "strain " + strain + " · " if strain != "" else "",
		HaulTurn.feel(c), _difficulty]
	_bot_mem = {}
	if _bot:
		run.set_process(false)

func _process(delta: float) -> void:
	_clock += delta
	if _bot:
		var press := _clock > 0.2 and run.sim.phase != HaulSim.DONE and HaulSim.prompt(run.sim, _bot_mem)
		run.tick(minf(delta, 0.05), press)
	if _shot_at >= 0.0 and _clock >= _shot_at:
		_shot_at = -1.0
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match (event as InputEventKey).keycode:
		KEY_RIGHT: step_contact(1)
		KEY_LEFT: step_contact(-1)
		KEY_H: step_option()
		KEY_Z:
			var z: String = current().zone
			_jump_to_zone(ZONES[(ZONES.find(z) + 1) % ZONES.size()])
			_start()
		KEY_T:
			_difficulty = "normal" if _difficulty == "tutorial" else "tutorial"
			_start()
