# scenes/barge_hub/ZoneSelector.gd
extends VBoxContainer

@onready var district7_btn: Button = $District7Button
@onready var exchange_btn: Button = $ExchangeButton
@onready var axiom_btn: Button = $AxiomButton

func _ready() -> void:
	district7_btn.focus_mode = Control.FOCUS_ALL
	exchange_btn.focus_mode = Control.FOCUS_ALL
	axiom_btn.focus_mode = Control.FOCUS_ALL

	district7_btn.pressed.connect(func() -> void: GameState.select_zone("district7"))
	exchange_btn.pressed.connect(func() -> void: GameState.select_zone("exchange"))
	axiom_btn.pressed.connect(func() -> void: GameState.select_zone("axiom"))

	EventBus.zone_changed.connect(_on_zone_changed)
	_on_zone_changed(GameState.selected_zone)

func _on_zone_changed(zone_id: String) -> void:
	district7_btn.text = ("▶ " if zone_id == "district7" else "") + "District 7 Ruins"
	exchange_btn.text = ("▶ " if zone_id == "exchange" else "") + "The Voss Exchange"
	axiom_btn.text = ("▶ " if zone_id == "axiom" else "") + "Axiom Tower Sub-Basement"
