# tests/test_ambient_panels.gd
# Flavour panels recede to DeckStyle.AMBIENT_ALPHA so the numbers the player
# manages read first. The panels stay on screen and keep animating.
extends GutTest

const AMBIENT_TITLES := ["sonar_hydro-scan", "hydrophone", "biosign", "life_support",
	"market_ticker", "cipher_crack", "cipher_log", "tension_gauge", "maintenance_log",
	"relay_link"]
const SCREENS := [
	"res://scenes/barge_hub/BargeHub.tscn",
	"res://scenes/barge_hub/Workshop.tscn",
	"res://scenes/barge_hub/DecryptBox.tscn",
	"res://scenes/barge_hub/Bunk.tscn",
	"res://scenes/relay/RelayTab.tscn",
	"res://scenes/relay/CallScreen.tscn",
	"res://scenes/barge_hub/VendorsLayout.tscn",
	"res://scenes/dive_run/DiveRun.tscn",
]

var _saved_run_count: int

func before_each() -> void:
	_saved_run_count = GameState.run_count
	GameState.run_count = 10
	GameState.selected_zone = "district7"

func after_each() -> void:
	GameState.run_count = _saved_run_count

func test_a_panel_is_full_strength_by_default() -> void:
	var panel := TerminalPanel.new()
	add_child_autofree(panel)
	assert_eq(panel.modulate, Color.WHITE)

func test_an_ambient_panel_recedes() -> void:
	var panel := TerminalPanel.new()
	panel.ambient = true
	add_child_autofree(panel)
	assert_almost_eq(panel.modulate.a, DeckStyle.AMBIENT_ALPHA, 0.001)
	assert_eq(panel.resting_modulate(), panel.modulate)

func test_flavour_panels_recede_and_real_panels_do_not() -> void:
	var seen_titles: Array[String] = []
	for path in SCREENS:
		var screen: Node = load(path).instantiate()
		add_child_autofree(screen)
		await get_tree().process_frame
		for panel in screen.find_children("*", "TerminalPanel", true, false):
			var title: String = panel.title
			seen_titles.append(title)
			if title in AMBIENT_TITLES:
				assert_true(panel.ambient, "%s should recede" % title)
			else:
				assert_false(panel.ambient, "%s should stay full strength" % title)
	for title in AMBIENT_TITLES:
		assert_has(seen_titles, title, "expected to find the %s panel" % title)

func test_biosign_pulse_settles_back_to_ambient() -> void:
	var biosign := BiosignPanel.new()
	add_child_autofree(biosign)
	biosign._pulse()
	await wait_seconds(BiosignPanel.TENSION_PULSE_SECONDS + 0.1)
	assert_almost_eq(biosign.modulate.a, DeckStyle.AMBIENT_ALPHA, 0.01)
	assert_almost_eq(biosign.modulate.r, 1.0, 0.01)
