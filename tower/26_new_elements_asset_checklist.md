# New Elements — Asset Production Checklist

Date: 2026-05-11
Scope: every new game element introduced in the last batch (Boss phase mechanics for Act 2/3 bosses, 6 new boss-phase moves, 10 new trigger-diversity relics, the second character `char_archivist`, plus per-act event tier flavor). For each new element this doc documents what it does in-game, where the data lives, and what art / audio assets need to be produced for it.

Existing folder convention from `tower/13_visual_asset_manifest.md` is reused:

| Folder | Use |
| --- | --- |
| `tower_game/art/generated/sprites/` | Character / enemy / prop cutouts (transparent PNG). |
| `tower_game/art/generated/icons/` | Relic / status / intent / VFX icons. |
| `tower_game/art/generated/cards/` | Card illustration art. |
| `tower_game/art/generated/ui/` | UI frames, banners, character select chips. |
| `tower_game/audio/sfx/` | One-shot sound effects (.ogg/.mp3/.wav). |
| `tower_game/audio/music/` | Loops. |

Status legend: `Needed` (asset must be produced), `Optional` (nice to have), `Reuse` (an existing asset is acceptable as a stand-in).

Priority legend: `P0` required for the next polished demo pass, `P1` important for a complete vertical slice, `P2` polish/expansion.

---

## 1. Second Character — `char_archivist`

A new playable archetype focused on draw + status application. Stats and starter deck differ from `char_vanguard`; theme color is cool blue instead of amber. Starts with 68 max HP, the relic `scribes_focus` (first Skill played each combat grants 1 Energy), and a deck of 4 strikes / 3 guards / 2 quick_read / margin_note / deep_breath / copyist_focus. Source data lives in `tower_game/data/characters/char_archivist.tres`. The main menu shows a chip-row character picker that swaps `selected_character_id`.

Today the resource reuses `vanguard_archivist.png` as a placeholder sprite — the Vanguard sprite must be replaced with a distinct silhouette before this character is shippable.

| Asset ID | Element | Use | Output Path | Size | Format | Status | Priority | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| player_archivist_portrait | char_archivist | Combat player sprite + main-menu hero swap | `tower_game/art/generated/sprites/archivist.png` | 512–768 px tall source | Transparent PNG | Needed | P0 | Tall, slimmer silhouette than the Vanguard. Long ink-stained robes, brass quill on a chain at the hip, an open ledger held on the forearm. Cool indigo / teal palette, rim-lit by a single lantern. No copyrighted character likeness. Background must be true alpha (no green halo). |
| character_select_chip_vanguard | UI | Main-menu character toggle chip | `tower_game/art/generated/ui/char_chip_vanguard.png` | 96×96 | Transparent PNG | Needed | P1 | Small circular emblem: stylized brass-sword + ledger silhouette. Amber palette `#DA9F4D` matching the Vanguard `theme_color`. |
| character_select_chip_archivist | UI | Main-menu character toggle chip | `tower_game/art/generated/ui/char_chip_archivist.png` | 96×96 | Transparent PNG | Needed | P1 | Small circular emblem: quill crossed over an open page. Cool indigo `#5C8CD1` matching the Archivist `theme_color`. |
| character_card_back_archivist | UI | Per-character card back tint variant | `tower_game/art/generated/ui/card_back_archivist.png` | 240×336 | PNG | Optional | P2 | Same frame geometry as the existing card back, but tinted with the Archivist's blue `theme_color` so the deck reads as "this character's deck" at a glance. |
| sfx_run_start_archivist | Audio | Plays when char_archivist starts a run | `tower_game/audio/sfx/sfx_run_start_archivist.ogg` | mono, ~0.6s | OGG | Optional | P2 | Variant of the existing `sfx_ui_run_start`: paper unrolling + a quill-dip splash instead of a wax stamp. |

Wiring notes:
- The `theme_color` field on `CharacterData` is read but not yet driving any UI tint. Adding a tinted card back / HUD accent is a future polish hook.
- `sprite_path` on the Archivist resource currently points at `vanguard_archivist.png`; once `archivist.png` ships, change `tower_game/data/characters/char_archivist.tres:sprite_path`.

---

## 2. Boss Phase Mechanics — Act 2 & Act 3

`b_chronicler_of_lost_pages` flips into phase 2 below 50% HP (gains +4 strength, +14 block, switches to the new phase pool). `b_grand_archivist` flips below 40% HP (+6 strength, +20 block, new phase pool). When the flip happens, `combat_manager._announce_boss_phase()` shows a "Phase Shift" banner, a toast with the boss name, plays `sfx_boss_intro`, and screen-shakes.

The bosses themselves already have art (`chronicler_of_lost_pages.png`, `grand_archivist.png`). What's new is the phase shift moment — there is currently no visual or audio asset specific to phase transitions; only the existing `sfx_boss_intro` is reused.

| Asset ID | Element | Use | Output Path | Size | Format | Status | Priority | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| vfx_phase_shift_burst | Boss phase trigger | Banner backdrop / fullscreen flash when a boss flips phase | `tower_game/art/generated/sprites/vfx_phase_shift_burst.png` | 1024×512 source | Transparent PNG | Needed | P0 | Wide horizontal burst of broken wax + paper shards, deep red core fading into amber edges. Will be drawn behind the "Phase Shift" banner; needs to be readable as a single brief flash. |
| icon_phase_marker | Boss intent | Small glyph that appears on the boss intent label after the flip | `tower_game/art/generated/icons/icon_phase_marker.png` | 64×64 | Transparent PNG | Needed | P1 | A second-stage seal — cracked wax with a crimson sigil — used as a permanent marker beside the boss intent so the player can see at-a-glance the boss is in phase 2. |
| sprite_chronicler_phase2 | b_chronicler_of_lost_pages | Optional alternate sprite shown after phase flip | `tower_game/art/generated/sprites/chronicler_of_lost_pages_phase2.png` | match base sprite | Transparent PNG | Optional | P2 | Same composition as `chronicler_of_lost_pages.png` but page-storm intensified, eyes lit. Hot-swap the texture in `_announce_boss_phase()` when added. |
| sprite_grand_archivist_phase2 | b_grand_archivist | Optional alternate sprite shown after phase flip | `tower_game/art/generated/sprites/grand_archivist_phase2.png` | match base sprite | Transparent PNG | Optional | P2 | Robes lifted by air currents, ledger flame visible, brass tone takes on red-orange edge. |
| sfx_boss_phase_shift | Boss phase trigger | Distinct sting when the flip happens (currently reusing `sfx_boss_intro`) | `tower_game/audio/sfx/sfx_boss_phase_shift.ogg` | mono, ~1.6s | OGG | Needed | P0 | Slow bell tail layered with a single dry crack and rising paper rustle. Heavier than `sfx_boss_intro`. Replace the `am.play_sfx("sfx_boss_intro")` line in `_announce_boss_phase()` once shipped. |

---

## 3. New Boss Phase-2 Moves (6 entries)

These are pure data moves added to `EnemyCatalog.build_moves()`. They use existing intent types (`attack`, `attack_multi`, `defend`), so the existing intent icons cover them. The only mandatory new asset is one VFX overlay for the multi-hit page-storm (`mv_lost_pages`) — every other move animates fine off the existing damage / block effects.

| Move ID | Display | Type | Numbers | Used By | Asset Need |
| --- | --- | --- | --- | --- | --- |
| mv_lost_pages | Lost Pages | attack_multi | 5 × 4 | Chronicler P2 | New VFX recommended — see below. |
| mv_silence_clause | Silence Clause | attack | 24 + 2 Weak | Chronicler P2 | Existing attack/debuff VFX cover it. |
| mv_amend_record | Amend Record | defend | 14 block + 2 strength | Chronicler P2 | Existing block/buff VFX cover it. |
| mv_anathema | Anathema | attack | 28 + 2 Frail | Grand Archivist P2 | Existing big-hit shake covers it. |
| mv_excommunicate | Excommunicate | attack_multi | 10 × 3 + 1 Vulnerable | Grand Archivist P2 | Existing slash + status VFX cover it. |
| mv_archival_decree | Archival Decree | defend | 22 block + 3 strength | Grand Archivist P2 | Existing block/buff VFX cover it. |

| Asset ID | Element | Use | Output Path | Size | Format | Status | Priority | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| vfx_lost_pages_storm | mv_lost_pages | Overlay drawn behind the player while Chronicler resolves the 4-hit page barrage | `tower_game/art/generated/sprites/vfx_lost_pages_storm.png` | 1024×512 source | Transparent PNG | Needed | P1 | Sweeping diagonal bands of paper sheets and ink flecks, fading at edges so it composites cleanly over the combat background. Single-frame is fine — code can fade it in/out and shift it for each of the 4 hits. |
| sfx_move_paper_storm | mv_lost_pages | Loops under the four-hit barrage | `tower_game/audio/sfx/sfx_move_paper_storm.ogg` | mono, ~1.0s | OGG | Optional | P2 | Layered paper-flutter / book-flap. Played once when the move resolves, ducked under the existing `sfx_combat_hit` per-hit pitches. |

No new intent icons are required — the existing `intent_attack`, `intent_heavy_attack`, `intent_defend`, `intent_debuff` icons all match these moves' types.

---

## 4. Trigger-Diversity Relics (10 new relics)

All ten live in `tower_game/data/relics/`. Each needs a unique relic icon. Sizes match the existing relics under `tower_game/art/generated/icons/` — one icon per relic, square transparent PNG.

For every entry below, the asset path is `tower_game/art/generated/icons/relic_<id>.png`, the size is `128×128`, and the format is Transparent PNG. Status `Needed` for all unless noted.

| Relic ID | Display | Rarity | Trigger | Effect (in-game) | Visual prompt | Priority |
| --- | --- | --- | --- | --- | --- | --- |
| morning_ledger | Morning Ledger | uncommon | turn_start | +2 Block at the start of each turn. | Open ledger with a soft sunrise glow rising off its pages; brass corner clasps. Warm amber base + cool blue rim light. | P0 |
| dawn_kindling | Dawn Kindling | uncommon | turn_start | Draw 1 extra card at the start of each turn. | Bundled candle + a single lit wick; a curl of smoke shaped like a page corner peeling up. | P0 |
| clerks_pen | Clerk's Pen | common | card_played (every 3rd Attack) | Every 3rd Attack played deals 4 extra damage to the enemy. | A nibbed quill mid-stroke leaving three short ink ticks behind it; the third tick glows hotter. | P0 |
| scribes_focus | Scribe's Focus | uncommon | card_played (first Skill / combat) | The first Skill you play each combat grants 1 Energy. (Also doubles as the Archivist's starting relic.) | Round inkwell with a focused teal flame inside, brass rim. Should read as "concentration / clarity". | P0 |
| ember_charm | Ember Charm | uncommon | enemy_killed | Gain 4 Block when you defeat an enemy. | Small wax-pressed charm on a leather thong, the wax seal showing a stylized shield with a tiny ember in its center. | P0 |
| scavengers_satchel | Scavenger's Satchel | rare | enemy_killed | Gain 5 Gold when you defeat an enemy. | Worn leather satchel half-open, three loose coins spilling at the corner; one coin catches a highlight. | P0 |
| last_stand_oath | Last Stand Oath | rare | hp_threshold (HP < 50%) | First time HP drops below 50% in a combat, gain 3 Strength. | Folded battlefield oath sealed with a half-cracked red wax seal; the crack looks like a lightning bolt. | P0 |
| wax_amulet | Wax Amulet | rare | hp_threshold (HP < 30%) | First time HP drops below 30% in a combat, heal 12 HP. | Heart-shaped wax amulet on a frayed cord, faint warm glow inside the wax. | P0 |
| quiet_resolve | Quiet Resolve | common | turn_end | At end of each turn, gain 1 Block. | Simple closed book, a small index ribbon falling out, dust motes. Quiet, monastic feel. | P0 |
| lingering_whisper | Lingering Whisper | uncommon | card_played (every 4th card) | Every 4th card you play makes the enemy Vulnerable for 1. | Half-open book with a thin tendril of ink-smoke rising and curling into a sigil. | P0 |

Optional follow-up:
- All ten descriptions could use a one-line **flavor** string for the inspector tooltip (relics currently only carry the rule text). If we add a `flavor` field to `RelicData`, queue 10 flavor lines as a writing task.

---

## 5. Per-Act Event Tiering — Flavor Assets

`run_manager._roll_event_id` now buckets events into Act 1 / 2 / 3 / shared / character pools, but every event already has its event-screen background (`event_archive_contract.png`) and the events themselves are reused from the existing pool. **No new event illustrations are required for this batch.** Listed here only so it isn't mistaken for missing work.

| Asset ID | Status | Notes |
| --- | --- | --- |
| event_archive_contract | Reuse | Existing P0 background still serves every event in the pool. |
| event_<id>_inset (10 total) | Optional, P2 | If we later want each event to have a small inset illustration above its choice list, that's its own pass — not blocked on this batch. |

---

## 6. Quick Production Order

If you only have time to produce one batch, do these first (P0):

1. `archivist.png` player sprite — without it, the second character is unshippable.
2. The 10 relic icons in section 4 — without them, the new relics fall back to type placeholders.
3. `vfx_phase_shift_burst.png` + `sfx_boss_phase_shift.ogg` — gives the new boss-phase moment its own beat.
4. `vfx_lost_pages_storm.png` — sells the only mechanically-distinct phase-2 move (the four-hit paper storm).

Everything else (character chips, alternate phase sprites, optional SFX) can roll into the next polish pass.
