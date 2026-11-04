# deadcast

A terminal-style deep-sea data fishing game.

You operate a signal rig from a decaying barge — the Meridian Deck — casting lines into submerged network infrastructure to extract data, encounter entities, and pay off a mounting debt to Marta Voss before she sends someone to collect.

## premise

The Sump is a drowned city. Its servers still run. Someone has to fish them.

DEADCAST_OS presents itself as a diegetic operating system running on failing barge hardware. Everything you interact with — the vendors, the debt clock, the dive terminal — is mediated through this interface.

## mechanics

- **Dive runs** — cast into a zone and work the column layer by layer; at each depth checkpoint, bank your haul or descend for richer, riskier draws
- **Tension** — your line has a cap; exceed it and it snaps, forfeiting the run's haul. Cutting a connection vents half your tension but costs signal
- **Corruption (SIG)** — builds as you extract; weights what deeper layers send up, scales hostile backlash, and garbles your terminal
- **Lures** — active tools fired mid-dive: scan the layer ahead, slip a contact, bait entities at a checkpoint, or shock mechanical systems
- **Debt clock** — 10,000cr due every five runs; miss payments and pressure escalates
- **Vendors** — Okeke sells lures at a discount; the vendor sells rods and restocks; both have opinions about you

## built with

[Godot 4.7](https://godotengine.org/)

## running

Open the project in Godot 4.7 and run from the editor. No external dependencies.

## credits

Sound effects: [Kenney](https://kenney.nl) - Interface Sounds, Sci-Fi Sounds, Impact Sounds and RPG Audio (CC0). Press M (or Back on a pad) to mute.

Title music: ["Pyro"](https://opengameart.org/content/pyro) from OpenGameArt (CC0). Trimmed and loudness-normalised for the title loop.
