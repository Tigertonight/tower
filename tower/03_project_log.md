# Project Log

Project codename: **Tower**

## Current Status

Status: first Godot prototype in development.

The initial gameplay research and high-level design plan have been written. The Godot project now contains a first combat prototype with placeholder UI, deck piles, playable cards, enemy intent, turn flow, and win/loss checks.

## Decision Log

| Date | Decision | Reason | Impact |
| --- | --- | --- | --- |
| 2026-05-10 | Use Godot 4.x as the target engine. | Godot scenes, nodes, Resources, signals, and UI tools fit the project. | Technical design will assume Godot 4.x patterns. |
| 2026-05-10 | Treat the project as an original roguelike deckbuilder rather than a direct clone. | Reduces copyright risk and gives room for stronger identity. | All characters, writing, art, card names, relics, and event text must be original. |
| 2026-05-10 | Start with documentation before implementation. | The project has many interlocking systems and needs scope control. | Next work focuses on technical design and MVP scope. |
| 2026-05-10 | Install Godot standard edition 4.6.2. | The current plan uses GDScript first, so Mono/C# is not required. | Development and CLI validation can use `godot` and `godot_console`. |

## Progress Log

### 2026-05-10

- Created project documentation folder.
- Saved gameplay research and complete plan.
- Created initial technical design draft.
- Created project log.
- Created asset generation tracking document.
- Created content database document.
- Created originality checklist.
- Installed Godot Engine 4.6.2 standard edition via winget.
- Added local command shims for `godot` and `godot_console`.
- Created local environment setup document.
- Added MVP scope document.
- Added first character design document.
- Added initial implementation plan.
- Created initial Godot project at `tower_game`.
- Added main scene and combat scene.
- Implemented first combat prototype with player stats, enemy intent, deck piles, clickable cards, basic effects, turn flow, and win/loss checks.
- Verified project loads with `godot_console --headless --path .\tower_game --quit`.
- Extracted card UI into `CardView`.
- Moved initial card definitions into Godot `.tres` data resources.
- Added first reward screen with card choice and skip.
- Added starter relic data and a simple relic trigger manager.
- Added lightweight current-run save/load for deck IDs and combat progress.
- Added fixed demo route map with combat, event, shop, elite, campfire, and boss nodes.
- Added run manager, persistent HP/gold/deck state, defeat state, and demo completion state.
- Added basic visual theme for placeholder UI.
- Added Godot smoke test script for core scene/data loading.
- Replaced the linear demo route with a branching layer map.
- Added two more card data resources: `Break Rhythm` and `Oath Pressure`.
- Added campfire card upgrades using lightweight `card_id+` run-state entries.
- Added enemy defend/heavy attack intent variations.
- Added story prologue and objective/task flow.
- Added combat feedback effects: slash flash, floating damage, block, and draw text.
- Added green-background placeholder SVG source files for character, enemy, boss, and key assets.
- Researched public Slay the Spire UI screenshots and documented interaction patterns in `11_ui_reference_research.md`.
- Began UI rework toward deckbuilder conventions: card-shaped card views, compact route nodes, clearer story intro, and reward cards reusing the card face component.
- Verified screenshots manually; current prologue is readable, but the UI still needs stronger map graph and combat stage polish.
- Added a custom `RouteMapView` control that draws route connections and circular map nodes.
- Added combat HP bars and block labels for player/enemy stage panels.
- Added combat energy HUD and draw/discard/exhaust pile counters.
- Added intent badge styling for attack/defend/heavy attack.
- Added card hover lift/scale animation.
- Reworked reward screen into a dimmed full-screen overlay.
- Copied generated green-screen asset sheet into `tower_game/art/generated/`.
- Sliced generated asset sheet into transparent PNG sprites for Vanguard Archivist, Dust Scribe, Sealed Curator, and Archive Key.
- Replaced combat text placeholders with generated character/enemy/boss sprites.
- Improved main menu with generated character/key art and corrected layout clipping after screenshot review.
- Reworked node/event screens into two-column story/action layouts with state display.
- Improved card type coloring, disabled-card dimming, and menu/stage background layering.
- Rebuilt the combat screen proportions after screenshot review: fixed-size character art, compact hand cards, visible energy/pile/end-turn HUD, and clearer enemy intent.
- Reworked the route map into a fixed stage with compact tower-path nodes and a visible deck/status summary area.
- Verified the UI with Godot desktop screenshots and smoke tests after layout changes.
- Started the P0 frontend polish pass from `12_frontend_ui_upgrade_plan.md`: rebuilt `CardView` into a composed card component with cost orb, rarity, name band, art window, type strip, rules text, hover lift, and type-colored frames.
- Compressed the combat stage against real desktop-window screenshots so the hand, energy, piles, and end-turn controls fit within the visible 1280x720 play area.
- Added second P0/P1 polish pass: overlay turn banner, intent sign display, card-play ghost animation, non-damage focus pulse, stronger combat background bands, route-node hover preview, compact icon node labels, and a more authored reward overlay.
- Screenshot verification confirmed `ui_combat_safe_area_pass.png` keeps hand, energy, piles, and End Turn visible in the actual desktop window safe area.
- Generated and integrated two original scene backgrounds: `living_archive_combat_floor.png` for combat and `living_archive_route_board.png` for the route map.
- Added player/enemy status HUD rows and made empty statuses collapse to avoid wasting vertical space.
- Reworked combat UI from VBox-driven layout to fixed 1280x720 deckbuilder screen zones: top HUD, centered turn banner, left player anchor, right enemy/intent anchor, bottom hand row, left energy/piles, and right End Turn button.
- Reduced map task prompt to a compact left-aligned objective panel and fixed oversized story/completion art by ignoring source image dimensions.

## Active Tasks

| Task | Owner | Status | Notes |
| --- | --- | --- | --- |
| Lock original theme | TBD | In progress | Temporary MVP theme selected: forbidden tower/archive. |
| Finish technical design | Codex | Draft | Needs deeper Godot class/interface details. |
| Define MVP scope | Codex | Draft | First version created in `08_mvp_scope.md`. |
| Create first card data schema | TBD | Not started | Depends on technical design. |
| Create first character design | Codex | Draft | First version created in `09_first_character_design.md`. |
| Create art direction guide | TBD | Not started | Depends on final original theme. |
| Create Godot project skeleton | Codex | Done | Created `tower_game` with scenes, scripts, and placeholder asset folders. |
| Build first combat prototype | Codex | Done | Combat loads with cards, energy, block, enemy intent, turn flow, and rewards. |
| Add reward loop | Codex | Done | Victory opens a card reward screen and updates the run deck. |
| Add relic trigger prototype | Codex | Done | `Sealed Badge` heals after combat victory. |
| Add lightweight run save | Codex | Done | Saves run deck IDs and combat progress to `user://tower_run.json`. |
| Build fixed demo route | Codex | Done | Route includes combat, event, shop, elite, campfire, and boss. |
| Add smoke test | Codex | Done | `scripts/tests/smoke_test.gd` validates scene/data loading. |
| Add branching route decisions | Codex | Done | Each map layer now offers 1-3 selectable nodes. |
| Add campfire upgrades | Codex | Done | Campfires can upgrade the first non-upgraded card in the deck. |

## Risks

| Risk | Severity | Mitigation |
| --- | --- | --- |
| Scope grows too quickly. | High | Lock MVP content and avoid building 3 characters at once. |
| Card/relic effect system becomes hard to extend. | High | Build a shared data-driven effect resolver early. |
| Game feels too close to an existing title. | High | Use original theme, naming, writing, mechanics, UI presentation, and numerical content. |
| Balance work becomes manual and slow. | Medium | Add automated combat simulation once the core loop is stable. |
| UI becomes difficult to adapt. | Medium | Build responsive Control layouts early and test multiple resolutions. |
| Image assets can accidentally force layouts to overflow. | Medium | TextureRect now ignores source image size and uses fixed stage dimensions. |

## Next Milestones

1. Choose original theme and project name.
2. Complete technical design details.
3. Define MVP scope.
4. Add generated/handmade placeholder art for character, enemies, cards, relics, and map nodes.
5. Replace authored branch map with seeded procedural generation.
6. Add richer combat animation timing, card targeting previews, and card/relic inspection overlays.
