# Imagegen Asset Status

Date: 2026-05-11

This pass used Codex native `imagegen` to create raster PNG assets for the remaining Living Archive visual gaps. Source sheets are kept under `tower_game/art/generated/sources/`, and sliced usable assets are kept under their runtime folders.

Integration status: **runtime assets are now wired into the Godot prototype UI** for the current polished demo pass.

## Generated Sources

- `tower_game/art/generated/sources/card_art_sheet_10_current.png`
- `tower_game/art/generated/sources/icon_sheet_18_ui.png`
- `tower_game/art/generated/sources/sprite_prop_vfx_sheet_9.png`
- `tower_game/art/generated/sources/ui_surface_sheet_3.png`
- `tower_game/art/generated/sources/reward_panel_frame_source.png`
- `tower_game/art/generated/sources/generated_asset_preview.png`
- `tower_game/art/generated/sources/card_art_sheet_missing_01.png`
- `tower_game/art/generated/sources/card_art_sheet_missing_02.png`
- `tower_game/art/generated/sources/card_art_sheet_missing_03.png`
- `tower_game/art/generated/sources/card_art_sheet_missing_04.png`
- `tower_game/art/generated/sources/enemy_sprite_sheet_missing_01.png`
- `tower_game/art/generated/sources/enemy_sprite_sheet_missing_02.png`
- `tower_game/art/generated/sources/icon_sheet_relic_potion_status_20.png`
- `tower_game/art/generated/sources/vfx_sheet_combat_feedback_10.png`
- `tower_game/art/generated/sources/ui_shop_campfire_sheet_10.png`
- `tower_game/art/generated/sources/event_illustration_sheet_5.png`

## Generated Runtime Assets

### Cards

Ten card illustrations were generated and sliced to 512x384 PNG files:

- `tower_game/art/generated/cards/strike_form.png`
- `tower_game/art/generated/cards/guard_form.png`
- `tower_game/art/generated/cards/archive_bash.png`
- `tower_game/art/generated/cards/quick_read.png`
- `tower_game/art/generated/cards/forward_step.png`
- `tower_game/art/generated/cards/measured_cut.png`
- `tower_game/art/generated/cards/brace.png`
- `tower_game/art/generated/cards/shield_tap.png`
- `tower_game/art/generated/cards/break_rhythm.png`
- `tower_game/art/generated/cards/oath_pressure.png`

The P0/P1 completion pass generated and sliced the remaining twenty MVP card illustrations to 512x384 PNG files:

- `tower_game/art/generated/cards/binding_cut.png`
- `tower_game/art/generated/cards/brass_guard.png`
- `tower_game/art/generated/cards/burnt_clause.png`
- `tower_game/art/generated/cards/candle_count.png`
- `tower_game/art/generated/cards/closed_file.png`
- `tower_game/art/generated/cards/counterseal.png`
- `tower_game/art/generated/cards/field_order.png`
- `tower_game/art/generated/cards/filing_edge.png`
- `tower_game/art/generated/cards/final_argument.png`
- `tower_game/art/generated/cards/hardcopy.png`
- `tower_game/art/generated/cards/index_thrust.png`
- `tower_game/art/generated/cards/last_word.png`
- `tower_game/art/generated/cards/ledger_strike.png`
- `tower_game/art/generated/cards/margin_note.png`
- `tower_game/art/generated/cards/page_turn.png`
- `tower_game/art/generated/cards/quiet_revision.png`
- `tower_game/art/generated/cards/red_string.png`
- `tower_game/art/generated/cards/redline.png`
- `tower_game/art/generated/cards/stamp_down.png`
- `tower_game/art/generated/cards/wax_seal.png`

### Icons

Eighteen icon PNGs were generated, sliced, and chroma-keyed to transparent 128x128 PNG files:

- Intent icons: attack, heavy attack, defend, buff, debuff, unknown.
- Status icons: strength, vulnerable, weak, block, energy.
- Relic icon: sealed badge.
- Map node icons: combat, elite, event, shop, campfire, boss.

The P0/P1 completion pass added transparent 128x128 PNGs for:

- Relics: bound key, brass bookmark, contract nail, field lantern, inkstone, quiet eraser, red string relic, torn badge, wax stamp.
- Potions: clean breath, guard draught, ink spark, seal oil, volatile clause.
- Status/reserve icons: frail, burned page, debt mark, sealed, marked, empty relic slot.

### Sprites, Props, And VFX

Nine transparent 512x512 PNGs were generated:

- `index_knight.png`
- `shop_vendor.png`
- `campfire_wax_flame.png`
- `event_ink_contract.png`
- `upgrade_bookstand.png`
- `vfx_slash_arc.png`
- `vfx_block_pulse.png`
- `vfx_hit_spark.png`
- `vfx_reward_glow.png`

The P0/P1 completion pass added six transparent enemy sprites and ten transparent VFX sprites:

- Enemy sprites: `burnt_courier.png`, `loose_folio.png`, `margin_hound.png`, `wax_acolyte.png`, `first_clause.png`, `wax_sentinel.png`.
- VFX sprites: `vfx_draw_trail.png`, `vfx_discard_trail.png`, `vfx_enemy_lunge_smear.png`, `vfx_player_hit_impact.png`, `vfx_status_apply_debuff.png`, `vfx_status_apply_buff.png`, `vfx_heal_pulse.png`, `vfx_energy_gain.png`, `vfx_shuffle_pages.png`, `vfx_card_upgrade_flash.png`.

The P2 generation-first pass added five event illustrations and ten UI/shop/campfire assets:

- Event illustrations: `event_quiet_stack.png`, `event_clean_margin.png`, `event_red_string.png`, `event_revision_desk.png`, `event_loose_page.png`.
- UI assets: `card_inspector_frame.png`, `deck_modal_frame.png`, `relic_slot.png`, `potion_slot.png`, `price_tag.png`, `sold_stamp.png`, `shop_remove_service.png`, `shop_card_shelf.png`, `campfire_rest_icon.png`, `campfire_upgrade_icon.png`.

### UI

Three transparent UI PNGs were generated:

- `tower_game/art/generated/ui/card_back.png`
- `tower_game/art/generated/ui/energy_orb.png`
- `tower_game/art/generated/ui/reward_panel_frame.png`

## Notes

- The transparent assets were generated through Codex native `imagegen` on chroma-key backgrounds, then processed locally with Pillow.
- The original generated images remain in Codex's generated image cache; project copies are stored under `tower_game/art/generated/`.
- Card art is now shown in `CardView`.
- Route map nodes now use generated map node icons.
- Combat now uses generated intent/status icons, energy orb art, card back pile icons, `index_knight.png` for elite combat, and generated VFX sprites for slash, block, hit, and focus feedback.
- Main menu, prologue, reward overlay, shop/event/campfire/defeat screens now use the generated background and prop/UI assets.
- The six new enemy sprites are wired into their `EnemyData.art_path` resources.
- Godot headless MVP and runtime scene checks pass after the P0/P1 asset pass.
