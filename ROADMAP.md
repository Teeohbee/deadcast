# Deadcast Roadmap

Prioritised backlog from a full code/design review (2026-06-04). Three tiers: fix what's broken, add content, then layer on features. Work top-to-bottom within each tier.

---

## Tier 1: Bugs and Balance Fixes ✓

Small, independent commits. Fix these first - some affect balance enough to change how you think about features later.

### ~~1.1 Freezer spoil logic bug~~

**File:** `autoload/GameState.gd:79-81`

The `if freezer_runs == FREEZER_SPOIL_RUNS` check fires exactly once. After spoiling, `freezer_runs` stays at `FREEZER_SPOIL_RUNS`, so bio catches added after the first spoil accumulate forever without degrading.

**Fix:** Either use `>=` and reset `freezer_runs` after each spoil, or implement recurring degradation (e.g. halve every N runs). Recurring spoilage is more interesting - it makes the freezer a ticking clock, not a one-time tax.

### ~~1.2 Persist selected_zone~~

**File:** `autoload/GameState.gd` - `_save_to` / `_load_from`

`selected_zone` isn't saved. Resets to `"district7"` every session. Add it to the `gear` section of the config file.

### ~~1.3 Cap depth upgrades~~

**File:** `scenes/barge_hub/Workshop.gd:60-68`

No limit on depth upgrades. After 2-3 purchases, depth-gating (shallows/mid/deep) is permanently trivialised.

**Fix:** Cap at 2-3 upgrades, or use exponential pricing (2000, 4000, 8000). Exponential pricing is better - it makes each upgrade a real economic decision and naturally limits via the debt clock.

### ~~1.4 Rename roll_difficulty to fail_chance~~

**Files:** `resources/catch_option.gd`, all `.tres` files using `roll_difficulty`, `scenes/dive_run/DiveRun.gd:215`

`roll_difficulty` reads as "threshold to beat" but is actually a failure probability. A 0.7 value means 70% chance of failure. Anyone authoring new catches will get this backwards.

**Fix:** Rename to `fail_chance` everywhere. The logic stays the same, just the name changes.

### ~~1.5 Add decrypt box risk~~

**File:** `autoload/GameState.gd:69-75`, `scenes/barge_hub/DecryptBox.gd`

Currently a no-brainer: 1000cr in, 4000cr out, no risk. There's never a reason not to use it.

**Options (pick one or combine):**
- Marta seizes the box contents at pressure 3+ (ties into the pressure narrative)
- Variable multiplier (2x-6x, rolled on completion) adds uncertainty
- Chance of partial data corruption (get back 0.5x-4x instead of guaranteed 4x)

Marta seizure is the most narratively interesting - it means the decrypt box becomes unsafe exactly when you need it most.

### ~~1.6 Remove dead code~~

- `debt_collector_triggered` on GameState: persisted but never read. Either remove it or wire it into something (see Tier 3 pressure mechanics).
- `zone_weights` on CatchData: unused since zone filtering became structural via ZoneData.catches. Remove the field and the comment in CatchPool, or implement shared cross-zone pools (see 2.1).
- `OKEKE_LURE_PATHS` in VendorsLayout.gd is identical to `LURE_PATHS`. Either differentiate Okeke's stock or use one constant.
- `stamina` field on CatchData: marked legacy, unused by TerminalOverload. Remove if no plans to use it.

### ~~1.7 Fix corruption reset on line cut~~

**File:** `scenes/dive_run/DiveRun.gd:172` calls `line_system.reset()` which zeros both tension and corruption.

Cutting a line shouldn't undo signal disturbance you've already caused. Either reset tension only, or reduce corruption by a fraction (e.g. halve it). Keeps corruption as a run-long accumulator with real consequences.

### ~~1.8 Show lure stock during dives~~

**File:** `scenes/dive_run/CatchEvent.gd:33`

The HUD strip shows slot/zone/tension but not lure uses remaining. `consume_lure_use()` fires silently. Add remaining uses to the HUD label so the player can make informed decisions.

### ~~1.9 GameOver scene navigation inconsistency~~

**File:** `scenes/barge_hub/GameOver.gd:18`

Uses `change_scene_to_file` instead of UIController, breaking the shell pattern. Not a gameplay issue but worth aligning for consistency.

---

## Tier 2: Content

The single highest-impact area. The authoring pipeline (.tres resources, ZoneData references) is already built for scale. Rich content on simple mechanics feels complete; features on thin content feel thin.

### ~~2.1 More catches per zone~~

**Current state:** 5 catches per zone, runs are 3-8 slots. Repetition within 3-4 runs.

**Target:** 10-15 per zone minimum. Prioritise variety across layers (shallows/mid/deep) and behaviour types. Each zone should have its own flavour:

- **District 7:** Civilian ghosts, personal data, residential AI echoes. Emotionally heavy, lower credit yields. More ENTITY and DATA catches.
- **Exchange:** Black market goods, rival fishers, contraband. Mercenary tone, higher risk/reward. More NEGOTIATING catches and rival encounters.
- **Axiom:** Corporate secrets, security drones, bioweapons. Hostile and high-value. More AGGRESSIVE and RESISTANT catches, deeper layer content.

When creating new catches, consider:
- Each catch needs 2-3 options with meaningfully different risk/reward profiles
- ENTITY catches should have a non-monetary "listen" or "interact" option - these are the most memorable content in the game
- At least 2-3 catches per layer per zone to avoid repetition within a depth tier

### ~~2.2 Ghost memory (returning encounters)~~

**The strongest content in the game is SOLACE-7 and MARIANA.** Build on this.

If the player chose "Listen" on a previous encounter, subsequent encounters with the same entity should have different dialogue and options. Track which entities the player has engaged with in GameState (a set of entity IDs).

**Implementation sketch:**
- Add `entity_id` field to CatchData (or derive from resource path)
- Add `encountered_entities: Dictionary` to GameState (entity_id -> interaction count or choice history)
- In CatchEvent.populate, check history and swap options/flavour text for returning encounters
- SOLACE-7 second encounter: it remembers you. Different dialogue. Maybe it has information about Marta.
- MARIANA second encounter: she recognises you but doesn't understand why you keep coming back.

This is mostly writing work with a small system change. High emotional impact.

### 2.3 Journal entry expansion

**Current state:** 4 hardcoded journal entries at runs 1, 5, 8, 12.

Add more entries and make some responsive to player choices:
- Entry after first entity listen (references the specific entity)
- Entry after first line snap
- Entry after first Marta pressure escalation
- Entry when debt drops below 50% for the first time

The journal is where the player character's voice lives. More entries = more personality.

---

## Tier 3: Systems and Features

Layer these on top of a game with solid content. Pick based on what excites you - momentum matters more than optimal ordering at this stage.

### 3.1 Corruption effects (visual/mechanical)

**Currently corruption only affects entity encounter weighting.** The terminal framing is begging for more:

**Visual corruption (medium effort):**
- At 30+: occasional garbled characters in flavour text
- At 50+: HUD strip shows unreliable tension readings (display jitters by +/- 5)
- At 70+: option labels occasionally scramble for a frame before resolving
- At 90+: fake "[SIGNAL LOST]" flash that resolves after 0.5s

**Mechanical corruption (lower effort):**
- At 50+: one extra backlash per turn in Terminal Overload
- At 70+: one command in Terminal Overload replaced with `[GARBLED]` (unknown effect)
- At 90+: chance of a catch being replaced with a corruption-specific hostile encounter

Start with visual effects - they reinforce the diegetic framing without changing balance.

### 3.2 Marta's jobs

Optional side objectives offered at the Marta terminal before a dive. Success reduces debt directly (not via credits).

**Examples:**
- "Retrieve a DATA catch from Axiom sub-basement" (zone + type constraint)
- "Complete a run without cutting line" (behaviour constraint)
- "Survive at 80%+ corruption for 3 consecutive catches" (push-your-luck)
- "Don't engage any entities this run" (moral choice - skip the interesting content for debt relief)

**Implementation:** Add `active_job: Dictionary` to GameState (or null). Marta terminal shows available job. DiveRun checks job conditions on run complete. Jobs get harder/more lucrative as the story progresses.

Creates meaningful pre-dive decisions and gives Marta's terminal a gameplay purpose beyond reading dialogue.

### 3.3 Zone unlocking

**Currently all 3 zones available from the start.** Gate them behind story progression:

- **District 7:** Available from run 1 (starter zone, lower risk)
- **Exchange:** Unlocked at run 3 (Marta gives coordinates as part of the "I know about the Exchange shard" beat)
- **Axiom:** Unlocked at run 6 or after first depth upgrade (corporate sub-basement requires deeper reach)

Paces content discovery and makes zone access feel earned. Modify ZoneSelector to check unlock conditions and grey out locked zones with a flavour text reason.

### 3.4 Okeke relationship

Track trust with Okeke independently from Marta's pressure. Currently Okeke is just a discount vendor who shuts down at pressure 3.

**Expansion:**
- Okeke has his own dialogue beats (like Marta's story beats)
- At high trust, Okeke offers intel about Marta's operations
- Player can choose to relay Okeke's info to Marta (debt reduction) or keep it secret (Okeke trust)
- Okeke could offer a unique lure or rod not available from the vendor

Makes the hub feel like a place with relationships, not just shops.

### 3.5 Inter-catch events

Random events between catch slots during a dive:

- **Environmental:** Pressure surge (+tension), signal clearing (-corruption), debris field (skip next slot)
- **Discovery:** Found cache (small credit bonus), abandoned lure (free lure use), signal echo (preview next 2 catches)
- **Rival:** Another fisher's line detected (trade, cut, or ignore - like the Exchange catch but as an event)

Breaks up the slot-by-slot rhythm. Implement as a chance roll between `_advance_slot` and `_show_next_catch`, with a simple event scene similar to CatchEvent but with 1-2 options.

### 3.6 Run length choice

Before each dive, let the player choose:
- **Shallow sweep:** 3 slots, shallows only. Safe, low yield.
- **Standard dive:** 5-6 slots, shallows + mid. Balanced.
- **Deep run:** 7-8 slots, all layers. High risk, high reward.

Ties into the depth upgrade progression and gives the debt-pressured player a meaningful risk/reward decision. Modify CatchPool.generate_column to accept a run-type parameter.

### 3.7 Audio

Even minimal audio transforms the feel:

- **Ambient:** Low electrical hum, water/pressure sounds. Loop with subtle variation.
- **UI:** Click/keypress on button selection. Different tone for navigation vs confirmation.
- **Events:** Line snap sound (sharp, mechanical). Catch reveal (data chirp). Terminal Overload backlash (warning tone). Entity encounter (distinct, unsettling tone).
- **Music:** Optional. A single droning ambient track per zone would be enough.

Godot's AudioStreamPlayer makes this straightforward. Source sounds from freesound.org or generate with sfxr/jsfxr.

### 3.8 Screen transitions

Content swaps instantly in zone2. A terminal-appropriate transition:

- Line-by-line text render (typewriter effect on the first frame)
- Brief screen flicker/static (0.1-0.2s ColorRect flash)
- "Redraw" effect (content appears top-to-bottom over 0.3s)

Implement in UIController.navigate_to - add a brief tween/animation between queue_free and add_child.

### 3.9 Rod/lure crafting

MECH catches yield components instead of (or alongside) credits. Components assembled in Workshop.

- Salvage Drone parts -> basic rod repair materials (reduce repair cost)
- Axiom Drone components -> Shock Lure charges
- Rare deep-layer MECH catches -> unique rod/lure recipes

Gives MECH catches non-credit value and adds a reason to specifically seek them out. Needs a new `components` inventory on GameState and a crafting UI in Workshop.

### 3.10 New game+

After clearing the 80,000cr debt:
- Marta offers a new deal. 150,000cr. New conditions.
- Transponder stays on. Axiom is aware of you now.
- New zone tier (deeper Axiom levels, or a new location entirely)
- Existing zones get harder variants of catches
- Pressure escalates faster

Gives the game longevity beyond a single debt arc. Track `ng_plus_level` on GameState.

### 3.11 Pressure mechanics expansion

Currently pressure 5 = instant game over on next deck visit. Expand the ramp:

- **Pressure 4:** Drones appear in shallows across all zones (new AGGRESSIVE catch)
- **Pressure 5:** 3-run countdown before forced surrender (not instant). Player sees "marta's people arrive in 3 runs" - creates a desperate final push
- Wire up `debt_collector_triggered` (currently dead) to trigger a one-time event where Marta takes a percentage of your credits

### 3.12 Run log

Auto-generate a text log after each dive:
```
RUN 7 - DISTRICT 7 RUINS
slot 1: corrupted finance archive - reel in (+800cr, +15T)
slot 2: tenant echo - unit 2214 - listen (+0cr, +0T)
slot 3: salvage drone - strip for parts - RESISTED (+0cr, +20T)
slot 4: [CONNECTION TERMINATED]
yield: 800cr (forfeited - line snap)
```

Store in GameState, viewable from the bunk alongside journal entries. Gives the player a sense of their own history and helps them learn which catches/options are worth the risk.

---

## Implementation Notes

- **Branching:** Feature branches off main. One branch per tier-1 fix is fine since they're small. Tier 2/3 items might warrant their own branches.
- **Testing:** Tier 1 fixes should have test coverage where applicable (freezer spoil, zone persistence, depth cap). Tier 2/3 items - test the system changes, not the content.
- **Content authoring:** New catches are just `.tres` files. Consider a spreadsheet or table to plan them before creating resources - catch name, zone, layer, type, behaviour, options with values. Avoids ad-hoc balance.
- **Order flexibility:** Within each tier, items are roughly priority-ordered but you can shuffle based on what you're in the mood to build. The main constraint is: finish Tier 1 before Tier 2, finish most of Tier 2 before Tier 3.
