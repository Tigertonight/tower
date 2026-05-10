# Frontend UI Upgrade Plan

Date: 2026-05-10

Goal: raise the current Godot demo from a functional prototype to a polished, demo-ready roguelike deckbuilder interface inspired by the interaction structure of Slay the Spire, while keeping all art, names, writing, iconography, and theme original to **Living Archive**.

Current assessment: the architecture is recognizable, but the presentation still feels like a debug UI. It needs a composed combat stage, readable card language, stronger visual hierarchy, richer transitions, scene-specific backgrounds, and consistent asset direction before it can be shown as a convincing demo.

## Definition of Done

The UI pass is complete when:

- [ ] A new player can understand the main loop within 30 seconds: choose route, enter combat, play cards, end turn, choose reward.
- [x] Combat screen has a strong visual center: player left, enemy right, intent clearly readable, hand and energy always visible.
- [x] Cards feel like cards, not rectangular buttons: cost badge, name band, type/rarity treatment, readable rules text, hover focus.
- [ ] Map screen feels like a climb: connected route nodes, current choices, locked future path, run status, deck/relic summary.
- [ ] Reward, event, shop, campfire, victory, and defeat screens feel like game screens, not plain forms.
- [ ] All screens fit at 1280x720 and 1600x900 without clipping, overlapping, or hiding critical controls.
- [ ] Screenshot review confirms visual hierarchy, spacing, and readability.
- [ ] Smoke test and one manual run-through pass after each major phase.

## Phase 1: Visual Foundation

Purpose: replace the current generic Control look with a unified original art direction.

### Work Items

- [ ] Define a compact UI style guide for Living Archive: colors, fonts, borders, shadows, panels, card colors, icon style.
- [ ] Create a reusable `ThemeFactory` pass for buttons, labels, panels, progress bars, and tooltips.
- [x] Replace flat black backgrounds with layered scene backgrounds: dark archive, warm route parchment, combat floor, reward glow.
- [ ] Add consistent panel frames with subtle texture-like color layering.
- [x] Establish UI scale tokens: top bar height, card size, hand area, side panel width, node size.
- [ ] Add font-size tiers: screen title, section label, body, card title, card rules, numeric badges.
- [ ] Verify all screens at 1280x720.

### Implementation Notes

- Keep cards and controls in Godot `Control` nodes for speed.
- Use generated bitmap backgrounds for mood and local shader/color overlays for polish.
- Avoid copying source UI art. Use only original symbols and original theme terms.

### Acceptance Checklist

- [ ] Screens no longer look like default Godot UI.
- [ ] Buttons, panels, and labels share one visual language.
- [ ] Text contrast passes screenshot review.

## Phase 2: Combat Screen Rebuild

Purpose: make combat the main selling scene of the demo.

### Target Layout

Top bar:

- run title / floor
- HP, block, energy
- draw, discard, exhaust counts
- relics

Middle stage:

- player on left with HP bar, block shield, status icons
- enemy on right with HP bar, block shield, status icons
- enemy intent above or near enemy, visually dominant
- attack/skill effects traveling through center

Bottom interaction:

- large energy orb
- five-card hand in an arced or fanned row
- draw/discard/exhaust pile buttons
- clear end-turn button
- combat log compact and non-blocking

### Work Items

- [ ] Split combat UI into named components: `CombatHud`, `CombatStage`, `HandView`, `PileHud`, `IntentBadge`.
- [x] Replace current large panel boxes with a stage composition: floor band, entity anchors, HP bars near entities.
- [x] Create player and enemy anchor positions independent of art image size.
- [x] Add enemy intent icon variants: attack, heavy attack, defend, buff/debuff.
- [x] Add player/enemy status icon row with tooltips.
- [ ] Move combat log into a small bottom-left or center toast area.
- [x] Add turn banner: `Player Turn`, `Enemy Turn`, `Victory`.
- [x] Add card play animation: selected card lifts, moves forward, fades to discard.
- [x] Add attack effect: slash/projectile from player to enemy, hit flash, floating damage number.
- [x] Add block effect: shield pulse and blue floating number.
- [ ] Add enemy attack animation: enemy lunge/flash, player hit flash.
- [ ] Add disabled-state card dimming that still preserves readability.
- [x] Verify bottom HUD is always visible.

### Acceptance Checklist

- [x] The enemy intent can be identified at a glance.
- [x] The player always knows current energy and available cards.
- [x] Playing a card gives visible feedback within 0.2 seconds.
- [x] End Turn is impossible to miss.

## Phase 3: Card UI Upgrade

Purpose: make cards the tactile core of the game.

### Card Anatomy

- cost badge at top-left
- rarity/type small label
- card name band
- optional card art window
- rules text box
- type-colored frame
- upgraded treatment with glow or `+`

### Work Items

- [x] Replace `Button`-text cards with a custom `CardView` scene composed of Labels, Panels, and optional TextureRect.
- [ ] Add generated card art placeholders for attack, skill, and power categories.
- [ ] Add card frame styles for attack, skill, power, curse/status.
- [x] Add cost orb as a separate child node.
- [x] Add hover preview: card scales up, rises, and shows full rules text.
- [ ] Add selected/targeting state for future enemy targeting.
- [ ] Add upgraded visual treatment.
- [ ] Add tooltip or enlarged inspector for long text.
- [x] Ensure card text wraps cleanly with no clipping.

### Acceptance Checklist

- [x] Cards read clearly from screenshot scale.
- [ ] Hovered card feels interactive and important.
- [x] Different card types are visually distinct.
- [x] Card layout does not depend on text-only button sizing.

## Phase 4: Route Map Upgrade

Purpose: turn the map from a debug route graph into a compelling climb screen.

### Work Items

- [ ] Add parchment/archive background image or generated route backdrop.
- [ ] Replace text node labels with original icons: combat blade, elite seal, event ink, shop coin, campfire waxlight, boss key.
- [ ] Use circular/sigil node buttons with icon-first design and tooltip details.
- [ ] Draw active route connections brighter than future locked connections.
- [x] Add route selection preview: hover node shows title, risk/reward, and expected scene.
- [ ] Add current floor marker and completed node marker.
- [ ] Add run summary panel: HP, gold, deck count, relics.
- [ ] Add deck summary modal or side panel with scroll.
- [ ] Add map entrance/exit transition when entering a node.
- [ ] Verify all branches remain clickable and unclipped at 1280x720.

### Acceptance Checklist

- [ ] Route choices are visually obvious.
- [ ] Locked nodes read as future possibilities, not broken UI.
- [ ] The screen communicates climbing toward a boss.

## Phase 5: Reward, Event, Shop, Campfire Screens

Purpose: make non-combat nodes feel like authored game moments.

### Reward Screen

- [x] Use a full-screen dim overlay with three large card rewards.
- [x] Add gold/relic reward line before card choice.
- [ ] Add skip reward button with clear compensation.
- [ ] Add card hover zoom identical to combat.
- [ ] Add reward collect animation.

### Event Screen

- [ ] Add story illustration panel using generated archive scene art.
- [ ] Add meaningful choice buttons with cost/reward preview.
- [ ] Add result state after choice before returning to map.
- [ ] Add HP/gold/deck change animation.

### Shop Screen

- [ ] Build a shop grid: cards, removal service, maybe relic slot.
- [ ] Add price tags and disabled affordable state.
- [ ] Add vendor visual and warm lighting.
- [ ] Add purchase feedback and updated gold.

### Campfire Screen

- [ ] Add campfire/waxlight scene background.
- [ ] Make Rest and Upgrade big icon actions.
- [ ] Add upgrade card preview before confirming.
- [ ] Add heal/upgrade result animation.

### Acceptance Checklist

- [ ] Every map node type has a unique screen identity.
- [ ] Choices show consequences before selection.
- [ ] Returning to map feels smooth.

## Phase 6: Generated Asset Pass

Purpose: replace placeholder-like visuals with coherent original bitmap assets.

### Asset List

- [x] Combat background: Living Archive floor.
- [x] Map background: parchment/tower route board.
- [ ] Player idle sprite, cleaned transparent PNG.
- [ ] Enemy set: Dust Scribe, Index Knight, Sealed Curator.
- [ ] Intent icons: attack, heavy attack, defend, buff/debuff.
- [ ] Node icons: combat, elite, event, shop, campfire, boss.
- [ ] Card art set: at least 12 small illustrations.
- [ ] Reward glow/treasure effect.
- [ ] Shop vendor or counter scene.
- [ ] Campfire/waxlight scene.
- [ ] Victory key scene.

### Generation Rules

- Use original Living Archive prompts only.
- Generate on green background or transparent-friendly composition when slicing sprites.
- Store source sheets in `tower_game/art/generated/sources/`.
- Store cut sprites in `tower_game/art/generated/sprites/`.
- Store UI backgrounds in `tower_game/art/generated/backgrounds/`.
- Keep filenames semantic and lowercase.

### Acceptance Checklist

- [ ] No generated asset includes copied copyrighted characters, logos, or recognizable Slay the Spire art.
- [ ] Sprites have clean alpha edges.
- [ ] Assets are tracked in `04_asset_generation.md`.

## Phase 7: Motion and Game Feel

Purpose: make interactions feel alive even before deep content/balance polish.

### Work Items

- [ ] Add screen fade transitions between menu, map, combat, rewards, and events.
- [ ] Add card hover lift and drop shadow.
- [ ] Add card play path tween.
- [ ] Add draw animation from draw pile into hand.
- [ ] Add discard animation into discard pile.
- [ ] Add hit pause on damage.
- [ ] Add enemy intent pulse at start of player turn.
- [ ] Add HP bar tween instead of instant change.
- [ ] Add button hover/click audio placeholders if audio pipeline is ready.
- [ ] Add subtle ambient background motion using shader or slow overlay.

### Acceptance Checklist

- [ ] The UI responds immediately to clicks.
- [ ] Damage, block, and draw events are visible without reading logs.
- [ ] The screen never feels frozen after an action.

## Phase 8: UX Verification Pass

Purpose: make polish measurable instead of subjective.

### Screenshot Matrix

- [ ] Main menu at 1280x720.
- [ ] Prologue/story at 1280x720.
- [ ] Route map at 1280x720.
- [ ] Combat start at 1280x720.
- [ ] Combat after playing attack card.
- [ ] Combat after gaining block.
- [ ] Reward screen.
- [ ] Event screen.
- [ ] Shop screen.
- [ ] Campfire screen.
- [ ] Victory screen.
- [ ] Route map at 1600x900.
- [ ] Combat at 1600x900.

### Manual Test Script

- [ ] Start a new run.
- [ ] Read/skip prologue.
- [ ] Choose first combat node.
- [ ] Play one attack card.
- [ ] Play one block card.
- [ ] End turn.
- [ ] Win combat.
- [ ] Choose reward card.
- [ ] Enter event/shop/campfire node.
- [ ] Reach boss.
- [ ] Complete or lose run.

### Technical Checks

- [ ] `godot_console --headless --path .\tower_game --script res://scripts/tests/smoke_test.gd`
- [ ] `godot_console --headless --path .\tower_game --quit`
- [ ] Confirm no critical Godot warnings from missing textures or scripts.
- [ ] Confirm saved run can continue after restart.

## Suggested Development Order

1. Rebuild `CardView` as a real card component.
2. Rebuild combat layout around fixed anchors and bottom hand.
3. Add combat animations and feedback.
4. Upgrade route map iconography and hover preview.
5. Upgrade reward screen with real card components.
6. Upgrade event/shop/campfire screens.
7. Generate and integrate complete first-pass UI asset set.
8. Run screenshot matrix and fix clipping/readability issues.

## Priority Todo Board

### P0: Make Combat Demo-Worthy

- [x] Custom card component with cost/name/art/rules sections.
- [x] Stable combat stage with anchored entities.
- [x] Fully visible hand, energy, piles, and end-turn button.
- [ ] Enemy intent icons and status rows.
- [x] Card play, damage, and block animations.

### P1: Make Run Loop Feel Like a Game

- [ ] Polished route map with icon nodes.
- [ ] Reward screen using large interactive cards.
- [ ] Event/shop/campfire visual screens.
- [ ] Screen transitions.
- [ ] Save/continue presentation polish.

### P2: Make It Beautiful

- [x] Generated original background set.
- [ ] Generated card art set.
- [ ] Clean sprite alpha and consistent scale.
- [ ] Ambient visual effects.
- [ ] Sound placeholder hooks.

### P3: Make It Robust

- [ ] Multi-resolution screenshot matrix.
- [ ] Manual full-run QA script.
- [ ] Automated smoke test expanded for new scenes/assets.
- [ ] UI regression screenshots saved under `tower_game/ui_checks/`.

## Open Design Decisions

- [ ] Final card size for 1280x720: compact hand cards vs. larger hover inspector.
- [ ] Whether cards need individual art in MVP or type-based art frames are enough.
- [ ] Whether combat targeting starts as click-to-play or click-card-then-click-enemy.
- [ ] Whether map paths should remain authored for demo or become seeded procedural before visual polish.
- [ ] Whether to add audio before or after the next visual pass.
