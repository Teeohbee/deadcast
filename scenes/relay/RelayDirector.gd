# scenes/relay/RelayDirector.gd
# Decides which relay scripts are due at a moment in the game, from the save
# (run_count and the scripts already played). No scene-tree dependencies,
# like Unlocks.
#
# Moments, raised by the screens:
#   TRIGGER_NEW_GAME     the boot of a new game
#   TRIGGER_HUB_ARRIVAL  the hub is shown (after a dive, or on Continue)
#   TRIGGER_TAB_OPENED   a hub tab is shown, with its tab id
#
# A new-game script that hasn't played yet is also due at hub arrival, so a
# game quit mid-call replays the forced first call on Continue before the hub.
class_name RelayDirector

# The one call to play now, or {} when none is due. Forced calls come first,
# then the order of RelayScripts.all_scripts(). One call per moment at most.
static func due_call(moment: String, tab_id: String = "") -> Dictionary:
	var due := _due_scripts(moment, tab_id, RelayScripts.CHANNEL_CALL)
	for relay_script in due:
		if RelayScripts.is_forced(relay_script):
			return relay_script
	return due[0] if not due.is_empty() else {}

# Every text due now, in RelayScripts order.
static func due_texts(moment: String, tab_id: String = "") -> Array[Dictionary]:
	return _due_scripts(moment, tab_id, RelayScripts.CHANNEL_TEXT)

# For saves written before the relay existed: the scripts a player at this
# run_count has already moved past, so Continue doesn't replay the first call.
# Tab-opened scripts never count as past - Okeke can still introduce himself.
static func script_ids_already_past(run_count: int) -> Array[String]:
	var past: Array[String] = []
	for relay_script in RelayScripts.all_scripts():
		var trigger: Dictionary = relay_script.trigger
		match trigger.moment:
			RelayScripts.TRIGGER_NEW_GAME:
				if run_count > 0:
					past.append(relay_script.id)
			RelayScripts.TRIGGER_HUB_ARRIVAL:
				if trigger.has("min_pressure"):
					continue
				if run_count > trigger.get("from_run", 0):
					past.append(relay_script.id)
	return past

static func _due_scripts(moment: String, tab_id: String, channel: String) -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	for relay_script in RelayScripts.all_scripts():
		if relay_script.channel != channel:
			continue
		if GameState.relay_has_played(relay_script.id):
			continue
		if _trigger_matches(relay_script.trigger, moment, tab_id):
			due.append(relay_script)
	return due

static func _trigger_matches(trigger: Dictionary, moment: String, tab_id: String) -> bool:
	match trigger.moment:
		RelayScripts.TRIGGER_NEW_GAME:
			return moment == RelayScripts.TRIGGER_NEW_GAME or moment == RelayScripts.TRIGGER_HUB_ARRIVAL
		RelayScripts.TRIGGER_HUB_ARRIVAL:
			return moment == RelayScripts.TRIGGER_HUB_ARRIVAL \
				and GameState.run_count >= trigger.get("from_run", 0) \
				and GameState.pressure_level >= trigger.get("min_pressure", 0)
		RelayScripts.TRIGGER_TAB_OPENED:
			return moment == RelayScripts.TRIGGER_TAB_OPENED and tab_id == trigger.get("tab", "")
	return false
