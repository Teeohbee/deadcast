# Catch Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 10 new catches to each zone (District 7, Exchange, Axiom), expanding each from 5 to 15 catches via `.tres` resource files only — no code changes required.

**Architecture:** All catch data lives in `.tres` resource files. Each catch is a `CatchData` resource referencing `CatchOption` resources. Zone data is in `resources/zones/{zone}.tres` as an array of `CatchData` references. Adding a catch = create the `.tres` files + add the reference to the zone array.

**Tech Stack:** Godot 4, GDScript resource format (.tres). GUT framework for regression testing.

**Spec:** `docs/superpowers/specs/2026-06-05-catch-expansion-design.md`

---

## Enum Reference

These integer values map to GDScript enums in `catch_data.gd`:

| Field | Name | Value |
|---|---|---|
| catch_type | DATA | 0 |
| catch_type | BIO | 1 |
| catch_type | MECH | 2 |
| catch_type | ENTITY | 3 |
| behavior | PASSIVE | 0 |
| behavior | RESISTANT | 1 |
| behavior | AGGRESSIVE | 2 |
| behavior | NEGOTIATING | 3 |
| layer | SHALLOWS | 0 |
| layer | MID | 1 |
| layer | DEEP | 2 |

---

## .tres Format Templates

These templates are used throughout the plan. The `load_steps` value = 1 + number of `ext_resource` entries in the file.

**Catch — PASSIVE or RESISTANT or NEGOTIATING (3 options, load_steps=5):**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=5 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/{zone}/opt_{slug}_a.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/{zone}/opt_{slug}_b.tres" id="3_opt2"]
[ext_resource type="Resource" path="res://resources/catches/{zone}/opt_{slug}_c.tres" id="4_opt3"]

[resource]
script = ExtResource("1_data")
catch_name = "Display Name"
catch_type = {0|1|2|3}
behavior = {0|1|3}
corruption_gain = {int}
options = [ExtResource("2_opt1"), ExtResource("3_opt2"), ExtResource("4_opt3")]
flavor_text = "One sentence. Lowercase. Terminal voice."
layer = {0|1|2}
```

**Catch — PASSIVE or RESISTANT or NEGOTIATING (2 options, load_steps=4):**

Same as above but with one fewer `ext_resource` entry and `load_steps=4`, `options` array has 2 entries.

**Catch — AGGRESSIVE (1 reward option, load_steps=3):**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=3 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/{zone}/opt_{slug}_reward.tres" id="2_opt1"]

[resource]
script = ExtResource("1_data")
catch_name = "Display Name"
catch_type = {2|3}
behavior = 2
corruption_gain = {int}
options = [ExtResource("2_opt1")]
flavor_text = "One sentence. Lowercase. Terminal voice."
layer = 2
anchor_strength = {int}
```

**Option — PASSIVE (no risk):**

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Action Label"
tension_delta = {int}
credit_value = {int}
cuts_line = false
flavor_text = "Short flavour. Lowercase."
```

**Option — RESISTANT (with resist_chance):**

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Action Label"
tension_delta = {int}
credit_value = {int}
cuts_line = false
flavor_text = "Short flavour. Lowercase."
resist_chance = {float}
resist_tension_penalty = {int}
```

**Option — NEGOTIATING (with fail_chance):**

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Action Label"
tension_delta = {int}
credit_value = {int}
cuts_line = false
flavor_text = "Short flavour. Lowercase."
fail_chance = {float}
fail_tension_delta = {int}
fail_credit_value = {int}
```

**Option — AGGRESSIVE reward (only credit_value matters; not shown to player):**

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "reward"
tension_delta = 0
credit_value = {int}
cuts_line = false
flavor_text = ""
```

### Style Guide

- `catch_name`: Title Case. Use ` — ` (em-dash with spaces) for entity sub-designations (e.g. `"Feral Building AI — Block 14C"`).
- `flavor_text` on catches: one sentence, lowercase, present tense, spare. No punctuation that reads as a UI label.
- Option `label`: 1-4 words, title case, verb-led ("Reel In", "Brute Decrypt", "Leave It").
- Option `flavor_text`: one short phrase reinforcing the risk or outcome. Lowercase.
- Zone tones: District 7 = civilian grief, restraint; Exchange = mercenary, transactional; Axiom = corporate hostility, threat.
- Do **not** add `zone_weights` or `stamina` fields — they are dead code and absent from `catch_data.gd`.

---

## File Map

### District 7 — new files

| File | Type |
|---|---|
| `resources/catches/district7/residential_data_cluster.tres` | Create |
| `resources/catches/district7/opt_resdata_reel.tres` | Create |
| `resources/catches/district7/opt_resdata_skim.tres` | Create |
| `resources/catches/district7/opt_resdata_release.tres` | Create |
| `resources/catches/district7/emergency_medical_cache.tres` | Create |
| `resources/catches/district7/opt_medcache_haul.tres` | Create |
| `resources/catches/district7/opt_medcache_sample.tres` | Create |
| `resources/catches/district7/opt_medcache_leave.tres` | Create |
| `resources/catches/district7/ghost_loop.tres` | Create |
| `resources/catches/district7/opt_ghostloop_record.tres` | Create |
| `resources/catches/district7/opt_ghostloop_pass.tres` | Create |
| `resources/catches/district7/witness_archive.tres` | Create |
| `resources/catches/district7/opt_witness_reel.tres` | Create |
| `resources/catches/district7/opt_witness_partial.tres` | Create |
| `resources/catches/district7/opt_witness_release.tres` | Create |
| `resources/catches/district7/drowned_resident_echo.tres` | Create |
| `resources/catches/district7/opt_drownedecho_talk.tres` | Create |
| `resources/catches/district7/opt_drownedecho_pull.tres` | Create |
| `resources/catches/district7/opt_drownedecho_release.tres` | Create |
| `resources/catches/district7/encrypted_pension_record.tres` | Create |
| `resources/catches/district7/opt_pension_brute.tres` | Create |
| `resources/catches/district7/opt_pension_careful.tres` | Create |
| `resources/catches/district7/opt_pension_release.tres` | Create |
| `resources/catches/district7/contraband_bio_stash.tres` | Create |
| `resources/catches/district7/opt_biostash_negotiate.tres` | Create |
| `resources/catches/district7/opt_biostash_force.tres` | Create |
| `resources/catches/district7/opt_biostash_leave.tres` | Create |
| `resources/catches/district7/buried_blacksite_fragment.tres` | Create |
| `resources/catches/district7/opt_blacksite_haul.tres` | Create |
| `resources/catches/district7/opt_blacksite_careful.tres` | Create |
| `resources/catches/district7/opt_blacksite_release.tres` | Create |
| `resources/catches/district7/feral_building_ai.tres` | Create |
| `resources/catches/district7/opt_feralai_reward.tres` | Create |
| `resources/catches/district7/ghost_swarm.tres` | Create |
| `resources/catches/district7/opt_ghostswarm_reward.tres` | Create |
| `resources/zones/district7.tres` | Modify |

### Exchange — new files

| File | Type |
|---|---|
| `resources/catches/exchange/unclaimed_cargo_manifest.tres` | Create |
| `resources/catches/exchange/opt_cargo_download.tres` | Create |
| `resources/catches/exchange/opt_cargo_quick.tres` | Create |
| `resources/catches/exchange/opt_cargo_leave.tres` | Create |
| `resources/catches/exchange/factory_sealed_bioware.tres` | Create |
| `resources/catches/exchange/opt_factbio_bag.tres` | Create |
| `resources/catches/exchange/opt_factbio_sample.tres` | Create |
| `resources/catches/exchange/opt_factbio_leave.tres` | Create |
| `resources/catches/exchange/classified_shipment_log.tres` | Create |
| `resources/catches/exchange/opt_shiplog_intercept.tres` | Create |
| `resources/catches/exchange/opt_shiplog_partial.tres` | Create |
| `resources/catches/exchange/opt_shiplog_leave.tres` | Create |
| `resources/catches/exchange/black_market_surgeons_archive.tres` | Create |
| `resources/catches/exchange/opt_surgeon_full.tres` | Create |
| `resources/catches/exchange/opt_surgeon_selective.tres` | Create |
| `resources/catches/exchange/opt_surgeon_leave.tres` | Create |
| `resources/catches/exchange/stolen_corporate_prototype.tres` | Create |
| `resources/catches/exchange/opt_prototype_reel.tres` | Create |
| `resources/catches/exchange/opt_prototype_strip.tres` | Create |
| `resources/catches/exchange/opt_prototype_release.tres` | Create |
| `resources/catches/exchange/rival_fishers_hidden_cache.tres` | Create |
| `resources/catches/exchange/opt_rivalcache_disarm.tres` | Create |
| `resources/catches/exchange/opt_rivalcache_careful.tres` | Create |
| `resources/catches/exchange/opt_rivalcache_leave.tres` | Create |
| `resources/catches/exchange/black_market_organ_bank.tres` | Create |
| `resources/catches/exchange/opt_organbank_haul.tres` | Create |
| `resources/catches/exchange/opt_organbank_careful.tres` | Create |
| `resources/catches/exchange/opt_organbank_release.tres` | Create |
| `resources/catches/exchange/exchange_enforcer_ghost.tres` | Create |
| `resources/catches/exchange/opt_enforcerghost_reward.tres` | Create |
| `resources/catches/exchange/exchange_security_drone_mk2.tres` | Create |
| `resources/catches/exchange/opt_exsecdrone_reward.tres` | Create |
| `resources/catches/exchange/rogue_trade_engine.tres` | Create |
| `resources/catches/exchange/opt_tradeengine_reward.tres` | Create |
| `resources/zones/exchange.tres` | Modify |

### Axiom — new files

| File | Type |
|---|---|
| `resources/catches/axiom/decommissioned_surveillance_log.tres` | Create |
| `resources/catches/axiom/opt_survlog_download.tres` | Create |
| `resources/catches/axiom/opt_survlog_selective.tres` | Create |
| `resources/catches/axiom/opt_survlog_leave.tres` | Create |
| `resources/catches/axiom/access_badge_database.tres` | Create |
| `resources/catches/axiom/opt_badgedb_extract.tres` | Create |
| `resources/catches/axiom/opt_badgedb_partial.tres` | Create |
| `resources/catches/axiom/opt_badgedb_release.tres` | Create |
| `resources/catches/axiom/biohazard_sample_container.tres` | Create |
| `resources/catches/axiom/opt_biohazard_bag.tres` | Create |
| `resources/catches/axiom/opt_biohazard_seal.tres` | Create |
| `resources/catches/axiom/opt_biohazard_leave.tres` | Create |
| `resources/catches/axiom/corporate_ghost.tres` | Create |
| `resources/catches/axiom/opt_corpghost_talk.tres` | Create |
| `resources/catches/axiom/opt_corpghost_extract.tres` | Create |
| `resources/catches/axiom/opt_corpghost_ignore.tres` | Create |
| `resources/catches/axiom/classified_research_archive.tres` | Create |
| `resources/catches/axiom/opt_research_force.tres` | Create |
| `resources/catches/axiom/opt_research_partial.tres` | Create |
| `resources/catches/axiom/opt_research_release.tres` | Create |
| `resources/catches/axiom/executive_memory_core.tres` | Create |
| `resources/catches/axiom/opt_execcore_full.tres` | Create |
| `resources/catches/axiom/opt_execcore_selective.tres` | Create |
| `resources/catches/axiom/opt_execcore_release.tres` | Create |
| `resources/catches/axiom/axiom_security_drone_mk5.tres` | Create |
| `resources/catches/axiom/opt_axiommkv_reward.tres` | Create |
| `resources/catches/axiom/axiom_defense_ai.tres` | Create |
| `resources/catches/axiom/opt_defenseai_reward.tres` | Create |
| `resources/catches/axiom/viral_intrusion_payload.tres` | Create |
| `resources/catches/axiom/opt_viralpayload_reward.tres` | Create |
| `resources/catches/axiom/axiom_cleaner_protocol.tres` | Create |
| `resources/catches/axiom/opt_cleanerprotocol_reward.tres` | Create |
| `resources/zones/axiom.tres` | Modify |

---

## Task 1: District 7 — Shallows (2 PASSIVE catches)

**Files:**
- Create: `resources/catches/district7/residential_data_cluster.tres` + 3 opts
- Create: `resources/catches/district7/emergency_medical_cache.tres` + 3 opts

- [ ] **Step 1: Create residential_data_cluster.tres**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=5 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_resdata_reel.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_resdata_skim.tres" id="3_opt2"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_resdata_release.tres" id="4_opt3"]

[resource]
script = ExtResource("1_data")
catch_name = "Residential Data Cluster"
catch_type = 0
behavior = 0
corruption_gain = 5
options = [ExtResource("2_opt1"), ExtResource("3_opt2"), ExtResource("4_opt3")]
flavor_text = "{generate: someone's complete personal archive. mundane life made data. nothing illicit.}"
layer = 0
```

- [ ] **Step 2: Create option files for residential_data_cluster**

`opt_resdata_reel.tres` — PASSIVE, no risk:
```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Reel In"
tension_delta = 5
credit_value = 300
cuts_line = false
flavor_text = "{generate: full extraction, all the boring details}"
```

`opt_resdata_skim.tres` — PASSIVE, safer option:
```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Quick Scan"
tension_delta = 0
credit_value = 150
cuts_line = false
flavor_text = "{generate: surface data only, less tension}"
```

`opt_resdata_release.tres` — PASSIVE, no reward:
```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "Leave It"
tension_delta = 0
credit_value = 0
cuts_line = false
flavor_text = "{generate: let it sink back down}"
```

- [ ] **Step 3: Create emergency_medical_cache.tres and its 3 option files**

Catch properties: `catch_name = "Emergency Medical Cache"`, `catch_type = 1` (BIO), `behavior = 0` (PASSIVE), `corruption_gain = 0`, `layer = 0`

| Option file | label | tension_delta | credit_value | flavor_text hint |
|---|---|---|---|---|
| `opt_medcache_haul.tres` | Bag It | 5 | 350 | haul the whole thing, pharmaceuticals intact |
| `opt_medcache_sample.tres` | Take a Sample | 0 | 150 | pull a sample, leave the rest |
| `opt_medcache_leave.tres` | Leave It | 0 | 0 | sealed clinic supplies, not your problem |

All options: `cuts_line = false`, no resist/fail fields.

- [ ] **Step 4: Commit**

```
git add resources/catches/district7/
git commit -m "feat: add District 7 shallows catches (residential data, medical cache)"
```

---

## Task 2: District 7 — Mid (1 PASSIVE, 2 NEGOTIATING, 1 RESISTANT)

**Files:**
- Create: `ghost_loop.tres` + 2 opts
- Create: `witness_archive.tres` + 3 opts
- Create: `drowned_resident_echo.tres` + 3 opts
- Create: `encrypted_pension_record.tres` + 3 opts

All files in `resources/catches/district7/`.

- [ ] **Step 1: Create ghost_loop.tres (PASSIVE ENTITY, 2 options, load_steps=4)**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=4 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_ghostloop_record.tres" id="2_opt1"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_ghostloop_pass.tres" id="3_opt2"]

[resource]
script = ExtResource("1_data")
catch_name = "Ghost Loop"
catch_type = 3
behavior = 0
corruption_gain = 10
options = [ExtResource("2_opt1"), ExtResource("3_opt2")]
flavor_text = "{generate: a repeating moment. not a person anymore. just a gesture on a loop.}"
layer = 1
```

| Option file | label | tension_delta | credit_value | hint |
|---|---|---|---|---|
| `opt_ghostloop_record.tres` | Record Fragment | 0 | 250 | capture the loop as data |
| `opt_ghostloop_pass.tres` | Move On | 0 | 0 | leave it repeating |

- [ ] **Step 2: Create witness_archive.tres (NEGOTIATING DATA)**

Catch: `catch_name = "Witness Archive"`, `catch_type = 0`, `behavior = 3`, `corruption_gain = 5`, `layer = 1`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | fail_chance | fail_tension_delta | fail_credit_value | hint |
|---|---|---|---|---|---|---|---|
| `opt_witness_reel.tres` | Full Extraction | 15 | 600 | 0.35 | 25 | 0 | someone alive will notice |
| `opt_witness_partial.tres` | Selective Copy | 5 | 200 | 0.0 | — | — | cherry-pick the safe parts |
| `opt_witness_release.tres` | Drop It | 0 | 0 | 0.0 | — | — | let the dead keep their secrets |

For `opt_witness_partial.tres` and `opt_witness_release.tres`: omit `fail_chance`, `fail_tension_delta`, `fail_credit_value` fields (PASSIVE options within a NEGOTIATING catch don't need them — only options where `fail_chance > 0` need those fields).

- [ ] **Step 3: Create drowned_resident_echo.tres (NEGOTIATING ENTITY)**

Catch: `catch_name = "Drowned Resident Echo"`, `catch_type = 3`, `behavior = 3`, `corruption_gain = 15`, `layer = 1`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | fail_chance | fail_tension_delta | fail_credit_value | hint |
|---|---|---|---|---|---|---|---|
| `opt_drownedecho_talk.tres` | Talk It Down | 0 | 350 | 0.4 | 20 | 0 | negotiate with something that doesn't want to go |
| `opt_drownedecho_pull.tres` | Reel It In | 15 | 450 | 0.0 | — | — | force it up, no negotiation |
| `opt_drownedecho_release.tres` | Let It Go | 0 | 0 | 0.0 | — | — | honour the refusal |

- [ ] **Step 4: Create encrypted_pension_record.tres (RESISTANT DATA)**

Catch: `catch_name = "Encrypted Pension Record"`, `catch_type = 0`, `behavior = 1`, `corruption_gain = 5`, `layer = 1`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | resist_chance | resist_tension_penalty | hint |
|---|---|---|---|---|---|---|
| `opt_pension_brute.tres` | Brute Decrypt | 15 | 550 | 0.45 | 35 | corporate encryption, may bounce back |
| `opt_pension_careful.tres` | Careful Crack | 5 | 200 | 0.2 | 15 | slower, lower risk |
| `opt_pension_release.tres` | Leave It | 0 | 0 | 0.0 | — | someone's retirement, none of your business |

For options with `resist_chance = 0.0`, omit the `resist_chance` and `resist_tension_penalty` fields.

- [ ] **Step 5: Commit**

```
git add resources/catches/district7/
git commit -m "feat: add District 7 mid catches (ghost loop, witness archive, resident echo, pension record)"
```

---

## Task 3: District 7 — Deep (1 NEGOTIATING, 1 RESISTANT, 2 AGGRESSIVE)

**Files:** All in `resources/catches/district7/`

- [ ] **Step 1: Create contraband_bio_stash.tres (NEGOTIATING BIO)**

Catch: `catch_name = "Contraband Bio-Stash"`, `catch_type = 1`, `behavior = 3`, `corruption_gain = 10`, `layer = 2`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | fail_chance | fail_tension_delta | fail_credit_value | hint |
|---|---|---|---|---|---|---|---|
| `opt_biostash_negotiate.tres` | Negotiate Access | 10 | 800 | 0.3 | 25 | 0 | whoever hid this set a tripwire |
| `opt_biostash_force.tres` | Force It Open | 20 | 500 | 0.0 | — | — | guaranteed yield, messy |
| `opt_biostash_leave.tres` | Leave It | 0 | 0 | 0.0 | — | — | not worth the risk |

- [ ] **Step 2: Create buried_blacksite_fragment.tres (RESISTANT BIO)**

Catch: `catch_name = "Buried Blacksite Fragment"`, `catch_type = 1`, `behavior = 1`, `corruption_gain = 20`, `layer = 2`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | resist_chance | resist_tension_penalty | hint |
|---|---|---|---|---|---|---|
| `opt_blacksite_haul.tres` | Reel It Up | 20 | 900 | 0.5 | 40 | whatever this is, it doesn't want to surface |
| `opt_blacksite_careful.tres` | Careful Extraction | 10 | 500 | 0.25 | 25 | slower, still risky |
| `opt_blacksite_release.tres` | Leave It | 0 | 0 | 0.0 | — | some things stay buried |

- [ ] **Step 3: Create feral_building_ai.tres (AGGRESSIVE MECH, anchor 2)**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=3 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/district7/opt_feralai_reward.tres" id="2_opt1"]

[resource]
script = ExtResource("1_data")
catch_name = "Feral Building AI — Block 14C"
catch_type = 2
behavior = 2
corruption_gain = 15
options = [ExtResource("2_opt1")]
flavor_text = "{generate: residential management AI. 40 years alone. it thinks you're an intruder.}"
layer = 2
anchor_strength = 2
```

`opt_feralai_reward.tres` (reward option, credit_value only matters):

```
[gd_resource type="Resource" script_class="CatchOption" load_steps=2 format=3]

[ext_resource type="Script" path="res://resources/catch_option.gd" id="1_opt"]

[resource]
script = ExtResource("1_opt")
label = "reward"
tension_delta = 0
credit_value = 800
cuts_line = false
flavor_text = ""
```

- [ ] **Step 4: Create ghost_swarm.tres (AGGRESSIVE ENTITY, anchor 2)**

Catch: `catch_name = "Ghost Swarm"`, `catch_type = 3`, `behavior = 2`, `corruption_gain = 25`, `layer = 2`, `anchor_strength = 2`, `load_steps = 3`

Reward option `opt_ghostswarm_reward.tres`: `credit_value = 900`

Flavor hint: multiple ghost fragments merged into something that is no longer individual or coherent.

- [ ] **Step 5: Commit**

```
git add resources/catches/district7/
git commit -m "feat: add District 7 deep catches (bio-stash, blacksite, feral AI, ghost swarm)"
```

---

## Task 4: Exchange — Shallows (2 PASSIVE catches)

**Files:** All in `resources/catches/exchange/`

- [ ] **Step 1: Create unclaimed_cargo_manifest.tres (PASSIVE DATA)**

Catch: `catch_name = "Unclaimed Cargo Manifest"`, `catch_type = 0`, `behavior = 0`, `corruption_gain = 5`, `layer = 0`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | hint |
|---|---|---|---|---|
| `opt_cargo_download.tres` | Download All | 5 | 500 | full manifest, everything that passed through |
| `opt_cargo_quick.tres` | Quick Copy | 0 | 250 | surface entries only |
| `opt_cargo_leave.tres` | Leave It | 0 | 0 | someone else's lost shipment |

- [ ] **Step 2: Create factory_sealed_bioware.tres (PASSIVE BIO)**

Catch: `catch_name = "Factory-Sealed Bioware"`, `catch_type = 1`, `behavior = 0`, `corruption_gain = 0`, `layer = 0`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | hint |
|---|---|---|---|---|
| `opt_factbio_bag.tres` | Bag It | 5 | 550 | factory sterile, still viable |
| `opt_factbio_sample.tres` | Sample Only | 0 | 250 | break the seal, take a fraction |
| `opt_factbio_leave.tres` | Leave It | 0 | 0 | not worth the bag space |

- [ ] **Step 3: Commit**

```
git add resources/catches/exchange/
git commit -m "feat: add Exchange shallows catches (cargo manifest, factory bioware)"
```

---

## Task 5: Exchange — Mid (2 NEGOTIATING, 1 RESISTANT)

**Files:** All in `resources/catches/exchange/`

- [ ] **Step 1: Create classified_shipment_log.tres (NEGOTIATING DATA)**

Catch: `catch_name = "Classified Shipment Log"`, `catch_type = 0`, `behavior = 3`, `corruption_gain = 10`, `layer = 1`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | fail_chance | fail_tension_delta | fail_credit_value | hint |
|---|---|---|---|---|---|---|---|
| `opt_shiplog_intercept.tres` | Full Intercept | 15 | 900 | 0.35 | 30 | 0 | multiple parties want this gone |
| `opt_shiplog_partial.tres` | Partial Copy | 5 | 350 | 0.0 | — | — | safer subset |
| `opt_shiplog_leave.tres` | Leave It | 0 | 0 | 0.0 | — | — | someone's ledger, not your war |

- [ ] **Step 2: Create black_market_surgeons_archive.tres (NEGOTIATING DATA)**

Catch: `catch_name = "Black Market Surgeon's Archive"`, `catch_type = 0`, `behavior = 3`, `corruption_gain = 10`, `layer = 1`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | fail_chance | fail_tension_delta | fail_credit_value | hint |
|---|---|---|---|---|---|---|---|
| `opt_surgeon_full.tres` | Full Extraction | 15 | 850 | 0.4 | 25 | 0 | deadman protocol on the outer layer |
| `opt_surgeon_selective.tres` | Selective Copy | 5 | 300 | 0.0 | — | — | skip the trigger fields |
| `opt_surgeon_leave.tres` | Leave It | 0 | 0 | 0.0 | — | — | clients paid for privacy, apparently |

- [ ] **Step 3: Create stolen_corporate_prototype.tres (RESISTANT MECH)**

Catch: `catch_name = "Stolen Corporate Prototype"`, `catch_type = 2`, `behavior = 1`, `corruption_gain = 15`, `layer = 1`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | resist_chance | resist_tension_penalty | hint |
|---|---|---|---|---|---|---|
| `opt_prototype_reel.tres` | Reel It In | 20 | 1000 | 0.45 | 40 | axiom logo. it has opinions about being moved. |
| `opt_prototype_strip.tres` | Strip Components | 10 | 500 | 0.25 | 20 | salvage the accessible parts |
| `opt_prototype_release.tres` | Leave It | 0 | 0 | 0.0 | — | axiom's problem, not yours |

- [ ] **Step 4: Commit**

```
git add resources/catches/exchange/
git commit -m "feat: add Exchange mid catches (shipment log, surgeon archive, axiom prototype)"
```

---

## Task 6: Exchange — Deep (1 NEGOTIATING, 1 RESISTANT, 3 AGGRESSIVE)

**Files:** All in `resources/catches/exchange/`

- [ ] **Step 1: Create rival_fishers_hidden_cache.tres (NEGOTIATING BIO)**

Catch: `catch_name = "Rival Fisher's Hidden Cache"`, `catch_type = 1`, `behavior = 3`, `corruption_gain = 10`, `layer = 2`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | fail_chance | fail_tension_delta | fail_credit_value | hint |
|---|---|---|---|---|---|---|---|
| `opt_rivalcache_disarm.tres` | Disarm and Take | 15 | 1200 | 0.45 | 35 | 0 | they set a trap. you noticed. maybe. |
| `opt_rivalcache_careful.tres` | Take Carefully | 10 | 700 | 0.2 | 20 | 0 | slower, better odds |
| `opt_rivalcache_leave.tres` | Leave It | 0 | 0 | 0.0 | — | — | someone else's stash stays someone else's |

- [ ] **Step 2: Create black_market_organ_bank.tres (RESISTANT BIO)**

Catch: `catch_name = "Black Market Organ Bank"`, `catch_type = 1`, `behavior = 1`, `corruption_gain = 15`, `layer = 2`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | resist_chance | resist_tension_penalty | hint |
|---|---|---|---|---|---|---|
| `opt_organbank_haul.tres` | Full Haul | 20 | 1500 | 0.5 | 40 | preserved biological material. wants to stay preserved. |
| `opt_organbank_careful.tres` | Careful Extraction | 10 | 800 | 0.25 | 25 | less yield, less fight |
| `opt_organbank_release.tres` | Release | 0 | 0 | 0.0 | — | — |

- [ ] **Step 3: Create exchange_enforcer_ghost.tres (AGGRESSIVE ENTITY, anchor 2)**

Catch: `catch_name = "Exchange Enforcer Ghost"`, `catch_type = 3`, `behavior = 2`, `corruption_gain = 20`, `layer = 2`, `anchor_strength = 2`, `load_steps = 3`

Flavor hint: a mercenary ghost still protecting a client's stash. not ideological. just contracted.

Reward option `opt_enforcerghost_reward.tres`: `credit_value = 1100`

- [ ] **Step 4: Create exchange_security_drone_mk2.tres (AGGRESSIVE MECH, anchor 3)**

Catch: `catch_name = "Exchange Security Drone — Mark II"`, `catch_type = 2`, `behavior = 2`, `corruption_gain = 20`, `layer = 2`, `anchor_strength = 3`, `load_steps = 3`

Flavor hint: black market security hardware. nastier than anything in District 7, less sophisticated than Axiom.

Reward option `opt_exsecdrone_reward.tres`: `credit_value = 1400`

- [ ] **Step 5: Create rogue_trade_engine.tres (AGGRESSIVE MECH, anchor 2)**

Catch: `catch_name = "Rogue Trade Engine"`, `catch_type = 2`, `behavior = 2`, `corruption_gain = 15`, `layer = 2`, `anchor_strength = 2`, `load_steps = 3`

Flavor hint: a defunct automated auction AI that's turned hostile to anyone accessing the Exchange's records. it still thinks there's an open bid.

Reward option `opt_tradeengine_reward.tres`: `credit_value = 1200`

- [ ] **Step 6: Commit**

```
git add resources/catches/exchange/
git commit -m "feat: add Exchange deep catches (rival cache, organ bank, enforcer ghost, drones)"
```

---

## Task 7: Axiom — Shallows (1 PASSIVE, 2 RESISTANT)

**Files:** All in `resources/catches/axiom/`

- [ ] **Step 1: Create decommissioned_surveillance_log.tres (PASSIVE DATA)**

Catch: `catch_name = "Decommissioned Surveillance Log"`, `catch_type = 0`, `behavior = 0`, `corruption_gain = 5`, `layer = 0`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | hint |
|---|---|---|---|---|
| `opt_survlog_download.tres` | Download All | 5 | 700 | years of ambient surveillance. useless to axiom now. |
| `opt_survlog_selective.tres` | Selective Extract | 0 | 350 | pull entries for specific individuals |
| `opt_survlog_leave.tres` | Leave It | 0 | 0 | axiom already knows what's here |

- [ ] **Step 2: Create access_badge_database.tres (RESISTANT DATA)**

Catch: `catch_name = "Access Badge Database"`, `catch_type = 0`, `behavior = 1`, `corruption_gain = 10`, `layer = 0`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | resist_chance | resist_tension_penalty | hint |
|---|---|---|---|---|---|---|
| `opt_badgedb_extract.tres` | Full Extraction | 15 | 700 | 0.4 | 35 | employee credentials. axiom does not want these circulating. |
| `opt_badgedb_partial.tres` | Partial Pull | 5 | 350 | 0.2 | 15 | senior staff only |
| `opt_badgedb_release.tres` | Release | 0 | 0 | 0.0 | — | — |

- [ ] **Step 3: Create biohazard_sample_container.tres (RESISTANT BIO)**

Catch: `catch_name = "Biohazard Sample Container"`, `catch_type = 1`, `behavior = 1`, `corruption_gain = 15`, `layer = 0`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | resist_chance | resist_tension_penalty | hint |
|---|---|---|---|---|---|---|
| `opt_biohazard_bag.tres` | Careful Bag | 15 | 650 | 0.45 | 30 | axiom-branded containment. it does not want to be moved. |
| `opt_biohazard_seal.tres` | Seal and Haul | 5 | 350 | 0.2 | 15 | lower yield, lower fight |
| `opt_biohazard_leave.tres` | Leave It | 0 | 0 | 0.0 | — | whatever's inside can stay inside |

- [ ] **Step 4: Commit**

```
git add resources/catches/axiom/
git commit -m "feat: add Axiom shallows catches (surveillance log, badge database, biohazard sample)"
```

---

## Task 8: Axiom — Mid (1 NEGOTIATING, 1 RESISTANT)

**Files:** All in `resources/catches/axiom/`

- [ ] **Step 1: Create corporate_ghost.tres (NEGOTIATING ENTITY)**

Catch: `catch_name = "Corporate Ghost"`, `catch_type = 3`, `behavior = 3`, `corruption_gain = 15`, `layer = 1`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | fail_chance | fail_tension_delta | fail_credit_value | hint |
|---|---|---|---|---|---|---|---|
| `opt_corpghost_talk.tres` | Gain Its Confidence | 0 | 1000 | 0.4 | 30 | 0 | a mid-level axiom employee. it knows things. it's scared. |
| `opt_corpghost_extract.tres` | Extract Memories | 15 | 700 | 0.0 | — | — | forcible extraction, less yield |
| `opt_corpghost_ignore.tres` | Ignore It | 0 | 0 | 0.0 | — | — | ghosts in axiom know better than to talk |

- [ ] **Step 2: Create classified_research_archive.tres (RESISTANT DATA)**

Catch: `catch_name = "Classified Research Archive"`, `catch_type = 0`, `behavior = 1`, `corruption_gain = 20`, `layer = 1`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | resist_chance | resist_tension_penalty | hint |
|---|---|---|---|---|---|---|
| `opt_research_force.tres` | Force Decrypt | 20 | 1200 | 0.5 | 40 | classified for reasons not documented |
| `opt_research_partial.tres` | Partial Extraction | 10 | 600 | 0.25 | 25 | pull the unencrypted outer layer |
| `opt_research_release.tres` | Leave It | 0 | 0 | 0.0 | — | axiom buried this intentionally |

- [ ] **Step 3: Commit**

```
git add resources/catches/axiom/
git commit -m "feat: add Axiom mid catches (corporate ghost, research archive)"
```

---

## Task 9: Axiom — Deep (1 NEGOTIATING, 4 AGGRESSIVE)

**Files:** All in `resources/catches/axiom/`

- [ ] **Step 1: Create executive_memory_core.tres (NEGOTIATING BIO)**

Catch: `catch_name = "Executive Memory Core"`, `catch_type = 1`, `behavior = 3`, `corruption_gain = 25`, `layer = 2`, `load_steps = 5`

| Option file | label | tension_delta | credit_value | fail_chance | fail_tension_delta | fail_credit_value | hint |
|---|---|---|---|---|---|---|---|
| `opt_execcore_full.tres` | Full Access | 15 | 2500 | 0.5 | 40 | 0 | luxury biological memory backup. accessing it pings axiom security. |
| `opt_execcore_selective.tres` | Selective Pull | 10 | 1200 | 0.2 | 20 | 0 | pull the accessible partitions |
| `opt_execcore_release.tres` | Release | 0 | 0 | 0.0 | — | — | axiom keeps its executives close |

- [ ] **Step 2: Create axiom_security_drone_mk5.tres (AGGRESSIVE MECH, anchor 4)**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=3 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/axiom/opt_axiommkv_reward.tres" id="2_opt1"]

[resource]
script = ExtResource("1_data")
catch_name = "Axiom Security Drone — Mark V"
catch_type = 2
behavior = 2
corruption_gain = 30
options = [ExtResource("2_opt1")]
flavor_text = "{generate: upgraded from the mk iv. significantly more dangerous. still recognises shock lures.}"
layer = 2
anchor_strength = 4
```

Reward option `opt_axiommkv_reward.tres`: `credit_value = 2000`

Note: Shock Lure (OVERLOAD_CORE) works on this catch because `catch_type = 2` (MECH). Same as the existing Mk IV. The Mk V is harder because it's in the deep layer — encounters happen later in the run when corruption is higher, increasing the `threat_multiplier` and therefore backlash per turn.

- [ ] **Step 3: Create axiom_defense_ai.tres (AGGRESSIVE MECH, anchor 4)**

Catch: `catch_name = "Axiom Defense AI"`, `catch_type = 2`, `behavior = 2`, `corruption_gain = 35`, `layer = 2`, `anchor_strength = 4`, `load_steps = 3`

Flavor hint: a dedicated anti-intrusion system, not a repurposed security drone. it was built for this.

Reward option `opt_defenseai_reward.tres`: `credit_value = 2200`

- [ ] **Step 4: Create viral_intrusion_payload.tres (AGGRESSIVE MECH, anchor 3)**

Catch: `catch_name = "Viral Intrusion Payload"`, `catch_type = 2`, `behavior = 2`, `corruption_gain = 25`, `layer = 2`, `anchor_strength = 3`, `load_steps = 3`

Flavor hint: autonomous defense routines. when you hook it, it tries to hook back. manifests as a hostile presence in the terminal.

Reward option `opt_viralpayload_reward.tres`: `credit_value = 1800`

Note: `catch_type = 2` (MECH) so Shock Lure applies.

- [ ] **Step 5: Create axiom_cleaner_protocol.tres (AGGRESSIVE MECH, anchor 5)**

```
[gd_resource type="Resource" script_class="CatchData" load_steps=3 format=3]

[ext_resource type="Script" path="res://resources/catch_data.gd" id="1_data"]
[ext_resource type="Resource" path="res://resources/catches/axiom/opt_cleanerprotocol_reward.tres" id="2_opt1"]

[resource]
script = ExtResource("1_data")
catch_name = "Axiom Cleaner Protocol"
catch_type = 2
behavior = 2
corruption_gain = 40
options = [ExtResource("2_opt1")]
flavor_text = "{generate: axiom deployed this specifically to destroy what you're fishing for. it found you first.}"
layer = 2
anchor_strength = 5
```

Reward option `opt_cleanerprotocol_reward.tres`: `credit_value = 3000`

This is the hardest AGGRESSIVE encounter in the game. Anchor 5 requires 5 DECRYPT_NODE hits minimum. High corruption in deep Axiom means heavy backlash per turn. At 90+ corruption, `threat_multiplier = 1.9`, so each turn's backlash is `round(5 × 1.9) = 10T` before any commands.

- [ ] **Step 6: Commit**

```
git add resources/catches/axiom/
git commit -m "feat: add Axiom deep catches (executive memory core, mk5 drone, defense AI, viral payload, cleaner protocol)"
```

---

## Task 10: Wire all new catches into zone .tres files

**Files:**
- Modify: `resources/zones/district7.tres`
- Modify: `resources/zones/exchange.tres`
- Modify: `resources/zones/axiom.tres`

- [ ] **Step 1: Update resources/zones/district7.tres**

Replace the file with the following (adding all 10 new catches as `ext_resource` entries and appending them to the `catches` array). `load_steps` = 1 + 15 catches = 16.

```
[gd_resource type="Resource" script_class="ZoneData" load_steps=17 format=3]

[ext_resource type="Script" path="res://resources/zone_data.gd" id="1_zone"]
[ext_resource type="Resource" path="res://resources/catches/district7/civilian_ghost_mariana.tres" id="2_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/corrupted_finance_archive.tres" id="3_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/personal_blackmail.tres" id="4_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/salvage_drone.tres" id="5_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/tenant_echo.tres" id="6_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/residential_data_cluster.tres" id="7_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/emergency_medical_cache.tres" id="8_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/ghost_loop.tres" id="9_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/witness_archive.tres" id="10_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/drowned_resident_echo.tres" id="11_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/encrypted_pension_record.tres" id="12_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/contraband_bio_stash.tres" id="13_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/buried_blacksite_fragment.tres" id="14_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/feral_building_ai.tres" id="15_catch"]
[ext_resource type="Resource" path="res://resources/catches/district7/ghost_swarm.tres" id="16_catch"]

[resource]
script = ExtResource("1_zone")
zone_id = "district7"
display_name = "District 7 Ruins"
passive_tension_drain = 0
description = "Residential slums. Civilian ghost encounters, personal data."
catches = [ExtResource("2_catch"), ExtResource("3_catch"), ExtResource("4_catch"), ExtResource("5_catch"), ExtResource("6_catch"), ExtResource("7_catch"), ExtResource("8_catch"), ExtResource("9_catch"), ExtResource("10_catch"), ExtResource("11_catch"), ExtResource("12_catch"), ExtResource("13_catch"), ExtResource("14_catch"), ExtResource("15_catch"), ExtResource("16_catch")]
```

- [ ] **Step 2: Update resources/zones/exchange.tres**

```
[gd_resource type="Resource" script_class="ZoneData" load_steps=17 format=3]

[ext_resource type="Script" path="res://resources/zone_data.gd" id="1_zone"]
[ext_resource type="Resource" path="res://resources/catches/exchange/black_market_shard.tres" id="2_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/contraband_medkit.tres" id="3_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/fixer_network_node.tres" id="4_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/illegal_bioware.tres" id="5_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/rival_fisher_line.tres" id="6_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/unclaimed_cargo_manifest.tres" id="7_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/factory_sealed_bioware.tres" id="8_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/classified_shipment_log.tres" id="9_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/black_market_surgeons_archive.tres" id="10_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/stolen_corporate_prototype.tres" id="11_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/rival_fishers_hidden_cache.tres" id="12_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/black_market_organ_bank.tres" id="13_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/exchange_enforcer_ghost.tres" id="14_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/exchange_security_drone_mk2.tres" id="15_catch"]
[ext_resource type="Resource" path="res://resources/catches/exchange/rogue_trade_engine.tres" id="16_catch"]

[resource]
script = ExtResource("1_zone")
zone_id = "exchange"
display_name = "The Voss Exchange"
passive_tension_drain = 0
description = "Sunken black market. Contraband, rival fishers, high risk/reward."
catches = [ExtResource("2_catch"), ExtResource("3_catch"), ExtResource("4_catch"), ExtResource("5_catch"), ExtResource("6_catch"), ExtResource("7_catch"), ExtResource("8_catch"), ExtResource("9_catch"), ExtResource("10_catch"), ExtResource("11_catch"), ExtResource("12_catch"), ExtResource("13_catch"), ExtResource("14_catch"), ExtResource("15_catch"), ExtResource("16_catch")]
```

- [ ] **Step 3: Update resources/zones/axiom.tres**

```
[gd_resource type="Resource" script_class="ZoneData" load_steps=17 format=3]

[ext_resource type="Script" path="res://resources/zone_data.gd" id="1_zone"]
[ext_resource type="Resource" path="res://resources/catches/axiom/axiom_drone_mk4.tres" id="2_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/axiom_vault_shard.tres" id="3_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/bioweapon_prototype.tres" id="4_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/deep_archive_core.tres" id="5_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/solace7.tres" id="6_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/decommissioned_surveillance_log.tres" id="7_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/access_badge_database.tres" id="8_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/biohazard_sample_container.tres" id="9_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/corporate_ghost.tres" id="10_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/classified_research_archive.tres" id="11_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/executive_memory_core.tres" id="12_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/axiom_security_drone_mk5.tres" id="13_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/axiom_defense_ai.tres" id="14_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/viral_intrusion_payload.tres" id="15_catch"]
[ext_resource type="Resource" path="res://resources/catches/axiom/axiom_cleaner_protocol.tres" id="16_catch"]

[resource]
script = ExtResource("1_zone")
zone_id = "axiom"
display_name = "Axiom Tower Sub-Basement"
passive_tension_drain = 5
description = "Corporate server farm. Security countermeasures active."
catches = [ExtResource("2_catch"), ExtResource("3_catch"), ExtResource("4_catch"), ExtResource("5_catch"), ExtResource("6_catch"), ExtResource("7_catch"), ExtResource("8_catch"), ExtResource("9_catch"), ExtResource("10_catch"), ExtResource("11_catch"), ExtResource("12_catch"), ExtResource("13_catch"), ExtResource("14_catch"), ExtResource("15_catch"), ExtResource("16_catch")]
```

- [ ] **Step 4: Verify existing Exchange zone description**

Check the actual `resources/zones/exchange.tres` for the current `display_name` and `description` values and use those — the values above are guesses. Do not change existing display strings unless they are wrong.

- [ ] **Step 5: Run GUT tests**

```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests
```

Expected: all existing tests pass. These tests don't cover the new .tres files directly, but any malformed resource path in a zone file would cause a load error that surfaces here.

- [ ] **Step 6: Commit**

```
git add resources/zones/
git commit -m "feat: wire 30 new catches into zone pools"
```

---

## Self-Review

**Spec coverage check:**

| Spec item | Task |
|---|---|
| District 7: +2 PASSIVE shallows | Task 1 |
| District 7: +1 PASSIVE, +2 NEGOTIATING, +1 RESISTANT mid | Task 2 |
| District 7: +1 NEGOTIATING, +1 RESISTANT, +2 AGGRESSIVE deep | Task 3 |
| Exchange: +2 PASSIVE shallows | Task 4 |
| Exchange: +2 NEGOTIATING, +1 RESISTANT mid | Task 5 |
| Exchange: +1 NEGOTIATING, +1 RESISTANT, +3 AGGRESSIVE deep | Task 6 |
| Axiom: +1 PASSIVE, +2 RESISTANT shallows | Task 7 |
| Axiom: +1 NEGOTIATING, +1 RESISTANT mid | Task 8 |
| Axiom: +1 NEGOTIATING, +4 AGGRESSIVE deep | Task 9 |
| Zone .tres files updated | Task 10 |
| GUT regression test | Task 10 |

All spec requirements covered.

**Type consistency:**
- All `catch_type`, `behavior`, `layer` values use integer constants defined in the Enum Reference section — consistent throughout.
- `load_steps` formula (1 + ext_resource count) verified per template.
- AGGRESSIVE reward options use `credit_value` only — consistent with how `_on_terminal_caught` reads `catch_data.options[0].credit_value` in `DiveRun.gd:135`.
- Shock Lure note on AGGRESSIVE MECH catches is accurate: `_inject_shock_option` in `DiveRun.gd:91` checks `catch_type == CatchData.CatchType.MECH`.
