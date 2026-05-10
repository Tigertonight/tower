# Visual Asset Manifest

Date: 2026-05-11

Purpose: define every image asset needed for the next visual-production pass of **Living Archive**, including where it is used, whether it already exists, required output path, suggested size, format, generation notes, and priority.

Art direction: original dark fantasy archive deckbuilder. Use parchment, brass, wax seals, ritual geometry, tower silhouettes, candlelight, teal magic, ink, bound pages, and solemn knight/archive motifs. Do not copy any specific existing game's characters, UI frames, icons, compositions, card art, or wording.

## Folder Convention

| Folder | Use |
| --- | --- |
| `tower_game/art/generated/backgrounds/` | Full-screen and scene backgrounds. |
| `tower_game/art/generated/sprites/` | Character, enemy, boss, prop, and VFX cutout PNGs. |
| `tower_game/art/generated/icons/` | Intent, status, map node, relic, shop, campfire, and UI icons. |
| `tower_game/art/generated/cards/` | Card illustration art. |
| `tower_game/art/generated/ui/` | UI frames, panels, banners, card backs, overlays. |
| `tower_game/art/generated/sources/` | Original generated sheets before slicing. |
| `tower_game/art/generated/prompts/` | Prompt records for generated image assets. |

## Status Legend

- `Integrated`: already generated and used by the game.
- `Generated`: generated but not wired into UI yet.
- `Needed`: not generated yet.
- `Optional`: useful after core demo polish.
- `Replace`: current asset exists but should be regenerated or improved.

## Priority Legend

- `P0`: required for the next polished demo pass.
- `P1`: important for a complete vertical slice.
- `P2`: polish or content expansion.

## P0 Scene Backgrounds

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| combat_archive_floor | Integrated | Combat scene background | `tower_game/art/generated/backgrounds/living_archive_combat_floor.png` | 16:9, ideally 1792x1024 or larger | PNG | Current background works; keep unless later art pass needs repaint. |
| route_archive_board | Integrated | Route map screen | `tower_game/art/generated/backgrounds/living_archive_route_board.png` | 16:9, ideally 1792x1024 or larger | PNG | Current background works; has central parchment and right status zone. |
| main_menu_archive_entrance | Needed | Main menu | `tower_game/art/generated/backgrounds/main_menu_archive_entrance.png` | 16:9 | PNG | Large tower/archive entrance, dark negative space for menu panel. |
| prologue_door_scene | Needed | Prologue/story intro | `tower_game/art/generated/backgrounds/prologue_door_scene.png` | 16:9 | PNG | The remembered door, archive key motif, no readable text. |
| reward_archive_spoils | Needed | Combat reward overlay | `tower_game/art/generated/backgrounds/reward_archive_spoils.png` | 16:9 | PNG | Treasure desk, open folios, glow behind cards, dark safe center. |
| event_archive_contract | Needed | Event screen | `tower_game/art/generated/backgrounds/event_archive_contract.png` | 16:9 | PNG | Ink contract, sealed margins, ominous paper and wax. |
| shop_quiet_vendor | Needed | Shop screen | `tower_game/art/generated/backgrounds/shop_quiet_vendor.png` | 16:9 | PNG | Lantern-lit vendor counter, display shelves, no character if hard to reuse. |
| campfire_waxlight_nook | Needed | Campfire screen | `tower_game/art/generated/backgrounds/campfire_waxlight_nook.png` | 16:9 | PNG | Warm waxlight rest nook, upgrade anvil/book stand. |
| victory_archive_key | Needed | Victory/completion screen | `tower_game/art/generated/backgrounds/victory_archive_key_scene.png` | 16:9 | PNG | Archive key turning in a lock, light spilling from shelves. |
| defeat_archive_closing | Needed | Defeat screen | `tower_game/art/generated/backgrounds/defeat_archive_closing.png` | 16:9 | PNG | Tower shelves closing, dark but readable. |

## P0 Combat Sprites

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| player_vanguard_archivist | Integrated | Combat player, menu hero | `tower_game/art/generated/sprites/vanguard_archivist.png` | Around 512-768 px tall source | Transparent PNG | Current sprite works but has slight green edge; cleanup later. |
| enemy_dust_scribe | Integrated | Normal combat enemy | `tower_game/art/generated/sprites/dust_scribe.png` | 512-768 px source | Transparent PNG | Current enemy works. |
| enemy_index_knight | Replace | Elite combat enemy | `tower_game/art/generated/sprites/index_knight.png` | 512-768 px source | Transparent PNG | Currently reuses boss sprite; needs unique elite silhouette. |
| boss_sealed_curator | Integrated | Boss combat enemy | `tower_game/art/generated/sprites/sealed_curator.png` | 768-1024 px source | Transparent PNG | Current boss works for demo. |
| prop_archive_key | Integrated | Prologue/victory prop | `tower_game/art/generated/sprites/archive_key.png` | 512 px source | Transparent PNG | Current prop works but must be rendered with fixed size. |

## P0 Intent Icons

These can be generated as one icon sheet on a flat green background, then sliced.

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| intent_attack | Needed | Enemy intent badge | `tower_game/art/generated/icons/intent_attack.png` | 128x128 | Transparent PNG | Original blade/impact mark, red/orange. |
| intent_heavy_attack | Needed | Enemy heavy intent | `tower_game/art/generated/icons/intent_heavy_attack.png` | 128x128 | Transparent PNG | Double blade, cracked seal, more urgent. |
| intent_defend | Needed | Enemy defend intent | `tower_game/art/generated/icons/intent_defend.png` | 128x128 | Transparent PNG | Brass shield or sealed ward, blue/teal. |
| intent_buff | Needed | Enemy buff intent | `tower_game/art/generated/icons/intent_buff.png` | 128x128 | Transparent PNG | Rising sigil, gold/teal. |
| intent_debuff | Needed | Enemy debuff intent | `tower_game/art/generated/icons/intent_debuff.png` | 128x128 | Transparent PNG | Ink drop or broken wax seal, purple/red. |
| intent_unknown | Needed | Unknown/mixed intent | `tower_game/art/generated/icons/intent_unknown.png` | 128x128 | Transparent PNG | Question seal, subdued. |

## P0 Status Icons

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| status_strength | Needed | Player/enemy status row | `tower_game/art/generated/icons/status_strength.png` | 96x96 | Transparent PNG | Brass sword/sunburst. |
| status_vulnerable | Needed | Player/enemy status row | `tower_game/art/generated/icons/status_vulnerable.png` | 96x96 | Transparent PNG | Cracked wax shield. |
| status_weak | Needed | Player/enemy status row | `tower_game/art/generated/icons/status_weak.png` | 96x96 | Transparent PNG | Faded ink chain. |
| status_block | Needed | Block badge/HUD | `tower_game/art/generated/icons/status_block.png` | 96x96 | Transparent PNG | Blue ward shield. |
| status_energy | Needed | Energy orb/HUD | `tower_game/art/generated/icons/status_energy.png` | 96x96 | Transparent PNG | Teal arcane flame/orb. |

## P0 Map Node Icons

These should replace text-only map labels.

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| node_combat | Needed | Route map combat node | `tower_game/art/generated/icons/node_combat.png` | 128x128 | Transparent PNG | Mask/blade original symbol. |
| node_elite | Needed | Route map elite node | `tower_game/art/generated/icons/node_elite.png` | 128x128 | Transparent PNG | Crowned seal or heavy index mark. |
| node_event | Needed | Route map event node | `tower_game/art/generated/icons/node_event.png` | 128x128 | Transparent PNG | Ink question mark, not standard punctuation if possible. |
| node_shop | Needed | Route map shop node | `tower_game/art/generated/icons/node_shop.png` | 128x128 | Transparent PNG | Brass coin/lantern. |
| node_campfire | Needed | Route map campfire node | `tower_game/art/generated/icons/node_campfire.png` | 128x128 | Transparent PNG | Waxlight flame. |
| node_boss | Needed | Route map boss node | `tower_game/art/generated/icons/node_boss.png` | 128x128 | Transparent PNG | Archive keyhole/sealed crown. |

## P0 Card Art Set

Minimum: one small illustration per existing card. If generation time is tight, generate three category sheets first: attack, skill, power.

| Asset ID | Status | Card | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| card_strike_form | Needed | Strike Form | CardView art window | `tower_game/art/generated/cards/strike_form.png` | 256x192 or 512x384 | PNG | A disciplined blade stroke through paper seals. |
| card_guard_form | Needed | Guard Form | CardView art window | `tower_game/art/generated/cards/guard_form.png` | 256x192 or 512x384 | PNG | Archive ward shield, blue-gold. |
| card_archive_bash | Needed | Archive Bash | CardView art window | `tower_game/art/generated/cards/archive_bash.png` | 256x192 or 512x384 | PNG | Heavy book/gauntlet impact. |
| card_quick_read | Needed | Quick Read | CardView art window | `tower_game/art/generated/cards/quick_read.png` | 256x192 or 512x384 | PNG | Pages flipping into teal light. |
| card_forward_step | Needed | Forward Step | CardView art window | `tower_game/art/generated/cards/forward_step.png` | 256x192 or 512x384 | PNG | Armored boot crossing glowing glyph. |
| card_measured_cut | Needed | Measured Cut | CardView art window | `tower_game/art/generated/cards/measured_cut.png` | 256x192 or 512x384 | PNG | Precise sword mark over measuring brass arc. |
| card_brace | Needed | Brace | CardView art window | `tower_game/art/generated/cards/brace.png` | 256x192 or 512x384 | PNG | Knight bracing behind sealed shield. |
| card_shield_tap | Needed | Shield Tap | CardView art window | `tower_game/art/generated/cards/shield_tap.png` | 256x192 or 512x384 | PNG | Shield strike sending ring pulse. |
| card_break_rhythm | Needed | Break Rhythm | CardView art window | `tower_game/art/generated/cards/break_rhythm.png` | 256x192 or 512x384 | PNG | Snapped metronome chain, enemy tempo broken. |
| card_oath_pressure | Needed | Oath Pressure | CardView art window | `tower_game/art/generated/cards/oath_pressure.png` | 256x192 or 512x384 | PNG | Wax seal pressing down on glowing oath script. |

## P1 UI Frames And Surfaces

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| ui_card_back | Needed | Draw/discard pile preview, deck UI | `tower_game/art/generated/ui/card_back.png` | 256x384 | PNG | Original archive card back, no text. |
| ui_card_attack_frame | Optional | CardView frame overlay | `tower_game/art/generated/ui/card_frame_attack.png` | 512x768 | PNG | Only needed if code-native frames are not enough. |
| ui_card_skill_frame | Optional | CardView frame overlay | `tower_game/art/generated/ui/card_frame_skill.png` | 512x768 | PNG | Only needed if code-native frames are not enough. |
| ui_card_power_frame | Optional | CardView frame overlay | `tower_game/art/generated/ui/card_frame_power.png` | 512x768 | PNG | Only needed if code-native frames are not enough. |
| ui_reward_panel_frame | Needed | Reward overlay | `tower_game/art/generated/ui/reward_panel_frame.png` | 1024x512 | PNG | Ornate but not busy; may be code-native instead. |
| ui_turn_banner | Optional | Turn banner | `tower_game/art/generated/ui/turn_banner.png` | 768x96 | PNG | Current code-native banner works; image optional. |
| ui_energy_orb | Needed | Energy HUD | `tower_game/art/generated/ui/energy_orb.png` | 256x256 | PNG | Could replace current code-native orb. |

## P1 Shop/Event/Campfire Props

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| shop_vendor_portrait | Needed | Shop screen | `tower_game/art/generated/sprites/shop_vendor.png` | 512-768 px tall | Transparent PNG | Hooded archive vendor, original silhouette. |
| shop_card_shelf | Optional | Shop screen | `tower_game/art/generated/sprites/shop_card_shelf.png` | 512x512 | Transparent PNG | Display shelf/counter prop. |
| campfire_wax_flame | Needed | Campfire screen | `tower_game/art/generated/sprites/campfire_wax_flame.png` | 512x512 | Transparent PNG | Wax candle flame cluster. |
| event_ink_contract | Needed | Event screen | `tower_game/art/generated/sprites/event_ink_contract.png` | 512x512 | Transparent PNG | Contract sheet with unreadable marks. |
| upgrade_anvil_bookstand | Needed | Campfire upgrade preview | `tower_game/art/generated/sprites/upgrade_bookstand.png` | 512x512 | Transparent PNG | Bookstand/anvil hybrid for card upgrade. |

## P1 VFX Sprites

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| vfx_slash_arc | Needed | Attack card effect | `tower_game/art/generated/sprites/vfx_slash_arc.png` | 512x256 | Transparent PNG | Warm slash arc, no background. |
| vfx_block_pulse | Needed | Block gain effect | `tower_game/art/generated/sprites/vfx_block_pulse.png` | 512x512 | Transparent PNG | Teal shield pulse ring. |
| vfx_card_draw_trail | Optional | Draw animation | `tower_game/art/generated/sprites/vfx_card_draw_trail.png` | 512x256 | Transparent PNG | Paper/ink trail. |
| vfx_hit_spark | Needed | Damage hit | `tower_game/art/generated/sprites/vfx_hit_spark.png` | 256x256 | Transparent PNG | Red-gold spark impact. |
| vfx_reward_glow | Needed | Reward screen | `tower_game/art/generated/sprites/vfx_reward_glow.png` | 512x512 | Transparent PNG | Gold/teal glow behind chosen card. |

## P2 Additional Content Assets

| Asset ID | Status | Used In | Output Path | Size | Format | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| relic_sealed_badge | Needed | Relic bar | `tower_game/art/generated/icons/relic_sealed_badge.png` | 128x128 | Transparent PNG | Current relic is text-only. |
| relic_placeholder_set | Optional | Future relics | `tower_game/art/generated/icons/relic_sheet_001.png` | Sheet | PNG | 8-12 icons. |
| potion_placeholder_set | Optional | Future potions | `tower_game/art/generated/icons/potion_sheet_001.png` | Sheet | PNG | Not needed for current demo. |
| enemy_loose_folios | Optional | Additional combat enemy | `tower_game/art/generated/sprites/loose_folios.png` | 512-768 px | Transparent PNG | For route variety. |
| enemy_restless_shelves | Optional | Additional combat enemy | `tower_game/art/generated/sprites/restless_shelves.png` | 512-768 px | Transparent PNG | For route variety. |

## Suggested Generation Batches

### Batch 1: Missing Scene Backgrounds

Generate individually as 16:9 landscape images:

- `main_menu_archive_entrance`
- `prologue_door_scene`
- `reward_archive_spoils`
- `event_archive_contract`
- `shop_quiet_vendor`
- `campfire_waxlight_nook`
- `victory_archive_key`
- `defeat_archive_closing`

### Batch 2: Icon Sheets

Generate as flat green-background sheets for slicing:

- Intent icons: attack, heavy attack, defend, buff, debuff, unknown.
- Status icons: strength, vulnerable, weak, block, energy.
- Map node icons: combat, elite, event, shop, campfire, boss.

### Batch 3: Cards

Generate either:

- one sheet with 10 labeled slots for current cards, no rendered text inside images; or
- 10 individual card illustrations at 512x384.

Preferred: individual images for quality, then downsample/crop in Godot UI if needed.

### Batch 4: Scene Props And VFX

Generate as green-background sheets:

- shop vendor
- wax flame
- ink contract
- upgrade bookstand
- slash arc
- block pulse
- hit spark
- reward glow

## Prompt Base For Backgrounds

Use this base and swap the scene:

```text
Original dark fantasy archive game background for Living Archive.
No characters, no readable text, no UI, no logos, no watermark.
Hand-painted premium fantasy game art.
Use parchment, brass, wax seals, candlelight, teal magic, old tower archive motifs.
Composition must leave clear safe areas for game UI overlays.
Avoid resemblance to any existing game artwork.
```

## Prompt Base For Green-Screen Sheets

```text
Create an original game asset sheet on a perfectly flat solid #00ff00 chroma-key background.
Each asset should be isolated with generous padding, crisp edges, no shadows, no contact shadow, no text, no watermark.
Style: hand-painted dark fantasy archive UI/icon art, brass, wax, parchment, teal magic.
Do not use #00ff00 anywhere inside the assets.
```

## Immediate Next Step

Generate assets in this order:

1. `main_menu_archive_entrance`
2. `reward_archive_spoils`
3. `intent_icon_sheet`
4. `map_node_icon_sheet`
5. `status_icon_sheet`
6. `card_strike_form` through `card_oath_pressure`
7. `shop_quiet_vendor`
8. `campfire_waxlight_nook`

