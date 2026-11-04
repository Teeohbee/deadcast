# tests/test_shell_separators.gd
extends GutTest

# The header and footer rules are box-drawing text. They must reach the right
# edge of the 1280px shell rather than stopping partway across.

func _rule_reaches_edge(rule: Label) -> bool:
	var font := rule.get_theme_font("font")
	var font_size := rule.get_theme_font_size("font_size")
	var text_width := font.get_string_size(rule.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return text_width >= rule.size.x and rule.size.x >= 1200.0

func _make_in_shell_width(scene_path: String) -> Node:
	var host := Control.new()
	host.theme = DeckStyle.get_theme()
	host.size = Vector2(1280, 100)
	add_child_autofree(host)
	var bar: Control = load(scene_path).instantiate()
	host.add_child(bar)
	bar.size = Vector2(1280, 60)
	return bar

func test_header_rules_reach_right_edge() -> void:
	var header := _make_in_shell_width("res://scenes/ui/Zone1Header.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(_rule_reaches_edge(header.top_sep), "top rule should span the shell")
	assert_true(_rule_reaches_edge(header.bot_sep), "bottom rule should span the shell")

func test_footer_rule_reaches_right_edge() -> void:
	var footer := _make_in_shell_width("res://scenes/ui/Zone3Footer.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(_rule_reaches_edge(footer.sep_label), "footer rule should span the shell")

# The header readouts and footer tabs sit in from the screen edges, in line
# with the panels, rather than touching them.
const SHELL_SIDE_INSET := 8.0

func test_header_readouts_are_inset_from_both_edges() -> void:
	var header := _make_in_shell_width("res://scenes/ui/Zone1Header.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var header_rect: Rect2 = header.get_global_rect()
	var first_readout_left: float = header.os_label.get_global_rect().position.x
	var last_readout_right: float = header.status_label.get_global_rect().end.x
	assert_gte(first_readout_left - header_rect.position.x, SHELL_SIDE_INSET, "OS label should not touch the left edge")
	assert_gte(header_rect.end.x - last_readout_right, SHELL_SIDE_INSET, "status label should not touch the right edge")

func test_footer_tabs_are_inset_from_the_left_edge() -> void:
	var footer := _make_in_shell_width("res://scenes/ui/Zone3Footer.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var footer_left: float = footer.get_global_rect().position.x
	var first_hint_left: float = footer._prev_hint.get_global_rect().position.x
	assert_gte(first_hint_left - footer_left, SHELL_SIDE_INSET, "footer's [Q] hint should not touch the left edge")
