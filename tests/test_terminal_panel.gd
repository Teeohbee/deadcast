# tests/test_terminal_panel.gd
extends GutTest

func _make_panel() -> TerminalPanel:
	var p := TerminalPanel.new()
	add_child_autofree(p)
	return p

func test_default_panel_has_dim_border() -> void:
	var p := _make_panel()
	var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(sb.border_color, DeckStyle.BORDER)

func test_active_panel_has_green_border() -> void:
	var p := _make_panel()
	p.active = true
	var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(sb.border_color, DeckStyle.GREEN)

func test_active_toggles_back() -> void:
	var p := _make_panel()
	p.active = true
	p.active = false
	var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(sb.border_color, DeckStyle.BORDER)

func test_title_is_stored() -> void:
	var p := _make_panel()
	p.title = "¹sonar_hydro-scan"
	assert_eq(p.title, "¹sonar_hydro-scan")
