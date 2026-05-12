# Kenney Interface Sounds Selection Notes

Source: https://kenney.nl/assets/interface-sounds

License: CC0 1.0 Universal. The copied Godot-ready WAV package also includes
`LICENSE.txt` from the source repository.

## Decision

Keep this pack as a candidate library for UI, shop, reward, confirmation, and
menu sounds. Do not use it for core combat Foley such as card draw, card
shuffle, hit, block, boss intro, or status effects.

## Why It Fits

- 100 short WAV files already packaged for Godot.
- Clean categories: click, select, confirmation, open, close, switch, toggle,
  tick, scroll, drop, question, error, glass, scratch.
- Most UI candidates are in the 0.04-0.56 second range, which matches button,
  reward, shop, and confirmation feedback.
- CC0 license keeps commercial/release risk low.

## Why It Does Not Replace Combat Foley

- The sound palette is clean and digital/interface-like, not paper/card/body
  Foley.
- Combat actions need tactile, material-specific sounds: paper slide, deck
  shuffle, cloth-paper impact, block thump, archive-horror boss stings.
- Replacing combat sounds with this pack would make the combat feel more like a
  generic UI than a physical card fight.

## Candidate Mapping

These candidates have been wired as `_01` / `_02` variants under
`res://audio/sfx/`, so `AudioManager` can randomly pick them together with the
existing base placeholder:

- `sfx_ui_button_click`: `click_001.wav`, `click_003.wav`
- `sfx_ui_hover_soft`: `select_001.wav`, `select_002.wav`
- `sfx_ui_run_start`: `open_003.wav`, `confirmation_002.wav`
- `sfx_reward_pick`: `confirmation_001.wav`, `confirmation_003.wav`
- `sfx_reward_appear`: `confirmation_002.wav`, `confirmation_004.wav`
- `sfx_shop_enter`: `open_002.wav`, `confirmation_002.wav`
- `sfx_shop_buy`: `confirmation_001.wav`, `drop_001.wav`
- `sfx_event_open`: `open_001.wav`, `open_003.wav`
- `sfx_turn_start`: `open_002.wav`, `select_004.wav`
- `sfx_turn_end`: `close_001.wav`, `close_003.wav`

These are still only used on UI / reward / shop / turn-feedback hooks. Core
combat Foley remains on the current generated/procedural placeholders.

Keep current generated/procedural placeholders for:

- `sfx_card_draw`
- `sfx_card_shuffle`
- `sfx_card_play_attack`
- `sfx_card_play_skill`
- `sfx_card_play_power`
- `sfx_combat_hit`
- `sfx_combat_block`
- `sfx_combat_status_neg`
- `sfx_combat_status_pos`
- `sfx_enemy_intent`
- `sfx_boss_intro`
