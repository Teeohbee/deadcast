# tests/test_header_split.gd
# The header splits into a dim vessel block (left) and a framed operator block
# (right) so ship flavour never sits on the same line as the player's numbers.
extends GutTest

const HEADER := preload("res://scenes/ui/Zone1Header.tscn")

func _make() -> Node:
	var header := HEADER.instantiate()
	add_child_autofree(header)
	return header

func test_vessel_readouts_are_dimmed() -> void:
	var header := _make()
	for label in [header.os_label, header.host_label, header.clock_label, header.battery_label]:
		assert_almost_eq((label as Label).modulate.a, DeckStyle.AMBIENT_ALPHA, 0.001, label.name)

func test_operator_readouts_are_framed_and_full_strength() -> void:
	var header := _make()
	for label in [header.depth_label, header.status_label]:
		assert_eq((label as Label).modulate, Color.WHITE, label.name)
		assert_true((label as Label).has_theme_stylebox_override("normal"), "%s should be framed" % label.name)

func test_operator_block_sits_right_of_a_divider() -> void:
	var header := _make()
	var row: HBoxContainer = header.status_label.get_parent()
	var order: Array[String] = []
	for child in row.get_children():
		order.append(child.name)
	assert_eq(order, ["OSLabel", "HostLabel", "ClockLabel", "BatteryLabel", "Spacer",
		"Divider", "DepthLabel", "StatusLabel"] as Array[String])

func test_status_frame_turns_red_with_the_text() -> void:
	var header := _make()
	EventBus.corruption_changed.emit(60.0)
	var frame := header.status_label.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(Color(frame.border_color, 1.0), DeckStyle.RED)
	EventBus.corruption_changed.emit(0.0)
