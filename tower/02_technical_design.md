# Technical Design

Project codename: **Tower**

Status: Draft

## Technical Goal

Build a maintainable Godot 4.x implementation for a single-player roguelike deckbuilder. The architecture should support data-driven content, reusable combat effects, save/load, fast balance iteration, and later expansion to more characters, cards, relics, events, and enemies.

## Engine Target

- Engine: Godot 4.5 or newer.
- Language: GDScript first.
- Rendering: 2D UI-heavy game using Control nodes and 2D animation.
- Data: Godot Resources for authored content, runtime classes for mutable state.

## Proposed Project Structure

```text
res://scenes/
  main/
  combat/
  map/
  cards/
  ui/
  shop/
  event/
  campfire/

res://scripts/
  core/
  combat/
  cards/
  relics/
  map/
  rewards/
  save/
  ui/

res://data/
  cards/
  relics/
  enemies/
  events/
  potions/
  characters/
  encounters/

res://art/
res://audio/
res://localization/
```

## Core Managers

- `GameManager`: top-level scene flow and global state.
- `RunManager`: current run state, map, deck, relics, gold, HP, act, seed.
- `CombatManager`: combat lifecycle and turn flow.
- `DeckManager`: draw pile, hand, discard pile, exhaust pile operations.
- `CardResolver`: validates and plays cards.
- `EffectResolver`: executes reusable effects.
- `RelicManager`: listens to combat/run events and triggers relic effects.
- `EnemyAIManager`: selects enemy moves and exposes intents.
- `MapGenerator`: creates act maps.
- `RewardGenerator`: creates combat and node rewards.
- `SaveManager`: current-run save, profile save, settings save.
- `AudioManager`: music and sound effects.
- `LocalizationManager`: localized strings.

## Static Data Resources

Recommended Resource classes:

```text
CardData.gd
RelicData.gd
EnemyData.gd
EnemyMoveData.gd
PotionData.gd
EventData.gd
EventChoiceData.gd
CharacterData.gd
EncounterData.gd
StatusData.gd
EffectData.gd
```

## Runtime Instances

Static authored data should not be mutated during a run. Runtime wrappers should hold temporary and run-specific state.

Examples:

- `CardData`: card template.
- `CardInstance`: upgrade state, temporary cost, generated modifiers.
- `RelicData`: relic template.
- `RelicInstance`: counters, cooldowns, per-run state.
- `EnemyData`: enemy template.
- `EnemyInstance`: HP, block, statuses, selected intent.

## Combat Event Flow

Important signals/events:

```text
combat_started
combat_ended
turn_started
turn_ended
card_drawn
card_play_requested
card_played
card_resolved
card_exhausted
damage_calculated
damage_dealt
damage_taken
block_gained
status_applied
enemy_intent_selected
enemy_died
reward_generated
```

## Effect System

The effect system should be reusable across cards, relics, potions, events, and enemy moves.

Initial effect types:

```text
DealDamage(amount, target)
GainBlock(amount, target)
DrawCards(count)
GainEnergy(amount)
ApplyStatus(status_id, stacks, target)
RemoveStatus(status_id, stacks, target)
Heal(amount, target)
LoseHP(amount, target)
AddCardToHand(card_id)
AddCardToDrawPile(card_id)
AddCardToDiscardPile(card_id)
ExhaustCard(selector)
DiscardCard(selector)
UpgradeCard(selector)
ModifyCardCost(selector, amount, duration)
GainGold(amount)
LoseGold(amount)
GainRelic(relic_id)
RemoveCardFromDeck(selector)
TransformCard(selector)
```

## Targeting

Target types:

- Self.
- Single enemy.
- All enemies.
- Random enemy.
- Enemy with lowest HP.
- Enemy with highest HP.
- All characters.
- Card selector.

## Save Design

Separate save files:

- Current run save.
- Profile unlock save.
- Settings save.
- Statistics save.

Current run save should include:

- Seed.
- Selected character.
- Act and map state.
- Current node.
- Player HP, max HP, gold.
- Deck card instance list.
- Relic instance list.
- Potion list.
- Completed encounters and rewards.
- RNG state if deterministic resume is required.

## Testing Plan

Minimum manual tests:

- Start a run.
- Enter combat.
- Play attack, skill, and power cards.
- End turn.
- Enemy attacks.
- Win combat.
- Pick a card reward.
- Enter map node.
- Save and reload.

Automated tests to add later:

- Card effect unit tests.
- Relic trigger tests.
- Deck shuffle consistency tests.
- Enemy AI move selection tests.
- Map generation validity tests.
- Save/load round-trip tests.
- Combat simulation for balance.

## Open Technical Questions

- Should card, relic, and event data be authored as `.tres` Resources, JSON, CSV, or a hybrid?
- Should the effect system use Resource subclasses, dictionaries, or scriptable callbacks?
- How deterministic should seeded runs be after saving and loading?
- Should mod support be planned from the beginning or deferred?
- Should mobile touch input be considered during the first UI pass?
