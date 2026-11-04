# scenes/ui/Zone1Header.gd
extends Control

@onready var os_label: Label = $VBoxContainer/ReadoutMargin/HBoxContainer/OSLabel
@onready var host_label: Label = $VBoxContainer/ReadoutMargin/HBoxContainer/HostLabel
@onready var depth_label: Label = $VBoxContainer/ReadoutMargin/HBoxContainer/DepthLabel
@onready var clock_label: Label = $VBoxContainer/ReadoutMargin/HBoxContainer/ClockLabel
@onready var battery_label: Label = $VBoxContainer/ReadoutMargin/HBoxContainer/BatteryLabel
@onready var status_label: Label = $VBoxContainer/ReadoutMargin/HBoxContainer/StatusLabel
@onready var top_sep: Label = $VBoxContainer/TopSep
@onready var bot_sep: Label = $VBoxContainer/BottomSep

var _credits: int = 0
var _corruption: float = 0.0

func _ready() -> void:
	DeckStyle.apply_label(top_sep, DeckStyle.BORDER)
	DeckStyle.apply_label(bot_sep, DeckStyle.BORDER)
	DeckStyle.apply_label(os_label, DeckStyle.GREEN)
	DeckStyle.apply_label(host_label, DeckStyle.DIM)
	DeckStyle.apply_label(depth_label, DeckStyle.SKY)
	DeckStyle.apply_label(clock_label, DeckStyle.DIM)
	DeckStyle.apply_label(battery_label, DeckStyle.GREEN)
	DeckStyle.apply_label(status_label, DeckStyle.TEXT)

	os_label.text = "// DEADCAST_OS %s //" % GameState.OS_VERSION

	var clock_timer := Timer.new()
	clock_timer.wait_time = 1.0
	clock_timer.timeout.connect(_on_clock_tick)
	add_child(clock_timer)
	clock_timer.start()
	_on_clock_tick()

	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.corruption_changed.connect(_on_corruption_changed)
	UIController.screen_changed.connect(_on_screen_changed)

	_credits = GameState.credits
	_refresh_status()
	_refresh_depth()
	host_label.text = "HOST: THE_MERIDIAN_DECK"

# The rod's depth rating, in feet like every other depth in the game. Refreshed
# on each screen change so a rod bought or upgraded shows on the next screen.
func _refresh_depth() -> void:
	var rated_feet: int = GameState.current_rod.max_depth if GameState.current_rod else 100
	depth_label.text = "LINE RATING: %dft" % rated_feet

func _on_clock_tick() -> void:
	clock_label.text = "SYS_TIME: %s" % Time.get_time_string_from_system()

func _on_credits_changed(value: int) -> void:
	_credits = value
	_refresh_status()

func _on_corruption_changed(value: float) -> void:
	_corruption = value
	_refresh_status()

func _on_screen_changed(id: String) -> void:
	_refresh_depth()
	if id == "dive":
		host_label.text = "HOST: %s" % _zone_host_name(GameState.selected_zone)
	else:
		host_label.text = "HOST: THE_MERIDIAN_DECK"

func _refresh_status() -> void:
	var sig_pct := int(100.0 - _corruption)
	status_label.text = "CR: %d  SIG: %d%%" % [_credits, sig_pct]
	var color := DeckStyle.RED if _corruption >= 50.0 else DeckStyle.TEXT
	DeckStyle.apply_label(status_label, color)

func _zone_host_name(zone_id: String) -> String:
	match zone_id:
		"district7": return "DISTRICT_7_RUINS"
		"exchange":  return "THE_VOSS_EXCHANGE"
		"axiom":     return "AXIOM_TOWER_SUB-BASEMENT"
	return "THE_MERIDIAN_DECK"
