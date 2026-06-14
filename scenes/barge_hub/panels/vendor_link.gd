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

	refresh("okeke")

# Pure per-vendor channel descriptor. Tested directly.
func link_info(vendor: String) -> Dictionary:
	if vendor == "okeke":
		return {
			"dealer": "okeke",
			"trust": "████░",
			"channel": "open / warm",
		}
	return {
		"dealer": "the vendor",
		"trust": "██░░░",
		"channel": "encrypted / cold",
	}

func refresh(vendor: String) -> void:
	var info := link_info(vendor)
	_body.text = "DEALER   %s\nTRUST    %s\nCHANNEL  %s" % [
		info.dealer, info.trust, info.channel]
