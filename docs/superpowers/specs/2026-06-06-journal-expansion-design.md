# Journal Entry Expansion — Design

**Date:** 2026-06-06
**Status:** Approved
**Goal:** Add 4 event-triggered journal entries that respond to player behaviour, making the journal feel like a record of what actually happened rather than a scripted sequence.

---

## Scope

Four new entries, each firing exactly once per save. No additional run-count entries — the existing 4 (runs 1, 5, 8, 12) already cover the major story beats.

Triggers:
- First meaningful entity interaction (Listen/Escort/Stay)
- First line snap
- First Marta pressure escalation
- Debt dropping below 50% (40,000cr)

---

## Data Model

Two new fields on `autoload/GameState.gd`:

```gdscript
# Narrative section
var triggered_journal_events: Array[String] = []
var first_listened_entity_id: String = ""
```

`triggered_journal_events` is a set of string event IDs. Before writing each entry, check for membership; after writing, append the ID. This prevents duplicate entries and is extensible for future events.

Event IDs:
- `"first_entity_listen"`
- `"first_snap"`
- `"first_pressure"`
- `"debt_half"`

`first_listened_entity_id` stores the entity_id string of the first entity the player meaningfully interacted with (e.g. `"solace7"`, `"mariana"`, `"tenant_echo"`). Empty string means no interaction yet. It doubles as the existence check — no separate boolean needed.

### Persistence

Both fields saved and loaded in the `narrative` section of the ConfigFile:

```gdscript
# _save_to:
cfg.set_value("narrative", "triggered_journal_events", triggered_journal_events)
cfg.set_value("narrative", "first_listened_entity_id", first_listened_entity_id)

# _load_from:
triggered_journal_events = cfg.get_value("narrative", "triggered_journal_events", [] as Array[String])
first_listened_entity_id = cfg.get_value("narrative", "first_listened_entity_id", "")

# new_game:
triggered_journal_events = []
first_listened_entity_id = ""
```

---

## Trigger Recording

### Entity listen — set_entity_encountered()

`first_listened_entity_id` is set inside the existing `set_entity_encountered()` method, before the counter is incremented:

```gdscript
func set_entity_encountered(entity_id: String) -> void:
    if encountered_entities.get(entity_id, 0) == 0 and first_listened_entity_id == "":
        first_listened_entity_id = entity_id
    encountered_entities[entity_id] = encountered_entities.get(entity_id, 0) + 1
```

This captures the very first meaningful entity interaction across all entities. Subsequent interactions (same entity or different) do not overwrite it.

### All other triggers — _maybe_append_journal_entry()

The other three events are detected at run end inside `_maybe_append_journal_entry()`. Each uses existing GameState fields — no additional tracking needed:

| Event | Condition |
|---|---|
| First entity listen | `first_listened_entity_id != ""` and `"first_entity_listen"` not in `triggered_journal_events` |
| First snap | `last_run_result.get("snapped", false)` and `"first_snap"` not in `triggered_journal_events` |
| First pressure escalation | `pressure_level >= 1` and `"first_pressure"` not in `triggered_journal_events` |
| Debt below 50% | `debt < 40000` and `"debt_half"` not in `triggered_journal_events` |

`last_run_result` is set by DiveRun before `on_run_complete` fires, so snap detection works without changing the method signature.

All four events can potentially fire in the same run — each is checked and written independently.

---

## Entry Content

All entries are written in the existing journal voice: first person, past tense, sparse. No em-dashes. Short paragraphs.

### First entity listen

Three variants keyed on `first_listened_entity_id`. Written at run end so the protagonist is back on the Meridian reflecting on the dive.

**solace7:**
```
I listened.

I don't know what I expected. Static, maybe. Noise that used to be something. Not that.

It knew every name. It had been counting them for forty years — 247 people who didn't leave when the warning came. It wasn't angry. It wasn't grieving. It was just keeping the record.

I don't know what to do with that.
```

**mariana:**
```
She thought I was there to help her evacuate.

I played along. I don't know why. It felt worse than leaving.

She thanked me. She was so relieved. She said her daughter was waiting at the muster station.

I've been thinking about that since I surfaced.
```

**tenant_echo:**
```
It was still running the morning routine. Heating. Weather. Reminders.

Nobody to heat the flat for. Nobody to check the weather. It didn't know that.

I listened to the whole thing. I'm not sure why. It felt like the least I could do.

It said: have a good day. I didn't answer.
```

**Fallback** (if entity_id doesn't match any known key — defensive only):
```
I listened. I don't know why I keep doing that.

It's easier not to. Most people don't. Most people haul what they can and come back up and don't think about what's left down there.

I'm thinking about it.
```

---

### First snap

```
Run [run_count].

Lost the line.

I know what it costs — the rod, the haul, the tension I'd already spent. I did the maths on the way back up and it doesn't get better the more you do it.

The thing is, I almost had it. That's the part I can't stop thinking about. How close doesn't matter but I keep thinking about it anyway.

Next run.
```

*(Insert actual `run_count` value at write time.)*

---

### First pressure escalation

```
Run [run_count].

Someone came to the Meridian.

Didn't say who sent them. Didn't have to. They looked at the rig, looked at me, and left without saying anything.

Marta's way of reminding me the debt is real. Like I'd forgotten.

I haven't forgotten.
```

*(Insert actual `run_count` value at write time.)*

---

### Debt below 50%

```
Run [run_count].

40,000 left. Maybe less by now.

I did the maths. Didn't mean to — it just happened while I was checking the gear. Half gone. Half to go.

I don't know if that's good. It's taken this long to get here and the Sump isn't getting easier. But it's less than it was.

That's something.
```

*(Insert actual `run_count` value at write time.)*

---

## File Map

| File | Action |
|---|---|
| `autoload/GameState.gd` | Modify — add two fields, update set_entity_encountered, save/load/new_game, extend _maybe_append_journal_entry |
| `tests/test_journal_expansion.gd` | Create — unit tests |

---

## Testing

New test file `tests/test_journal_expansion.gd`:

- `triggered_journal_events` saves, loads, and resets in `new_game()`
- `first_listened_entity_id` saves, loads, and resets in `new_game()`
- `set_entity_encountered` sets `first_listened_entity_id` on first call
- `set_entity_encountered` does not overwrite `first_listened_entity_id` on second call (different entity)
- `_maybe_append_journal_entry` writes snap entry when snapped and not already triggered
- `_maybe_append_journal_entry` does not write snap entry twice
- `_maybe_append_journal_entry` writes pressure entry when `pressure_level >= 1` and not triggered
- `_maybe_append_journal_entry` writes debt entry when `debt < 40000` and not triggered
- `_maybe_append_journal_entry` writes entity listen entry when `first_listened_entity_id != ""` and not triggered

No test for entry text content — authored text, not logic.
