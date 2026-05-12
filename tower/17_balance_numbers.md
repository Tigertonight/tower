# Balance and Numbers

Project codename: **Tower**

Status: Draft v1

This document is the numerical source of truth for MVP. It defines the energy curve, damage budget, HP/scaling constants, rarity probabilities, reward curve, card cost-to-effect formulas, and upgrade rules. When a card or relic is added the designer should compute its expected value through the formulas here before merging.

## Player Baseline

Defined in `09_first_character_design.md`:

| Stat | Value |
| --- | --- |
| Max HP | 76 |
| Starting energy | 3 |
| Starting hand size | 5 |
| Cards drawn per turn | 5 |
| Starting gold | 99 |
| Potion slots | 3 |

## Combat Length Targets

| Encounter | Target turns | Notes |
| --- | --- | --- |
| Normal floors 1–3 | 3–4 | Tutorial pacing. |
| Normal floors 4–8 | 4–5 | Player has shaped deck. |
| Elite | 5–6 | Forces use of relics + statuses. |
| Boss | 6–9 | Deck shows full identity. |

These targets feed the HP and damage formulas in `15_enemy_boss_design.md`.

## Damage Budget per Card

Damage and block values are derived from a **resource value** model.

```text
damage_per_energy_baseline:
  common  = 6
  uncommon = 7
  rare    = 8.5
block_per_energy_baseline:
  common  = 5
  uncommon = 6
  rare    = 7.5
```

For a card costing `C` energy with rarity `R`:

```text
expected_damage(R, C)  ≈ damage_per_energy_baseline[R] × C
expected_block(R, C)   ≈ block_per_energy_baseline[R]  × C
```

Rules:

1. If a card has a **conditional clause** (e.g. "if you have block"), the conditional bonus may exceed the baseline by up to 30%.
2. If a card has a **drawback** (Exhaust, self-damage, discard), the baseline may be exceeded by up to 25%.
3. **Hybrid cards** (damage + block, or damage + draw) split the budget proportionally; the sum should land within ±10% of the baseline.
4. **Card draw** is valued at 1.0 energy per card drawn.
5. **Energy gain** is valued at 1.5 energy per energy gained, due to flexibility.
6. **Status apply** values:
   - Vulnerable / Weak / Frail: 0.5 energy per stack for 1 turn.
   - Strength / Momentum: 1.0 energy per +1 strength to player.
   - Poison: 0.4 energy per stack.

Worked example — `Measured Cut` (Attack, 1 cost, common):

- Baseline: 6 damage.
- Conditional bonus to 9 if blocked.
- Effective value: roughly 7 damage average.
- Within +30% conditional cap. ✅

Worked example — `Counterseal` (Skill, 1 cost, uncommon):

- Baseline: 6 block.
- Reads: gain 7 block, next attack +4 damage.
- Block portion: 7 (slightly above baseline).
- Bonus damage: ~4 (worth 0.66 energy).
- Total energy value ~1.16, within +25% combo allowance. ✅

If a card cannot fit within these rules it must include a written justification in the design notes block of its `.tres` data.

## HP Curve

Formula recap from `15_enemy_boss_design.md`:

```text
normal_hp(floor_band) = 18 + 6 × floor_band     # band 1..3
elite_hp(floor_band)  = 55 + 8 × floor_band
boss_hp = 200
```

Per-enemy ±15% role variance is permitted but documented in their data file.

## Damage Pressure on the Player

Target: average **net incoming damage per turn** over a normal combat ≤ player_hp × 0.04. Net = enemy attack damage − player block.

This guides healing economy: roughly one normal combat costs 3 HP after block, an elite costs 8 HP, a boss costs 12–18 HP. Across an MVP run (~10 nodes) this expects ~35 HP loss against ~35 HP recovery (Sealed Badge end-of-combat heal × normal combat count + campfire rest).

## Energy Curve

- Player starts with 3 energy.
- The `Tower Key` boss relic raises this to 4 energy (with potion lockout).
- Designed top-end card cost in MVP: 3.
- Cards costing 0 must include a meaningful drawback (exhaust, conditional, low ceiling).

## Card Rarity Distribution

Card reward roll probabilities per node:

| Node | Common | Uncommon | Rare |
| --- | --- | --- | --- |
| Normal combat | 60% | 37% | 3% |
| Elite combat | 40% | 50% | 10% |
| Boss combat | 0% | 60% | 40% |

Three offers per reward, drawn without replacement. If the same card is rolled twice during one offer the duplicate is rerolled.

## Relic Distribution

Sources and pools:

| Source | Pool | Count per run target |
| --- | --- | --- |
| Starter | `Sealed Badge` (fixed) | 1 |
| Combat reward (boss only in MVP) | Boss pool | 1 |
| Elite reward | Common/Uncommon | 1–2 |
| Event | Common/Uncommon | 0–2 |
| Shop | Common/Uncommon (Rare ≥ floor 5) | 0–1 |

Target relic count at end of MVP run: 4–6.

## Potion Distribution

- Drop chance after normal combat: 35%.
- Drop chance after elite combat: 70%.
- Drop chance after boss combat: 0% (skip; reward is relic).
- Maximum potion slots: 3. If full, drop is replaced by 25 gold.

## Gold Economy

Gold sources (per run target totals):

| Source | Average gold | Notes |
| --- | --- | --- |
| Normal combat | 12–18 | Scales with floor band. |
| Elite combat | 30–45 |  |
| Event payouts | 0–60 | Event-dependent. |
| Boss combat | 60 |  |

Gold sinks:

| Sink | Cost |
| --- | --- |
| Card removal in shop | 75, +25 per use |
| Card upgrade event | 50 |
| Shop common card | 50 |
| Shop relic | 150–300 |

Designer rule: end-of-MVP gold should leave the player able to afford **either** 1 relic in the final shop **or** 1 card removal + 1 potion. Not both.

## Upgrade Rules

- Each card has exactly one upgrade tier in MVP.
- Upgrade is +25–40% effect by rule of thumb.
- Status-applying cards upgrade in stack count, not turns, where possible.
- Cards with conditional bonuses should upgrade either the base or the bonus, not both.
- Upgraded cards are tagged in the run save as `card_id+`.

## Floor → Encounter Curve

```text
floor 1: tutorial combat (e_dust_scribe)
floor 2: normal
floor 3: choice node (event/normal)
floor 4: normal or elite
floor 5: campfire OR shop
floor 6: normal
floor 7: elite
floor 8: campfire
floor 9: boss
```

The procedural generator must keep floor 8 a campfire (per MVP rule "campfire before boss"). See `18_map_generation.md`.

## Status Effect Numbers

| Status | Stack effect | Decay |
| --- | --- | --- |
| Vulnerable | +50% damage taken | -1 stack per turn |
| Weak | -25% damage dealt | -1 stack per turn |
| Frail | -25% block gained | -1 stack per turn |
| Poison | take N damage at turn end | -1 stack at turn end |
| Strength | +1 damage per stack on attacks | permanent unless removed |
| Momentum | +1 damage on attacks; expires end of turn | full reset |
| Guard | next attack +2 damage if block > 0 | full reset |
| Burned Page | unplayable, take 2 dmg at end of turn, exhaust | self-removing |

## Random Number Generator Rules

Each run uses one root seed and three derived RNG streams:

```text
combat_rng    -> enemy moves, damage variance (none in MVP)
map_rng       -> map generation
reward_rng    -> card/relic/potion rewards
event_rng     -> event branches
```

This allows deterministic save resume and reproducible balance simulation.

## Balance Sim Targets

Implementation deferred to `21_testing_strategy.md`, but the targets:

- Win rate vs. baseline starter deck across 1000 simulated runs: 35–55%.
- Average run length: 9–11 nodes.
- HP at boss start: 50–65% of max.
- No single card with >15% pick-rate that produces a >75% win rate (would indicate dominant card).

## Open Numerical Questions

- Should base energy be 3 or 4? Currently 3; revisit if average combat exceeds 6 turns.
- Should reward gold scale with floor or stay flat? Current spec scales with floor band.
- Should boss provide a heal-on-victory? Currently no.
