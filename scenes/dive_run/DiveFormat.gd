# scenes/dive_run/DiveFormat.gd
# Static text formatters for dive-run messaging. No scene-tree dependencies.
class_name DiveFormat

static func result_line(credits: int, tension_delta: int, corruption_gain: int) -> String:
	var parts: Array[String] = []
	if credits != 0:
		parts.append("%+dcr" % credits)
	if tension_delta != 0:
		parts.append("%+dT" % tension_delta)
	if corruption_gain != 0:
		parts.append("SIG %+d%%" % (-corruption_gain))
	if parts.is_empty():
		return ">>> no change"
	return ">>> " + "  ·  ".join(parts)

## The haul's fragments as plain log text: read words, scrambled ones, and blanks for unread.
static func recovered_fragments(recovered: Array) -> String:
	var parts: Array[String] = []
	for f in recovered:
		var word: String = f.word
		match f.state:
			HaulFragments.READ:
				parts.append(word)
			HaulFragments.LOST:
				parts.append(_mask(word, "▓"))
			_:
				parts.append(_mask(word, "░"))
	return "  ·  ".join(parts)

static func _mask(word: String, ch: String) -> String:
	var out := ""
	for c in word:
		out += " " if c == " " else ch
	return out

static func type_tag(catch_type: CatchData.CatchType) -> String:
	match catch_type:
		CatchData.CatchType.DATA:   return "[DATA_CONTAINER]"
		CatchData.CatchType.BIO:    return "[BIO_SPECIMEN]"
		CatchData.CatchType.MECH:   return "[MECH_SYSTEM]"
		CatchData.CatchType.ENTITY: return "[ENTITY_DETECTED]"
	return "[UNKNOWN]"

static func security_tag(behavior: CatchData.BehaviorType) -> String:
	match behavior:
		CatchData.BehaviorType.PASSIVE:     return "[STANDARD_YIELD]"
		CatchData.BehaviorType.RESISTANT:   return "[ENC_RESISTANT]"
		CatchData.BehaviorType.NEGOTIATING: return "[NEGOTIATING]"
		CatchData.BehaviorType.AGGRESSIVE:  return "[HOSTILE]"
	return "[UNKNOWN]"

## sig_cost: the contact's signal cost on the current line (QUIET halves it);
## -1 means the catch's own corruption_gain.
static func contact_card(catch_data: CatchData, hauled: bool = false, sig_cost: int = -1) -> String:
	var cost := catch_data.corruption_gain if sig_cost < 0 else sig_cost
	var sig := ("-%d%%" % cost) if cost > 0 else "none"
	var card := "\n> contact: %s\n│  class: %s   security: %s\n│  %s\n│  SIG IMPACT: %s" % [
		catch_data.catch_name,
		type_tag(catch_data.catch_type),
		security_tag(catch_data.behavior),
		catch_data.flavor_text,
		sig]
	if hauled:
		card += "\n│  hauls: %s" % HaulTurn.feel(catch_data)
	return card

## Tells, not sums: rough stakes in words (line strain, value), and UNCERTAIN when the
## option still rolls dice. Hauled options never do - the haul decides them. Exact
## numbers go to the session log once the option resolves.
static func lure_label(num: int, text: String) -> String:
	return "[%d] %s" % [num, text]

static func option_label(num: int, option: CatchOption, behavior: CatchData.BehaviorType, hauled: bool = false) -> String:
	if option.cuts_line:
		return "[%d] abort_connection  ·  vents half the strain  ·  costs signal  ·  no reward" % num
	var parts: Array[String] = ["[%d] %s" % [num, option.label.to_lower().replace(" ", "_")]]
	var strain := HaulTurn.strain_word(option.tension_delta)
	if strain != "":
		parts.append("strain: " + strain)
	var value := HaulTurn.value_word(option.credit_value)
	if value != "":
		parts.append("value: " + value)
	if not hauled and _rolls_dice(option, behavior):
		parts.append("UNCERTAIN")
	return "  ·  ".join(parts)

static func _rolls_dice(option: CatchOption, behavior: CatchData.BehaviorType) -> bool:
	match behavior:
		CatchData.BehaviorType.RESISTANT:
			return option.resist_chance > 0.0
		CatchData.BehaviorType.NEGOTIATING:
			return option.fail_chance > 0.0
	return false

## Overload fight commands in words, built from the command's own numbers.
static func command_label(num: int, cmd: Dictionary) -> String:
	var parts: Array[String] = ["[%d] %s" % [num, cmd.id]]
	if cmd.id == "DECOY_SLIP":
		parts.append("slip it, draw something calmer")
		parts.append("uses a decoy")
		return "  ·  ".join(parts)
	if cmd.id == "ISOLATE_FEED":
		parts.append("emergency disconnect")
		parts.append("lose the catch, keep the strain")
		return "  ·  ".join(parts)
	var cost: int = cmd.get("t_cost", 0)
	if cost < 0:
		parts.append("eases strain")
	elif cost > 0:
		parts.append("strain: " + HaulTurn.strain_word(cost))
	var hit: int = cmd.get("anchor_hit", 0)
	if hit < 0:
		parts.append("breaks %d" % -hit)
	parts.append(odds_word(cmd.get("success_rate", 1.0)))
	if cmd.id == "OVERLOAD_CORE":
		parts.append("uses a shock lure")
	return "  ·  ".join(parts)

static func odds_word(success_rate: float) -> String:
	if success_rate >= 1.0:
		return "SURE"
	if success_rate > 0.5:
		return "RISKY"
	return "COIN FLIP"

static func overload_status(anchor_current: int, anchor_strength: int, threat: float, turn: int) -> String:
	var filled := "◆".repeat(anchor_current)
	var empty := "◇".repeat(maxi(0, anchor_strength - anchor_current))
	return "│  anchor %s%s  %d/%d  ·  threat ×%.2f  ·  turn %d" % [
		filled, empty, anchor_current, anchor_strength, threat, turn]

static func narrative_entry(catch_name: String, text: String) -> String:
	var indented := "│  " + "\n│  ".join(text.split("\n"))
	return "── LOG_ENTRY: %s\n%s" % [catch_name, indented]

static func archive_result(result: String, credits: int, tension: int, sig: int) -> String:
	if credits == 0 and tension == 0 and sig == 0:
		return result if result != "" else "no change"
	var base := result_line(credits, tension, sig).trim_prefix(">>> ")
	if result == "":
		return base
	return "%s  ·  %s" % [result, base]

static func job_result(title: String, met: bool, relief: int) -> String:
	if met:
		return "job: %s  ·  complete  ·  axiom balance -%dcr" % [title, relief]
	return "job: %s  ·  failed" % title

static func run_log_text(record: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("── RUN_%03d.LOG  ·  %s ──────────────────" % [int(record.run), str(record.zone)])
	lines.append("")
	var contacts := 0
	for e: Dictionary in record.entries:
		match str(e.kind):
			"slot":
				contacts += 1
				lines.append("[S%d] %s  %s" % [int(e.slot), str(e.name), str(e.type_tag)])
				lines.append("     > %s" % str(e.echo))
				lines.append("     >>> %s" % archive_result(
					str(e.result), int(e.credits), int(e.tension), int(e.sig)))
			"checkpoint":
				lines.append("[CP] %s cleared  ·  haul %dcr" % [str(e.layer), int(e.haul)])
				lines.append("     > %s" % str(e.choice))
			"lure":
				lines.append("     >>> %s" % str(e.text))
			"snapped":
				lines.append("     [!!! TENSION EXCEEDED !!!]")
			"job":
				lines.append("[JOB] %s" % job_result(str(e.title), bool(e.met), int(e.relief)))
	lines.append("")
	if str(record.outcome) == "snapped":
		lines.append(">>> session terminated  ·  haul forfeited: %dcr" % int(record.forfeited))
	else:
		lines.append(">>> surfaced  ·  banked %dcr  ·  contacts resolved: %d" % [
			int(record.banked), contacts])
	return "\n".join(lines)

# At 90+ corruption a new contact sometimes blacks the feed out with a fake
# [SIGNAL LOST] before the real card appears. roll is 0..1.
const FAKE_SIGNAL_LOSS_CORRUPTION := 90.0
const FAKE_SIGNAL_LOSS_CHANCE := 0.35

static func should_fake_signal_loss(corruption: float, roll: float) -> bool:
	return corruption >= FAKE_SIGNAL_LOSS_CORRUPTION and roll < FAKE_SIGNAL_LOSS_CHANCE

static func glitch_intensity(corruption: float) -> float:
	if corruption >= 90.0:
		return 0.18
	if corruption >= 70.0:
		return 0.10
	if corruption >= 50.0:
		return 0.05
	if corruption >= 30.0:
		return 0.02
	return 0.0
