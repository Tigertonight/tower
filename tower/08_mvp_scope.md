# MVP Scope

Project codename: **Tower**

Status: Draft locked for first playable prototype

## Goal

Build a small but complete playable slice of the roguelike deckbuilder loop:

```text
Start run -> choose first character -> move through a short map -> fight enemies -> gain rewards -> improve deck -> defeat boss or die
```

The MVP should prove the game can support:

- Turn-based card combat.
- Deck growth and card rewards.
- Branching route choices.
- Relic-triggered passive effects.
- Basic shops, campfires, and events.
- Saving and resuming a run.

## Temporary Theme

Temporary MVP theme: **forbidden tower/archive**.

The player enters a living archive tower where memories, weapons, debts, and old contracts have become hostile. This is only a working direction so development can begin without waiting for full worldbuilding.

Design benefits:

- Cards can be framed as techniques, oaths, seals, and tactics.
- Relics can be framed as archive fragments, tools, badges, and forbidden objects.
- Enemies can be scribes, animated armor, bound spirits, failed explorers, and archive guardians.
- UI can use parchment, ink, metal, wax, and subtle arcane light without copying existing card battler UI.

## MVP Content Targets

| Category | Target |
| --- | --- |
| Characters | 1 |
| Acts | 1 short act |
| Map rows | 7 to 9 |
| Normal enemies | 5 |
| Elite enemies | 2 |
| Bosses | 1 |
| Cards | 30 |
| Relics | 10 |
| Potions | 5 |
| Events | 5 |
| Shops | 1 node type |
| Campfires | 1 node type |
| Save system | Current run only |

## MVP Character

First character: **Vanguard Archivist**.

Role:

- Balanced attack and defense.
- Easy to test.
- Supports core combat without needing complex mechanics.

Core mechanics:

- Guard: block and defensive payoff.
- Momentum: temporary attack scaling.
- Retaliate: rewards blocking before attacking.

## MVP Combat Features

Required:

- Draw pile, hand, discard pile, exhaust pile.
- Energy.
- End turn.
- Enemy intent display.
- Target selection.
- Attack, skill, and power card types.
- Basic statuses.
- Enemy AI move selection.
- Victory and defeat states.
- Card reward screen.

Deferred:

- Multi-character party.
- Complex animation timing.
- Summons.
- Transforming enemies.
- Hidden final acts.
- Daily challenge.
- Custom mode.

## MVP Card Effects

Required effect types:

- Deal damage.
- Gain block.
- Draw cards.
- Gain energy.
- Apply status.
- Gain temporary or permanent strength.
- Exhaust a card.
- Apply power.
- Add temporary card to hand.

Required statuses:

- Vulnerable.
- Weak.
- Frail.
- Poison or burn-like damage over time.
- Strength.
- Guard, project-specific defensive state.

## MVP Map Nodes

Required nodes:

- Normal combat.
- Elite combat.
- Event.
- Shop.
- Campfire.
- Treasure.
- Boss.

Map constraints:

- At least 2 starting routes.
- Boss at the top.
- Campfire before boss.
- At least one elite route and one safer route.
- No shop directly after shop.

## MVP Rewards

Required:

- Gold.
- Card reward, 3 options plus skip.
- Relic reward.
- Potion reward.

Deferred:

- Rare reward animations.
- Complex reward manipulation relics.
- Character unlock rewards.

## MVP Shop

Required:

- 3 cards.
- 2 relics.
- 2 potions.
- Remove one card.

Deferred:

- Shop-exclusive relic pool.
- Discount rules.
- Special services.

## MVP Campfire

Required:

- Rest.
- Upgrade one card.

Deferred:

- Character-specific campfire actions.
- Relic upgrades.
- Map scouting.

## MVP Events

Required event patterns:

- Pay HP for relic.
- Pay gold to remove a card.
- Gain curse for powerful reward.
- Upgrade a card at a cost.
- Fight or flee event.

## MVP Save

Required:

- Save current run when entering a new node.
- Save after combat rewards are resolved.
- Resume from main menu.

Deferred:

- Cloud save.
- Multiple save slots.
- Replay history.
- Deterministic rollback.

## Non-Goals

The MVP will not include:

- Three characters.
- Three full acts.
- Final secret boss.
- Achievements.
- Daily challenges.
- Localization.
- Mobile UI.
- Full art production.
- Voice acting.
- Mod support.
- Online features.

## Exit Criteria

MVP is considered complete when:

- A fresh run can be started.
- The player can move through a generated map.
- The player can complete at least 5 combats.
- The player can gain cards, relics, potions, and gold.
- The player can rest or upgrade at campfires.
- The player can buy and remove cards in shops.
- The player can defeat or lose to the MVP boss.
- The player can close the game and resume the current run.
- The game has placeholder art but no missing core UI.
