# scenes/dive_run/override/OverrideArt.gd
# ASCII portraits for the encounter frame, keyed by the hostile's look. Plex Mono
# safe: no ▲▼◂ (not in the font). A hostile names its portrait in CatchData; anything
# unnamed falls back by catch type.
class_name OverrideArt

const DRONE := """
        .-=======-.
   ____/  [ o ]   \\____
  |====|  _____  |====|
  '----' /|||||\\ '----'
          \\_____/
         /  | |  \\
        '   ' '   '"""

const GHOST := """
          .-~~~-.
        .'  . .  '.
       /   (o o)   \\
      |     ' '     |
       \\   \\___/   /
        '.  ~~~  .'
     ~~~~ '~-.-~' ~~~~
        /  /   \\  \\"""

const ENGINE := """
   ┌──────────────────┐
   │ BID  ↑ 0.4471    │
   │ ASK  ↓ 0.4469    │
   │ ▓▓▒▒░░  ░░▒▒▓▓   │
   │ [ORDER BOOK: HOT]│
   └───┬──────────┬───┘
       │ ╳╳╳╳╳╳╳╳ │
      ═╧══════════╧═"""

const CORE := """
         ___________
      .-'  _______  '-.
     /   .'  ___  '.   \\
    |   /   ( @ )   \\   |
    |   \\    '-'    /   |
     \\   '._______.'   /
      '-.___________.-'
       /|  |  |  |  |\\"""

const SWARM := """
     .  ~  .    .  ~  .
   ( o o )  ~  ( o o )
    '~-~'   .   '~-~'
  ~   .  ( o o )  .   ~
      ~   '~-~'   ~
   ( o o )  .  ( o o )
    '~-~'   ~   '~-~'"""

const PAYLOAD := """
     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
     ▓ 0x4F 31 89 98 ▓
     ▓ ░░ PAYLOAD ░░ ▓
     ▓ 14 02 89 04 A8▓
     ▓▓▓▓▓▓▓▒▒▒▒▒░░░░
        ░░  ▒▒  ░░
          ░░  ░░"""

const BUILDING := """
    ┌────┬────┬────┐
    │ ▓▓ │ ░░ │ ▓▓ │
    ├────┼────┼────┤
    │ ░░ │(o) │ ░░ │
    ├────┼────┼────┤
    │ ▓▓ │ ░░ │ ▓▓ │
    └────┴─┬┬─┴────┘
    ═══════╧╧═══════"""

const BY_NAME := {
	"drone": DRONE, "ghost": GHOST, "engine": ENGINE, "core": CORE,
	"swarm": SWARM, "payload": PAYLOAD, "building": BUILDING,
}

static func portrait(art_name: String, catch_type: CatchData.CatchType) -> String:
	if BY_NAME.has(art_name):
		return BY_NAME[art_name]
	return GHOST if catch_type == CatchData.CatchType.ENTITY else DRONE
