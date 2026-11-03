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

static func contact_card(catch_data: CatchData) -> String:
	var sig := ("-%d%%" % catch_data.corruption_gain) if catch_data.corruption_gain > 0 else "none"
	return "\n> contact: %s\n│  class: %s   security: %s\n│  %s\n│  SIG IMPACT: %s" % [
		catch_data.catch_name,
		type_tag(catch_data.catch_type),
		security_tag(catch_data.behavior),
		catch_data.flavor_text,
		sig]

static func option_label(num: int, option: CatchOption, behavior: CatchData.BehaviorType) -> String:
	if option.cuts_line:
		return "[%d] abort_connection  ·  vents half tension  ·  SIG -10%%  ·  no reward" % num

	var t_str: String
	if option.tension_delta > 0:
		t_str = "+%dT" % option.tension_delta
	elif option.tension_delta < 0:
		t_str = "%dT" % option.tension_delta
	else:
		t_str = "+0T"

	var parts: Array[String] = [t_str]
	if option.credit_value > 0:
		parts.append("+%dcr" % option.credit_value)

	match behavior:
		CatchData.BehaviorType.RESISTANT:
			if option.resist_chance > 0.0:
				parts.append("%d%% resist (+%dT)" % [
					int(option.resist_chance * 100), option.resist_tension_penalty])
		CatchData.BehaviorType.NEGOTIATING:
			if option.fail_chance > 0.0:
				var fail_cr := "+%dcr" % option.fail_credit_value if option.fail_credit_value > 0 else "+0cr"
				parts.append("%d%% fail (+%dT, %s)" % [
					int(option.fail_chance * 100), option.fail_tension_delta, fail_cr])

	var label := option.label.to_lower().replace(" ", "_")
	return "[%d] %s  ·  %s" % [num, label, "  ·  ".join(parts)]

static func command_label(num: int, cmd: Dictionary) -> String:
	match cmd.id:
		"DECRYPT_NODE":
			return "[%d] DECRYPT_NODE          +10T  ·  -1 anchor  ·  guaranteed" % num
		"BRUTE_FORCE_OVERRIDE":
			return "[%d] BRUTE_FORCE_OVERRIDE  +25T  ·  -2 anchor  ·  60%%  (fail: +40T)" % num
		"SYNGAS_FLOOD":
			return "[%d] SYNGAS_FLOOD          +0T   ·  -1 anchor  ·  50%%  (fail: +30T)" % num
		"SIGNAL_DAMPEN":
			return "[%d] SIGNAL_DAMPEN         -15T  ·  no effect  ·  guaranteed" % num
		"OVERLOAD_CORE":
			return "[%d] OVERLOAD_CORE [shock] +15T  ·  -2 anchor  ·  guaranteed" % num
		"ISOLATE_FEED":
			return "[%d] ISOLATE_FEED          emergency disconnect  (lose catch, keep tension)" % num
	return ""

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
