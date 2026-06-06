# Journal Entry Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 4 event-triggered journal entries that fire once per save in response to player behaviour (first entity listen, first line snap, first pressure escalation, debt below 50%).

**Architecture:** All changes are in `autoload/GameState.gd`. Two new fields track which events have fired (`triggered_journal_events: Array[String]`) and which entity was first listened to (`first_listened_entity_id: String`). `set_entity_encountered` is updated to record the first entity. `_maybe_append_journal_entry` is extended with 4 new event checks after the existing run-count match block.

**Tech Stack:** Godot 4, GDScript, GUT test framework

---

## File Map

| File | Action |
|---|---|
| `autoload/GameState.gd` | Modify — add fields, update set_entity_encountered, extend save/load/new_game, extend _maybe_append_journal_entry |
| `tests/test_journal_expansion.gd` | Create — unit tests |

---

### Task 1: Data model, persistence, and set_entity_encountered

**Files:**
- Modify: `autoload/GameState.gd`
- Create: `tests/test_journal_expansion.gd`

**Context:** GameState is a singleton autoload at `autoload/GameState.gd`. Tests use the GUT framework. Run tests with: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests` from `/Users/toby/code/deadcast`. Currently 85 tests pass.

---

- [ ] **Step 1: Create the test file**

Create `tests/test_journal_expansion.gd`:

```gdscript
# tests/test_journal_expansion.gd
extends GutTest

func before_each() -> void:
	GameState.triggered_journal_events = []
	GameState.first_listened_entity_id = ""
	GameState.journal_entries = []
	GameState.last_run_result = {}
	GameState.pressure_level = 0
	GameState.debt = 80000
	GameState.run_count = 99
	GameState.encountered_entities = {}

func after_each() -> void:
	DirAccess.remove_absolute("user://save_journal_test.cfg")

func test_triggered_journal_events_saves_and_loads() -> void:
	GameState.triggered_journal_events = ["first_snap", "debt_half"]
	GameState._save_to("user://save_journal_test.cfg")
	GameState.triggered_journal_events = []
	GameState._load_from("user://save_journal_test.cfg")
	assert_eq(GameState.triggered_journal_events.size(), 2)
	assert_true("first_snap" in GameState.triggered_journal_events)
	assert_true("debt_half" in GameState.triggered_journal_events)

func test_first_listened_entity_id_saves_and_loads() -> void:
	GameState.first_listened_entity_id = "solace7"
	GameState._save_to("user://save_journal_test.cfg")
	GameState.first_listened_entity_id = ""
	GameState._load_from("user://save_journal_test.cfg")
	assert_eq(GameState.first_listened_entity_id, "solace7")

func test_new_game_clears_triggered_journal_events() -> void:
	GameState.triggered_journal_events = ["first_snap"]
	GameState.new_game()
	assert_eq(GameState.triggered_journal_events.size(), 0)

func test_new_game_clears_first_listened_entity_id() -> void:
	GameState.first_listened_entity_id = "mariana"
	GameState.new_game()
	assert_eq(GameState.first_listened_entity_id, "")

func test_set_entity_encountered_sets_first_listened_on_first_call() -> void:
	GameState.first_listened_entity_id = ""
	GameState.encountered_entities = {}
	GameState.set_entity_encountered("solace7")
	assert_eq(GameState.first_listened_entity_id, "solace7")

func test_set_entity_encountered_does_not_overwrite_first_listened() -> void:
	GameState.first_listened_entity_id = "solace7"
	GameState.encountered_entities = {"solace7": 1}
	GameState.set_entity_encountered("mariana")
	assert_eq(GameState.first_listened_entity_id, "solace7")

func test_set_entity_encountered_does_not_set_if_entity_already_seen() -> void:
	GameState.first_listened_entity_id = ""
	GameState.encountered_entities = {"solace7": 1}
	GameState.set_entity_encountered("solace7")
	assert_eq(GameState.first_listened_entity_id, "")
```

- [ ] **Step 2: Run tests to verify they fail**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: failures on the new tests (fields don't exist yet). Existing 85 tests still pass.

- [ ] **Step 3: Add the two new fields to GameState.gd**

In `autoload/GameState.gd`, find the Narrative section (around line 52):

```gdscript
# Narrative
var marta_last_seen_run: int = -1
var journal_entries: Array[String] = []
var encountered_entities: Dictionary = {}
```

Change to:

```gdscript
# Narrative
var marta_last_seen_run: int = -1
var journal_entries: Array[String] = []
var encountered_entities: Dictionary = {}
var triggered_journal_events: Array[String] = []
var first_listened_entity_id: String = ""
```

- [ ] **Step 4: Update set_entity_encountered**

Find `set_entity_encountered` (around line 122):

```gdscript
func set_entity_encountered(entity_id: String) -> void:
	encountered_entities[entity_id] = encountered_entities.get(entity_id, 0) + 1
```

Replace with:

```gdscript
func set_entity_encountered(entity_id: String) -> void:
	if encountered_entities.get(entity_id, 0) == 0 and first_listened_entity_id == "":
		first_listened_entity_id = entity_id
	encountered_entities[entity_id] = encountered_entities.get(entity_id, 0) + 1
```

- [ ] **Step 5: Add save lines**

In `_save_to`, find:

```gdscript
	cfg.set_value("narrative", "encountered_entities", encountered_entities)
	cfg.save(path)
```

Replace with:

```gdscript
	cfg.set_value("narrative", "encountered_entities", encountered_entities)
	cfg.set_value("narrative", "triggered_journal_events", triggered_journal_events)
	cfg.set_value("narrative", "first_listened_entity_id", first_listened_entity_id)
	cfg.save(path)
```

- [ ] **Step 6: Add load lines**

In `_load_from`, find:

```gdscript
	encountered_entities = cfg.get_value("narrative", "encountered_entities", {})
	EventBus.credits_changed.emit(credits)
```

Replace with:

```gdscript
	encountered_entities = cfg.get_value("narrative", "encountered_entities", {})
	triggered_journal_events = cfg.get_value("narrative", "triggered_journal_events", [] as Array[String])
	first_listened_entity_id = cfg.get_value("narrative", "first_listened_entity_id", "")
	EventBus.credits_changed.emit(credits)
```

- [ ] **Step 7: Add new_game resets**

In `new_game()`, find:

```gdscript
	encountered_entities = {}
	journal_entries = []
```

Replace with:

```gdscript
	encountered_entities = {}
	triggered_journal_events = []
	first_listened_entity_id = ""
	journal_entries = []
```

- [ ] **Step 8: Run tests to verify they pass**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: `---- All tests passed! ----` — 85 + 7 = 92 passing.

- [ ] **Step 9: Commit**

```bash
git add autoload/GameState.gd tests/test_journal_expansion.gd
git commit -m "feat: add triggered_journal_events and first_listened_entity_id to GameState"
```

---

### Task 2: Event-triggered journal entries in _maybe_append_journal_entry

**Files:**
- Modify: `autoload/GameState.gd`
- Modify: `tests/test_journal_expansion.gd`

**Context:** `_maybe_append_journal_entry()` is called at the end of every run inside `on_run_complete()`. `last_run_result` is set by DiveRun before `on_run_complete` fires, so it's readable here. The existing method has a `match run_count` block for the 4 story-beat entries. Add the event checks after that block.

---

- [ ] **Step 1: Append tests to test_journal_expansion.gd**

Add these tests to the end of `tests/test_journal_expansion.gd`:

```gdscript
# --- _maybe_append_journal_entry event triggers ---

func test_entity_listen_entry_written_when_entity_id_set() -> void:
	GameState.first_listened_entity_id = "solace7"
	GameState._maybe_append_journal_entry()
	assert_true("first_entity_listen" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 1)

func test_entity_listen_entry_not_written_twice() -> void:
	GameState.first_listened_entity_id = "solace7"
	GameState.triggered_journal_events = ["first_entity_listen"]
	GameState._maybe_append_journal_entry()
	assert_eq(GameState.journal_entries.size(), 0)

func test_entity_listen_entry_not_written_without_entity_id() -> void:
	GameState.first_listened_entity_id = ""
	GameState._maybe_append_journal_entry()
	assert_false("first_entity_listen" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 0)

func test_snap_entry_written_on_first_snap() -> void:
	GameState.last_run_result = {"snapped": true, "credits": 0, "bio_credits": 0}
	GameState._maybe_append_journal_entry()
	assert_true("first_snap" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 1)

func test_snap_entry_not_written_twice() -> void:
	GameState.last_run_result = {"snapped": true, "credits": 0, "bio_credits": 0}
	GameState.triggered_journal_events = ["first_snap"]
	GameState._maybe_append_journal_entry()
	assert_eq(GameState.journal_entries.size(), 0)

func test_snap_entry_not_written_when_not_snapped() -> void:
	GameState.last_run_result = {"snapped": false, "credits": 0, "bio_credits": 0}
	GameState._maybe_append_journal_entry()
	assert_false("first_snap" in GameState.triggered_journal_events)

func test_pressure_entry_written_on_first_escalation() -> void:
	GameState.pressure_level = 1
	GameState._maybe_append_journal_entry()
	assert_true("first_pressure" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 1)

func test_pressure_entry_not_written_twice() -> void:
	GameState.pressure_level = 1
	GameState.triggered_journal_events = ["first_pressure"]
	GameState._maybe_append_journal_entry()
	assert_eq(GameState.journal_entries.size(), 0)

func test_pressure_entry_not_written_at_zero_pressure() -> void:
	GameState.pressure_level = 0
	GameState._maybe_append_journal_entry()
	assert_false("first_pressure" in GameState.triggered_journal_events)

func test_debt_entry_written_below_half() -> void:
	GameState.debt = 39999
	GameState._maybe_append_journal_entry()
	assert_true("debt_half" in GameState.triggered_journal_events)
	assert_eq(GameState.journal_entries.size(), 1)

func test_debt_entry_not_written_twice() -> void:
	GameState.debt = 39999
	GameState.triggered_journal_events = ["debt_half"]
	GameState._maybe_append_journal_entry()
	assert_eq(GameState.journal_entries.size(), 0)

func test_debt_entry_not_written_at_exactly_half() -> void:
	GameState.debt = 40000
	GameState._maybe_append_journal_entry()
	assert_false("debt_half" in GameState.triggered_journal_events)
```

- [ ] **Step 2: Run tests to verify new ones fail**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: new tests fail (event logic not implemented yet). Existing 92 pass.

- [ ] **Step 3: Extend _maybe_append_journal_entry**

In `autoload/GameState.gd`, find the complete `_maybe_append_journal_entry` function:

```gdscript
func _maybe_append_journal_entry() -> void:
	match run_count:
		1:
			journal_entries.append("Run 1.\n\nQuieter than I expected. The Sump doesn't echo the way open water does. Sound just — stops.\n\nPulled an archive from the District 7 shallows. Old finance data. Someone's mortgage payments, still encrypted after forty years. Nobody left to foreclose on.\n\nThis is the job.")
		5:
			journal_entries.append("Run 5.\n\nMarta knew about the Axiom shard before I mentioned it. I didn't mention it.\n\nI told myself she has sources. Buyers who talk. That's how fixers work.\n\nI'm telling myself that.")
		8:
			journal_entries.append("Run 8.\n\nThe transponder. She told me to my face.\n\nEvery dive. Every coordinate. Axiom Corp has a map of everywhere the Meridian has anchored since day one. They know what I've been pulling up.\n\nShe said it changes nothing. She's right. The debt is still real. The rig still works.\n\nI keep thinking about what's in the Deep Archive that Axiom wants so badly they'd pay for this.")
		12:
			journal_entries.append("Run 12.\n\nOkeke left a lure on my line. Basic hook, nothing special. No note.\n\nHe hasn't spoken to me in three runs. Either Marta got to him or he figured something out on his own.\n\nShe's offering to accelerate the debt. Won't say what for.\n\nI haven't said yes.")
```

Replace with (preserve the existing match block exactly, add the event block after it):

```gdscript
func _maybe_append_journal_entry() -> void:
	match run_count:
		1:
			journal_entries.append("Run 1.\n\nQuieter than I expected. The Sump doesn't echo the way open water does. Sound just — stops.\n\nPulled an archive from the District 7 shallows. Old finance data. Someone's mortgage payments, still encrypted after forty years. Nobody left to foreclose on.\n\nThis is the job.")
		5:
			journal_entries.append("Run 5.\n\nMarta knew about the Axiom shard before I mentioned it. I didn't mention it.\n\nI told myself she has sources. Buyers who talk. That's how fixers work.\n\nI'm telling myself that.")
		8:
			journal_entries.append("Run 8.\n\nThe transponder. She told me to my face.\n\nEvery dive. Every coordinate. Axiom Corp has a map of everywhere the Meridian has anchored since day one. They know what I've been pulling up.\n\nShe said it changes nothing. She's right. The debt is still real. The rig still works.\n\nI keep thinking about what's in the Deep Archive that Axiom wants so badly they'd pay for this.")
		12:
			journal_entries.append("Run 12.\n\nOkeke left a lure on my line. Basic hook, nothing special. No note.\n\nHe hasn't spoken to me in three runs. Either Marta got to him or he figured something out on his own.\n\nShe's offering to accelerate the debt. Won't say what for.\n\nI haven't said yes.")

	if first_listened_entity_id != "" and "first_entity_listen" not in triggered_journal_events:
		triggered_journal_events.append("first_entity_listen")
		var entity_text: String
		match first_listened_entity_id:
			"solace7":
				entity_text = "I listened.\n\nI don't know what I expected. Static, maybe. Noise that used to be something. Not that.\n\nIt knew every name. It had been counting them for forty years — 247 people who didn't leave when the warning came. It wasn't angry. It wasn't grieving. It was just keeping the record.\n\nI don't know what to do with that."
			"mariana":
				entity_text = "She thought I was there to help her evacuate.\n\nI played along. I don't know why. It felt worse than leaving.\n\nShe thanked me. She was so relieved. She said her daughter was waiting at the muster station.\n\nI've been thinking about that since I surfaced."
			"tenant_echo":
				entity_text = "It was still running the morning routine. Heating. Weather. Reminders.\n\nNobody to heat the flat for. Nobody to check the weather. It didn't know that.\n\nI listened to the whole thing. I'm not sure why. It felt like the least I could do.\n\nIt said: have a good day. I didn't answer."
			_:
				entity_text = "I listened. I don't know why I keep doing that.\n\nIt's easier not to. Most people don't. Most people haul what they can and come back up and don't think about what's left down there.\n\nI'm thinking about it."
		journal_entries.append(entity_text)

	if last_run_result.get("snapped", false) and "first_snap" not in triggered_journal_events:
		triggered_journal_events.append("first_snap")
		journal_entries.append("Run %d.\n\nLost the line.\n\nI know what it costs — the rod, the haul, the tension I'd already spent. I did the maths on the way back up and it doesn't get better the more you do it.\n\nThe thing is, I almost had it. That's the part I can't stop thinking about. How close doesn't matter but I keep thinking about it anyway.\n\nNext run." % run_count)

	if pressure_level >= 1 and "first_pressure" not in triggered_journal_events:
		triggered_journal_events.append("first_pressure")
		journal_entries.append("Run %d.\n\nSomeone came to the Meridian.\n\nDidn't say who sent them. Didn't have to. They looked at the rig, looked at me, and left without saying anything.\n\nMarta's way of reminding me the debt is real. Like I'd forgotten.\n\nI haven't forgotten." % run_count)

	if debt < 40000 and "debt_half" not in triggered_journal_events:
		triggered_journal_events.append("debt_half")
		journal_entries.append("Run %d.\n\n40,000 left. Maybe less by now.\n\nI did the maths. Didn't mean to — it just happened while I was checking the gear. Half gone. Half to go.\n\nI don't know if that's good. It's taken this long to get here and the Sump isn't getting easier. But it's less than it was.\n\nThat's something." % run_count)
```

- [ ] **Step 4: Run tests to verify they all pass**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: `---- All tests passed! ----` — 92 + 13 = 105 passing.

- [ ] **Step 5: Commit**

```bash
git add autoload/GameState.gd tests/test_journal_expansion.gd
git commit -m "feat: add event-triggered journal entries for entity listen, snap, pressure, and debt"
```
