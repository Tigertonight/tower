# Implementation Plan

Project codename: **Tower**

Status: Draft

## Development Strategy

Build vertically, not by isolated mega-systems.

First milestone:

```text
One playable combat with starter deck, one enemy, turn flow, damage, block, draw/discard, and victory.
```

Then expand into rewards, map, relics, and save.

## Godot Project Location

Recommended project path:

```text
C:\Users\admin\Documents\Codex\2026-05-10\godot-1-review\tower_game
```

Documentation remains in:

```text
C:\Users\admin\Documents\Codex\2026-05-10\godot-1-review\tower
```

## Initial Godot Project Structure

```text
tower_game/
  project.godot
  scenes/
    main/
      main.tscn
    combat/
      combat_scene.tscn
      card_view.tscn
      enemy_view.tscn
    ui/
      tooltip.tscn
  scripts/
    core/
      game_manager.gd
      run_manager.gd
    combat/
      combat_manager.gd
      combat_state.gd
      enemy_instance.gd
    cards/
      card_data.gd
      card_instance.gd
      deck_manager.gd
      card_resolver.gd
      effect_data.gd
      effect_resolver.gd
    relics/
      relic_data.gd
      relic_instance.gd
      relic_manager.gd
    enemies/
      enemy_data.gd
      enemy_move_data.gd
    ui/
      card_view.gd
      enemy_view.gd
  data/
    cards/
    relics/
    enemies/
    characters/
  art/
    placeholder/
```

## Milestone 1: Combat Skeleton

Goal:

One combat can start, progress through turns, and end.

Tasks:

1. Create Godot project.
2. Create main scene.
3. Create combat scene.
4. Add placeholder player and enemy UI.
5. Implement `CombatManager`.
6. Implement player HP, block, energy, and turn state.
7. Implement enemy HP, block, and simple attack intent.
8. Implement end turn button.
9. Implement victory and defeat checks.

Done when:

- Player can end turn.
- Enemy attacks.
- HP and block update.
- Combat can be won or lost through debug actions or simple cards.

Current status:

- Done in the first prototype pass.
- Implemented in `tower_game/scenes/combat/combat_scene.tscn` and `tower_game/scripts/combat/combat_manager.gd`.

## Milestone 2: Card Core

Goal:

The starter deck works.

Tasks:

1. Create `CardData` Resource.
2. Create `CardInstance`.
3. Create `DeckManager`.
4. Implement draw pile, hand, discard pile, exhaust pile.
5. Create card UI.
6. Implement card hover and click-to-play.
7. Implement energy costs.
8. Implement targeting for single enemy cards.
9. Implement `EffectResolver`.
10. Add Strike Form, Guard Form, and Archive Bash.

Done when:

- Player draws 5 cards.
- Player can play starter cards.
- Attack cards damage the enemy.
- Skill cards grant block.
- End turn discards hand.
- Empty draw pile shuffles discard pile.

Current status:

- Done for the prototype.
- Supports draw pile, hand, discard pile, energy costs, playable cards, damage, block, draw, energy, and vulnerable.
- Card UI is extracted into `CardView`.
- Initial cards are authored as `.tres` resources.

## Milestone 3: Enemy Intent and Statuses

Goal:

Combat starts to feel like a card battler instead of a static damage race.

Tasks:

1. Add `EnemyData`.
2. Add `EnemyMoveData`.
3. Show enemy intent.
4. Implement weighted move selection.
5. Implement Vulnerable.
6. Implement Weak.
7. Implement Strength.
8. Implement simple status tooltip.

Done when:

- Enemy telegraphs next move.
- Player can apply Vulnerable.
- Statuses affect damage.

## Milestone 4: Rewards

Goal:

One combat feeds into deckbuilding.

Tasks:

1. Create reward scene.
2. Generate 3 card choices.
3. Allow skipping.
4. Add chosen card to deck.
5. Add gold rewards.
6. Add basic potion reward placeholder.

Done when:

- Winning combat opens reward screen.
- Picking a card changes the run deck.

Current status:

- Done for the prototype.
- Victory opens a reward screen with 3 cards and skip.
- Picking a card appends it to the run deck and starts the next test combat.

## Milestone 5: Relics

Goal:

Passive effects can listen to combat events.

Tasks:

1. Create `RelicData`.
2. Create `RelicInstance`.
3. Create `RelicManager`.
4. Add event hooks.
5. Implement Sealed Badge.
6. Implement two simple common relics.
7. Show relic icons as placeholders.

Done when:

- Starter relic heals at combat end.
- At least one combat-start relic triggers.

Current status:

- Partially done.
- Starter relic `Sealed Badge` triggers on combat victory and heals 5 HP.
- Combat-start relic support still needs another test relic.

## Milestone 6: Map

Goal:

The player can move between nodes.

Tasks:

1. Create map scene.
2. Generate short MVP map.
3. Render nodes and connections.
4. Allow selecting reachable nodes.
5. Route normal combat nodes into combat.
6. Add boss node placeholder.

Done when:

- Player can progress through a short route.

Current status:

- Done for the prototype.
- A branching route map now supports combat, event, shop, elite, campfire, and boss nodes.
- Procedural map generation is still pending.

## Milestone 7: Shop, Campfire, Event

Goal:

The non-combat node loop exists.

Tasks:

1. Create shop scene.
2. Create campfire scene.
3. Create event scene.
4. Implement card removal.
5. Implement rest and upgrade.
6. Implement 2 event templates.

Done when:

- Player can interact with all MVP node types.

Current status:

- Done for the prototype.
- Event, shop, and campfire have minimal but functional choices.
- Campfire now supports card upgrades.

## Milestone 8: Save and Resume

Goal:

Current run can survive closing the game.

Tasks:

1. Create `SaveManager`.
2. Serialize run state.
3. Serialize deck card IDs and upgrade states.
4. Serialize relics, gold, HP, map position.
5. Add continue button.
6. Add save on node entry and reward completion.

Done when:

- Close and reopen the game.
- Continue resumes current run.

Current status:

- Partially done.
- Current prototype saves run deck IDs and combat progress.
- Full map position, HP, relic state, and reward state still need the final save schema.

## First Implementation Order

Immediate next steps:

1. Create `tower_game` Godot project.
2. Add minimal scene structure.
3. Add initial scripts for card data and combat state.
4. Build first combat screen with placeholder UI.
5. Verify with `godot_console --headless --path tower_game --quit` or equivalent project load check.

## Engineering Rules

- Keep data templates immutable during runs.
- Keep runtime state separate from static Resources.
- Use signals/events for combat triggers.
- Avoid hardcoding card-specific logic in UI.
- Keep cards and relics using the same effect resolver where possible.
- Prefer placeholder art until gameplay is stable.
- Update project log after each milestone.

## Known Early Risks

| Risk | Mitigation |
| --- | --- |
| Effect system becomes too rigid. | Start with simple effect resources but keep target and condition fields extensible. |
| UI consumes too much time. | Use clean placeholders for MVP. Polish later. |
| Map generation distracts from combat. | Build static test map first, then procedural generation. |
| Save schema changes often. | Save only MVP run state first. Version the save data. |
