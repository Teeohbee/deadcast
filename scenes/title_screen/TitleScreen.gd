# scenes/title_screen/TitleScreen.gd
extends Control

@onready var continue_button: Button = $OuterMargin/MainPanel/ContentAnchor/ActionBlock/ContinueButton
@onready var new_game_button: Button = $OuterMargin/MainPanel/ContentAnchor/ActionBlock/NewGameButton
@onready var confirm_panel: VBoxContainer = $OuterMargin/MainPanel/ContentAnchor/ActionBlock/ConfirmPanel
@onready var title_label: Label = $OuterMargin/MainPanel/ContentAnchor/TitleLabel
@onready var confirm_label: Label = $OuterMargin/MainPanel/ContentAnchor/ActionBlock/ConfirmPanel/ConfirmLabel
@onready var header_label: Label = $OuterMargin/MainPanel/ContentAnchor/HeaderLabel
@onready var footer_label: Label = $OuterMargin/MainPanel/ContentAnchor/FooterLabel
@onready var yes_button: Button = $OuterMargin/MainPanel/ContentAnchor/ActionBlock/ConfirmPanel/ConfirmButtons/YesButton
@onready var no_button: Button = $OuterMargin/MainPanel/ContentAnchor/ActionBlock/ConfirmPanel/ConfirmButtons/NoButton
@onready var _crt_overlay: ColorRect = $CRTOverlay

var _cursor_visible := true
var sound_button: Button
var crt_button: Button
var _crt_material: ShaderMaterial

const WORDMARK := """██████╗ ███████╗ █████╗ ██████╗  ██████╗ █████╗ ███████╗████████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝╚══██╔══╝
██║  ██║█████╗  ███████║██║  ██║██║     ███████║███████╗   ██║
██║  ██║██╔══╝  ██╔══██║██║  ██║██║     ██╔══██║╚════██║   ██║
██████╔╝███████╗██║  ██║██████╔╝╚██████╗██║  ██║███████║   ██║
╚═════╝ ╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝"""
const TAGLINE := "signal trawling in the drowned city"
const WORDMARK_FONT_SIZE := 15
const ACTION_COLUMN_WIDTH := 420

func _ready() -> void:
	self.theme = DeckStyle.get_theme()
	var crt_mat := (_crt_overlay.material as ShaderMaterial).duplicate() as ShaderMaterial
	if not Settings.crt_enabled:
		crt_mat.set_shader_parameter("scan_alpha", 0.0)
	_crt_overlay.material = crt_mat
	_crt_material = crt_mat

	var save_exists := FileAccess.file_exists(GameState.save_path)
	continue_button.visible = save_exists
	confirm_panel.visible = false

	header_label.text = "deadcast_os %s" % GameState.OS_VERSION
	DeckStyle.apply_label(header_label, DeckStyle.DIM, 13)

	title_label.text = WORDMARK
	# Left-align the lines but centre the label: centring each line separately
	# would shear the block letters, since the lines differ in length.
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	DeckStyle.apply_label(title_label, DeckStyle.GREEN, WORDMARK_FONT_SIZE)
	_arrange_centred_layout()
	_add_settings_toggles()
	DeckStyle.apply_label(confirm_label, DeckStyle.AMBER, DeckStyle.SIZE_BODY)
	DeckStyle.apply_label(footer_label, DeckStyle.DIM, 13)

	for btn in [continue_button, new_game_button]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		DeckStyle.apply_action_button(btn)
	for btn in [yes_button, no_button]:
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	DeckStyle.apply_action_button(yes_button, DeckStyle.RED)
	DeckStyle.apply_action_button(no_button, DeckStyle.AMBER)

	continue_button.text = "[ CONTINUE ]"
	new_game_button.text = "[ NEW GAME ]"
	yes_button.text = "[ CONFIRM ERASE ]"
	no_button.text = "[ CANCEL ]"
	confirm_label.text = "this will erase your progress. are you sure?"

	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	yes_button.pressed.connect(_on_confirm_yes)
	no_button.pressed.connect(_on_confirm_no)

	DeckNav.chain_vertical(_visible_actions())

	if save_exists:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()

	_blink_cursor()

# Header pinned top, footer pinned bottom; wordmark, tagline, sonar and a
# narrow column of actions float in the middle.
func _arrange_centred_layout() -> void:
	var content := title_label.get_parent() as VBoxContainer
	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(top_spacer)
	content.move_child(top_spacer, title_label.get_index())

	var tagline := Label.new()
	tagline.text = TAGLINE
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DeckStyle.apply_label(tagline, DeckStyle.DIM, DeckStyle.SIZE_BODY)
	content.add_child(tagline)
	content.move_child(tagline, title_label.get_index() + 1)

	var sonar := SonarWave.new()
	sonar.custom_minimum_size = Vector2(0, 90)
	sonar.amplitude = 14.0
	sonar.frequency = 0.015
	sonar.speed = 1.2
	sonar.line_color = Color(DeckStyle.GREEN, 0.7)
	content.add_child(sonar)
	content.move_child(sonar, tagline.get_index() + 1)

	var action_block := continue_button.get_parent() as Control
	action_block.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_block.custom_minimum_size.x = ACTION_COLUMN_WIDTH

func _add_settings_toggles() -> void:
	var action_block := continue_button.get_parent()
	sound_button = _make_toggle_button()
	sound_button.pressed.connect(_on_sound_pressed)
	action_block.add_child(sound_button)
	action_block.move_child(sound_button, new_game_button.get_index() + 1)
	crt_button = _make_toggle_button()
	crt_button.pressed.connect(_on_crt_pressed)
	action_block.add_child(crt_button)
	action_block.move_child(crt_button, sound_button.get_index() + 1)
	_refresh_toggle_labels()

func _make_toggle_button() -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	DeckStyle.apply_action_button(button, DeckStyle.DIM)
	return button

func _refresh_toggle_labels() -> void:
	sound_button.text = "[ SOUND: %s ]" % ("OFF" if Settings.audio_muted else "ON")
	crt_button.text = "[ CRT: %s ]" % ("ON" if Settings.crt_enabled else "OFF")

func _on_sound_pressed() -> void:
	Audio.toggle_mute()
	_refresh_toggle_labels()

func _on_crt_pressed() -> void:
	Settings.set_crt_enabled(not Settings.crt_enabled)
	if Settings.crt_enabled:
		_crt_material.set_shader_parameter("scan_alpha", null)  # back to the shader default
	else:
		_crt_material.set_shader_parameter("scan_alpha", 0.0)
	_refresh_toggle_labels()

func _visible_actions() -> Array[Control]:
	var actions: Array[Control] = []
	for button in [continue_button, new_game_button, sound_button, crt_button]:
		if button.visible:
			actions.append(button)
	return actions

func _set_main_actions_visible(should_show: bool, save_exists: bool) -> void:
	continue_button.visible = should_show and save_exists
	new_game_button.visible = should_show
	sound_button.visible = should_show
	crt_button.visible = should_show

func _blink_cursor() -> void:
	while is_instance_valid(self):
		footer_label.text = "root@meridian_deck:~# " + ("█" if _cursor_visible else " ")
		_cursor_visible = not _cursor_visible
		await get_tree().create_timer(0.5).timeout

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/AppShell.tscn")

func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(GameState.save_path):
		_set_main_actions_visible(false, true)
		confirm_panel.visible = true
		yes_button.grab_focus()
	else:
		GameState.new_game()
		get_tree().change_scene_to_file("res://scenes/boot/BootSequence.tscn")

func _on_confirm_yes() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/boot/BootSequence.tscn")

func _on_confirm_no() -> void:
	confirm_panel.visible = false
	_set_main_actions_visible(true, true)
	continue_button.grab_focus()
