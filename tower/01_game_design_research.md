# Game Design Research and Complete Plan

Project codename: **Tower**

Date: 2026-05-10

## Positioning

The target is an original single-player 2D turn-based roguelike deckbuilder built with Godot. The game can learn from the successful structure of *Slay the Spire*: deck construction, branching route maps, turn-based card combat, relics, events, shops, elites, bosses, randomness, and permadeath.

The project should not directly copy characters, art, card names, card text, relic names, event writing, enemy designs, UI assets, or exact numerical tables from any existing game.

## Research Summary

Godot 4.x is suitable for this project because:

- Scenes and nodes can represent combat screens, map screens, cards, enemies, UI panels, and reusable components.
- Godot Resources can store data definitions for cards, relics, enemies, events, potions, and characters.
- Signals are useful for a decoupled combat event flow.
- Control nodes are suitable for card UI, map UI, shops, rewards, and tooltips.

The core public feature set of the genre includes:

- Crafting a deck over a run.
- Choosing a path through a procedural map.
- Resolving turn-based combat with cards.
- Collecting passive relic-like modifiers.
- Taking calculated risks through elites, events, shops, and campfires.
- Starting over after death while unlocking long-term content.

Reference sources:

- Godot official documentation: https://docs.godotengine.org/
- Godot Nodes and Scenes: https://docs.godotengine.org/en/4.5/getting_started/step_by_step/nodes_and_scenes.html
- Godot Resources: https://docs.godotengine.org/en/4.5/getting_started/step_by_step/resources.html
- Slay the Spire Steam page: https://store.steampowered.com/app/646570/Slay_the_Spire/
- Slay the Spire community wiki: https://slaythespire.wiki.gg/

## Product Goal

Genre: single-player 2D turn-based roguelike deckbuilder.

Primary platform: PC first, with possible mobile support later.

Engine: Godot 4.5 or newer.

Core fantasy: the player chooses a character, enters a dangerous layered route, builds a deck through rewards and events, collects relics, defeats bosses, and either clears the run or dies and starts again.

Potential original themes:

- Sci-fi: descending into a broken orbital city.
- Eastern fantasy: entering a nine-layer spirit ruin.
- Wasteland: crossing a ruined megastructure.
- Arcane academy: entering a forbidden library tower.
- Biopunk: diving through the body of a colossal organism.

## Core Game Loop

Single-run loop:

1. Choose a character.
2. Generate the map.
3. Pick a route node.
4. Enter node content: combat, elite, event, shop, campfire, treasure, or boss.
5. Gain rewards or pay costs.
6. Improve the deck, relic set, potion inventory, and build direction.
7. Move to the next connected node.
8. Defeat the act boss to enter the next act.
9. Win or die.
10. Unlock long-term content based on run performance.

Combat loop:

1. Combat starts, opening hand is drawn, start-of-combat effects trigger.
2. Player turn starts: energy is gained, cards are drawn, statuses trigger.
3. Player plays cards while reading enemy intents.
4. Player ends turn.
5. Enemy turn resolves according to visible intents.
6. End-of-round cleanup occurs.
7. Repeat until all enemies die or the player dies.
8. Victory rewards are generated.

## Character System

Each character should define:

- Starting deck.
- Starting health.
- Starting gold.
- Starting relic.
- Exclusive card pool.
- Exclusive mechanics.
- Unlock rules.
- Statistics.

Recommended first three characters:

### Armed Vanguard

Role: balanced, beginner-friendly.

Mechanics:

- Rage.
- Block counterattacks.
- Damage scaling.

Build directions:

- Strength scaling.
- Defensive counterattack.
- Self-damage and healing.

### Shadow Operator

Role: combo, poison, discard.

Mechanics:

- Combo points.
- Poison.
- Draw and discard loops.

Build directions:

- Poison kill.
- High-cycle burst.
- Dodge and block.

### Core Engineer

Role: modules, charge, delayed payoff.

Mechanics:

- Module slots.
- Charge.
- Automatic triggers.

Build directions:

- Module turret.
- Zero-cost loop.
- Charge burst.

## Card System

Recommended card fields:

```text
id
name
character_id
rarity: basic/common/uncommon/rare/special/status/curse
type: attack/skill/power/status/curse
cost
target_type
effects[]
upgrade_effects[]
tags[]
exhaust
ethereal
retain
description_template
art_path
```

Card types:

- Attack: direct damage.
- Skill: block, draw, energy, status effects.
- Power: long-term combat effect.
- Status: temporary negative combat card.
- Curse: persistent negative deck card.
- Special: event, relic, or boss-generated card.

Suggested keywords:

- Exhaust: remove from combat after play.
- Retain: stays in hand at end of turn.
- Ethereal: exhausts at end of turn if not played.
- Innate: always appears in opening hand.
- Combo: improves after previous cards are played this turn.
- Vulnerable: target receives more attack damage.
- Weak: target deals less attack damage.
- Frail: target gains less block.
- Poison: loses health each turn and decreases by 1.
- Barrier: block is not removed at end of turn.
- Overload: gain immediate benefit with a next-turn penalty.

## Relic System

Recommended relic fields:

```text
id
name
rarity: common/uncommon/rare/boss/shop/event
trigger
condition
effect
stack_rule
description
```

Trigger points:

- run_start
- combat_start
- turn_start
- card_played
- attack_played
- skill_played
- enemy_killed
- damage_taken
- gold_gained
- reward_generated
- combat_end
- shop_entered
- rest_site_entered

Design principles:

- Relics should clarify deck direction.
- Relics should influence route choice.
- Strong combinations are good, but single relics should not solve the whole game.
- Boss relics can be powerful but should often include tradeoffs.

## Potion System

Potions are one-use combat items.

Suggested potion types:

- Damage potion.
- Block potion.
- Draw potion.
- Energy potion.
- Cleanse potion.
- Temporary rare-card potion.
- Duplicate-next-card potion.
- Temporary power potion.

## Map and Node System

The map should be a directed acyclic graph per act.

The player starts from several bottom nodes and moves upward through connected nodes until reaching the act boss.

Node types:

- Normal combat.
- Elite combat.
- Event.
- Shop.
- Campfire.
- Treasure.
- Boss.
- Hidden node for future expansion.

Recommended act structure:

```text
Act 1: onboarding and early build formation.
Act 2: deck direction pressure test.
Act 3: high-pressure consistency and final boss test.
Hidden finale: optional later expansion.
```

Recommended node distribution:

- 12 to 16 rows per act.
- Normal combat: 45% to 55%.
- Events: 15% to 25%.
- Elites: 8% to 15%.
- Shops: 8% to 12%.
- Campfires: 8% to 12%.
- Treasure: 3% to 8%.
- Boss: fixed at top.

Generation constraints:

- At least 3 starting nodes.
- A campfire should appear before each boss.
- Avoid 3 identical non-combat node types in a row.
- Elites should not appear in the first 2 rows.
- Shops should not be adjacent to shops.
- Every route should have at least one meaningful branch decision.

## Combat System

Base rules:

- Base energy per turn: 3.
- Base draw per turn: 5.
- Hand size limit: 10.
- When draw pile is empty, shuffle discard pile into draw pile.
- At turn end, discard all non-retained cards.
- Block normally clears at end of player turn.

Player runtime state:

```text
hp
max_hp
block
energy
draw_pile
hand
discard_pile
exhaust_pile
powers
relics
potions
```

Enemy runtime state:

```text
id
hp
max_hp
block
intent
moveset
powers
status
ai_pattern
```

Enemy intent types:

- Attack.
- Defend.
- Attack plus debuff.
- Buff self.
- Debuff player.
- Summon.
- Charge.
- Escape.
- Special mechanic.

Enemy move definition:

```text
move_id
weight
cooldown
cannot_repeat
condition
intent_preview
effects
```

Bosses should include phase mechanics:

- Health threshold phase changes.
- Scheduled power turns.
- Debuff clearing or shield gaining.
- Pressure against one-dimensional builds.

## Rewards and Economy

Combat rewards:

- Gold.
- Card choice.
- Potion drop chance.
- Elite or boss relics.
- Special event rewards.

Card reward rules:

- Draw from the character card pool.
- Normal combats prefer common and uncommon cards.
- Elites increase uncommon and rare odds.
- Bosses offer rare cards and boss relics.
- Skipping card rewards should be supported.

Shop inventory:

- Cards.
- Relics.
- Potions.
- Card removal.
- Special services, such as upgrade, transform, or duplicate.

Suggested economy:

- Normal combat gold: 10 to 20.
- Elite gold: 25 to 40.
- Common card price: 40 to 60.
- Uncommon or rare card price: 70 to 120.
- Relic price: 150 to 300.
- Card removal starts at 75 and increases after each use.

## Campfire System

Base options:

- Rest: recover about 30% max HP.
- Upgrade: upgrade one card.

Expandable options:

- Forge: enhance a relic.
- Meditate: remove one card at the cost of HP.
- Scout: reveal part of the next act map.
- Character-exclusive campfire actions.

## Event Design

Events should be meaningful risk-reward choices, not only random gifts.

Event categories:

- Pay HP for relic.
- Pay gold for card removal.
- Gain curse for powerful card.
- Lose max HP for upgrades.
- Combat event.
- Randomly transform cards.
- Duplicate cards.
- Gain special relics.
- Modify upcoming map nodes.

Event fields:

```text
event_id
title
body
choices[]
conditions
result_effects
seen_weight
act_allowed
```

Choice fields:

```text
text
requirements
preview
effects
```

Initial content target:

- 12 to 18 events per act.
- 20 global events.
- 3 to 5 character-specific events per character.

## Content Scope

MVP content:

- 1 character.
- 60 character cards.
- 40 relics.
- 15 potions.
- 20 normal enemies.
- 6 elites.
- 3 bosses.
- 25 events.
- 3 acts.
- Save system, settings, compendium, basic unlocks.

Version 1.0 content:

- 3 characters.
- 75 to 90 cards per character.
- 120 to 180 relics.
- 30 to 45 potions.
- 45 to 60 normal enemies.
- 12 to 18 elites.
- 9 to 12 bosses.
- 60 to 90 events.
- Character unlock tracks.
- Ascending difficulty system.
- Daily challenge or seed system.
- Compendium, statistics, achievements.

## UI and Interaction Design

Main menu:

- Start run.
- Continue run.
- Character select.
- Compendium.
- Statistics.
- Settings.

Combat screen:

- Player on the left.
- Enemies on the right.
- Cards at the bottom.
- Draw, discard, and exhaust piles near the bottom.
- Relics at top.
- Energy display.
- End turn button.
- Clear enemy intent display.
- Hover card zoom.
- Targeting line.
- Status tooltips.

Map screen:

- Branching node graph.
- Available nodes highlighted.
- Completed path marked.
- Route preview.
- Current HP, gold, relics, and deck access.

Reward screen:

- Card choice.
- Skip button.
- Deck viewer.
- Clear reward order.

Shop screen:

- Card section.
- Relic section.
- Potion section.
- Card removal.
- Current gold.
- Tooltips.

## Balance Principles

Initial character baseline:

```text
Max HP: 70 to 80
Starting deck: 10 cards
Basic attacks: 5
Basic defends: 4
Special card: 1
Base energy: 3
Base draw: 5
```

Card value baseline:

```text
1-cost attack: 6 to 8 damage
1-cost defense: 5 to 8 block
2-cost attack: 12 to 18 damage
0-cost card: low raw value but strong tempo or combo utility
```

Rarity expectations:

- Common cards solve basic problems.
- Uncommon cards guide build direction.
- Rare cards offer strong direction or high risk-reward.
- Powers trade immediate tempo for long-term value.

Difficulty curve:

- Act 1 helps the player form a build.
- Act 2 punishes missing defense, scaling, or area control.
- Act 3 tests consistency, burst, and sustain.
- Finale tests complete build quality.

Ascending difficulty system:

Use an original name such as Depth Level, Calamity Level, or Descent Level.

Each level should change one pressure point:

- Higher enemy HP.
- Stronger elites.
- Stronger bosses.
- Lower starting gold.
- Reduced healing.
- Harsher events.
- Starting negative card.
- More dangerous enemy patterns.

## Development Roadmap

### Phase 0: Prototype, 1 to 2 weeks

Goals:

- Draw pile, hand, discard pile, exhaust pile.
- Play cards and spend energy.
- Enemy intent.
- Turn switching.
- Win and loss state.

Deliverable:

- One test combat.
- 10 test cards.
- 3 enemies.
- No map.

### Phase 1: MVP Combat Loop, 3 to 5 weeks

Goals:

- Data-driven cards.
- Basic statuses.
- Basic relics.
- Combat rewards.
- Deck viewer.
- Save and load.

Deliverable:

- 1 character.
- 40 to 60 cards.
- 20 relics.
- 10 enemies.

### Phase 2: Map and Run Flow, 3 to 4 weeks

Goals:

- Random map.
- Node system.
- Shop.
- Campfire.
- Events.
- Boss fight.

Deliverable:

- Full playable run.
- 3 acts.
- One boss per act.

### Phase 3: Content Expansion, 6 to 10 weeks

Goals:

- More roles, cards, relics, enemies, and events.
- Build diversity.
- Balance testing.
- UI animation and audio.

Deliverable:

- Playable demo candidate.

### Phase 4: Version 1.0 Polish, 8 to 12 weeks

Goals:

- 3 characters.
- Ascending difficulty.
- Compendium.
- Statistics.
- Achievements.
- Daily challenge or seed system.
- Localization.
- Performance.
- Bug fixing.

## Priority

Build first:

1. Combat system.
2. Card effect system.
3. Data-driven cards.
4. Enemy intent.
5. Card reward choice.
6. Map nodes.
7. Save system.

Avoid building too early:

- Large art production.
- Complex story.
- Localization.
- Achievements.
- Daily challenge.
- Mobile support.
- Too many characters.

Highest refactor risk:

- Card effect system.
- Relic trigger system.
- Save structure.
- UI resolution adaptation.
- Event data format.
- Enemy AI representation.

## Completeness Review

Covered systems:

- Core combat.
- Cards and card piles.
- Energy.
- Enemy intent.
- Statuses.
- Relics.
- Potions.
- Map.
- Nodes.
- Shop.
- Campfire.
- Events.
- Bosses.
- Rewards.
- Characters.
- Unlocks.
- Ascending difficulty.
- Save system.
- Compendium.
- Statistics.
- Godot architecture.
- Content scale.
- Development roadmap.

Areas that still need dedicated documents:

1. Detailed numerical tables for cards, enemies, relics, events, and economy.
2. Original world setting and art direction.
3. Card effect DSL or data format.
4. Save schema.
5. Automated simulation and testing plan.
6. Copyright and originality checklist.
7. Locked demo scope.
