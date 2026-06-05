# Decrypt Box Risk - Design Spec

**Date:** 2026-06-05
**Scope:** Item 1.5 from ROADMAP.md

## Problem

The decrypt box is a no-brainer: load 1000cr, wait 3 runs, collect 4000cr. No risk, no decision. It functions as a background savings account rather than an interesting mechanic.

## Goal

Make the decrypt box a true gamble. Player commits credits, waits, and gets a random outcome - could lose everything, break even, or hit a windfall.

## Outcome Table

Rolled on payout (when `decrypt_box_runs >= DECRYPT_THRESHOLD`):

| Outcome ID | Display Label | Multiplier | Weight |
|---|---|---|---|
| `corruption` | `[CORRUPTION_DETECTED]` | 0x | 20% |
| `partial` | `[PARTIAL_DECRYPT]` | 1.5x | 35% |
| `clean` | `[DECRYPT_COMPLETE]` | 4x | 35% |
| `anomaly` | `[ANOMALY_DETECTED]` | 6x | 10% |

Expected value: ~2.3x. Deliberately unfavourable - it's a gamble, not an investment.

## Changes

### GameState.gd

- Add `var decrypt_last_outcome: String = ""` and `var decrypt_last_payout: int = 0`
- Persist both in `_save_to` / `_load_from` under the `decrypt` section
- Reset both in `new_game()`
- Replace the fixed `DECRYPT_MULTIPLIER` payout in `on_run_complete` with a weighted random roll against the outcome table
- Store the outcome ID and payout amount after the roll

### DecryptBox.gd

- In `_refresh()`, when decryption is in progress, replace `"→ Xcr"` predicted payout with `"→ ?"` since the outcome is unknown
- In `_refresh()`, when queue is empty:
  - If `decrypt_last_outcome` is set, show: `"last result: [LABEL] → Xcr"`
  - Always show: `"data integrity not guaranteed."`
- No changes to the load flow

### Removed

- `DECRYPT_MULTIPLIER` constant on GameState (replaced by the outcome table)

## Out of Scope

- Pressure-weighted odds (can layer on later as per roadmap item C)
- Multiple loads (existing behaviour: can only load once per cycle)
