# scenes/dive_run/haul/HaulDebug.gd
# Spike-only: play hauls on their own, without a dive. Removed in the conversion.
#   godot --path . res://scenes/dive_run/haul/HaulDebug.tscn
# Keys 1-4 pick the prototype's contacts; T toggles tutorial. Each haul loops into the next.
# For frame checks: `-- --bot --shot=/tmp/haul.png@4.0` lets a prompt bot play and saves a
# screenshot at that many seconds of play.
extends Control

const CONTACTS := [
	{ "glyph": "[#]", "title": "encrypted pension record", "dials": { "weight": 1.0, "slip": 0.6, "tempo": 1.0, "erratic": false },
		"words": ["PAYROLL", "0447-K", "TRANSFER", "KESSLER", "VOID"] },
	{ "glyph": "(@)", "title": "contraband bio-stash", "dials": { "weight": 0.8, "slip": 1.6, "tempo": 1.25, "erratic": true },
		"words": ["LOT 17", "COLD", "VIABLE", "4C", "SEALED"] },
	{ "glyph": "<=>", "title": "salvage drone hull", "dials": { "weight": 1.9, "slip": 0.3, "tempo": 0.6, "erratic": false },
		"words": ["MK II", "PATROL", "PING", "GATE 9"] },
	{ "glyph": "{=}", "title": "deep archive server core", "dials": { "weight": 1.4, "slip": 1.3, "tempo": 1.1, "erratic": true },
		"words": ["FLOOD NIGHT", "GATE 9 OPEN", "EVAC LIST", "247 NAMES", "M. VOSS"] },
]

var _contact := 0
var _difficulty := "normal"
var _run: HaulRun
var _bot := false
var _bot_mem := {}
var _shot_path := ""
var _shot_at := -1.0
var _clock := 0.0

func _ready() -> void:
	theme = DeckStyle.get_theme()
	for arg in OS.get_cmdline_user_args():
		if arg == "--bot":
			_bot = true
		elif arg.begins_with("--shot="):
			var parts := arg.trim_prefix("--shot=").split("@")
			_shot_path = parts[0]
			_shot_at = float(parts[1])
		elif arg.begins_with("--contact="):
			_contact = int(arg.trim_prefix("--contact="))
	_start()

func _start() -> void:
	if _run:
		_run.queue_free()
	var c: Dictionary = CONTACTS[_contact]
	_run = HaulRun.new()
	_run.setup(c.dials, _difficulty, PackedStringArray(c.words), c.glyph, c.title)
	_run.finished.connect(func(_r: Dictionary) -> void: _start())
	add_child(_run)
	_bot_mem = {}
	if _bot:
		_run.set_process(false)

func _process(delta: float) -> void:
	_clock += delta
	if _bot:
		var press := _clock > 0.2 and (_run.sim.phase != HaulSim.DONE) and HaulSim.prompt(_run.sim, _bot_mem)
		_run.tick(minf(delta, 0.05), press)
	if _shot_at >= 0.0 and _clock >= _shot_at:
		_shot_at = -1.0
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_4:
			_contact = k - KEY_1
			_start()
		elif k == KEY_T:
			_difficulty = "normal" if _difficulty == "tutorial" else "tutorial"
			_start()
