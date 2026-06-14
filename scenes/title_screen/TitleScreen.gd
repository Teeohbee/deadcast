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
const _CRT_SCAN_ALPHA := 0.03

func _ready() -> void:
	self.theme = UIStyle.get_theme()
	var crt_mat := (_crt_overlay.material as ShaderMaterial).duplicate() as ShaderMaterial
	crt_mat.set_shader_parameter("scan_alpha", _CRT_SCAN_ALPHA if Settings.crt_enabled else 0.0)
	_crt_overlay.material = crt_mat

	var save_exists := FileAccess.file_exists(GameState.SAVE_PATH)
	continue_button.visible = save_exists
	confirm_panel.visible = false

	header_label.text = "deadcast_os %s" % GameState.OS_VERSION
	DeckStyle.apply_label(header_label, DeckStyle.DIM, 13)

	title_label.text = "┌ deadcast ─────────────────────────────┐\n└────────────────────────────────────────┘"
	DeckStyle.apply_label(title_label, DeckStyle.TEXT, DeckStyle.SIZE_VALUE)
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

	if save_exists:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()

	_blink_cursor()

func _blink_cursor() -> void:
	while is_instance_valid(self):
		footer_label.text = "root@meridian_deck:~# " + ("█" if _cursor_visible else " ")
		_cursor_visible = not _cursor_visible
		await get_tree().create_timer(0.5).timeout

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/AppShell.tscn")

func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(GameState.SAVE_PATH):
		continue_button.visible = false
		new_game_button.visible = false
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
	continue_button.visible = true
	new_game_button.visible = true
	continue_button.grab_focus()
