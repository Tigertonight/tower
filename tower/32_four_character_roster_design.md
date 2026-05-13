# Four Character Roster Design

Project codename: **Tower / Living Archive**

Date: 2026-05-13
Status: Character roster direction for card-pool expansion

## Design Intent

The game should ultimately have four immediately readable character fantasies:

1. **Warrior** — durable weapon fighter; block, strength, exhaust, retaliation.
2. **Warlock** — curse and forbidden-contract user; sacrifice, hex, doom, self-risk.
3. **Mage** — spell engine and elemental scholar; charge, spell chains, mana bursts, generated spells.
4. **Assassin** — speed and precision killer; combo, poison/bleed, discard, stealth burst.

The old internal names (`Vanguard`, `Archivist`, `Shadow`, `Core`) can remain as world-flavored titles under these classes, but the player-facing class read should be simple. A new player should understand the broad identity before reading a tooltip.

## Naming Model

Use a two-layer naming model:

| Player-Facing Class | Tower World Title | Current / Future ID |
| --- | --- | --- |
| Warrior | Vanguard Archivist | `char_vanguard` |
| Warlock | Hex Archivist / Contract Scribe | `char_warlock` |
| Mage | Core Arcanist / Index Mage | `char_mage` |
| Assassin | Shadow Operator / Margin Knife | `char_assassin` |

This keeps the archive setting while giving the roster a recognizable RPG silhouette.

## Roster Overview

| Class | HP | Difficulty | Core Fantasy | Main Resources |
| --- | ---: | --- | --- | --- |
| Warrior | 76 | Beginner | Outlast, brace, then punish. | Block, Strength, Guard, Exhaust |
| Warlock | 70 | Advanced | Pay life/cards to curse enemies and bend reward rules. | Hex, Curse, Sacrifice, Doom |
| Mage | 64 | Intermediate | Build spell engines and convert charge into burst turns. | Charge, Focus, Channel, Generated Spells |
| Assassin | 66 | Intermediate | Sculpt hand, stack marks/poison, then finish in one turn. | Combo, Mark, Poison/Bleed, Discard |

## Shared Rules

- Each class has a dedicated card pool.
- Public cards remain usable by all classes but should not carry a class's defining mechanic.
- Each class has a starter relic that teaches its core loop.
- Each class should support 4 archetypes:
  - One direct/simple build.
  - One defensive/survival build.
  - One scaling/engine build.
  - One high-risk/high-reward build.
- Each class eventually targets 72-75 exclusive cards.
- C1 implementation target is 45 exclusive cards per implemented class.

## Character 1 — Warrior

### Identity

Player-facing class: **Warrior**  
World title: **Vanguard Archivist**  
Current ID: `char_vanguard`

The Warrior is the reliable first character. They survive through disciplined defense and convert preparation into damage.

### Starter Stats

| Field | Value |
| --- | --- |
| HP | 76 |
| Energy | 3 |
| Draw | 5 |
| Starter relic | `sealed_badge` |

### Starter Relic

`sealed_badge` — **Sealed Badge**

Effect:

```text
At the end of combat, heal 5 HP.
```

Purpose:

- Keeps the first character forgiving.
- Rewards ending fights cleanly.
- Lets beginners experiment without dying to small mistakes.

### Core Mechanics

- **Guard**: next attack this turn gains a bonus if the player has Block.
- **Momentum**: temporary attack pressure that expires at end of turn.
- **Exhaust**: remove low-value cards/statuses for block, draw, or damage.
- **Retaliate**: defense triggers counter-damage or attack bonuses.

### Archetypes

| Archetype | Card Tags | Gameplay |
| --- | --- | --- |
| Guard Tempo | `guard_tempo`, `block`, `hybrid` | Block before attacking; hybrid cards overperform. |
| Oath Strength | `strength`, `multi_hit`, `vulnerable` | Stack Strength, then use repeated attacks. |
| Paper Furnace | `exhaust`, `draw`, `status_cleanse` | Exhaust cards for value and thin the deck. |
| Unbroken Wall | `block_carry`, `block_to_damage`, `dexterity` | Turn defense into win condition. |

### Card Pool Shape

C1 target:

| Rarity | Count |
| --- | ---: |
| Basic | 3 |
| Common | 18-20 |
| Uncommon | 18-20 |
| Rare | 9-11 |

Benchmark target: 72-75 exclusive cards.

### Current Mapping

Existing `vanguard` pool already maps to this class. It should be renamed in UI as Warrior while keeping `char_vanguard` internally for save compatibility.

## Character 2 — Warlock

### Identity

Player-facing class: **Warlock**  
World title: **Hex Archivist** or **Contract Scribe**  
Future ID: `char_warlock`

The Warlock uses forbidden indexing, curses, and life-payment. They are not a generic spellcaster: they bargain with the archive. Their strength is bending normal rules at a cost.

### Starter Stats

| Field | Value |
| --- | --- |
| HP | 70 |
| Energy | 3 |
| Draw | 5 |
| Starter relic | `black_contract` |

### Starter Relic

`black_contract` — **Black Contract**

Effect:

```text
The first time each combat you lose HP from your own card, draw 1 and gain 1 Energy.
```

Purpose:

- Teaches sacrifice immediately.
- Makes self-damage a resource, not just a drawback.
- Creates tension between power and survival.

### Core Mechanics

- **Hex**: enemy takes extra effects when hit, debuffed, or at turn end.
- **Sacrifice**: lose HP, exhaust cards, or add curses for stronger effects.
- **Doom**: delayed payoff counter; when it reaches a threshold, it bursts.
- **Cursecraft**: use curses/statuses as resources rather than pure punishment.

### Archetypes

| Archetype | Card Tags | Gameplay |
| --- | --- | --- |
| Blood Bargain | `sacrifice`, `hp_trade`, `draw`, `energy` | Pay HP for tempo and burst. |
| Hex Control | `hex`, `weak`, `vulnerable`, `frail` | Stack enemy debuffs and punish them. |
| Cursecraft | `curse`, `exhaust`, `generated`, `reward_break` | Add/manage curses for scaling effects. |
| Doom Engine | `doom`, `delayed_damage`, `power` | Build delayed explosions and survive until they fire. |

### Card Pool Shape

C1 target when implemented:

| Rarity | Count |
| --- | ---: |
| Basic | 4 |
| Common | 18-20 |
| Uncommon | 18-20 |
| Rare | 9-11 |

Benchmark target: 72-75 exclusive cards.

### Starter Deck Sketch

| Card | Count | Role |
| --- | ---: | --- |
| Contract Strike | 4 | Basic attack. |
| Warding Clause | 4 | Basic block. |
| Blood Signature | 1 | Lose 2 HP. Deal damage and apply Hex. |
| Small Hex | 1 | Apply Hex. Draw 1. |
| Quiet Offering | 1 | Lose 1 HP. Gain 1 Energy. Exhaust. |

### First Relic Support

| Relic | Rarity | Effect |
| --- | --- | --- |
| `black_contract` | Starter | First self-HP loss each combat draws 1 and gives 1 Energy. |
| `cracked_talisman` | Common | Hexed enemies take +2 attack damage. |
| `blood_wax` | Common | When you lose HP from a card, gain 3 Block. |
| `debtor_chain` | Uncommon | Whenever a Curse is exhausted, apply 2 Hex to all enemies. |
| `final_invoice` | Rare | Doom bursts deal +50% damage. |

### Implementation Notes

Warlock should not be implemented before the current two-character card pools are stable. It requires new effect hooks:

- Self-damage trigger.
- Cards-in-deck curse count checks.
- Doom stack threshold.
- Curse exhaustion payoff.

## Character 3 — Mage

### Identity

Player-facing class: **Mage**  
World title: **Core Arcanist** or **Index Mage**  
Future ID: `char_mage`

The Mage is the engine character. They build charge, channel spells, create temporary cards, and turn setup turns into explosive turns.

### Starter Stats

| Field | Value |
| --- | --- |
| HP | 64 |
| Energy | 3 |
| Draw | 5 |
| Starter relic | `core_lantern` |

### Starter Relic

`core_lantern` — **Core Lantern**

Effect:

```text
At the start of combat, gain 1 Charge. The first spell you play each combat costs 1 less.
```

Purpose:

- Teaches Charge and spell sequencing.
- Gives the fragile character a strong first-turn identity.

### Core Mechanics

- **Charge**: stackable resource consumed by spells for bonus effects.
- **Focus**: improves generated spell effects or elemental damage.
- **Channel**: prepare a spell card for next turn or repeat a spell effect.
- **Generated Spells**: temporary cards created during combat.

### Archetypes

| Archetype | Card Tags | Gameplay |
| --- | --- | --- |
| Charge Burst | `charge`, `spender`, `burst` | Build Charge, spend it for large effects. |
| Elemental Pages | `fire`, `frost`, `storm`, `aoe` | Different spell schools solve different fights. |
| Spell Loop | `generated`, `copy`, `cost_reduce` | Create temporary cards and loop them. |
| Focus Engine | `focus`, `power`, `scaling` | Powers make every spell better over time. |

### Card Pool Shape

C1 target when implemented:

| Rarity | Count |
| --- | ---: |
| Basic | 4 |
| Common | 18-20 |
| Uncommon | 18-20 |
| Rare | 9-11 |

Benchmark target: 72-75 exclusive cards.

### Starter Deck Sketch

| Card | Count | Role |
| --- | ---: | --- |
| Spark Script | 4 | Basic spell attack. |
| Glass Ward | 4 | Basic block. |
| Charge Primer | 1 | Gain Charge. Draw 1. |
| Core Bolt | 1 | Spend Charge for bonus damage. |
| Cool Index | 1 | Gain Block; if you have Charge, draw 1. |

### First Relic Support

| Relic | Rarity | Effect |
| --- | --- | --- |
| `core_lantern` | Starter | Start combat with 1 Charge; first spell costs 1 less. |
| `blue_wick` | Common | First Charge gained each turn gives +1 Block. |
| `spellglass` | Common | Generated cards deal +2 damage. |
| `looping_sigils` | Uncommon | Every third Skill creates a temporary Spark Script. |
| `white_core` | Rare | Charge is not fully removed when spent; keep 1. |

### Implementation Notes

Mage should come after Warlock or Assassin only if the engine system is ready. It needs:

- Charge status/resource.
- Generated temporary cards.
- Cost-reduction duration.
- Per-turn/card-count triggers.

## Character 4 — Assassin

### Identity

Player-facing class: **Assassin**  
World title: **Shadow Operator** or **Margin Knife**  
Future ID: `char_assassin`

The Assassin is the precision character. They discard, draw, mark targets, stack poison/bleed, and convert setup into lethal turns.

### Starter Stats

| Field | Value |
| --- | --- |
| HP | 66 |
| Energy | 3 |
| Draw | 5 |
| Starter relic | `hidden_blade` |

### Starter Relic

`hidden_blade` — **Hidden Blade**

Effect:

```text
The first Attack you play each combat applies 2 Mark.
```

Purpose:

- Teaches target setup and burst.
- Makes early attack selection matter.

### Core Mechanics

- **Mark**: marked enemies take bonus from precision cards.
- **Combo**: count cards played this turn; later cards gain bonuses.
- **Poison/Bleed**: damage over time that supports longer fights.
- **Discard**: sculpt hand and trigger payoff cards.

### Archetypes

| Archetype | Card Tags | Gameplay |
| --- | --- | --- |
| Mark Burst | `mark`, `finisher`, `single_target` | Set up a target, then execute. |
| Poison Knives | `poison`, `dot`, `multi_hit` | Win through stacking DoT and chip damage. |
| Combo Chain | `combo`, `zero_cost`, `draw` | Play many cards in one turn. |
| Discard Tempo | `discard`, `reflex`, `energy` | Turn discard into draw/energy/damage. |

### Card Pool Shape

C1 target when implemented:

| Rarity | Count |
| --- | ---: |
| Basic | 4 |
| Common | 18-20 |
| Uncommon | 18-20 |
| Rare | 9-11 |

Benchmark target: 72-75 exclusive cards.

### Starter Deck Sketch

| Card | Count | Role |
| --- | ---: | --- |
| Knife Form | 4 | Basic attack. |
| Slip Guard | 4 | Basic block. |
| Marking Cut | 1 | Deal damage. Apply Mark. |
| Vanish Step | 1 | Gain Block. Draw 1 then discard 1. |
| Needle Drop | 1 | Apply Poison/Bleed. |

### First Relic Support

| Relic | Rarity | Effect |
| --- | --- | --- |
| `hidden_blade` | Starter | First Attack each combat applies 2 Mark. |
| `smoke_pin` | Common | First discard each turn gains 2 Block. |
| `black_needle` | Common | Poison/Bleed cards apply +1 stack. |
| `silent_boot` | Uncommon | Every fourth card played deals 4 damage to a marked enemy. |
| `mirror_dagger` | Rare | First finisher each combat repeats at 50% value. |

### Implementation Notes

Assassin can reuse some current Archivist draw/debuff/card-flow tech, so it may be cheaper than Mage. It needs:

- Mark status.
- Combo count per turn.
- Draw-then-discard / discard-selected-card effects.
- Poison or Bleed status if separate from Ink.

## Relationship to Current Archivist

The current `char_archivist` is mechanically closer to a **Warlock-Assassin hybrid**:

- Ink DoT and debuffs point toward Warlock/Assassin.
- Draw and hand control point toward Assassin/Mage.
- The name "Archivist" is too broad to represent a class fantasy.

Recommended migration:

1. Keep `char_vanguard` as Warrior.
2. Keep `char_archivist` temporarily as the second playable character for compatibility.
3. During the next content wave, decide whether to evolve `char_archivist` into:
   - **Warlock** if Ink becomes Hex/Doom/curse gameplay.
   - **Assassin** if Ink becomes Poison/Mark/discard gameplay.
4. Add the missing class as a new character after the two implemented classes are stable.

My recommendation: migrate current Archivist into **Warlock** because Ink, debt, contracts, and forbidden knowledge already fit that fantasy. Then create Assassin separately with Mark/Combo/Discard.

## Recommended Implementation Order

| Order | Character | Reason |
| ---: | --- | --- |
| 1 | Warrior | Already implemented as `char_vanguard`; needs card depth and UI naming. |
| 2 | Warlock | Current `char_archivist` can be migrated here with Ink/Hex/curse identity. |
| 3 | Assassin | Can reuse draw/debuff/discard tech; high player appeal. |
| 4 | Mage | Requires the most engine work: Charge, generated spells, cost manipulation. |

Do not build all four at once. The production-safe route is:

1. Complete Warrior and Warlock C1 card pools.
2. Run `31_card_playability_regression_plan.md`.
3. Add Assassin as the third character.
4. Add Mage once generated-card and Charge systems exist.

## Data Model Implications

The current `CardData.pool_id` model can already support the four roles:

```text
pool_id:
  warrior
  warlock
  mage
  assassin
  public
  status
  curse
  generated
  event
```

Because current code already uses `char_vanguard -> vanguard` and `char_archivist -> archivist`, migration should be staged:

1. Add `class_id` to `CharacterData`, e.g. `warrior`, `warlock`, `mage`, `assassin`.
2. Add `card_pool_id` to `CharacterData`, defaulting to the old ID-derived pool for compatibility.
3. Update reward filtering to use `card_pool_id`, not `character_id.trim_prefix("char_")`.
4. Then rename pools from `vanguard/archivist` to `warrior/warlock` safely.

Proposed `CharacterData` additions:

```gdscript
@export var class_id: String = ""
@export var card_pool_id: String = ""
@export var class_display_name: String = ""
@export var class_trait_summary: String = ""
@export var class_keywords: Array = []
```

## Art Direction

Each class needs a distinct silhouette:

| Class | Silhouette | Palette | Icon |
| --- | --- | --- | --- |
| Warrior | Broad coat, weapon/ledger, shielded stance | Amber, brass, iron | Sword + ledger |
| Warlock | Tall ritual robe, contract chains, ink halo | Violet, black, wax red | Contract seal |
| Mage | Lantern staff, floating pages, geometric core | Teal, blue, white-gold | Core lantern |
| Assassin | Lean hooded figure, knives, trailing paper strips | Green, black, silver | Dagger + margin mark |

These should become requirements in the next asset checklist before generating character portraits.

## Open Decisions

- Should `char_archivist` be renamed in saves or kept as an internal legacy ID?
  - Recommendation: keep the ID for now, change display/class text only.
- Should Ink become Warlock's Hex or Assassin's Poison?
  - Recommendation: migrate Ink into Warlock as Hex/Doom-adjacent forbidden text damage.
- Should Mage be third or fourth?
  - Recommendation: fourth. It has the highest implementation burden.
- Should public cards use fantasy-neutral names or archive-neutral names?
  - Recommendation: archive-neutral expedition tools, usable by all four classes.

