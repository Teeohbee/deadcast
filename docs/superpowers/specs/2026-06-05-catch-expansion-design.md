# Catch Expansion Design — Roadmap Item 2.1

**Date:** 2026-06-05  
**Status:** Approved  
**Goal:** Expand each zone from 5 to 15 catches. 30 new catches total. No code changes required — the authoring pipeline (.tres resources, ZoneData references) is already built.

---

## Distribution

Each zone gets 10 new catches across a zone-specific layer and behavior profile. The profile reinforces zone identity mechanically, not just thematically.

### District 7 — accessible, narrative-heavy, low-credit

| | PASSIVE | NEGOTIATING | RESISTANT | AGGRESSIVE |
|---|---|---|---|---|
| Shallows | +2 | — | — | — |
| Mid | +1 | +2 | +1 | — |
| Deep | — | +1 | +1 | +2 |

**Type targets (adds):** +3 ENTITY, +3 DATA, +3 BIO, +1 MECH

### Exchange — mercenary, deal-making, mid/deep heavy

| | PASSIVE | NEGOTIATING | RESISTANT | AGGRESSIVE |
|---|---|---|---|---|
| Shallows | +2 | — | — | — |
| Mid | — | +2 | +1 | — |
| Deep | — | +1 | +1 | +3 |

**Type targets (adds):** +1 ENTITY, +3 DATA, +3 BIO, +3 MECH

### Axiom — corporate, hostile, deep-heavy

| | PASSIVE | NEGOTIATING | RESISTANT | AGGRESSIVE |
|---|---|---|---|---|
| Shallows | +1 | — | +2 | — |
| Mid | — | +1 | +1 | — |
| Deep | — | +1 | — | +4 |

**Type targets (adds):** +1 ENTITY, +3 DATA, +2 BIO, +4 MECH

---

## Zone Content

### District 7

Tone: civilian grief. Emotionally heavy, lower credit yields. Ghosts are individuals, not threats. The two AGGRESSIVE catches are degraded systems — not corporate-grade hostility.

**Shallows — 2 PASSIVE:**
- Residential Data Cluster — PASSIVE DATA — backed-up personal files, nothing illicit, just someone's whole life on a server
- Emergency Medical Cache — PASSIVE BIO — sealed pharmaceutical supplies from a drowned clinic, still viable

**Mid — 1 PASSIVE, 2 NEGOTIATING, 1 RESISTANT:**
- Ghost Loop — PASSIVE ENTITY — environmental ghost fragment on a repeating cycle, not interactive, just present
- Witness Archive — NEGOTIATING DATA — someone recorded everything before the flood; someone alive wants it buried
- Drowned Resident Echo — NEGOTIATING ENTITY — a ghost that knows it's dead and is actively refusing extraction; talk it down or cut it loose
- Encrypted Pension Record — RESISTANT DATA — corporate-locked civilian retirement data, still fighting to protect someone who's gone

**Deep — 1 NEGOTIATING, 1 RESISTANT, 2 AGGRESSIVE:**
- Contraband Bio-Stash — NEGOTIATING BIO — illegal meds hidden deep in a basement; the person who hid them is a ghost upstairs
- Buried Blacksite Fragment — RESISTANT BIO — something biological that corporate got buried in residential infrastructure before the flood
- Feral Building Management AI — AGGRESSIVE MECH — the residential AI from a 300-unit block, corrupted over 40 years of isolation; anchor 2
- Ghost Swarm — AGGRESSIVE ENTITY — multiple fragmented ghosts that have merged into something no longer individual or coherent; anchor 2

---

### Exchange

Tone: mercenary and transactional. Everyone has an angle. The three deep AGGRESSIVE catches are the zone's teeth — not as sophisticated as Axiom, but dangerous and self-interested.

**Shallows — 2 PASSIVE:**
- Unclaimed Cargo Manifest — PASSIVE DATA — shipping record for goods that never arrived; the cargo is gone but the data has value
- Factory-Sealed Bioware — PASSIVE BIO — wetware in a waterproof case, still sterile, still worth market rate

**Mid — 2 NEGOTIATING, 1 RESISTANT:**
- Classified Shipment Log — NEGOTIATING DATA — a full record of Exchange traffic before the flood; multiple parties would pay to have it or destroy it
- Black Market Surgeon's Archive — NEGOTIATING DATA — a back-alley medic's client records and procedures; negotiate access without triggering the deadman protocol
- Stolen Corporate Prototype — RESISTANT MECH — something in transit through the Exchange before the flood, Axiom-branded, does not want to come up

**Deep — 1 NEGOTIATING, 1 RESISTANT, 3 AGGRESSIVE:**
- Rival Fisher's Hidden Cache — NEGOTIATING BIO — you found someone else's stash; they set a trap
- Black Market Organ Bank — RESISTANT BIO — illegally preserved biological material; high value, fights extraction
- Exchange Enforcer Ghost — AGGRESSIVE ENTITY — mercenary ghost still protecting a client's stash; anchor 2
- Exchange Security Drone Mk II — AGGRESSIVE MECH — black market security hardware, nastier than District 7's feral systems; anchor 3
- Rogue Trade Engine — AGGRESSIVE MECH — a defunct auction AI that's turned hostile to anyone accessing the Exchange's records; anchor 2

---

### Axiom

Tone: corporate and hostile. Everything down here is either classified or trying to kill you. The four deep AGGRESSIVE catches are the hardest encounters in the game. Shock Lure (OVERLOAD_CORE) still applies to all MECH AGGRESSIVE catches.

**Shallows — 1 PASSIVE, 2 RESISTANT:**
- Decommissioned Surveillance Log — PASSIVE DATA — years of ambient surveillance, useless to Axiom now, gold to anyone who was being watched
- Access Badge Database — RESISTANT DATA — encrypted employee credentials; the kind of thing Axiom does not want circulating
- Biohazard Sample Container — RESISTANT BIO — sealed corporate sample, Axiom-branded, fighting to stay sealed

**Mid — 1 NEGOTIATING, 1 RESISTANT:**
- Corporate Ghost — NEGOTIATING ENTITY — a mid-level Axiom employee echo; knows things, will talk if you can convince it this is safe
- Classified Research Archive — RESISTANT DATA — research that never made it to the surface, for reasons that aren't documented

**Deep — 1 NEGOTIATING, 4 AGGRESSIVE:**
- Executive Memory Core — NEGOTIATING BIO — a biological memory backup, luxury tech; accessing it risks triggering Axiom's buried security protocols
- Axiom Security Drone Mk V — AGGRESSIVE MECH — upgraded from the Mk IV; significantly more dangerous; anchor 4. Shock Lure works.
- Axiom Defense AI — AGGRESSIVE MECH — a dedicated anti-intrusion system, not a repurposed security drone; anchor 4. Shock Lure works.
- Viral Intrusion Payload — AGGRESSIVE MECH — autonomous defense routines that manifest as a hostile entity in the terminal when hooked; anchor 3. Shock Lure works.
- Axiom Cleaner Protocol — AGGRESSIVE MECH — something Axiom deployed specifically to destroy what's down here; the hardest AGGRESSIVE encounter in the game; anchor 5. Shock Lure works.

---

## Value and Tension Guidelines

Flavor text, option labels, and specific credit/tension values are AI-generated during implementation within these ranges.

### Credit ranges

| | Shallows | Mid | Deep |
|---|---|---|---|
| District 7 | 150–400cr | 350–700cr | 600–1,000cr |
| Exchange | 300–600cr | 600–1,100cr | 900–1,800cr |
| Axiom | 400–800cr | 800–1,500cr | 1,200–3,000cr |

For RESISTANT and NEGOTIATING catches: success reward sits at the upper end of the range. Fail/resist states give no reward or 25–50% of success value.

### Tension costs by behavior

- PASSIVE: 0–10T per option
- RESISTANT: 10–20T on success; resist penalty 25–40T with no reward
- NEGOTIATING: 10–20T on success; fail state 15–30T with reduced or no credit
- AGGRESSIVE: accrued through Terminal Overload turns; no separate per-option tension cost

### Anchor strength for new AGGRESSIVE catches

| Catch | Zone | Anchor |
|---|---|---|
| Feral Building AI | District 7 | 2 |
| Ghost Swarm | District 7 | 2 |
| Exchange Enforcer Ghost | Exchange | 2 |
| Rogue Trade Engine | Exchange | 2 |
| Exchange Security Drone Mk II | Exchange | 3 |
| Viral Intrusion Payload | Axiom | 3 |
| Axiom Defense AI | Axiom | 4 |
| Axiom Security Drone Mk V | Axiom | 4 |
| Axiom Cleaner Protocol | Axiom | 5 |

### Corruption gain

- District 7 civilian/emotional content: 5–15
- Exchange contraband: 10–20
- Axiom corporate/hostile: 15–35
- Axiom Cleaner Protocol: 40+

---

## Implementation Notes

- New catches are `.tres` files only. No code changes required.
- Option `.tres` files are flat in the zone folder alongside the catch — e.g. `resources/catches/district7/opt_ghost_loop_listen.tres`. Follow the existing naming convention: `opt_{catch_slug}_{action}.tres`.
- Each catch references its options as `ExtResource` entries in the `.tres` file.
- After creating all `.tres` files, add each catch to the relevant `resources/zones/{zone}.tres` catches array.
- Follow existing `.tres` format exactly — see `resources/catches/district7/tenant_echo.tres` as the canonical example.
- The `zone_weights` and `stamina` fields appear in existing `.tres` files but are dead code (not in `catch_data.gd`). Do not add them to new catches.
