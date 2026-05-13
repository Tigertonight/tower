# Character-Linked Content System Design

Project codename: **Tower / Living Archive**

Date: 2026-05-13
Status: System design plus data-instance baseline

## Purpose

This document defines how character class, card pools, shops, relics, random events, rewards, and future unlocks should work together.

The reference model is the structure of Slay the Spire: each character has a distinct card pool, starter relic, mechanical identity, and class-specific content, while colorless/public cards and relics provide cross-character glue. Tower should adopt the structure, not copy content, names, or numbers.

## Core Principle

Every run starts with a class identity, and every content system should reinforce it:

```text
Character choice
  -> starter HP / starter deck / starter relic
  -> primary card reward pool
  -> shop offer weighting
  -> relic synergy weighting
  -> event variants and class events
  -> run summary and balance tracking
```

If a Warrior and a Mage visit the same node, they may see the same world, but the reward decisions should not feel the same.

## Four-Class Model

| Class | Current Entity | Card Pool | Starter Relic | Current State |
| --- | --- | --- | --- | --- |
| Warrior | `char_vanguard` | `vanguard` | `sealed_badge` | Playable |
| Warlock | `char_archivist` now, `char_warlock` later | `archivist` now, `warlock` later | `scribes_focus` now, `black_contract` later | Playable candidate + future entity |
| Mage | `char_mage` | `mage` | `core_lantern` | Data prototype, not playable |
| Assassin | `char_assassin` | `assassin` | `hidden_blade` | Data prototype, not playable |

Implementation note:

- `char_archivist` remains playable for compatibility.
- `char_warlock`, `char_mage`, and `char_assassin` exist as data prototypes with `is_playable = false`.
- Once Warlock C1 content exists, either migrate `char_archivist` display/class text to Warlock or retire it behind a save migration.

## Technical Entities

### CharacterData

Implemented fields:

```gdscript
id: String
display_name: String
subtitle: String
class_id: String
class_display_name: String
card_pool_id: String
class_trait_summary: String
class_keywords: Array
is_playable: bool
theme_color: Color
starting_hp: int
starting_relic_id: String
starter_deck: Array
sprite_path: String
```

Rules:

- `class_id` is the high-level class identity: `warrior`, `warlock`, `mage`, `assassin`.
- `card_pool_id` is the reward/shop card pool used by code.
- `is_playable = false` means the resource can exist without appearing in the character-select menu.
- `id` should remain stable for save compatibility.

### CardData

Implemented class-link fields:

```gdscript
pool_id: String
character_id: String
archetype_tags: Array
keyword_tags: Array
rewardable: bool
shop_weight: float
reward_weight: float
unlock_tier: int
```

Rules:

- `pool_id` controls ownership: `vanguard`, `archivist`, `warlock`, `mage`, `assassin`, `public`, `status`, `curse`, `generated`, `event`.
- `character_id` points to a specific owner only when needed.
- `archetype_tags` drive diagnostics, shop weighting, events, and future smart rewards.
- `keyword_tags` drive tooltips and UI highlights.
- `rewardable = false` for basic, special, curse, status, generated, and event-only cards unless a system explicitly opts in.

### RelicData

Implemented class-link fields:

```gdscript
pool_id: String
character_id: String
archetype_tags: Array
```

Rules:

- Starter relics should set `rarity = "starter"`.
- Class relics should set `pool_id` to the class/card-pool identity.
- Public relics can keep `pool_id = "public"`.
- Future shop/relic reward logic can bias class relics without changing the data model.

## Card Reward System

### Normal Rewards

Current production rule:

```text
Normal combat:
  85% selected character card pool
  15% public pool

Elite:
  80% selected character card pool
  20% public pool

Boss:
  70% selected character card pool
  30% public pool
```

Candidate filter:

```text
rewardable == true
rarity == rolled rarity
pool_id in [character.card_pool_id, public]
card_type not in [curse, status]
rarity not in [basic, special]
not already in the same offer
```

Fallback rule:

- Relax rarity first.
- Do not relax ownership unless a special event/relic explicitly allows off-class cards.

### Future Smart Reward Layer

After C1 content exists, add archetype-aware soft weighting:

```text
If deck already contains 3+ cards tagged "ink_ledger":
  +20% reward_weight for Ink cards
  +10% reward_weight for public draw cards
  -10% reward_weight for unrelated rare attacks
```

This should be subtle. The game should guide, not force.

## Shop System

### Base Offer Shape

Every shop should aim for:

- 3 cards.
- 2 relics.
- 2 potions.
- 1 removal service.

Card offer weighting:

```text
60% selected character pool
35% public pool
5% special/off-class only if enabled by event, relic, or later unlock
```

### Class-Aware Shop Goals

| Class | Shop should emphasize | Avoid |
| --- | --- | --- |
| Warrior | block tools, attack upgrades, exhaust payoffs | too much fragile setup |
| Warlock | sacrifice mitigation, curse handling, hex payoff | free power without cost |
| Mage | charge generation, draw, power engines | too many plain attacks |
| Assassin | low-cost cards, discard payoffs, mark/poison tools | slow block-only cards |

### Future Shop Services

Class-specific services can appear later:

| Class | Service | Effect |
| --- | --- | --- |
| Warrior | Reforge | Upgrade an Attack or Skill at a discount. |
| Warlock | Seal Debt | Remove a Curse or transform it into a reward. |
| Mage | Copy Spell | Duplicate a non-rare Skill/Power. |
| Assassin | Sharpen | Add a temporary Mark/Combo modifier to one card. |

These services should be event/shop variants, not always visible.

## Relic System

Relics should have three content layers:

1. **Starter relics**: one per character, always owned at run start.
2. **Class relics**: only offered to matching class unless a special rule says otherwise.
3. **Public relics**: generic run-shaping rewards.

### Starter Relics

| Class | Relic | Implemented Entity | Gameplay Purpose |
| --- | --- | --- | --- |
| Warrior | Sealed Badge | `sealed_badge` | Sustain and beginner forgiveness. |
| Warlock | Scribe's Focus now / Black Contract later | `scribes_focus`, `black_contract` | Skill tempo now; sacrifice engine later. |
| Mage | Core Lantern | `core_lantern` | Charge/spell setup prototype. |
| Assassin | Hidden Blade | `hidden_blade` | Mark/first-attack prototype. |

### Relic Offer Rules

Short term:

- Keep relics mostly public.
- Never offer another character's starter relic.

Medium term:

```text
Relic reward:
  70% public
  30% matching class relic
```

Shop relic offer:

```text
60% public
35% matching class relic
5% public fallback
```

Implemented behavior, 2026-05-13:

- Normal relic rewards roll 70% public / 30% matching class.
- Shop relic slots roll 60% public / 35% matching class / 5% public fallback.
- Cross-class relics are not offered by default.
- If a class pool has no available relic, the code falls back to public relics; if no relic remains, the player gets 25 gold.

## Random Event System

Events should have three axes:

```text
act pool
class pool
archetype variant
```

### Event Types

| Type | Purpose | Example |
| --- | --- | --- |
| Shared event | World texture and generic tradeoffs | Pay HP for relic, remove card, transform card |
| Class event | Reinforce class fantasy | Warlock signs a contract; Mage stabilizes a core |
| Archetype event | Support a deck direction | Warrior exhaust deck gets cleanse/upgrade choice |
| Risk event | Give power with curse/status cost | Add Curse for rare relic |

### Class Event Examples

| Class | Event | Choices |
| --- | --- | --- |
| Warrior | The Broken Standard | Pay HP for a Warrior relic; gain `guarded_cut`; refuse. |
| Warlock | The Unpaid Contract | Pay HP for a Warlock relic; gain `index_mark` + gold; refuse. |
| Mage | The Core Orrery | Gain Charge card; transform Skill into Power; lose max HP for rare spell. |
| Assassin | The Silent Margin | Remove card; gain Mark card; take damage for gold and poison card. |

### Event Reward Rules

- Generic card rewards use current-character/public pool.
- Class events may force a class card.
- Curse/status additions must be explicit and should never use normal card reward selection.
- Transform events should default to current-character/public pool and same card type.

## Potions

Potions can remain public for now, but the long-term design should include class-biased potions:

| Class | Potion Direction |
| --- | --- |
| Warrior | Block, Strength, temporary Retaliate |
| Warlock | HP-for-power, Hex, curse cleanse |
| Mage | Charge, Focus, generated spells |
| Assassin | Mark, Combo count, poison/bleed burst |

Shop potion offers should stay mostly public until there are enough class potions.

## Save / Compatibility Rules

- Saves keep `character_id`, not `class_id`.
- `CharacterData.card_pool_id` controls rewards, so class migration does not require save migration.
- `char_vanguard` remains stable.
- `char_archivist` remains stable until an explicit migration is written.
- New `char_warlock`, `char_mage`, and `char_assassin` are data prototypes and not player-selectable yet.

## Implementation Baseline Added

Data entities now exist for:

- `char_vanguard` — playable Warrior.
- `char_archivist` — playable Warlock candidate using the current Archivist content.
- `char_warlock` — non-playable Warlock prototype.
- `char_mage` — non-playable Mage prototype.
- `char_assassin` — non-playable Assassin prototype.
- `sealed_badge` — Warrior starter relic.
- `scribes_focus` — current Archivist/Warlock-candidate starter relic.
- `black_contract` — Warlock starter relic prototype.
- `core_lantern` — Mage starter relic prototype.
- `hidden_blade` — Assassin starter relic prototype.
- 13 additional Vanguard/Warrior cards, bringing `vanguard` reward cards to 45.
- 14 additional Archivist/Warlock-candidate cards, bringing `archivist` reward cards to 45.
- Warrior class relics: `field_lantern`, `warden_glove`, `binding_thread_warrior`.
- Warlock class relics: `inkstone_warlock`, `blood_wax`, `adjudicator_seal_warlock`.
- Mage class relics: `spellglass`, `orrery_pin`, `blue_core_fragment`.
- Assassin class relics: `silent_boot`, `black_needle`, `margin_cloak`.
- Warrior class event: `ev_broken_standard`.
- Warlock-candidate class event: `ev_unpaid_contract`.
- Mage class event: `ev_core_orrery`.
- Assassin class event: `ev_silent_margin`.
- Mage C1 data wave: 45 rewardable cards in the `mage` pool.
- Assassin C1 data wave: 45 rewardable cards in the `assassin` pool.

Code baseline:

- Character select only lists `is_playable = true` characters.
- Reward filtering reads `CharacterData.card_pool_id`.
- Combat reward generation receives both `character_id` and `card_pool_id`.
- Relic drops and shop relic offers read `CharacterData.class_id` and only offer public or matching-class relics.
- Event rolling adds class-specific event ids from `CharacterData.class_id`.

## Next Implementation Steps

1. Decide whether `char_archivist` becomes the final Warlock or remains a temporary bridge.
2. Add the remaining public C1 cards and extra status/curse/generated cards.
3. Add real sacrifice/hex, charge/spell, and mark/poison trigger hooks.
4. Add class-aware relic icons and card art for the new content wave.
5. Run the card playability regression plan across all four class pools.
6. Unlock Mage/Assassin only after their starter relics and missing bespoke mechanics are implemented.
7. Tune starting decks before making the prototype characters selectable.
