# Audio Plan

Project codename: **Tower**

Status: Draft v1

This document defines the audio direction, file layout, naming convention, event-to-sound mapping, mixing rules, and licensing constraints for MVP. Audio is currently absent from the prototype; this plan unblocks the first audio pass without forcing premature production-quality assets.

## Audio Direction

The Living Archive is **quiet by default**. Most ambient is paper, breath, and distant echo; combat punches are sharp but short; music is sparse, tonal, and mood-driven rather than melodic. The intent is that audio reinforces the bureaucratic-horror tone established in `24_world_narrative.md`.

Reference moodboard descriptors (no copy from existing IPs):

- Distant page-flutter, soft creaking wood, dry gulps of breath.
- Stamps and seals as percussive UI sounds.
- Glassy, low strings or detuned bell pads for music.
- Combat hits use cloth-and-paper texture mixed with subtle metal.

## File Layout

```
res://audio/
  music/
    main_theme.ogg
    combat_normal.ogg
    combat_elite.ogg
    combat_boss.ogg
    map_theme.ogg
    campfire.ogg
  sfx/
    ui/
    combat/
    cards/
    enemies/
    relics/
    events/
  ambience/
    archive_room.ogg
    burnt_stack.ogg
```

All audio assets target OGG Vorbis at 44.1 kHz; SFX are mono unless they specifically need stereo width.

## Naming Convention

```
sfx_{category}_{verb}_{variant}.ogg
mus_{location_or_state}.ogg
amb_{location}.ogg
```

Examples:

- `sfx_card_play_attack_01.ogg`
- `sfx_card_play_skill_01.ogg`
- `sfx_ui_button_click.ogg`
- `mus_combat_normal.ogg`
- `amb_archive_room.ogg`

Variants increment with `_01`, `_02`, etc. The runtime audio manager picks a variant at random per trigger to avoid fatigue.

## Audio Manager API (proposed)

```text
AudioManager
  play_music(track_id: String, fade_ms: int = 600)
  stop_music(fade_ms: int = 600)
  play_sfx(sfx_id: String, volume_db: float = 0.0)
  play_ambient(amb_id: String, fade_ms: int = 1200)
  set_master_volume_db(db)
  set_music_volume_db(db)
  set_sfx_volume_db(db)
```

The manager owns three audio buses: `master`, `music`, `sfx`.

## Event → Sound Mapping (MVP)

| Event | Sound id | Notes |
| --- | --- | --- |
| Game start | `mus_main_theme` | Loop; fade out on Run Start. |
| Run start | `sfx_ui_run_start` | Single shot. |
| Map screen | `mus_map_theme` | Quiet loop with paper rustle. |
| Node hover | `sfx_ui_hover_soft` | Very short, low volume. |
| Node click | `sfx_ui_button_click` | |
| Combat start | crossfade to `mus_combat_normal` / `_elite` / `_boss` | Picked from encounter tier. |
| Card draw | `sfx_card_draw` | One per card drawn; throttled if > 5 in <0.5s. |
| Card hover | `sfx_card_hover` | Optional; off by default. |
| Card play (attack) | `sfx_card_play_attack` | |
| Card play (skill) | `sfx_card_play_skill` | |
| Card play (power) | `sfx_card_play_power` | Slightly longer tail. |
| Damage dealt | `sfx_combat_hit` | Pitch-randomized ±1 semitone. |
| Block gained | `sfx_combat_block` | Soft cloth-paper. |
| Status applied | `sfx_combat_status_neg` / `_pos` | |
| Enemy attack | `sfx_enemy_attack_{enemy_id}` | Enemy-specific where authored. |
| Turn start | `sfx_turn_start` | |
| Turn end | `sfx_turn_end` | |
| Combat victory | `sfx_combat_victory` + drop to `mus_map_theme` | |
| Combat defeat | `sfx_combat_defeat` | Followed by silence. |
| Reward shown | `sfx_reward_appear` | |
| Card chosen | `sfx_reward_pick` | |
| Shop enter | `sfx_shop_enter` | |
| Shop purchase | `sfx_shop_buy` | |
| Campfire rest | `sfx_campfire_rest` | |
| Campfire upgrade | `sfx_campfire_upgrade` | |
| Event open | `sfx_event_open` | |
| Boss intro | `mus_combat_boss` + `sfx_boss_intro` | |

## Mixing Rules

- Default mix: master 0 dB, music −6 dB, sfx 0 dB.
- Maximum simultaneous SFX: 8. Excess oldest is dropped.
- Card-play SFX always cuts above ambient. Ambient ducks 4 dB during combat.
- Boss music never crossfades below −18 dB.

## Player Controls (deferred — not MVP)

- Master / Music / SFX sliders in Settings menu.
- "Reduce sudden sounds" toggle that lowers boss intro spike by 6 dB.

## Asset Sourcing and Licensing

All audio must be cleared against `06_legal_originality_checklist.md` before merge.

Allowed sources for MVP:

- Original recordings (preferred).
- Licensed library content with redistribution rights (e.g. Creative Commons CC0 or commercial royalty-free libraries with documented purchase).
- AI-generated audio where the model and license permit commercial redistribution.

Disallowed:

- Lifted samples from other commercial games or films.
- Music or SFX whose license restricts derivative work or sale.
- Voice content imitating recognizable real performers.

For each asset, the asset manifest (`13_visual_asset_manifest.md` will get an audio sibling section, or a new `24_audio_asset_manifest.md` later) should track:

```text
asset_id, file_path, source, license, purchased_or_recorded_at
```

## Triggering in Code

- Hooks live on the existing combat signals enumerated in `02_technical_design.md` (`card_played`, `damage_taken`, `combat_started`, etc.).
- UI buttons emit a centralized `ui_action_triggered` signal that the audio manager listens for.
- No `play_sfx` calls in scene code; route everything through `AudioManager` so volume settings apply uniformly.

## Test Plan

- Smoke test: start a run, end a run; verify no missing sound errors logged.
- Volume rest: start at 0/0/0 settings, raise to 100/100/100; ensure no clipping.
- Stress: trigger 30 card plays in 1 second; manager throttles to ≤ 8 simultaneous.
- Fallback: missing file should log an error once and play silence; should not crash.

## Open Questions

- Music: composed loops vs. layered stems? Stems allow combat intensity transitions but cost more time.
- Should the badge have a per-floor whisper line as an audio asset, or text-only? Currently text-only.
- Mobile: should audio assets be downsampled? Out of MVP scope.
