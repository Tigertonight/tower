# Tower Game

Godot implementation for the original roguelike deckbuilder project codenamed **Tower**.

## Current State

The project currently boots directly into a first combat prototype.

Implemented prototype features:

- Branching demo route map with combat, event, shop, elite, campfire, and boss nodes.
- Player HP, block, and energy.
- Enemy HP, block, and attack intent.
- Draw pile, hand, discard pile, and reshuffle.
- Clickable card buttons.
- Damage, block, draw, energy, and vulnerable effects.
- Turn end and enemy attack.
- Victory and defeat checks.
- Card reward screen after victory.
- Run deck growth after choosing a reward.
- Starter relic trigger with end-of-combat healing.
- Lightweight run save for deck and combat progress.
- Demo completion state after defeating the boss.
- Campfire card upgrades.
- Enemy attack and defend intents.
- Story prologue and task/objective panel.
- Floating combat feedback for damage, block, draw, and attack slash.
- Green-background placeholder art sources for later slicing.
- Card-shaped card buttons for hand and reward choices.
- Compact route-node map layout.
- Custom route map control with node connection lines.
- Player and enemy HP bars plus block labels.
- Energy HUD and pile counters.
- Styled enemy intent badge.
- Card hover lift/scale animation.
- Full-screen dimmed reward overlay.
- Generated character/enemy/boss/key sprites integrated into combat and completion screens.
- Main menu uses generated character/key art.
- Event/shop/campfire screens use story/action two-column layout.
- Screenshot-reviewed combat layout with a visible bottom hand, energy orb, pile counters, and end-turn button.
- Screenshot-reviewed map layout with compact connected route nodes and a deck/status panel.
- P0 card UI pass: cards are composed controls with cost orb, rarity tag, title band, art glyph area, type strip, rules text, hover lift, and type-colored frames.
- Combat polish pass: overlay turn banner, symbolic enemy intent display, card-play ghost animation, focus pulse for non-attack cards, and screenshot-verified safe-area layout.
- Map polish pass: compact icon node labels and hover preview panel.
- Reward polish pass: authored "Archive Spoils" overlay with gold line and centered reward cards.
- Generated scene backgrounds integrated for combat and route map.
- Player/enemy status HUD rows added to combat.
- Combat layout now uses fixed 1280x720 deckbuilder zones instead of VBox-driven vertical stacking.
- Map objective prompt is compact and left-aligned; story/completion art ignores source image size to prevent oversized texture overflow.

## Run

From the repository root:

```powershell
godot --path .\tower_game
```

Headless load check:

```powershell
godot_console --headless --path .\tower_game --quit
```

Smoke test:

```powershell
godot_console --headless --path .\tower_game --script res://scripts/tests/smoke_test.gd
```

## Notes

Art is placeholder-only for now. Generated assets should be placed under:

```text
art/generated/
```

Current run progress is saved to:

```text
user://tower_run.json
```
