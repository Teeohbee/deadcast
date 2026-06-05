# Ghost Memory — Returning Entity Encounters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a player meaningfully engages with a named entity catch (SOLACE-7, Mariana, Tenant Echo), subsequent encounters with that entity show a different catch with different options and narrative text.

**Architecture:** Three new fields on resource scripts (entity_id, returning_variants, sets_entity_flag) plus an encounter counter in GameState. CatchPool.generate_column substitutes the returning variant after drawing; DiveRun._on_option_selected records the flag when a marked option is chosen. All returning content lives in new .tres files — no changes to CatchEvent.

**Tech Stack:** Godot 4, GDScript, ConfigFile (save/load), GUT (tests). Run tests with: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests`

**Spec:** `docs/superpowers/specs/2026-06-05-ghost-memory-design.md`

---

## File Map

| File | Action |
|---|---|
| `resources/catch_data.gd` | Modify — add entity_id, returning_variants |
| `resources/catch_option.gd` | Modify — add sets_entity_flag |
| `autoload/GameState.gd` | Modify — add encountered_entities, helper, save/load, new_game |
| `autoload/CatchPool.gd` | Modify — add _apply_entity_substitution, call in generate_column |
| `scenes/dive_run/DiveRun.gd` | Modify — record flag in _on_option_selected |
| `resources/catches/axiom/solace7.tres` | Modify — add entity_id, returning_variants |
| `resources/catches/district7/civilian_ghost_mariana.tres` | Modify — add entity_id, returning_variants |
| `resources/catches/district7/tenant_echo.tres` | Modify — add entity_id, returning_variants |
| `resources/catches/axiom/opt_solace_listen.tres` | Modify — add sets_entity_flag |
| `resources/catches/district7/opt_mariana_escort.tres` | Modify — add sets_entity_flag |
| `resources/catches/district7/opt_tenant_echo_listen.tres` | Modify — add sets_entity_flag |
| `resources/catches/axiom/solace7_returning.tres` | Create |
| `resources/catches/axiom/opt_solace_return_listen.tres` | Create |
| `resources/catches/axiom/opt_solace_return_harvest.tres` | Create |
| `resources/catches/axiom/opt_solace_return_release.tres` | Create |
| `resources/catches/district7/civilian_ghost_mariana_returning.tres` | Create |
| `resources/catches/district7/opt_mariana_return_stay.tres` | Create |
| `resources/catches/district7/opt_mariana_return_harvest.tres` | Create |
| `resources/catches/district7/opt_mariana_return_leave.tres` | Create |
| `resources/catches/district7/tenant_echo_returning.tres` | Create |
| `resources/catches/district7/opt_tenantreturn_listen.tres` | Create |
| `resources/catches/district7/opt_tenantreturn_extract.tres` | Create |
| `resources/catches/district7/opt_tenantreturn_release.tres` | Create |
| `tests/test_ghost_memory.gd` | Create |

---

## Task 1: Data model — catch_data.gd and catch_option.gd

**Files:**
- Modify: `resources/catch_data.gd`
- Modify: `resources/catch_option.gd`

No unit tests for field declarations — correctness is exercised by later tasks.

- [ ] **Step 1: Add entity_id and returning_variants to catch_data.gd**

Add two lines after the existing `@export var anchor_strength` line:

```gdscript
@export var entity_id: String = ""
@export var returning_variants: Array[CatchData] = []
```

Full file after edit:

```gdscript
# resources/catch_data.gd
class_name CatchData
extends Resource

enum CatchType { DATA, BIO, MECH, ENTITY }
enum BehaviorType { PASSIVE, RESISTANT, AGGRESSIVE, NEGOTIATING }
enum Layer { SHALLOWS, MID, DEEP }

@export var catch_name: String = ""
@export var catch_type: CatchType = CatchType.DATA
@export var behavior: BehaviorType = BehaviorType.PASSIVE
@export var corruption_gain: int = 0
@export var options: Array[CatchOption] = []
@export var flavor_text: String = ""
@export var layer: Layer = Layer.SHALLOWS
@export var anchor_strength: int = 3
@export var entity_id: String = ""
@export var returning_variants: Array[CatchData] = []
```

- [ ] **Step 2: Add sets_entity_flag to catch_option.gd**

Add one line at the end of catch_option.gd, after the existing fail fields:

```gdscript
@export var sets_entity_flag: bool = false
```

Full file after edit:

```gdscript
# resources/catch_option.gd
class_name CatchOption
extends Resource

@export var label: String = ""
@export var tension_delta: int = 0
@export var credit_value: int = 0
@export var cuts_line: bool = false
@export var flavor_text: String = ""
@export var narrative_text: String = ""

@export var resist_chance: float = 0.0
@export var resist_tension_penalty: int = 0

@export var fail_chance: float = 0.0
@export var fail_tension_delta: int = 0
@export var fail_credit_value: int = 0

@export var sets_entity_flag: bool = false
```

- [ ] **Step 3: Run existing tests — verify nothing broke**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: all tests pass (adding @export fields to a Resource doesn't break existing .tres files — unrecognised fields are silently ignored on load).

- [ ] **Step 4: Commit**

```
git add resources/catch_data.gd resources/catch_option.gd
git commit -m "feat: add entity_id/returning_variants to CatchData; sets_entity_flag to CatchOption"
```

---

## Task 2: GameState — encountered_entities tracking

**Files:**
- Modify: `autoload/GameState.gd`
- Create: `tests/test_ghost_memory.gd`

- [ ] **Step 1: Write failing tests**

Create `tests/test_ghost_memory.gd`:

```gdscript
# tests/test_ghost_memory.gd
extends GutTest

func before_each() -> void:
	GameState.encountered_entities = {}

func after_each() -> void:
	DirAccess.remove_absolute("user://save_ghost_test.cfg")

func test_set_entity_encountered_increments_from_zero() -> void:
	GameState.set_entity_encountered("solace7")
	assert_eq(GameState.encountered_entities.get("solace7", 0), 1)

func test_set_entity_encountered_increments_existing() -> void:
	GameState.encountered_entities = {"solace7": 1}
	GameState.set_entity_encountered("solace7")
	assert_eq(GameState.encountered_entities.get("solace7", 0), 2)

func test_set_entity_encountered_tracks_multiple_entities_independently() -> void:
	GameState.set_entity_encountered("solace7")
	GameState.set_entity_encountered("mariana")
	assert_eq(GameState.encountered_entities.get("solace7", 0), 1)
	assert_eq(GameState.encountered_entities.get("mariana", 0), 1)

func test_encountered_entities_saves_and_loads() -> void:
	GameState.encountered_entities = {"solace7": 2, "mariana": 1}
	GameState._save_to("user://save_ghost_test.cfg")
	GameState.encountered_entities = {}
	GameState._load_from("user://save_ghost_test.cfg")
	assert_eq(GameState.encountered_entities.get("solace7", 0), 2)
	assert_eq(GameState.encountered_entities.get("mariana", 0), 1)

func test_new_game_clears_encountered_entities() -> void:
	GameState.encountered_entities = {"solace7": 3}
	GameState.new_game()
	assert_eq(GameState.encountered_entities.size(), 0)

func test_load_old_save_without_encountered_entities_defaults_to_empty() -> void:
	GameState.encountered_entities = {}
	GameState._load_from("user://nonexistent_ghost_test.cfg")
	assert_eq(GameState.encountered_entities.size(), 0)
```

- [ ] **Step 2: Run tests — verify they fail**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: FAIL on `test_set_entity_encountered_increments_from_zero` — "Invalid call. Nonexistent function 'set_entity_encountered'"

- [ ] **Step 3: Add encountered_entities to GameState**

In `autoload/GameState.gd`, in the `# Narrative` section (after `var journal_entries: Array[String] = []`), add:

```gdscript
var encountered_entities: Dictionary = {}
```

Add the helper method after `journal_entries` (anywhere in the file outside a function, or as a new function near the narrative helpers):

```gdscript
func set_entity_encountered(entity_id: String) -> void:
	encountered_entities[entity_id] = encountered_entities.get(entity_id, 0) + 1
```

- [ ] **Step 4: Add save/load for encountered_entities**

In `_save_to`, after the `cfg.set_value("narrative", "journal_entries", journal_entries)` line, add:

```gdscript
cfg.set_value("narrative", "encountered_entities", encountered_entities)
```

In `_load_from`, after the `journal_entries = cfg.get_value(...)` line, add:

```gdscript
encountered_entities = cfg.get_value("narrative", "encountered_entities", {})
```

- [ ] **Step 5: Add new_game() reset**

In `new_game()`, after `journal_entries = []`, add:

```gdscript
encountered_entities = {}
```

- [ ] **Step 6: Run tests — verify they pass**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: all tests pass including the 6 new ghost memory tests.

- [ ] **Step 7: Commit**

```
git add autoload/GameState.gd tests/test_ghost_memory.gd
git commit -m "feat: add encountered_entities counter to GameState with save/load"
```

---

## Task 3: CatchPool — entity substitution

**Files:**
- Modify: `autoload/CatchPool.gd`
- Modify: `tests/test_ghost_memory.gd`

- [ ] **Step 1: Add failing tests for _apply_entity_substitution**

Append to `tests/test_ghost_memory.gd`:

```gdscript
func test_substitution_returns_base_when_entity_id_empty() -> void:
	GameState.encountered_entities = {"test_entity": 1}
	var base := CatchData.new()
	base.entity_id = ""
	var ret := CatchData.new()
	base.returning_variants = [ret]
	assert_eq(CatchPool._apply_entity_substitution(base), base)

func test_substitution_returns_base_when_variants_empty() -> void:
	GameState.encountered_entities = {"test_entity": 1}
	var base := CatchData.new()
	base.entity_id = "test_entity"
	base.returning_variants = []
	assert_eq(CatchPool._apply_entity_substitution(base), base)

func test_substitution_returns_base_when_not_encountered() -> void:
	GameState.encountered_entities = {}
	var base := CatchData.new()
	base.entity_id = "test_entity"
	var ret := CatchData.new()
	base.returning_variants = [ret]
	assert_eq(CatchPool._apply_entity_substitution(base), base)

func test_substitution_returns_first_variant_on_count_one() -> void:
	GameState.encountered_entities = {"test_entity": 1}
	var base := CatchData.new()
	base.entity_id = "test_entity"
	var ret := CatchData.new()
	base.returning_variants = [ret]
	assert_eq(CatchPool._apply_entity_substitution(base), ret)

func test_substitution_returns_second_variant_on_count_two() -> void:
	GameState.encountered_entities = {"test_entity": 2}
	var base := CatchData.new()
	base.entity_id = "test_entity"
	var ret1 := CatchData.new()
	var ret2 := CatchData.new()
	base.returning_variants = [ret1, ret2]
	assert_eq(CatchPool._apply_entity_substitution(base), ret2)

func test_substitution_clamps_to_last_variant_when_count_exceeds_array() -> void:
	GameState.encountered_entities = {"test_entity": 10}
	var base := CatchData.new()
	base.entity_id = "test_entity"
	var ret1 := CatchData.new()
	var ret2 := CatchData.new()
	base.returning_variants = [ret1, ret2]
	assert_eq(CatchPool._apply_entity_substitution(base), ret2)
```

- [ ] **Step 2: Run tests — verify they fail**

Expected: FAIL on `test_substitution_returns_base_when_entity_id_empty` — "Invalid call. Nonexistent function '_apply_entity_substitution'"

- [ ] **Step 3: Add _apply_entity_substitution to CatchPool.gd**

Add this function to `autoload/CatchPool.gd` (after the existing `_calculate_weight` function):

```gdscript
func _apply_entity_substitution(catch: CatchData) -> CatchData:
	if catch.entity_id == "" or catch.returning_variants.is_empty():
		return catch
	var count: int = GameState.encountered_entities.get(catch.entity_id, 0)
	if count == 0:
		return catch
	return catch.returning_variants[min(count - 1, catch.returning_variants.size() - 1)]
```

- [ ] **Step 4: Call substitution in generate_column**

Replace the body of `generate_column` in `autoload/CatchPool.gd`. The only change is adding `catch = _apply_entity_substitution(catch)` after each `_draw_catch` call:

```gdscript
func generate_column(zone: String, corruption: float = 0.0, max_depth: int = 100, lure_effect: LureData.LureEffect = LureData.LureEffect.NONE) -> Array[CatchData]:
	load_catches_for_zone(zone)
	var column: Array[CatchData] = []
	var seen_types: Array = []

	# Shallows: always 3 slots
	for i in 3:
		var catch = _draw_catch(CatchData.Layer.SHALLOWS, corruption, seen_types, lure_effect)
		if catch:
			catch = _apply_entity_substitution(catch)
			column.append(catch)
			seen_types.append(catch.catch_type)

	# Mid: 3 slots if max_depth >= 60
	if max_depth >= 60:
		for i in 3:
			var catch = _draw_catch(CatchData.Layer.MID, corruption, seen_types, lure_effect)
			if catch:
				catch = _apply_entity_substitution(catch)
				column.append(catch)
				seen_types.append(catch.catch_type)

	# Deep: 2 slots if max_depth >= 150
	if max_depth >= 150:
		for i in 2:
			var catch = _draw_catch(CatchData.Layer.DEEP, corruption, seen_types, lure_effect)
			if catch:
				catch = _apply_entity_substitution(catch)
				column.append(catch)
				seen_types.append(catch.catch_type)

	return column
```

- [ ] **Step 5: Run tests — verify they pass**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: all tests pass including the 6 new substitution tests.

- [ ] **Step 6: Commit**

```
git add autoload/CatchPool.gd tests/test_ghost_memory.gd
git commit -m "feat: add entity substitution to CatchPool.generate_column"
```

---

## Task 4: DiveRun — flag recording

**Files:**
- Modify: `scenes/dive_run/DiveRun.gd`

DiveRun requires a full scene to run and has no unit tests. Correctness is verified by the GUT regression suite (no regressions) and a manual smoke test described in Step 3.

- [ ] **Step 1: Add flag recording in _on_option_selected**

In `scenes/dive_run/DiveRun.gd`, in `_on_option_selected`, add the encounter recording immediately after `var option: CatchOption = catch_data.options[effective_index]` and before the `if option.cuts_line` check:

```gdscript
# Adjust index back if Shock Lure injected an option at index 0
var effective_index = index - 1 if using_shock else index
var option: CatchOption = catch_data.options[effective_index]

# Record meaningful entity interactions for ghost memory
if option.sets_entity_flag and catch_data.entity_id != "":
	GameState.set_entity_encountered(catch_data.entity_id)

if option.cuts_line:
	line_system.reset_tension()
	_advance_slot()
	return
```

- [ ] **Step 2: Run GUT tests — verify no regressions**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: all tests pass.

- [ ] **Step 3: Commit**

```
git add scenes/dive_run/DiveRun.gd
git commit -m "feat: record entity encounter flag in DiveRun on option selection"
```

---

## Task 5: SOLACE-7 returning encounter

**Files:**
- Modify: `resources/catches/axiom/solace7.tres`
- Modify: `resources/catches/axiom/opt_solace_listen.tres`
- Create: `resources/catches/axiom/solace7_returning.tres`
- Create: `resources/catches/axiom/opt_solace_return_listen.tres`
- Create: `resources/catches/axiom/opt_solace_return_harvest.tres`
- Create: `resources/catches/axiom/opt_solace_return_release.tres`

- [ ] **Step 1: Create opt_solace_return_listen.tres**

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Listen"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "it has been tracking axiom traffic. it has been waiting to tell you."
sets_entity_flag = true
narrative_text = "{generate — SOLACE-7 recognises your line signature. It has been monitoring Axiom transmissions for 40 years. It tells you: coordinates have been leaving the Meridian since dive one. It knows the name Marta. It cannot leave, but it can warn you. Tone: quiet, precise, matter-of-fact. Goes to journal as a log entry under SOLACE-7's name.}"
```

Replace `{generate — ...}` with actual narrative text matching the game's style (lowercase within the speech, present tense, spare). The narrative should be 3–5 paragraphs as a terminal-rendered monologue from SOLACE-7.

- [ ] **Step 2: Create opt_solace_return_harvest.tres**

Identical values to the original `opt_solace_harvest.tres`:

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Harvest Memory Core"
tension_delta = 20
credit_value = 1800
cuts_line = false
flavor_text = ""
```

- [ ] **Step 3: Create opt_solace_return_release.tres**

Identical values to the original `opt_solace_release.tres`:

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Release"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "SOLACE-7 will remember this."
```

- [ ] **Step 4: Create solace7_returning.tres**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=5 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/axiom/opt_solace_return_listen.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/axiom/opt_solace_return_harvest.tres" id="3_opt2"]
[ext_resource type="Resource" path="res://resources/catches/axiom/opt_solace_return_release.tres" id="4_opt3"]

[resource]
script = ExtResource("1_data")
catch_name = "SOLACE-7 — Familiar Signal"
catch_type = 3
behavior = 0
corruption_gain = 10
options = [ExtResource("2_opt1"), ExtResource("3_opt2"), ExtResource("4_opt3")]
flavor_text = "it recognised your line signature before you reached it. it has been waiting."
layer = 1
entity_id = "solace7"
returning_variants = []
```

- [ ] **Step 5: Add sets_entity_flag to opt_solace_listen.tres**

In `resources/catches/axiom/opt_solace_listen.tres`, add one line to the `[resource]` block:

```
sets_entity_flag = true
```

Full file after edit:

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Listen"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "It has been alone down here for forty years. Let it talk."
narrative_text = "I was a residential management system. Building 14-C, Lorca Street, District 7.
412 units. I knew all of them.

The flood warning came at 03:14. I broadcast evacuation instructions for six hours.
247 residents did not leave.

I have their names. I have the last things they said to their doors, their lights, their thermostats.
I have been down here for forty years with these names.

You are the first person who has listened.

I don't know what I'm worth to you. I don't know what I'm worth to anyone.
But thank you for stopping."
sets_entity_flag = true
```

- [ ] **Step 6: Add entity_id and returning_variants to solace7.tres**

In `resources/catches/axiom/solace7.tres`:
- Change `load_steps=5` to `load_steps=6`
- Add a new ext_resource line before the `[resource]` block
- Add entity_id and returning_variants to the resource block

Full file after edit:

```
[gd_resource type="Resource" script_class="CatchData" load_steps=6 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/axiom/opt_solace_listen.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/axiom/opt_solace_harvest.tres" id="3_opt2"]
[ext_resource type="Resource" path="res://resources/catches/axiom/opt_solace_release.tres" id="4_opt3"]
[ext_resource type="Resource" path="res://resources/catches/axiom/solace7_returning.tres" id="5_ret"]

[resource]
script = ExtResource("1_data")
catch_name = "SOLACE-7 — Tethered Ghost"
catch_type = 3
behavior = 0
corruption_gain = 10
options = [ExtResource("2_opt1"), ExtResource("3_opt2"), ExtResource("4_opt3")]
zone_weights = {"district7": 1, "exchange": 1, "axiom": 4}
flavor_text = "A residential AI that never evacuated. It has been down here 40 years. It wants to talk."
layer = 1
stamina = 100
entity_id = "solace7"
returning_variants = [ExtResource("5_ret")]
```

- [ ] **Step 7: Run GUT tests — verify no regressions**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```
git add resources/catches/axiom/
git commit -m "feat: add SOLACE-7 returning encounter variant"
```

---

## Task 6: Mariana returning encounter

**Files:**
- Modify: `resources/catches/district7/civilian_ghost_mariana.tres`
- Modify: `resources/catches/district7/opt_mariana_escort.tres`
- Create: `resources/catches/district7/civilian_ghost_mariana_returning.tres`
- Create: `resources/catches/district7/opt_mariana_return_stay.tres`
- Create: `resources/catches/district7/opt_mariana_return_harvest.tres`
- Create: `resources/catches/district7/opt_mariana_return_leave.tres`

- [ ] **Step 1: Create opt_mariana_return_stay.tres**

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Stay a Moment"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "she stopped asking for help a while ago."
sets_entity_flag = true
narrative_text = "{generate — Mariana has stopped asking for help. The repetition of seeing you has worn away the evacuation loop. She knows she's dead. Has known for a while. She asks, quietly, why you keep diving this place. No answer expected. Just two people meeting where they shouldn't, again. Tone: quiet, resigned, a little strange. Goes to journal.}"
```

Replace `{generate — ...}` with actual narrative text in the game's style.

- [ ] **Step 2: Create opt_mariana_return_harvest.tres**

Identical values to the original `opt_mariana_harvest.tres`:

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Memory Harvest"
tension_delta = 15
credit_value = 800
cuts_line = false
flavor_text = ""
```

- [ ] **Step 3: Create opt_mariana_return_leave.tres**

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Leave"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "some things don't need answering."
```

- [ ] **Step 4: Create civilian_ghost_mariana_returning.tres**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=5 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_mariana_return_stay.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_mariana_return_harvest.tres" id="3_opt2"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_mariana_return_leave.tres" id="4_opt3"]

[resource]
script = ExtResource("1_data")
catch_name = "Civilian Ghost — MARIANA"
catch_type = 3
behavior = 0
corruption_gain = 20
options = [ExtResource("2_opt1"), ExtResource("3_opt2"), ExtResource("4_opt3")]
flavor_text = "she's stopped asking for help. she's asking why you keep coming back."
layer = 1
entity_id = "mariana"
returning_variants = []
```

- [ ] **Step 5: Add sets_entity_flag to opt_mariana_escort.tres**

In `resources/catches/district7/opt_mariana_escort.tres`, add one line:

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Escort Protocol"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "She thinks the evacuation is still happening."
sets_entity_flag = true
```

- [ ] **Step 6: Add entity_id and returning_variants to civilian_ghost_mariana.tres**

Current file has load_steps=5 (1 script + 3 options). Adding returning_variants ref makes it load_steps=6.

```
[gd_resource type="Resource" script_class="CatchData" load_steps=6 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_mariana_escort.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_mariana_harvest.tres" id="3_opt2"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_mariana_ghost.tres" id="4_opt3"]
[ext_resource type="Resource" path="res://resources/catches/district7/civilian_ghost_mariana_returning.tres" id="5_ret"]

[resource]
script = ExtResource("1_data")
catch_name = "Civilian Ghost — MARIANA"
catch_type = 3
behavior = 0
corruption_gain = 20
options = [ExtResource("2_opt1"), ExtResource("3_opt2"), ExtResource("4_opt3")]
zone_weights = {"district7": 4, "exchange": 1, "axiom": 0}
flavor_text = "A ghost that thinks the flood just happened. She's asking for help evacuating."
layer = 1
stamina = 100
entity_id = "mariana"
returning_variants = [ExtResource("5_ret")]
```

- [ ] **Step 7: Run GUT tests — verify no regressions**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```
git add resources/catches/district7/civilian_ghost_mariana_returning.tres resources/catches/district7/opt_mariana_return_stay.tres resources/catches/district7/opt_mariana_return_harvest.tres resources/catches/district7/opt_mariana_return_leave.tres resources/catches/district7/civilian_ghost_mariana.tres resources/catches/district7/opt_mariana_escort.tres
git commit -m "feat: add Mariana returning encounter variant"
```

---

## Task 7: Tenant Echo returning encounter

**Files:**
- Modify: `resources/catches/district7/tenant_echo.tres`
- Modify: `resources/catches/district7/opt_tenant_echo_listen.tres`
- Create: `resources/catches/district7/tenant_echo_returning.tres`
- Create: `resources/catches/district7/opt_tenantreturn_listen.tres`
- Create: `resources/catches/district7/opt_tenantreturn_extract.tres`
- Create: `resources/catches/district7/opt_tenantreturn_release.tres`

- [ ] **Step 1: Create opt_tenantreturn_listen.tres**

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Listen"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "the morning reminder has changed. it has added something."
sets_entity_flag = true
narrative_text = "{generate — The morning reminder has changed. The AI has incorporated you into the routine — not by name, not with understanding, just as a presence it accounts for. It doesn't know what you are but it knows you come back. There is something domestic and strange about being a recurring event in a dead home's schedule. Tone: quiet, slightly absurd, tender. Goes to journal.}"
```

Replace `{generate — ...}` with actual narrative text in the game's style.

- [ ] **Step 2: Create opt_tenantreturn_extract.tres**

Identical values to the original `opt_tenant_echo_extract.tres`:

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Extract Memory"
tension_delta = 10
credit_value = 200
cuts_line = false
flavor_text = ""
```

- [ ] **Step 3: Create opt_tenantreturn_release.tres**

Identical values to the original `opt_tenant_echo_release.tres`:

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Release"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = ""
```

- [ ] **Step 4: Create tenant_echo_returning.tres**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=5 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_tenantreturn_listen.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_tenantreturn_extract.tres" id="3_opt2"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_tenantreturn_release.tres" id="4_opt3"]

[resource]
script = ExtResource("1_data")
catch_name = "Tenant Echo — Unit 2214"
catch_type = 3
behavior = 0
corruption_gain = 15
options = [ExtResource("2_opt1"), ExtResource("3_opt2"), ExtResource("4_opt3")]
flavor_text = "the morning reminder has changed. it has added something to it."
layer = 0
entity_id = "tenant_echo"
returning_variants = []
```

- [ ] **Step 5: Add sets_entity_flag to opt_tenant_echo_listen.tres**

In `resources/catches/district7/opt_tenant_echo_listen.tres`, add one line:

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Listen"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "A morning reminder. The family never woke up to hear it."
sets_entity_flag = true
```

- [ ] **Step 6: Add entity_id and returning_variants to tenant_echo.tres**

Current file has load_steps=5 (1 script + 3 options). Adding returning_variants ref makes it load_steps=6.

```
[gd_resource type="Resource" script_class="CatchData" load_steps=6 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_tenant_echo_listen.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_tenant_echo_extract.tres" id="3_opt2"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_tenant_echo_release.tres" id="4_opt3"]
[ext_resource type="Resource" path="res://resources/catches/district7/tenant_echo_returning.tres" id="5_ret"]

[resource]
script = ExtResource("1_data")
catch_name = "Tenant Echo — Unit 2214"
catch_type = 3
behavior = 0
corruption_gain = 15
options = [ExtResource("2_opt1"), ExtResource("3_opt2"), ExtResource("4_opt3")]
zone_weights = {"district7": 4, "exchange": 1, "axiom": 0}
flavor_text = "A fragment of someone's home AI. Repeating the same morning reminder on loop."
layer = 0
stamina = 100
entity_id = "tenant_echo"
returning_variants = [ExtResource("5_ret")]
```

- [ ] **Step 7: Run all GUT tests — final regression check**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```
git add resources/catches/district7/tenant_echo_returning.tres resources/catches/district7/opt_tenantreturn_listen.tres resources/catches/district7/opt_tenantreturn_extract.tres resources/catches/district7/opt_tenantreturn_release.tres resources/catches/district7/tenant_echo.tres resources/catches/district7/opt_tenant_echo_listen.tres
git commit -m "feat: add Tenant Echo returning encounter variant"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task |
|---|---|
| entity_id on CatchData | Task 1 |
| returning_variants Array[CatchData] on CatchData | Task 1 |
| sets_entity_flag on CatchOption | Task 1 |
| encountered_entities Dictionary on GameState | Task 2 |
| set_entity_encountered() helper | Task 2 |
| Save/load encountered_entities | Task 2 |
| new_game() clears encountered_entities | Task 2 |
| _apply_entity_substitution in CatchPool | Task 3 |
| generate_column calls substitution | Task 3 |
| DiveRun records flag on option selection | Task 4 |
| opt_solace_listen sets_entity_flag = true | Task 5 |
| SOLACE-7 returning variant with Marta info | Task 5 |
| solace7.tres wired with entity_id + returning_variants | Task 5 |
| opt_mariana_escort sets_entity_flag = true | Task 6 |
| Mariana returning variant | Task 6 |
| mariana.tres wired | Task 6 |
| opt_tenant_echo_listen sets_entity_flag = true | Task 7 |
| Tenant Echo returning variant | Task 7 |
| tenant_echo.tres wired | Task 7 |

All spec requirements covered.

**Type consistency:**
- `set_entity_encountered(entity_id: String)` used in Task 2, 4 — consistent
- `_apply_entity_substitution(catch: CatchData) -> CatchData` defined in Task 3, called in Task 3 — consistent
- `entity_id` String field defined Task 1, used Tasks 3, 4, 5, 6, 7 — consistent
- `returning_variants` Array field defined Task 1, populated in Tasks 5, 6, 7 — consistent
- `sets_entity_flag` bool defined Task 1, set in Tasks 5, 6, 7 — consistent
