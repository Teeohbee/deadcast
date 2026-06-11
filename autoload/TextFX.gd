# autoload/TextFX.gd
extends Node

const CORRUPT_CHARS := ["#", "%", "&", "?", "!", "@", "~", "0", "1", "§", "*", "^", "+", "="]

# Characters that must never be corrupted to preserve layout readability.
const PRESERVE := [" ", "\n", "[", "]", "(", ")", "|", "-", "·", "/",
	"┌", "└", "─", "│", ":", "×", "%", "·", "▸", "▹", "·"]

static func corrupt(text: String, intensity: float, rng: RandomNumberGenerator = null) -> String:
	if intensity <= 0.0:
		return text
	var _rng := rng if rng else RandomNumberGenerator.new()
	var chars := text.split("")
	for i in chars.size():
		if chars[i] in PRESERVE:
			continue
		if _rng.randf() < intensity:
			chars[i] = CORRUPT_CHARS[_rng.randi() % CORRUPT_CHARS.size()]
	return "".join(chars)
