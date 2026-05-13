# Enemy and Boss Design

Project codename: **Tower**

Status: Draft v2 — expanded encounter baseline

This document defines the MVP enemy and boss roster: HP bands, base stats, move pools, intent sequencing, AI weighting rules, and authoring rules for `EnemyData` / `EnemyMoveData` resources. All numbers below assume the Vanguard Archivist starting profile in `09_first_character_design.md` (76 HP, 3 energy, hand 5).

## Difficulty Bands

| Floor band | Encounter type | Player resource budget | Expected combat length |
| --- | --- | --- | --- |
| Floors 1–3 | Normal | 1–2 cards spent on block per turn | 3–4 turns |
| Floors 4–6 | Normal + first elite | 2 cards on block per turn | 4–5 turns |
| Floors 7–8 | Hard normal + Burnt Stack pressure | 2–3 cards on block | 4–6 turns |
| Floor 9 | Boss | Full deck use, 1 potion expected | 6–9 turns |

## Stat Authoring Rules

- Normal enemy HP = 18 + 6 × floor band (1, 2, or 3). Add ±15% per role.
- Elite HP = 55 + 8 × floor band.
- Boss HP = 200.
- Damage budget per attack ≈ player_max_HP × 0.06 for normals, × 0.1 for elites, × 0.15 for boss.
- No single attack should exceed 22 damage in MVP without a clear telegraph.
- Block-shedding moves (multi-hits) are flagged in their data as `multi_hit_count`.

## Intent Display Rules

Every enemy must telegraph its next move in the intent badge. MVP intent categories:

- `attack` — show damage number.
- `attack_multi` — show `n × dmg`.
- `defend` — show shield + value.
- `attack_defend` — combined sword + shield.
- `buff` — generic up arrow.
- `debuff` — generic down arrow.
- `unknown` — only used by Margin Hound (rare).

Intent must be calculated *before* turn end, not at enemy turn start, so the player can react.

## AI Selection Rules

Enemies pick their next move using a weighted pool with anti-repeat memory.

```text
move_pool: [ {move_id, weight, max_in_a_row} ... ]
```

Selection algorithm:

1. Filter out moves whose `max_in_a_row` is already met by the recent history.
2. Optional script overrides (e.g. boss phase change at < 50% HP).
3. Weighted random pick using `RunManager.combat_rng`.
4. Append picked move to a 3-entry move history buffer.

This is data-driven so designers can author behaviour without script changes.

## MVP Roster Summary

Implementation snapshot, 2026-05-13:

- Normal enemies: **18** total.
- Elites: **9** total, distributed as 3 per act.
- Bosses: **6** total, distributed as 2 candidates per act.
- Encounter generation now keeps act-specific early/mid/late normal pools, supports multi-enemy packs, and rolls a boss candidate per act map.
- New content intentionally reuses existing art placeholders; unique enemy art remains a follow-up asset task.

| ID | Tier | HP | Floors | Role |
| --- | --- | --- | --- | --- |
| `e_dust_scribe` | Normal | 24 | 1–3 | Tutorial attacker. |
| `e_loose_folio` | Normal | 30 | 1–4 | Multi-hit pressure. |
| `e_wax_acolyte` | Normal | 34 | 3–5 | Block + counter. |
| `e_margin_hound` | Normal | 28 | 4–6 | Debuffer. |
| `e_burnt_courier` | Normal | 38 | 6–8 | Self-burn synergy. |
| `el_wax_sentinel` | Elite | 70 | 4–6 | Block + retaliate. |
| `el_first_clause` | Elite | 78 | 6–8 | Card-disruption. |
| `b_sealed_curator` | Boss | 200 | 9 | Two-phase debuff/lock. |

Expanded roster:

| ID | Tier | Act | Role |
| --- | --- | --- | --- |
| `e_index_rat` | Normal | 1 | Low-HP multi-hit and Vulnerable tutorial. |
| `e_staple_swarm` | Normal | 1 | Frail + many small hits. |
| `e_ink_moth` | Normal | 2 | Ink pressure and single-hit dive. |
| `e_clause_mender` | Normal | 2 | Scaling defender that punishes slow decks. |
| `e_ledger_sentry` | Normal | 2 | Armored mark-and-slam check. |
| `e_null_page` | Normal | 3 | Weak/Fold pressure; asks for flexible turns. |
| `e_redaction_monk` | Normal | 3 | Strength scaling and Frail pressure. |
| `e_keyhole_mimic` | Normal | 3 | High block, Vulnerable, delayed bite. |
| `el_dust_chorus` | Elite | 1 | Multi-hit burst after Weak setup. |
| `el_penitent_index` | Elite | 2 | Block-scaling elite with Frail pressure. |
| `el_null_librarian` | Elite | 3 | Weak/Frail control into heavy attacks. |
| `el_redaction_engine` | Elite | 3 | Multi-hit damage check with block windows. |
| `b_ink_tyrant` | Boss | 1 | Ink DoT boss; tests burst before stack pressure snowballs. |
| `b_mirror_tribunal` | Boss | 2 | Block/scaling boss; tests pacing and debuff answers. |
| `b_last_catalog` | Boss | 3 | Final scaling boss with mixed debuffs and high phase-2 pressure. |

## Normal Enemies

### `e_dust_scribe` — Dust Scribe

- HP: 24
- Block on spawn: 0
- Theme: bound apprentice; teaches the basic attack/block rhythm.

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `inkstroke` | attack | 6 dmg | 5 | 2 |
| `defend` | defend | gain 5 block | 2 | 1 |
| `study` | buff | gain 1 strength next turn | 1 | 1 |

Notes: never opens with `study`. First turn always `inkstroke`.

### `e_loose_folio` — Loose Folio

- HP: 30
- Theme: pages that swarm. Multi-hit attacker; punishes letting block lapse.

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `flutter` | attack_multi | 3 × 3 dmg | 4 | 1 |
| `gather` | defend | gain 4 block | 2 | 1 |
| `slap` | attack | 8 dmg | 3 | 2 |

### `e_wax_acolyte` — Wax Acolyte

- HP: 34
- Theme: defensive caster, applies Frail.

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `seal` | defend | gain 6 block | 3 | 1 |
| `imprint` | debuff | apply 2 Frail | 2 | 1 |
| `stamp` | attack | 9 dmg | 3 | 2 |

### `e_margin_hound` — Margin Hound

- HP: 28
- Theme: torn entry given fangs. Debuff specialist.

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `tear` | attack | 7 dmg + apply 1 Vulnerable | 4 | 1 |
| `bay` | debuff | apply 2 Weak | 2 | 1 |
| `unknown_lunge` | attack | 11 dmg (intent shown as `unknown`) | 1 | 1 |

The `unknown_lunge` is the only case where intent is hidden; appears at most once per fight.

### `e_burnt_courier` — Burnt Courier

- HP: 38
- Theme: late floor pressure; loses HP to deal more damage.

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `dispatch` | attack | 12 dmg, self loses 2 HP | 4 | 1 |
| `kindle` | buff | gain 2 strength | 1 | 1 |
| `tamp` | defend | gain 6 block | 2 | 1 |

## Elite Enemies

### `el_wax_sentinel` — Wax Sentinel

- HP: 70
- Theme: stamp guard. Punishes greedy attackers via retaliation.

Phase rules:

- While block > 0, attacks against the sentinel cause 2 retaliation damage to attacker.
- At 50% HP, gains permanent +1 strength.

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `set_seal` | defend | gain 12 block | 3 | 2 |
| `heavy_stamp` | attack | 14 dmg | 3 | 1 |
| `double_press` | attack_multi | 2 × 7 dmg | 2 | 1 |

### `el_first_clause` — First Clause

- HP: 78
- Theme: contractual entity that disrupts the player's deck.

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `clause_strike` | attack | 11 dmg | 3 | 2 |
| `cite_subsection` | debuff | add 1 `Burned Page` to player discard | 2 | 1 |
| `amend` | buff | gain 8 block, apply 1 Frail to player | 2 | 1 |

## Boss

### `b_sealed_curator` — Sealed Curator

- HP: 200
- Two phases. Phase change at 50% HP.

#### Phase 1 — Stamp and Stamp Again

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `cold_appraisal` | attack | 13 dmg | 3 | 2 |
| `marginal_note` | debuff | apply 2 Vulnerable | 1 | 1 |
| `seal_block` | defend | gain 14 block | 2 | 1 |
| `errata` | buff | gain 1 strength | 1 | 2 |

Phase 1 always opens with `marginal_note` to teach the read-the-intent loop.

#### Phase 2 — Stamp the Reader

Triggers: at 50% HP boss heals 0 but gains 6 permanent strength and 12 block, plus speaks one line of dialogue. Move pool replaces.

| Move | Type | Effect | Weight | Max in row |
| --- | --- | --- | --- | --- |
| `final_review` | attack_multi | 3 × 6 dmg | 3 | 1 |
| `signature` | attack | 18 dmg, apply 1 Weak | 2 | 1 |
| `seal_player_card` | debuff | mark a random non-attack card in hand as 1-cost-higher next turn | 1 | 1 |
| `dictate` | defend | gain 18 block | 1 | 1 |

Phase 2 must always include at least one `signature` in the first three turns.

## Authoring Schema (proposed)

```text
EnemyData
  id: String
  display_name: String
  tier: enum(normal, elite, boss)
  hp_min: int
  hp_max: int
  spawn_block: int
  art_id: String
  move_pool: Array<EnemyMoveEntry>
  opener_move_ids: Array<String>     # forced first-turn options
  phase_rules: Array<PhaseRule>      # optional

EnemyMoveEntry
  move_id: String
  weight: int
  max_in_a_row: int

EnemyMoveData
  id: String
  intent_type: enum(attack, attack_multi, defend, attack_defend, buff, debuff, unknown)
  damage: int
  multi_hit_count: int
  block: int
  status_applied: Array<{status_id, stacks, target}>
  self_effects: Array<{...}>

PhaseRule
  trigger: enum(hp_below_pct, turn_n, on_status)
  threshold: float
  on_enter: Array<Effect>
  replace_move_pool: Array<EnemyMoveEntry>
```

## Encounter Tables

The MVP map uses the following encounter pools:

```text
floors_1_3_pool: [ e_dust_scribe, e_loose_folio ]
floors_4_5_pool: [ e_loose_folio, e_wax_acolyte, e_margin_hound ]
floors_6_8_pool: [ e_wax_acolyte, e_margin_hound, e_burnt_courier ]
elite_pool:     [ el_wax_sentinel, el_first_clause ]
boss_pool:      [ b_sealed_curator ]
```

Encounter generator picks 1 enemy for normal nodes (MVP keeps single-enemy combats; group fights are post-MVP).

## QA Targets per Enemy

- 100 simulated combats vs. baseline starter deck. Win rate target ≥ 80% for normals, 50–65% for elites, 35–55% for boss.
- No single attack must one-shot a player at 70%+ HP.
- Every enemy's intent must be shown 1 turn ahead. Verify in smoke test.

## Open Questions

- Should normal combats ever feature 2 enemies in MVP? (Currently no, reserved for post-MVP.)
- Should `unknown` intent be only on `e_margin_hound`, or also on a future "Marginalia" elite?
- Does the boss recover any block between phases? (Currently no.)
