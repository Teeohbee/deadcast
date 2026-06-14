# scenes/barge_hub/panels/vendor_link.gd
extends TerminalPanel
class_name VendorLink

var _body: Label

func _ready() -> void:
	title = "vendor_link"
	custom_minimum_size = Vector2(0, 96)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_OFF
	DeckStyle.apply_label(_body, DeckStyle.DIM, DeckStyle.SIZE_AMBIENT)
	add_child(_body)

	refresh()

# Okeke channel descriptor. Tested directly.
func link_info() -> Dictionary:
	return {
		"dealer": "okeke",
		"trust": "████░",
		"channel": "open / warm",
	}

func refresh() -> void:
	var info := link_info()
	_body.text = "DEALER   %s\nTRUST    %s\nCHANNEL  %s" % [
		info.dealer, info.trust, info.channel]
