# Asset Generation Plan

Project codename: **Tower**

Status: Draft

Detailed source-of-truth manifest: `13_visual_asset_manifest.md`.

## Purpose

This document tracks visual direction, asset needs, AI generation prompts, manual edits, licensing notes, and final asset usage.

## Art Direction Placeholder

The final art direction has not been chosen.

Possible directions:

- Arcane ruin with ink, jade, brass, and spectral light.
- Broken orbital megacity with clean silhouettes and warning-color accents.
- Forbidden library with ritual diagrams, paper, wax seals, and animated glyphs.
- Biopunk descent with organic architecture and luminous tissue.

## Asset Categories

- Character portraits.
- Character combat sprites.
- Enemy sprites.
- Boss sprites.
- Card illustrations.
- Relic icons.
- Potion icons.
- Status icons.
- Map node icons.
- UI frames and panels.
- Backgrounds.
- VFX sprites.
- Logo and key art.

## Asset Tracking Table

| Asset ID | Type | Description | Status | Source | License/Notes |
| --- | --- | --- | --- | --- | --- |
| vanguard_archivist_placeholder | Character | Green-background source for first player character. | Draft | `tower_game/art/placeholder/vanguard_archivist.svg` | Original placeholder. |
| dust_scribe_placeholder | Enemy | Green-background source for normal enemy. | Draft | `tower_game/art/placeholder/dust_scribe.svg` | Original placeholder. |
| sealed_curator_placeholder | Boss | Green-background source for demo boss. | Draft | `tower_game/art/placeholder/sealed_curator.svg` | Original placeholder. |
| archive_key_placeholder | Prop | Green-background source for victory key. | Draft | `tower_game/art/placeholder/archive_key.svg` | Original placeholder. |
| generated_asset_sheet_001 | Asset sheet | Image2-generated green-screen sheet for character/enemy/boss/key. | Integrated | `tower_game/art/generated/green_screen_asset_sheet.png` | Generated original art, sliced into sprites. |
| vanguard_archivist_sprite | Character | Transparent PNG sprite for first player character. | Integrated | `tower_game/art/generated/sprites/vanguard_archivist.png` | Cut from generated asset sheet. |
| dust_scribe_sprite | Enemy | Transparent PNG sprite for normal enemy. | Integrated | `tower_game/art/generated/sprites/dust_scribe.png` | Cut from generated asset sheet. |
| sealed_curator_sprite | Boss | Transparent PNG sprite for boss/elite placeholder. | Integrated | `tower_game/art/generated/sprites/sealed_curator.png` | Cut from generated asset sheet. |
| archive_key_sprite | Prop | Transparent PNG sprite for victory key. | Integrated | `tower_game/art/generated/sprites/archive_key.png` | Cut from generated asset sheet. |
| living_archive_combat_floor | Background | Hand-painted forbidden archive combat arena with central floor safe area. | Integrated | `tower_game/art/generated/backgrounds/living_archive_combat_floor.png` | Generated original art; used in combat screen. |
| living_archive_route_board | Background | Parchment route board on dark archive table with right-side status area. | Integrated | `tower_game/art/generated/backgrounds/living_archive_route_board.png` | Generated original art; used in route map screen. |

## Prompt Tracking

Use this table whenever an AI-generated image is created.

| Date | Asset ID | Prompt Summary | Tool/Model | Output Path | Review Notes |
| --- | --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD | TBD |
| 2026-05-10 | living_archive_combat_floor | Dark fantasy forbidden archive combat arena, no characters, no UI, safe center floor. | Built-in image generation | `tower_game/art/generated/backgrounds/living_archive_combat_floor.png` | Strong fit for combat; dark overlay added in Godot for readability. |
| 2026-05-10 | living_archive_route_board | Aged parchment and archive table route board, no text/nodes, right-side status zone. | Built-in image generation | `tower_game/art/generated/backgrounds/living_archive_route_board.png` | Strong fit for map; semi-transparent panels preserve readability. |

## Style Rules

- Avoid copying recognizable compositions, symbols, UI frames, characters, relics, or card art from existing games.
- Keep card illustrations readable at small size.
- Keep relic icons simple and high-contrast.
- Use consistent lighting direction across card art and enemy art.
- Make enemy silhouettes readable before adding detail.
- UI should support long localized text.

## Immediate Needs After Theme Lock

1. Moodboard description.
2. Color palette.
3. Shape language.
4. First player character concept.
5. First enemy faction concept.
6. Card frame direction.
7. Relic icon style.
