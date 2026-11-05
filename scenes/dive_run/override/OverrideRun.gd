# scenes/dive_run/override/OverrideRun.gd
# One hostile encounter on screen: d-pad codes in (ui_up/down/left/right - the pad's
# d-pad or the arrow keys), OverrideSim rules, the encounter frame, sounds, and a result
# card. Emits `tension_changed` as the line strains so the dive rail stays live, then
# `finished` once the player presses on from the result.
#
# Tests drive press() and tick() directly.
class_name OverrideRun
extends Control

signal finished(result: Dictionary)
signal tension_changed(tension: float)

const MAX_STEP := 0.05
const CONTINUE_DELAY := 0.4
const LOG_LINES := 4
const DIR_ACTIONS := { "ui_up": "u", "ui_down": "d", "ui_left": "l", "ui_right": "r" }

## What happened. outcome: won | snap | fled | slipped. used: provision id -> uses spent.
var result: Dictionary = {}
var sim: OverrideSim
var view: OverrideView
var result_card: PanelContainer

var _config: Dictionary
var _title: String
var _class_line: String
var _art: String
var _fx: Dictionary
var _rng: HaulSim.Lcg
var _start_uses: Dictionary
var _last_tension := 0.0
var _done_t := 0.0
var _emitted := false

func setup(config: Dictionary, title: String, class_line: String, art: String, fx: Dictionary,
		rng: HaulSim.Lcg = null) -> void:
	_config = config
	_title = title
	_class_line = class_line
	_art = art
	_fx = fx
	_rng = rng

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	sim = OverrideSim.new(_config, _rng)
	_start_uses = sim.uses.duplicate()
	_last_tension = sim.tension

	view = OverrideView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.sim = sim
	view.title = _title
	view.class_line = _class_line
	view.art = _art
	view.fx = _fx
	add_child(view)

	result_card = PanelContainer.new()
	result_card.visible = false
	result_card.set_anchors_preset(Control.PRESET_CENTER)
	result_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(result_card)

	_log("> contact: %s · anchor locked to the line" % _title.to_lower(), DeckStyle.AMBER)
	if sim.guided:
		view.hint = "enter the lock with the d-pad before the bar runs out"
	Audio.play_cue("contact_entity")

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	for action in DIR_ACTIONS:
		if event.is_action_pressed(action):
			press(DIR_ACTIONS[action])
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		continue_pressed()

func _process(delta: float) -> void:
	tick(minf(delta, MAX_STEP))

func press(dir: String) -> void:
	if sim.phase == OverrideSim.DONE:
		return
	_handle(sim.press(dir))

func tick(dt: float) -> void:
	if sim.phase == OverrideSim.DONE:
		_done_t += dt
		view.advance(dt)
		return
	_handle(sim.step(dt))
	view.advance(dt)

func continue_pressed() -> void:
	if sim.phase != OverrideSim.DONE or _done_t < CONTINUE_DELAY or _emitted:
		return
	_emitted = true
	finished.emit(result)

func _handle(events: Array[String]) -> void:
	for e in events:
		match e:
			"charge":
				Audio.play_cue("override_charge")
				if sim.guided and sim.round_number == 2:
					view.hint = "BREAK unlocked · it hits twice as hard while the hostile charges"
				elif sim.guided and sim.round_number == 3:
					view.hint = "the whole rig is live"
				elif sim.guided and sim.round_number > 3:
					view.hint = ""
			"input":
				Audio.play_cue("override_input")
			"wrong":
				Audio.play_cue("override_wrong")
				view.wrong_t = 0.0
				_log(">>> bad input · +%dT" % OverrideSim.WRONG_STRAIN, DeckStyle.RED)
			"requote":
				Audio.play_cue("override_requote")
				view.requote_t = 0.0
			"lock":
				Audio.play_cue("override_null")
				view.null_t = 0.0
				_fired(e)
				_log(">>> OVERRIDE ACCEPTED · attack nulled", DeckStyle.GREEN)
			"break":
				Audio.play_cue("override_break")
				view.deal_t = 0.0
				_fired(e)
				_log(">>> BREAK%s · anchor %d/%d" % [" while it's exposed" if sim.exposed() else "", sim.anchor, sim.anchor_max], DeckStyle.GREEN)
			"shock":
				Audio.play_cue("lure_fire")
				view.deal_t = 0.0
				_fired(e)
				_log(">>> SHOCK lure · anchor %d/%d" % [sim.anchor, sim.anchor_max], DeckStyle.SKY)
			"splice":
				Audio.play_cue("lure_fire")
				_fired(e)
				_log(">>> SPLICE fitted · line vented %dT" % OverrideSim.SPLICE_VENT, DeckStyle.SKY)
			"decoy", "isolate":
				Audio.play_cue("lure_fire" if e == "decoy" else "signal_glitch")
				_fired(e)
			"hit":
				Audio.play_cue("haul_hit")
				view.hit_t = 0.0
				_log(">>> attack lands · +%dT" % sim.hit_damage, DeckStyle.RED)
	if not is_equal_approx(sim.tension, _last_tension):
		_last_tension = sim.tension
		tension_changed.emit(sim.tension)
	if sim.phase == OverrideSim.DONE and result.is_empty():
		_finish()

func _fired(id: String) -> void:
	view.fired_id = id
	view.fired_t = 0.0

func _log(text: String, color: Color) -> void:
	view.log_lines.append({ "text": text, "color": color })
	while view.log_lines.size() > LOG_LINES:
		view.log_lines.pop_front()

func _finish() -> void:
	var used := {}
	for id in _start_uses:
		if _start_uses[id] > 0:
			used[id] = _start_uses[id] - sim.uses[id]
	result = {
		"outcome": sim.outcome,
		"anchor": sim.anchor,
		"anchor_max": sim.anchor_max,
		"rounds": sim.round_number,
		"nulled": sim.nulled,
		"hits": sim.hits_taken,
		"wrong": sim.wrong,
		"tension": sim.tension,
		"used": used,
	}
	match sim.outcome:
		OverrideSim.WON:
			Audio.play_cue("haul_land")
		OverrideSim.SNAP:
			Audio.play_cue("line_snap")
			Audio.play_cue("signal_lost")
			ScreenFX.shake(view, 18.0, 0.5)
	view.hint = ""
	_show_card()

const _HEADS := {
	"won": ["ANCHOR SEVERED · LANDED", DeckStyle.GREEN],
	"snap": ["LINE SNAPPED", DeckStyle.RED],
	"fled": ["FEED ISOLATED", DeckStyle.AMBER],
	"slipped": ["DECOY · CONTACT SLIPPED", DeckStyle.SKY],
}

func _show_card() -> void:
	var head: Array = _HEADS[result.outcome]
	var sb := DeckStyle.panel_style(true)
	sb.border_color = head[1]
	sb.bg_color = Color(DeckStyle.PANEL_BG, 0.95)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	result_card.add_theme_stylebox_override("panel", sb)
	result_card.theme = DeckStyle.get_theme()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	result_card.add_child(box)
	var title := Label.new()
	title.text = head[0]
	DeckStyle.apply_label(title, head[1], 24)
	box.add_child(title)
	var stats := Label.new()
	stats.text = "%d round%s · %d nulled · %d hit%s taken · tension %d" % [
		result.rounds, "" if result.rounds == 1 else "s", result.nulled,
		result.hits, "" if result.hits == 1 else "s", roundi(result.tension)]
	DeckStyle.apply_label(stats, DeckStyle.DIM, DeckStyle.SIZE_BODY)
	box.add_child(stats)
	box.add_child(DeckPromptRow.new("accept", "continue", DeckStyle.GREEN, DeckStyle.SIZE_BODY))
	result_card.visible = true
