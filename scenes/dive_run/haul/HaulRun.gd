# scenes/dive_run/haul/HaulRun.gd
# One winch haul on screen: hold HAUL (action_reel - Space / pad A) to pull the payload
# up, let go on amber. Owns the rules (HaulSim), the fragment block, the Signal trace
# view, sounds and the result card, then emits `finished` once the player presses on.
#
# A haul only starts on a fresh press, so the press that picked the option on the card
# can't start it by accident. Tests drive tick() directly with scripted button states.
class_name HaulRun
extends Control

signal finished(result: Dictionary)

const ACTION := "action_reel"
const ACTION_GLYPH := "haul"
const MAX_STEP := 0.05
const CONTINUE_DELAY := 0.3 # s after the result before a press moves on
const HUM_FILE := "res://audio/kenney_sci_fi/engineCircular_000.ogg"
const HUM_DB := -14.0
const SILENT_DB := -60.0

## What a haul brought up. outcome: perfect | clean | messy | snap.
## fragments: [{ word, state }] from HaulFragments.recovered().
var result: Dictionary = {}
var sim: HaulSim
## Shock lure charges for this haul (machines only), set before adding the run.
var shield := 0
var fragments: HaulFragments
var view: HaulView
var result_card: PanelContainer
var par := 0.0

var _dials: Dictionary
var _difficulty: String
var _words: PackedStringArray
var _glyph: String
var _title: String
var _rng: HaulSim.Lcg
var _armed := false
var _was_held := false
var _done_t := 0.0
var _emitted := false
var _banner_until := -1.0
var _hints_done := {}
var _creak_in := 0.0
var _hum: AudioStreamPlayer

func setup(dials: Dictionary, difficulty: String, words: PackedStringArray, glyph: String, title: String,
		rng: HaulSim.Lcg = null) -> void:
	_dials = dials
	_difficulty = difficulty
	_words = words
	_glyph = glyph
	_title = title
	_rng = rng

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	sim = HaulSim.new(_dials, _difficulty, _rng)
	sim.shield = shield
	fragments = HaulFragments.new(_words, HaulView.ROWS, _rng)
	par = HaulSim.par(_dials, _difficulty)

	view = HaulView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.sim = sim
	view.fragments = fragments
	view.glyph = _glyph
	add_child(view)

	result_card = PanelContainer.new()
	result_card.visible = false
	result_card.set_anchors_preset(Control.PRESET_CENTER)
	result_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(result_card)

	_hum = AudioStreamPlayer.new()
	var stream := (load(HUM_FILE) as AudioStream).duplicate() as AudioStreamOggVorbis
	stream.loop = true
	_hum.stream = stream
	_hum.bus = "Events"
	_hum.volume_db = SILENT_DB
	add_child(_hum)
	_hum.play()

	view.title = "%s %s" % [_glyph, _title]
	_say_opening()
	# The status already names the button, so the first hint explains instead.
	_hint("opening", "the payload rises while you hold and slips back when you let go")
	InputGlyphs.device_changed.connect(_on_device_changed)
	tree_exiting.connect(func() -> void:
		if InputGlyphs.device_changed.is_connected(_on_device_changed):
			InputGlyphs.device_changed.disconnect(_on_device_changed))

func _say_opening() -> void:
	_say(_prompt("hold to haul"), DeckStyle.GREEN, 0.0, InputGlyphs.icon(ACTION_GLYPH))

# The opening prompt follows the device until the haul starts.
func _on_device_changed(_mode: int) -> void:
	if sim.phase == HaulSim.READY:
		_say_opening()

func _process(delta: float) -> void:
	tick(minf(delta, MAX_STEP), Input.is_action_pressed(ACTION))

func tick(dt: float, pressed: bool) -> void:
	if not _armed:
		_armed = not pressed
		pressed = false
	if sim.phase == HaulSim.DONE:
		_done_t += dt
		if pressed and not _was_held and _done_t >= CONTINUE_DELAY and not _emitted:
			_emitted = true
			finished.emit(result)
		_was_held = pressed
		return
	if sim.phase == HaulSim.LIVE and pressed and not _was_held:
		Audio.play_cue("haul_grip")

	var events := sim.step(dt, pressed)
	view.hit_t += dt
	var hit := events.has("hit")
	if hit:
		view.hit_t = 0.0
	for i in fragments.update(dt, HaulView.rows_risen(sim), hit):
		Audio.play_cue("haul_decode")
		_hint("decode", "a fragment decoded - hits you take while hauling scramble them")
	_handle(events)

	if sim.phase == HaulSim.LIVE:
		if sim.line_load > 60.0:
			_creak_in -= dt
			if _creak_in <= 0.0:
				Audio.play_cue("line_strain")
				_creak_in = 0.35 - (sim.line_load - 60.0) / 160.0
		if sim.t >= _banner_until:
			_say("hauling" if pressed else "holding - it's slipping back", DeckStyle.TEXT if pressed else DeckStyle.DIM, 0.0)
	_update_hum(pressed, dt)
	view.held = pressed
	view.advance(dt)
	_was_held = pressed

func _handle(events: Array[String]) -> void:
	for e in events:
		match e:
			"start":
				_hint("start", "keep hauling... let go when the packet climbs the line")
			"tell":
				Audio.play_cue("haul_tell")
				_say(">> incoming - let go", DeckStyle.AMBER, sim.tell)
			"hit":
				Audio.play_cue("haul_hit")
				ScreenFX.shake(view, 12.0, 0.3)
				_say("HIT - you were still hauling", DeckStyle.RED, 0.8)
				_hint("hit", "that hit landed because you were hauling - let go on amber")
			"shocked":
				Audio.play_cue("lure_fire")
				_say("SHOCK - hit absorbed", DeckStyle.SKY, 0.8)
			"absorbed":
				Audio.play_cue("haul_absorbed")
				_say("hit absorbed", DeckStyle.GREEN, 0.6)
				_hint("absorbed", "nice - now haul again before it slips back down")
			"red":
				Audio.play_cue("haul_red")
				_say("RED - LET GO", DeckStyle.RED, sim.grace)
				_hint("red", "in the red - let go now or the line snaps")
			"snap", "land":
				_finish()

# Prompts lead with the button: an icon drawn before the text on a pad, the
# keycap written into the text on a keyboard.
func _prompt(caption: String) -> String:
	return caption if InputGlyphs.icon(ACTION_GLYPH) else "%s %s" % [InputGlyphs.glyph(ACTION_GLYPH), caption]

func _say(text: String, color: Color, hold: float, icon: Texture2D = null) -> void:
	view.status = text
	view.status_color = color
	view.status_icon = icon
	_banner_until = sim.t + hold

func _hint(key: String, text: String) -> void:
	if not sim.hints() or _hints_done.has(key):
		return
	_hints_done[key] = true
	view.hint = text
	view.hint_icon = null

func _update_hum(pressed: bool, dt: float) -> void:
	var live := sim.phase == HaulSim.LIVE and pressed
	var target_db := HUM_DB if live else SILENT_DB
	_hum.volume_db = lerpf(_hum.volume_db, target_db, minf(1.0, dt * 20.0))
	_hum.pitch_scale = lerpf(_hum.pitch_scale, 0.6 + sim.line_load * 0.008, minf(1.0, dt * 12.0))

func _finish() -> void:
	var outcome := sim.outcome
	if outcome == HaulSim.CLEAN and par > 0.0 and sim.t <= par:
		outcome = "perfect"
	var snapped := outcome == HaulSim.SNAP
	if snapped:
		Audio.play_cue("line_snap")
		Audio.play_cue("signal_lost")
		ScreenFX.shake(view, 18.0, 0.5)
	else:
		Audio.play_cue("haul_land")
		ScreenFX.shake(view, 11.0 if outcome != HaulSim.MESSY else 7.0, 0.35)
	result = {
		"outcome": outcome,
		"hits": sim.hits,
		"absorbed": sim.absorbed,
		"shocked": sim.shocked,
		"t": sim.t,
		"par": par,
		"peak": sim.peak,
		"fragments": fragments.recovered(snapped),
		"read": 0 if snapped else fragments.read_count(),
		"total": fragments.fragments.size(),
	}
	view.hint = ""
	view.status = ""
	_hum.volume_db = SILENT_DB
	_show_card()

const _HEADS := {
	"perfect": ["LANDED · PERFECT", DeckStyle.SKY],
	"clean": ["LANDED · CLEAN", DeckStyle.GREEN],
	"messy": ["LANDED · MESSY", DeckStyle.AMBER],
	"snap": ["LINE SNAPPED", DeckStyle.RED],
}

## The fragments line, BBCode: read words bright, scrambled ones red, unread ones as blanks.
static func fragments_bbcode(recovered: Array, snapped: bool) -> String:
	if snapped:
		return "[color=#%s]nothing recovered[/color]" % DeckStyle.RED.to_html(false)
	var parts: Array[String] = []
	for f in recovered:
		var word: String = f.word
		match f.state:
			HaulFragments.READ:
				parts.append(word)
			HaulFragments.LOST:
				var s := ""
				for ch in word:
					s += " " if ch == " " else HaulView.SCRAMBLE[randi() % HaulView.SCRAMBLE.length()]
				parts.append("[color=#%s]%s[/color]" % [DeckStyle.RED.to_html(false), s])
			_:
				var blank := ""
				for ch in word:
					blank += " " if ch == " " else "░"
				parts.append("[color=#%s]%s[/color]" % [DeckStyle.DIM.to_html(false), blank])
	return ("  [color=#%s]·[/color]  " % DeckStyle.DIM.to_html(false)).join(parts)

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

	var what := Label.new()
	var worth: String = {
		"perfect": "full value + bonus",
		"clean": "full value · beat %.1fs for perfect" % par,
		"messy": "took %d hit%s - damaged" % [sim.hits, "" if sim.hits == 1 else "s"],
		"snap": "payload lost",
	}[result.outcome]
	what.text = "%s %s · %s" % [_glyph, _title, worth]
	DeckStyle.apply_label(what, DeckStyle.TEXT, DeckStyle.SIZE_BODY)
	box.add_child(what)

	if result.total > 0:
		var frags := RichTextLabel.new()
		frags.bbcode_enabled = true
		frags.fit_content = true
		frags.autowrap_mode = TextServer.AUTOWRAP_OFF
		frags.scroll_active = false
		frags.add_theme_font_size_override("normal_font_size", DeckStyle.SIZE_VALUE)
		frags.text = fragments_bbcode(result.fragments, result.outcome == HaulSim.SNAP)
		box.add_child(frags)

	var stats := Label.new()
	stats.text = "%d/%d fragments · time %.1fs (par %.1fs) · peak load %d%% · hits dodged %d" % [
		result.read, result.total, sim.t, par, roundi(sim.peak), sim.absorbed]
	DeckStyle.apply_label(stats, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	box.add_child(stats)

	box.add_child(DeckPromptRow.new(ACTION_GLYPH, "continue", DeckStyle.GREEN, DeckStyle.SIZE_BODY))

	result_card.visible = true
