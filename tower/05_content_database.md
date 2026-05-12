# Content Database

Project codename: **Tower**

Status: Draft v2 (synced with `09_first_character_design.md`, `15_enemy_boss_design.md`, `16_events_shop_campfire.md`)

This document is the single source of truth for designed content. Detailed mechanics live in their dedicated docs; this file is the index and status board.

## Characters

| ID | Name | Role | Core Mechanic | Status | Source |
| --- | --- | --- | --- | --- | --- |
| `char_vanguard` | Vanguard Archivist | Balanced attacker/defender | Guard, Momentum, Retaliate | In implementation | `09_first_character_design.md` |
| `char_shadow` | Shadow Operator | Combo and poison | Combo points, poison, discard | Concept (post-MVP) | – |
| `char_core` | Core Engineer | Modules and charge | Module slots, charge | Concept (post-MVP) | – |

## Cards (Vanguard Archivist — MVP set, 30 cards)

### Basic

| ID | Name | Type | Cost | Rarity | Effect | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `strike_form` | Strike Form | Attack | 1 | Basic | Deal 6 dmg | Implemented |
| `guard_form` | Guard Form | Skill | 1 | Basic | Gain 5 block | Implemented |
| `archive_bash` | Archive Bash | Attack | 2 | Basic | Deal 8 dmg, apply 2 Vulnerable | Implemented |

### Common

| ID | Name | Type | Cost | Rarity | Effect | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `measured_cut` | Measured Cut | Attack | 1 | Common | Deal 7; if you have block, deal 9 | Implemented |
| `shield_tap` | Shield Tap | Attack | 1 | Common | Deal 5, gain 3 block | Implemented |
| `forward_step` | Forward Step | Skill | 0 | Common | Gain 3 block, gain 1 Momentum | Implemented |
| `brace` | Brace | Skill | 1 | Common | Gain 8 block | Implemented |
| `quick_read` | Quick Read | Skill | 1 | Common | Draw 2 | Implemented |
| `heavy_page` | Heavy Page | Attack | 2 | Common | Deal 14 dmg | Designed |
| `ink_mark` | Ink Mark | Skill | 1 | Common | Apply 2 Vulnerable | Designed |
| `defensive_note` | Defensive Note | Skill | 1 | Common | Gain 6 block, draw 1 | Designed |
| `clean_strike` | Clean Strike | Attack | 1 | Common | Deal 8 dmg | Designed |
| `hold_line` | Hold Line | Skill | 2 | Common | Gain 14 block | Designed |

### Uncommon

| ID | Name | Type | Cost | Rarity | Effect | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `counterseal` | Counterseal | Skill | 1 | Uncommon | Gain 7 block, next attack +4 dmg | Designed |
| `oath_pressure` | Oath Pressure | Attack | 1 | Uncommon | Deal 4 twice | Implemented |
| `tactical_memory` | Tactical Memory | Skill | 0 | Uncommon | Draw 1, if blocked gain 1 energy, exhaust | Designed |
| `guarded_advance` | Guarded Advance | Attack | 2 | Uncommon | Deal 10, gain block = unblocked dmg | Designed |
| `archive_tempo` | Archive Tempo | Power | 1 | Uncommon | First time gaining block per turn, gain 1 Momentum | Designed |
| `break_rhythm` | Break Rhythm | Skill | 1 | Uncommon | Apply 2 Weak, draw 1 | Implemented |
| `steel_margin` | Steel Margin | Power | 2 | Uncommon | Start of turn gain 3 block | Designed |
| `revision` | Revision | Skill | 1 | Uncommon | Discard 1, draw 2 | Designed |
| `focused_blow` | Focused Blow | Attack | 2 | Uncommon | Deal 12, +4 per Momentum | Designed |
| `burnt_clause` | Burnt Clause | Attack | 1 | Uncommon | Deal 9, exhaust random card in hand | Designed |

### Rare

| ID | Name | Type | Cost | Rarity | Effect | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `final_argument` | Final Argument | Attack | 3 | Rare | Deal 24; if blocked apply 3 Vulnerable | Designed |
| `unbroken_form` | Unbroken Form | Power | 2 | Rare | Block reduced by half (not removed) at turn end | Designed |
| `perfect_rebuttal` | Perfect Rebuttal | Skill | 2 | Rare | Gain 12 block, deal block dmg to all enemies, exhaust | Designed |
| `archive_surge` | Archive Surge | Skill | 1 | Rare | Gain 2 energy, draw 2, exhaust | Designed |
| `law_of_return` | Law of Return | Power | 2 | Rare | When losing block to attack, deal 3 dmg back | Designed |

### Status / Curse

| ID | Name | Type | Effect | Status |
| --- | --- | --- | --- | --- |
| `burned_page` | Burned Page | Status | Unplayable. End of turn take 2 dmg, exhaust | Designed |
| `debt_mark` | Debt Mark | Curse | Unplayable. When drawn, lose 1 HP | Designed |

Total Vanguard MVP card pool: 28 (basic + common + uncommon + rare). Add 2 more uncommon designs to hit the 30-card target.

## Relics

| ID | Name | Rarity | Trigger | Effect | Status |
| --- | --- | --- | --- | --- | --- |
| `sealed_badge` | Sealed Badge | Starter | combat_ended | Heal 5 HP | Implemented |
| `brass_bookmark` | Brass Bookmark | Common | combat_started | Draw 1 extra card this combat | Designed |
| `wax_seal` | Wax Seal | Common | first block per combat | Gain 2 extra block | Designed |
| `broken_lens` | Broken Lens | Common | damage_calculated | +2 dmg vs Vulnerable | Designed |
| `old_canteen` | Old Canteen | Common | campfire entered | Heal 4 HP | Designed |
| `iron_index` | Iron Index | Uncommon | every 3rd attack | +6 dmg | Designed |
| `red_string` | Red String | Uncommon | turn_started | If no block, gain 3 block | Designed |
| `contract_nail` | Contract Nail | Uncommon | card_exhausted | Gain 2 block | Designed |
| `locked_compass` | Locked Compass | Rare | combat_started | Apply 1 Weak to all enemies | Designed |
| `tower_key` | Tower Key | Boss | turn_started | +1 energy, disables potions | Designed |

## Potions (5)

| ID | Name | Effect | Status |
| --- | --- | --- | --- |
| `red_ink_vial` | Red Ink Vial | Deal 12 dmg to one enemy | Designed |
| `guard_draught` | Guard Draught | Gain 12 block | Designed |
| `clarity_drop` | Clarity Drop | Draw 3 | Designed |
| `spark_tonic` | Spark Tonic | Gain 2 energy this turn | Designed |
| `solvent` | Solvent | Remove all debuffs from self | Designed |

## Enemies (MVP — see `15_enemy_boss_design.md`)

| ID | Name | Tier | HP | Floors | Status |
| --- | --- | --- | --- | --- | --- |
| `e_dust_scribe` | Dust Scribe | Normal | 24 | 1–3 | Designed |
| `e_loose_folio` | Loose Folio | Normal | 30 | 1–4 | Designed |
| `e_wax_acolyte` | Wax Acolyte | Normal | 34 | 3–5 | Designed |
| `e_margin_hound` | Margin Hound | Normal | 28 | 4–6 | Designed |
| `e_burnt_courier` | Burnt Courier | Normal | 38 | 6–8 | Designed |
| `el_wax_sentinel` | Wax Sentinel | Elite | 70 | 4–6 | Designed |
| `el_first_clause` | First Clause | Elite | 78 | 6–8 | Designed |
| `b_sealed_curator` | Sealed Curator | Boss | 200 | 9 | Designed |

## Events (5 — see `16_events_shop_campfire.md`)

| ID | Name | Floors | Pattern | Status |
| --- | --- | --- | --- | --- |
| `ev_quiet_stack` | The Quiet Stack | 1–4 | Pay HP for relic | Designed |
| `ev_clean_margin` | A Clean Margin | 2–6 | Pay gold to remove a card | Designed |
| `ev_red_string` | The Red String | 3–7 | Curse for power | Designed |
| `ev_revision_desk` | The Revision Desk | 2–6 | Upgrade at a cost | Designed |
| `ev_loose_page` | A Loose Page | 1–6 | Fight or flee | Designed |

## Status Effects

| ID | Name | Sign | Effect | Decay | Status |
| --- | --- | --- | --- | --- | --- |
| `vulnerable` | Vulnerable | Negative | +50% dmg taken | -1 / turn | Implemented |
| `weak` | Weak | Negative | -25% dmg dealt | -1 / turn | Designed |
| `frail` | Frail | Negative | -25% block | -1 / turn | Designed |
| `poison` | Poison | Negative | N dmg at turn end | -1 / turn end | Designed |
| `strength` | Strength | Positive | +1 dmg per stack | permanent | Designed |
| `momentum` | Momentum | Positive | +1 attack dmg, expires turn end | full reset | Designed |
| `guard` | Guard | Positive | next attack +2 dmg if block > 0 | full reset | Designed |
| `barrier` | Barrier | Positive | block carries between turns | post-MVP | Concept |
| `overload` | Overload | Negative/tradeoff | future-turn penalty | per-card | Concept |

## Status Legend

- **Implemented** — playable in the current Godot prototype.
- **Designed** — fully specified in design docs, not yet authored as `.tres`.
- **Concept** — listed but not specified.

## Cross-References

- Card mechanics: `09_first_character_design.md`
- Cost/effect formulas: `17_balance_numbers.md`
- Enemy moves: `15_enemy_boss_design.md`
- Event flow: `16_events_shop_campfire.md`
- Shop & campfire: `16_events_shop_campfire.md`
- Originality check: `06_legal_originality_checklist.md`

When adding new content, update both the source doc and this index, plus the originality review row in `06`.
