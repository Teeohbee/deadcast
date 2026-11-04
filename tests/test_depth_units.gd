# tests/test_depth_units.gd
# Depths are in feet everywhere, matching rod ratings (100-250ft).
extends GutTest

const HEADER := preload("res://scenes/ui/Zone1Header.tscn")

var _saved_rod: RodData

func before_each() -> void:
	_saved_rod = GameState.current_rod

func after_each() -> void:
	GameState.current_rod = _saved_rod

func _metre_depths(text: String) -> Array:
	var regex := RegEx.new()
	regex.compile("\\d[\\d,]*m\\b")
	return regex.search_all(text).map(func(m: RegExMatch) -> String: return m.get_string())

func test_header_shows_the_rods_line_rating_in_feet() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	var header := HEADER.instantiate()
	add_child_autofree(header)
	assert_eq(header.depth_label.text, "LINE RATING: 100ft")

func test_header_follows_a_rod_change_on_the_next_screen() -> void:
	GameState.current_rod = load("res://resources/rods/scrap_rod.tres")
	var header := HEADER.instantiate()
	add_child_autofree(header)
	GameState.current_rod = load("res://resources/rods/monocarbon_rig.tres")
	UIController.screen_changed.emit("deck")
	assert_eq(header.depth_label.text, "LINE RATING: 180ft")

func test_hydrophone_lines_have_no_metre_depths() -> void:
	for tier in HydrophonePanel.LINES:
		for line in HydrophonePanel.LINES[tier]:
			assert_eq(_metre_depths(line), [], line)

func test_market_news_has_no_metre_depths() -> void:
	var ticker_script: GDScript = load("res://scenes/barge_hub/panels/market_ticker.gd")
	for line in ticker_script.NEWS:
		assert_eq(_metre_depths(line), [], line)

func test_life_support_readout_has_no_metre_depths() -> void:
	var strip_script: GDScript = load("res://scenes/barge_hub/panels/life_support_strip.gd")
	assert_eq(_metre_depths(strip_script.READOUT), [])

func test_boot_text_has_no_metre_depths() -> void:
	var boot_source: String = FileAccess.get_file_as_string("res://scenes/boot/BootSequence.gd")
	assert_eq(_metre_depths(boot_source), [])
