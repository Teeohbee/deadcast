# scenes/relay/RelayRunner.gd
# Steps through one relay script (a call, a text exchange or a dive line set
# from RelayScripts) and hands back one event at a time. Pure: no scene tree,
# no GameState. The screen that owns the runner shows the events and applies
# any "do" actions itself.
#
# Step kinds:
#   {"say": "text"}                       a line, spoken by the script contact
#                                         (or by "who" when the step names one)
#   {"attach": "text"}                    a case file or similar, shown as an attachment
#   {"replies": [{"text", "then"}], "silent": [...]}
#                                         the player picks a reply; "silent" adds
#                                         SAY_NOTHING as the last option
#   {"do": "action_id"}                   a game effect, see RelayScripts.ACTIONS
# Any step may carry "only_if": flag_name and "is": bool, and is skipped unless
# flags[flag_name] == is.
class_name RelayRunner
extends RefCounted

const EVENT_SAY := "say"
const EVENT_ATTACH := "attach"
const EVENT_REPLIES := "replies"
const EVENT_DO := "do"
const EVENT_END := "end"

const SAY_NOTHING := "…say nothing"
const SILENCE_IN_TRANSCRIPT := "…"
const PLAYER := "you"

var script_id: String
var contact: String
# Every line said, in order: {"who", "text"}, plus "attachment": true on attachments.
var transcript: Array[Dictionary] = []
# Every "do" action reached, in order.
var actions_taken: Array[String] = []

var _flags: Dictionary
var _values: Dictionary
# Each frame is {"steps": Array, "next_index": int}; branches push a frame.
var _frames: Array[Dictionary] = []
var _open_replies_step: Dictionary = {}
var _finished := false

func _init(relay_script: Dictionary, flags: Dictionary = {}, values: Dictionary = {}) -> void:
	script_id = relay_script.get("id", "")
	contact = relay_script.get("contact", "")
	_flags = flags
	_values = values
	_frames.append({"steps": relay_script.get("steps", []), "next_index": 0})

func is_finished() -> bool:
	return _finished

func is_waiting_for_reply() -> bool:
	return not _open_replies_step.is_empty()

func next_event() -> Dictionary:
	if is_waiting_for_reply():
		return _replies_event(_open_replies_step)
	while true:
		var step := _take_next_step()
		if step.is_empty():
			_finished = true
			return {"kind": EVENT_END}
		if not _step_applies(step):
			continue
		if step.has("say"):
			var line := {"who": step.get("who", contact), "text": _fill_values(step.say)}
			transcript.append(line)
			return {"kind": EVENT_SAY, "who": line.who, "text": line.text}
		if step.has("attach"):
			var attachment := {"who": step.get("who", contact), "text": _fill_values(step.attach), "attachment": true}
			transcript.append(attachment)
			return {"kind": EVENT_ATTACH, "who": attachment.who, "text": attachment.text}
		if step.has("replies"):
			_open_replies_step = step
			return _replies_event(step)
		if step.has("do"):
			actions_taken.append(step.do)
			return {"kind": EVENT_DO, "action": step.do}
		push_error("RelayRunner: %s has a step with no known kind: %s" % [script_id, step])
	return {"kind": EVENT_END}

# Picks a reply from the open replies; the index counts SAY_NOTHING last.
func choose(option_index: int) -> void:
	if not is_waiting_for_reply():
		push_error("RelayRunner: %s choose() with no replies open" % script_id)
		return
	var step := _open_replies_step
	_open_replies_step = {}
	var options: Array = step.replies
	if option_index < options.size():
		transcript.append({"who": PLAYER, "text": options[option_index].text})
		_frames.append({"steps": options[option_index].get("then", []), "next_index": 0})
	elif step.has("silent"):
		transcript.append({"who": PLAYER, "text": SILENCE_IN_TRANSCRIPT})
		_frames.append({"steps": step.silent, "next_index": 0})
	else:
		push_error("RelayRunner: %s reply %d out of range" % [script_id, option_index])

# Plays the rest of the script as if the player never answered: every open
# reply takes its silent branch. Used for missed calls and unanswered texts.
func run_to_end_without_replies() -> void:
	while not _finished:
		var event := next_event()
		if event.kind != EVENT_REPLIES:
			continue
		if not _open_replies_step.has("silent"):
			push_error("RelayRunner: %s has replies without a silent branch, so it can't play unanswered" % script_id)
			_finished = true
			return
		choose(_open_replies_step.replies.size())

func _take_next_step() -> Dictionary:
	while not _frames.is_empty():
		var frame: Dictionary = _frames.back()
		if frame.next_index < frame.steps.size():
			var step: Dictionary = frame.steps[frame.next_index]
			frame.next_index += 1
			return step
		_frames.pop_back()
	return {}

func _step_applies(step: Dictionary) -> bool:
	if not step.has("only_if"):
		return true
	return bool(_flags.get(step.only_if, false)) == bool(step.get("is", true))

func _replies_event(step: Dictionary) -> Dictionary:
	var options: Array[String] = []
	for option in step.replies:
		options.append(option.text)
	if step.has("silent"):
		options.append(SAY_NOTHING)
	return {"kind": EVENT_REPLIES, "options": options}

func _fill_values(text: String) -> String:
	return text.format(_values)
