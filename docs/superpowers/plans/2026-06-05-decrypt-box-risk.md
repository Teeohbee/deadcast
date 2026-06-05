# Decrypt Box Risk Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the decrypt box's guaranteed 4x payout with a weighted random outcome table.

**Architecture:** Extract outcome rolling into a deterministic `_roll_decrypt_outcome(roll: float)` helper on GameState, called with `randf()` at payout time. Store last outcome and payout for display. Update DecryptBox UI to show uncertainty during decryption and results after.

**Tech Stack:** GDScript 4, Godot 4.6, GUT test framework

---

### Task 1: Add outcome rolling to GameState

**Files:**
- Modify: `autoload/GameState.gd`
- Test: `tests/test_decrypt_box.gd` (create)

- [ ] **Step 1: Create test file with failing tests for `_roll_decrypt_outcome`**

Create `tests/test_decrypt_box.gd`:

```gdscript
# tests/test_decrypt_box.gd
extends GutTest

func before_each() -> void:
	GameState.credits = 50000
	GameState.debt = 80000
	GameState.run_count = 0
	GameState.runs_since_payment = 0
	GameState.pressure_level = 0
	GameState.rod_damaged = false
	GameState.decrypt_box_queue = 0
	GameState.decrypt_box_runs = 0
	GameState.decrypt_last_outcome = ""
	GameState.decrypt_last_payout = 0
	GameState.freezer_value = 0
	GameState.freezer_runs = 0

func test_roll_returns_corruption_at_low_roll() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.0)
	assert_eq(outcome.id, "corruption")

func test_roll_returns_corruption_just_before_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.199)
	assert_eq(outcome.id, "corruption")

func test_roll_returns_partial_at_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.20)
	assert_eq(outcome.id, "partial")

func test_roll_returns_partial_before_clean_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.549)
	assert_eq(outcome.id, "partial")

func test_roll_returns_clean_at_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.55)
	assert_eq(outcome.id, "clean")

func test_roll_returns_clean_before_anomaly_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.899)
	assert_eq(outcome.id, "clean")

func test_roll_returns_anomaly_at_boundary() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.90)
	assert_eq(outcome.id, "anomaly")

func test_roll_returns_anomaly_at_max() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.999)
	assert_eq(outcome.id, "anomaly")

func test_outcome_has_required_fields() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.5)
	assert_true(outcome.has("id"))
	assert_true(outcome.has("label"))
	assert_true(outcome.has("multiplier"))

func test_corruption_multiplier_is_zero() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.0)
	assert_eq(outcome.multiplier, 0.0)

func test_anomaly_multiplier_is_six() -> void:
	var outcome = GameState._roll_decrypt_outcome(0.90)
	assert_eq(outcome.multiplier, 6.0)
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /Users/toby/code/deadcast && godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_decrypt_box.gd 2>&1 | tail -20
```

Expected: errors — `_roll_decrypt_outcome` not defined, `decrypt_last_outcome` not defined.

- [ ] **Step 3: Add outcome table and `_roll_decrypt_outcome` to GameState**

In `autoload/GameState.gd`, replace:

```gdscript
const DECRYPT_MULTIPLIER: int = 4
```

With:

```gdscript
const DECRYPT_OUTCOMES: Array = [
	{"id": "corruption", "label": "[CORRUPTION_DETECTED]", "multiplier": 0.0,  "weight": 0.20},
	{"id": "partial",    "label": "[PARTIAL_DECRYPT]",     "multiplier": 1.5,  "weight": 0.35},
	{"id": "clean",      "label": "[DECRYPT_COMPLETE]",    "multiplier": 4.0,  "weight": 0.35},
	{"id": "anomaly",    "label": "[ANOMALY_DETECTED]",    "multiplier": 6.0,  "weight": 0.10},
]
```

Add these vars in the `# Decrypt Box` section:

```gdscript
var decrypt_last_outcome: String = ""
var decrypt_last_payout: int = 0
```

Add this method anywhere after the existing decrypt-related code:

```gdscript
func _roll_decrypt_outcome(roll: float) -> Dictionary:
	var cumulative: float = 0.0
	for outcome in DECRYPT_OUTCOMES:
		cumulative += outcome.weight
		if roll < cumulative:
			return outcome
	return DECRYPT_OUTCOMES[-1]
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /Users/toby/code/deadcast && godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_decrypt_box.gd 2>&1 | tail -20
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add autoload/GameState.gd tests/test_decrypt_box.gd
git commit -m "feat: add decrypt outcome table and roll helper"
```

---

### Task 2: Wire outcome roll into payout and persistence

**Files:**
- Modify: `autoload/GameState.gd`
- Modify: `tests/test_decrypt_box.gd`
- Modify: `tests/test_debt_clock.gd`

- [ ] **Step 1: Add payout and persistence tests to test_decrypt_box.gd**

Append to `tests/test_decrypt_box.gd`:

```gdscript
func test_decrypt_payout_clears_queue() -> void:
	GameState.decrypt_box_queue = 1000
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.decrypt_box_queue, 0)

func test_decrypt_payout_sets_last_outcome() -> void:
	GameState.decrypt_box_queue = 1000
	for i in 3:
		GameState.on_run_complete(false, 0)
	var valid_ids = ["corruption", "partial", "clean", "anomaly"]
	assert_true(GameState.decrypt_last_outcome in valid_ids)

func test_decrypt_payout_sets_last_payout() -> void:
	GameState.decrypt_box_queue = 1000
	for i in 3:
		GameState.on_run_complete(false, 0)
	# Valid payouts: 0, 1500, 4000, 6000
	var valid_payouts = [0, 1500, 4000, 6000]
	assert_true(GameState.decrypt_last_payout in valid_payouts)

func test_decrypt_last_outcome_saved_and_loaded() -> void:
	GameState.decrypt_last_outcome = "anomaly"
	GameState.decrypt_last_payout = 6000
	GameState._save_to("user://save_test.cfg")
	GameState.decrypt_last_outcome = ""
	GameState.decrypt_last_payout = 0
	GameState._load_from("user://save_test.cfg")
	assert_eq(GameState.decrypt_last_outcome, "anomaly")
	assert_eq(GameState.decrypt_last_payout, 6000)

func test_new_game_resets_decrypt_last_outcome() -> void:
	GameState.decrypt_last_outcome = "clean"
	GameState.decrypt_last_payout = 4000
	GameState.new_game()
	assert_eq(GameState.decrypt_last_outcome, "")
	assert_eq(GameState.decrypt_last_payout, 0)

func after_each() -> void:
	DirAccess.remove_absolute("user://save_test.cfg")
```

- [ ] **Step 2: Run new tests to confirm they fail**

```bash
cd /Users/toby/code/deadcast && godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_decrypt_box.gd 2>&1 | tail -20
```

Expected: payout/persistence tests fail — still using old multiplier logic.

- [ ] **Step 3: Replace fixed payout with outcome roll in `on_run_complete`**

In `autoload/GameState.gd`, find:

```gdscript
		if decrypt_box_runs >= DECRYPT_THRESHOLD:
			add_credits(decrypt_box_queue * DECRYPT_MULTIPLIER)
			decrypt_box_queue = 0
			decrypt_box_runs = 0
```

Replace with:

```gdscript
		if decrypt_box_runs >= DECRYPT_THRESHOLD:
			var outcome = _roll_decrypt_outcome(randf())
			decrypt_last_payout = int(decrypt_box_queue * outcome.multiplier)
			decrypt_last_outcome = outcome.id
			add_credits(decrypt_last_payout)
			decrypt_box_queue = 0
			decrypt_box_runs = 0
```

- [ ] **Step 4: Add persistence for `decrypt_last_outcome` and `decrypt_last_payout`**

In `_save_to`, in the `# decrypt` section, add:

```gdscript
	cfg.set_value("decrypt", "last_outcome", decrypt_last_outcome)
	cfg.set_value("decrypt", "last_payout", decrypt_last_payout)
```

In `_load_from`, after the existing decrypt lines, add:

```gdscript
	decrypt_last_outcome = cfg.get_value("decrypt", "last_outcome", "")
	decrypt_last_payout = cfg.get_value("decrypt", "last_payout", 0)
```

In `new_game()`, add:

```gdscript
	decrypt_last_outcome = ""
	decrypt_last_payout = 0
```

- [ ] **Step 5: Update the existing decrypt test in `test_debt_clock.gd`**

Find and replace `test_decrypt_box_multiplies_after_3_runs`:

```gdscript
func test_decrypt_box_pays_out_after_3_runs() -> void:
	GameState.decrypt_box_queue = 1000
	GameState.decrypt_box_runs = 0
	var credits_before = GameState.credits
	for i in 3:
		GameState.on_run_complete(false, 0)
	assert_eq(GameState.decrypt_box_queue, 0, "Queue should be cleared after payout")
	assert_true(GameState.credits != credits_before or GameState.decrypt_last_outcome == "corruption",
		"Credits should change unless corruption outcome")
```

- [ ] **Step 6: Run all tests**

```bash
cd /Users/toby/code/deadcast && godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/ 2>&1 | tail -30
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add autoload/GameState.gd tests/test_decrypt_box.gd tests/test_debt_clock.gd
git commit -m "feat: wire randomised outcome into decrypt box payout"
```

---

### Task 3: Update DecryptBox UI

**Files:**
- Modify: `scenes/barge_hub/DecryptBox.gd`

No new tests needed — UI display is trivial string formatting, covered by manual verification.

- [ ] **Step 1: Update the in-progress status to show `→ ?`**

In `scenes/barge_hub/DecryptBox.gd`, find `_refresh()` and replace the status line that references `DECRYPT_MULTIPLIER`:

```gdscript
		var runs_left = GameState.DECRYPT_THRESHOLD - GameState.decrypt_box_runs
		status_label.text = "queued: %dcr\ndecrypts in %d run%s → %dcr" % [
			GameState.decrypt_box_queue,
			runs_left,
			"s" if runs_left != 1 else "",
			GameState.decrypt_box_queue * GameState.DECRYPT_MULTIPLIER
		]
```

With:

```gdscript
		var runs_left = GameState.DECRYPT_THRESHOLD - GameState.decrypt_box_runs
		status_label.text = "queued: %dcr\ndecrypts in %d run%s → ?" % [
			GameState.decrypt_box_queue,
			runs_left,
			"s" if runs_left != 1 else "",
		]
```

- [ ] **Step 2: Update the empty-box status to show last result and disclaimer**

In `_refresh()`, replace the empty-box branch:

```gdscript
	if GameState.decrypt_box_queue == 0:
		status_label.text = "box is empty.\nload credits to decrypt at 4x after %d runs." % GameState.DECRYPT_THRESHOLD
```

With:

```gdscript
	if GameState.decrypt_box_queue == 0:
		var last := ""
		if GameState.decrypt_last_outcome != "":
			var outcome_label := GameState.decrypt_last_outcome
			for o in GameState.DECRYPT_OUTCOMES:
				if o.id == GameState.decrypt_last_outcome:
					outcome_label = o.label
					break
			last = "\nlast result: %s → %dcr" % [outcome_label, GameState.decrypt_last_payout]
		status_label.text = "box is empty.%s\ndata integrity not guaranteed.\nload credits to decrypt after %d runs." % [
			last, GameState.DECRYPT_THRESHOLD]
```

- [ ] **Step 3: Verify manually**

Run the game and check:
- Empty box with no history: shows `"box is empty.\ndata integrity not guaranteed.\nload credits to decrypt after 3 runs."`
- Load 1000cr: button disabled, status shows `"queued: 1000cr\ndecrypts in 3 runs → ?"`
- After 3 runs: status shows `"box is empty.\nlast result: [DECRYPT_COMPLETE] → 4000cr\ndata integrity not guaranteed.\n..."`

- [ ] **Step 4: Commit**

```bash
git add scenes/barge_hub/DecryptBox.gd
git commit -m "feat: update decrypt box UI for randomised outcomes"
```

---

### Task 4: Open PR

- [ ] **Step 1: Push branch and open draft PR**

```bash
git push -u origin feat/decrypt-box-risk
gh pr create --repo Teeohbee/deadcast \
  --title "feat: randomised decrypt box outcomes" \
  --body "Replaces guaranteed 4x decrypt payout with a weighted outcome table. 0x/1.5x/4x/6x outcomes at 20/35/35/10% weights. Expected value ~2.3x — it's a genuine gamble now." \
  --draft
```
