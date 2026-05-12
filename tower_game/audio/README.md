# Tower audio

Drop `.ogg`, `.mp3`, or `.wav` files here. The runtime `AudioManager` (autoload, see `scripts/audio/audio_manager.gd`) loads them at:

```
audio/music/<id>.<ext>            # mus_main_theme, mus_combat_normal, ...
audio/sfx/<id>.<ext>              # sfx_card_play_attack, sfx_combat_hit, ...
audio/ambience/<id>.<ext>         # amb_archive_room, amb_burnt_stack
```

Variants are picked at random when present: `id_01.ogg`, `id_02.ogg`, ... up to `_04`; the same works for `.mp3` / `.wav`.

To generate all assets via your local minimax CLI:

```bash
bash tower/generate_audio.sh
```

`tower/audio_manifest.json` has the per-asset prompt + duration. Edit prompts there before re-running. Re-running skips files that already exist; set `SKIP_EXISTING=0` to overwrite.

Until OGGs land, `AudioManager` silently no-ops with one warning per missing id.

## Candidate libraries

`audio/vendor/kenney_interface_sounds/` contains the CC0 Kenney Interface
Sounds pack as an audition library for UI, shop, reward, confirmation, and menu
feedback. It is intentionally not wired into `AudioManager` yet and should not
replace core combat Foley without an in-game listening pass.
