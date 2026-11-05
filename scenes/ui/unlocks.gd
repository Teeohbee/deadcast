# scenes/ui/unlocks.gd
# Which hub tabs, zones and panels a player can see, staged over the first few
# runs so a new operator isn't handed every system at once. Derived purely from
# save state (run_count, freezer_base), so there is no save-format change and an
# existing save past the thresholds sees everything.
class_name Unlocks

# Runs completed before each feature opens.
const TAB_OPENS_AFTER_RUN := {
	"deck": 0,
	"bunk": 0,
	"workshop": 1,
	"vendors": 1,
	"relay": 0,
	"decrypt": 3,
}
const ZONE_OPENS_AFTER_RUN := {
	"district7": 0,
	"exchange": 2,
	"axiom": 4,
}
# The freezer appears with its first deposit, and for good from this run on.
const FREEZER_ALWAYS_AFTER_RUN := 2

const FREEZER := "freezer"

# DECK COMM line posted when each feature first opens.
const ANNOUNCEMENTS := {
	"workshop": "DECK COMM: Credits logged. Workshop bay unlocked - repairs and depth upgrades.",
	"vendors": "DECK COMM: Okeke's barge is in range. VENDORS open.",
	"freezer": "DECK COMM: Freezer online. Bio catches keep here - sell before they spoil.",
	"exchange": "DECK COMM: New host on the sonar: the voss exchange.",
	"decrypt": "DECK COMM: Decrypt box powered. Feed it credits, wait three runs, gamble.",
	"axiom": "DECK COMM: Axiom sub-basement answering pings. Bring a better rod.",
}

static func is_tab_open(tab_id: String) -> bool:
	return GameState.run_count >= TAB_OPENS_AFTER_RUN.get(tab_id, 0)

static func is_zone_open(zone_id: String) -> bool:
	return GameState.run_count >= ZONE_OPENS_AFTER_RUN.get(zone_id, 0)

static func is_freezer_open() -> bool:
	return GameState.freezer_base > 0 or GameState.run_count >= FREEZER_ALWAYS_AFTER_RUN

# Every open feature id (tabs, zones and the freezer), for before/after diffs.
static func open_features() -> Array[String]:
	var features: Array[String] = []
	for tab_id in TAB_OPENS_AFTER_RUN:
		if is_tab_open(tab_id):
			features.append(tab_id)
	for zone_id in ZONE_OPENS_AFTER_RUN:
		if is_zone_open(zone_id):
			features.append(zone_id)
	if is_freezer_open():
		features.append(FREEZER)
	return features

static func newly_opened(before: Array[String], after: Array[String]) -> Array[String]:
	var opened: Array[String] = []
	for feature in after:
		if feature not in before:
			opened.append(feature)
	return opened

static func announcement_for(feature: String) -> String:
	return ANNOUNCEMENTS.get(feature, "")
