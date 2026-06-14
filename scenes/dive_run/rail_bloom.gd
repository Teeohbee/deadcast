# scenes/dive_run/rail_bloom.gd
# Drives the "the interface is infected" effect: as corruption climbs, the rail
# panels' borders bleed green -> amber -> red. Reskins EventBus.corruption_changed.
# Holds refs to the panels it tints; recolours each panel's "panel" stylebox border
# in place. border_for() is a pure function so the colour ramp is unit-tested.
class_name RailBloom
extends Node

# Untyped Array so a mixed literal of TerminalPanel subclasses passes cleanly.
var _panels: Array = []

# Pure: corruption 0..100 -> border colour. 0 == base BORDER (no rot), ramps
# green->amber (first half) then amber->red (second half), blended in by severity.
static func border_for(corruption: float) -> Color:
	var t := clampf(corruption / 100.0, 0.0, 1.0)
	var target := DeckStyle.GREEN.lerp(DeckStyle.AMBER, clampf(t * 2.0, 0.0, 1.0))
	if t > 0.5:
		target = DeckStyle.AMBER.lerp(DeckStyle.RED, (t - 0.5) * 2.0)
	return DeckStyle.BORDER.lerp(target, t)

func track(panels: Array) -> void:
	_panels = panels
	EventBus.corruption_changed.connect(_on_corruption_changed)
	_on_corruption_changed(0.0)

func _on_corruption_changed(value: float) -> void:
	var border := border_for(value)
	for panel in _panels:
		if not is_instance_valid(panel):
			continue
		var sb: StyleBox = panel.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			var panel_sb := sb as StyleBoxFlat
			if not panel.has_theme_stylebox_override("panel"):
				panel_sb = panel_sb.duplicate() as StyleBoxFlat
				panel.add_theme_stylebox_override("panel", panel_sb)
			panel_sb.border_color = border
