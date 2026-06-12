# scenes/dive_run/DiveFormat.gd
# Static text formatters for dive-run messaging. No scene-tree dependencies.
class_name DiveFormat

static func result_line(credits: int, tension_delta: int, corruption_gain: int) -> String:
	var parts: Array[String] = []
	if credits != 0:
		parts.append("%+dcr" % credits)
	if tension_delta != 0:
		parts.append("%+dT" % tension_delta)
	if corruption_gain != 0:
		parts.append("SIG %+d%%" % (-corruption_gain))
	if parts.is_empty():
		return ">>> no change"
	return ">>> " + "  ·  ".join(parts)
