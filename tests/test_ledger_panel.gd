# tests/test_ledger_panel.gd
extends GutTest

const PANEL := preload("res://scenes/barge_hub/panels/LedgerPanel.tscn")

func before_each() -> void:
	GameState.credits = 0
	GameState.debt = 80000
	GameState.pressure_level = 0
	GameState.runs_since_payment = 0

func _make_panel() -> Node:
	var p := PANEL.instantiate()
	add_child_autofree(p)
	return p

func test_fill_colour_bands() -> void:
	var p := _make_panel()
	assert_eq(p.pressure_fill_color(0), DeckStyle.GREEN)
	assert_eq(p.pressure_fill_color(1), DeckStyle.GREEN)
	assert_eq(p.pressure_fill_color(2), DeckStyle.AMBER)
	assert_eq(p.pressure_fill_color(3), DeckStyle.AMBER)
	assert_eq(p.pressure_fill_color(4), DeckStyle.RED)
	assert_eq(p.pressure_fill_color(5), DeckStyle.RED)

func test_segments_filled_to_pressure_level() -> void:
	GameState.pressure_level = 3
	var p := _make_panel()
	for i in 5:
		var seg: ColorRect = p._segments[i]
		if i < 3:
			assert_eq(seg.color, DeckStyle.AMBER, "segment %d should be filled" % i)
		else:
			assert_eq(seg.color, p.SEGMENT_EMPTY, "segment %d should be empty" % i)

func test_wallet_and_debt_text() -> void:
	GameState.credits = 1500
	GameState.debt = 80000
	var p := _make_panel()
	assert_eq(p._wallet_value.text, "1,500 cr")
	assert_eq(p._debt_value.text, "80,000 cr")

func test_repossession_countdown() -> void:
	GameState.runs_since_payment = 3
	var p := _make_panel()
	assert_eq(p._due_value.text, "in 2 runs")

func test_repossession_immediate_danger() -> void:
	GameState.runs_since_payment = 5
	var p := _make_panel()
	assert_eq(p._due_value.text, "IMMEDIATE DANGER")

func test_thousands_formatting() -> void:
	var p := _make_panel()
	assert_eq(p.format_thousands(0), "0")
	assert_eq(p.format_thousands(999), "999")
	assert_eq(p.format_thousands(80000), "80,000")
	assert_eq(p.format_thousands(1234567), "1,234,567")

func test_refreshes_on_credits_changed() -> void:
	var p := _make_panel()
	GameState.add_credits(2500)
	assert_eq(p._wallet_value.text, "2,500 cr")

func test_money_readouts_use_value_tier() -> void:
	var p := _make_panel()
	assert_eq(p._wallet_value.get_theme_font_size("font_size"), DeckStyle.SIZE_VALUE)
	assert_eq(p._debt_value.get_theme_font_size("font_size"), DeckStyle.SIZE_VALUE)
	assert_eq(p._due_value.get_theme_font_size("font_size"), DeckStyle.SIZE_VALUE)

# The pips count missed payments (game over at 5); the row below counts runs to
# the next payment. Labelled so the two fives don't read as the same clock.
func _caption_of(value_label: Label) -> String:
	return (value_label.get_parent().get_child(0) as Label).text

func test_pressure_row_is_labelled_missed_payments() -> void:
	var p := _make_panel()
	assert_eq(_caption_of(p._pressure_ratio), "MISSED PAYMENTS:")

func test_due_row_names_the_payment_amount() -> void:
	var p := _make_panel()
	assert_eq(_caption_of(p._due_value), "NEXT PAYMENT (10,000cr):")

func test_due_row_shows_a_smaller_final_payment() -> void:
	GameState.debt = 4000
	var p := _make_panel()
	assert_eq(_caption_of(p._due_value), "NEXT PAYMENT (4,000cr):")
