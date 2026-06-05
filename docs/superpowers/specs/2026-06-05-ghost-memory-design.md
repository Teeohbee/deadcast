# Ghost Memory — Returning Entity Encounters Design

**Date:** 2026-06-05
**Status:** Approved
**Goal:** When a player meaningfully engages with a named entity, subsequent encounters show a different catch with different options and narrative — the entity remembers them.

---

## Scope

Three entities get returning encounter variants in this implementation:
- **SOLACE-7** (Axiom mid)
- **Civilian Ghost — Mariana** (District 7 mid)
- **Tenant Echo — Unit 2214** (District 7 shallows)

The system is built generically — any entity catch can opt in. Other entity catches are left without returning variants for now.

One returning variant per entity. The counter model supports more; content for additional variants is out of scope here.

---

## Data Model

### catch_data.gd — two new fields

```gdscript
@export var entity_id: String = ""
@export var returning_variants: Array[CatchData] = []
```

`entity_id` is the stable string key used to track encounters (e.g. `"solace7"`, `"mariana"`, `"tenant_echo"`). Empty string means the catch is not tracked and the returning system ignores it.

`returning_variants` is an ordered array of alternate catch resources to show after meaningful interactions. Index 0 is shown after the first flag, index 1 after the second, and so on. The last entry loops — if the player has interacted more times than there are variants, the last variant always shows.

### catch_option.gd — one new field

```gdscript
@export var sets_entity_flag: bool = false
```

Marks options that count as meaningful engagement: Listen, Stay a Moment, Talk. Choosing Harvest or Release does not set the flag. The flag records regardless of resist/fail outcome — the act of choosing is what matters.

### GameState — encounter tracking

```gdscript
var encountered_entities: Dictionary = {}  # entity_id → int (count of meaningful interactions)

func set_entity_encountered(entity_id: String) -> void:
    encountered_entities[entity_id] = encountered_entities.get(entity_id, 0) + 1
```

Saved and loaded in the `narrative` section of the config file:

```gdscript
# in _save_to:
cfg.set_value("narrative", "encountered_entities", encountered_entities)

# in _load_from:
encountered_entities = cfg.get_value("narrative", "encountered_entities", {})

# in new_game:
encountered_entities = {}
```

---

## Substitution — CatchPool.generate_column

After drawing each catch, apply the entity variant substitution before appending to the column:

```gdscript
if catch.entity_id != "" and not catch.returning_variants.is_empty():
    var count: int = GameState.encountered_entities.get(catch.entity_id, 0)
    if count > 0:
        catch = catch.returning_variants[min(count - 1, catch.returning_variants.size() - 1)]
```

This runs inside the existing draw loops (shallows, mid, deep), after `_draw_catch` returns and before `column.append`. The rest of DiveRun is unaware a substitution occurred.

---

## Flag Recording — DiveRun._on_option_selected

After resolving the effective option index and before dispatching to the behavior resolver, record the entity flag:

```gdscript
if option.sets_entity_flag and catch_data.entity_id != "":
    GameState.set_entity_encountered(catch_data.entity_id)
```

Use `catch_data` (the unaugmented `_column[_current_slot]`) not `_current_catch_data` (which may have a Shock Lure option injected at index 0). The `entity_id` is on the base resource in the column, and is identical on any returning variant.

---

## Existing File Modifications

### Three catch .tres files — add entity_id and returning_variants ref

**resources/catches/axiom/solace7.tres**
```
entity_id = "solace7"
returning_variants = [ExtResource("N_ret")]
```

**resources/catches/district7/civilian_ghost_mariana.tres**
```
entity_id = "mariana"
returning_variants = [ExtResource("N_ret")]
```

**resources/catches/district7/tenant_echo.tres**
```
entity_id = "tenant_echo"
returning_variants = [ExtResource("N_ret")]
```

### Three option .tres files — add sets_entity_flag

**resources/catches/axiom/opt_solace_listen.tres**
```
sets_entity_flag = true
```

**resources/catches/district7/opt_mariana_escort.tres** (Escort Protocol — playing along with her evacuation belief)
```
sets_entity_flag = true
```

**resources/catches/district7/opt_tenant_echo_listen.tres**
```
sets_entity_flag = true
```

---

## New Files — Returning Catch Variants

### SOLACE-7 — Familiar Signal

**resources/catches/axiom/solace7_returning.tres**
- `catch_name = "SOLACE-7 — Familiar Signal"`
- `catch_type = 3` (ENTITY), `behavior = 0` (PASSIVE), `corruption_gain = 10`, `layer = 1`
- `entity_id = "solace7"` (same entity, so continued encounters keep showing this variant)
- `returning_variants = []`

Options:
- **opt_solace_return_listen.tres** — `sets_entity_flag = true`, `narrative_text` present
  - Narrative direction: SOLACE-7 has been monitoring Axiom traffic in the deep archive for 40 years. It recognised your line signature and has been waiting. It tells you what it has seen: coordinates leaving the Meridian since dive one. It knows the name Marta. It cannot leave but it can warn you. Goes to journal.
  - `tension_delta = 0`, `credit_value = 0`
- **opt_solace_return_harvest.tres** — same values as original `opt_solace_harvest`
- **opt_solace_return_release.tres** — same values as original `opt_solace_release`

---

### Civilian Ghost — Mariana — Returning

**resources/catches/district7/civilian_ghost_mariana_returning.tres**
- `catch_name = "Civilian Ghost — MARIANA"`
- `catch_type = 3`, `behavior = 0`, `corruption_gain = 20`, `layer = 1`
- `entity_id = "mariana"`, `returning_variants = []`

Options:
- **opt_mariana_return_stay.tres** — `label = "Stay a Moment"`, `sets_entity_flag = true`, `narrative_text` present
  - Narrative direction: She has stopped asking for help. The repetition of seeing you has worn away the evacuation loop. She knows she's dead now — has for a while. She asks why you keep diving this place. No answer expected. A quiet acknowledgement between two people who keep meeting where they shouldn't. Goes to journal.
  - `tension_delta = 0`, `credit_value = 0`
- **opt_mariana_return_harvest.tres** — same values as original `opt_mariana_harvest`
- **opt_mariana_return_leave.tres** — `label = "Leave"`, same values as original `opt_mariana_escort` (no reward)

---

### Tenant Echo — Unit 2214 — Returning

**resources/catches/district7/tenant_echo_returning.tres**
- `catch_name = "Tenant Echo — Unit 2214"`
- `catch_type = 3`, `behavior = 0`, `corruption_gain = 15`, `layer = 0`
- `entity_id = "tenant_echo"`, `returning_variants = []`

Options:
- **opt_tenantreturn_listen.tres** — `label = "Listen"`, `sets_entity_flag = true`, `narrative_text` present
  - Narrative direction: The morning reminder has changed. The AI has incorporated you into the routine — not by name, not with understanding, just as a presence it accounts for. It doesn't know what you are but it knows you come back. There is something domestic and strange about being a recurring event in a dead home's schedule. Goes to journal.
  - `tension_delta = 0`, `credit_value = 0`
- **opt_tenantreturn_extract.tres** — same values as original `opt_tenant_echo_extract`
- **opt_tenantreturn_release.tres** — same values as original `opt_tenant_echo_release`

---

## File Map Summary

| File | Action |
|---|---|
| `resources/catch_data.gd` | Modify — add entity_id, returning_variants |
| `resources/catch_option.gd` | Modify — add sets_entity_flag |
| `autoload/GameState.gd` | Modify — add encountered_entities, save/load, new_game, helper |
| `autoload/CatchPool.gd` | Modify — substitution in generate_column |
| `scenes/dive_run/DiveRun.gd` | Modify — flag recording in _on_option_selected |
| `resources/catches/axiom/solace7.tres` | Modify — add entity_id, returning_variants |
| `resources/catches/district7/civilian_ghost_mariana.tres` | Modify — add entity_id, returning_variants |
| `resources/catches/district7/tenant_echo.tres` | Modify — add entity_id, returning_variants |
| `resources/catches/axiom/opt_solace_listen.tres` | Modify — add sets_entity_flag |
| `resources/catches/district7/opt_mariana_ghost.tres` | Modify — add sets_entity_flag |
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

---

## Testing

- Unit tests in `tests/test_ghost_memory.gd`:
  - `generate_column` returns base catch when entity not encountered
  - `generate_column` returns returning_variant when encounter count = 1
  - `generate_column` clamps to last variant when encounter count exceeds variants array size
  - `set_entity_encountered` increments counter correctly
  - `encountered_entities` persists across save/load
  - `new_game` clears encountered_entities
- No test for narrative_text content — that's authored content, not logic
