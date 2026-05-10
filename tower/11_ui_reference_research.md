# UI Reference Research: Slay the Spire Interaction Patterns

Date: 2026-05-10

Purpose: understand proven roguelike deckbuilder UI interaction patterns so **Tower** can build an original interface with similar clarity, not copied visuals.

## Sources Reviewed

- Steam page screenshots and feature description: https://store.steampowered.com/app/646570/Slay_the_Spire/
- Interface In Game screenshot index: https://interfaceingame.com/games/slay-the-spire/
- MobyGames screenshot index: https://www.mobygames.com/game/98734/slay-the-spire/screenshots/
- Map locations reference: https://slay-the-spire.fandom.com/wiki/Map_locations
- Card reward reference: https://slay-the-spire.fandom.com/wiki/Card_Rewards

## Key UI Screens To Emulate Structurally

Do not copy visual art, exact icon silhouettes, text, card frames, or layout assets. Use these only as interaction lessons.

### Main Menu

Observed pattern:

- Strong title/logo.
- Vertical menu options.
- Minimal clutter.
- Immediate access to continue/start.

Tower direction:

- Keep a large title and simple vertical actions.
- Add original archive-themed background.
- Show current run status if a save exists.

### Map Screen

Observed pattern:

- Top bar shows run-critical state: HP, gold, relics, act/floor context.
- Map is a vertical route graph, not a flat list.
- Nodes use distinct icons for event, merchant, rest, enemy, elite, treasure, boss.
- Pathing is the main interaction; reachable nodes are visually distinct.
- Boss is clearly at the top/end.

Tower direction:

- Replace row-button list with a route graph.
- Use original icons: quill/event, lantern/shop, waxfire/rest, mask/combat, crowned seal/elite, keyhole/boss.
- Draw connection lines between nodes.
- Make current reachable nodes glow.
- Move deck summary to a side panel or overlay, not below the map.

### Combat Screen

Observed pattern:

- Player and enemies occupy the central stage.
- Player HP/block and enemy HP/block are near their bodies.
- Enemy intent is prominent above/near enemies.
- Cards sit in a fan/row at the bottom.
- Energy is near the hand.
- Draw/discard/exhaust piles are visible.
- End turn is a large, consistent button.
- Tooltips explain statuses and card details.

Tower direction:

- Build a central combat stage with player left, enemies right.
- Add HP bars and block badges, not only text labels.
- Put intent icon/text directly over each enemy.
- Make cards card-shaped, with cost circle, type label, title, effect text.
- Add draw/discard/exhaust pile counters.
- Add hover enlargement and disabled card dimming.

### Card Reward Screen

Observed pattern:

- Rewards appear as overlay after combat.
- Card choice is a clear 1-of-3 selection.
- Skip option is present.
- Cards use the same visual grammar as combat cards.

Tower direction:

- Reward overlay should darken background.
- Present 3 large cards centered.
- Show "Take" affordance on hover.
- Show skip reward clearly, with exact compensation if any.

### Event Screen

Observed pattern:

- Event art/text sits as focused scene.
- Choices appear as stacked buttons with cost/reward implications.
- Some choices are disabled if requirements are not met.

Tower direction:

- Add event illustration area.
- Show story text in readable width.
- Buttons should preview costs: HP, gold, card removal, curse, reward.

### Campfire

Observed pattern:

- Very focused screen with two primary actions: rest or upgrade.
- Card upgrade flow previews before/after.

Tower direction:

- Campfire should show Rest and Upgrade as large choices.
- Upgrade should open a deck view and let player choose a card.
- Show card upgraded state visually.

### Shop

Observed pattern:

- Shop is item grid plus player gold.
- Cards/relics/potions have prices.
- Card removal is a distinct service.

Tower direction:

- Build shop grid: cards, relics, potions, service.
- Disable unaffordable options and show prices clearly.

## Immediate UI Rework Checklist

1. Build card-shaped `CardView`, not plain buttons.
2. Build combat stage with HP bars, block badges, intent badges, and pile counters.
3. Replace map rows with route graph nodes and connection lines.
4. Add original icon system for map node types.
5. Add reward overlay with large card choices.
6. Add event/campfire/shop dedicated screens with clear choices.
7. Add hover/pressed visual feedback.
8. Add story and task panel, but keep text constrained and readable.
9. Add generated art assets after layout is stable.

## Current Gap Assessment

The current Tower UI is still a functional prototype:

- It has menus, map, combat, rewards, events, shop, campfire, and boss flow.
- It lacks the core visual grammar of a deckbuilder: card faces, route graph, character stage, HP bars, intent icons, and overlay reward presentation.

Next implementation priority should be **visual interaction structure**, not more backend systems.
