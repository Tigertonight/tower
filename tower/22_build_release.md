# Build and Release

Project codename: **Tower**

Status: Draft v1

This document defines build targets, Godot export presets, version numbering, the release checklist, and the artifact handoff process. MVP is local-only; this plan also reserves later space for Steam and itch distribution without committing to it now.

## Versioning

Format: `MAJOR.MINOR.PATCH` (semantic versioning).

- MVP target: `0.1.0` for the first internal playable build.
- Pre-release suffix: `-alpha.N`, `-beta.N`.
- Public store releases would start at `1.0.0` once content lock is achieved (not in MVP).

The version string is stored in three places that **must** stay in sync:

```
tower_game/project.godot   -> config/version
tower_game/scripts/core/main.gd -> const BUILD_VERSION
tower/03_project_log.md     -> "Build" line for milestone entries
```

A small helper script `tools/bump_version.gd` should update all three at once (post-MVP).

## Target Platforms

| Platform | MVP | Notes |
| --- | --- | --- |
| Windows x64 | Yes | Primary developer platform. |
| macOS arm64 | Yes (best-effort) | Tester machine. |
| macOS x64 | Deferred | Add when needed. |
| Linux x64 | Deferred | Likely free since Godot. |
| Web (HTML5) | No | Save IO complications; revisit post-MVP. |
| Mobile | No | UI not designed for touch (`02` open question). |

## Godot Export Presets

Stored in `tower_game/export_presets.cfg` (do not commit credentials — see Secrets below).

```text
preset.0  Windows Desktop  release  -> tower_win_x64_{version}.exe
preset.1  macOS arm64      release  -> tower_macos_arm64_{version}.zip
preset.2  Linux x64        release  -> tower_linux_x64_{version}.x86_64
```

Common settings:

- Resource compression: enabled.
- Embed PCK: yes.
- Custom icon: `tower_game/icon.svg` exported to platform formats.
- Output naming: `tower_{platform}_{version}.{ext}`.

## Build Pipeline (local first)

For MVP, builds are produced locally via Godot's Export dialog or via headless command:

```text
godot_console --headless --path .\tower_game --export-release "Windows Desktop" build/tower_win_x64_0.1.0.exe
```

Pipeline order:

1. Bump version.
2. Run smoke + unit tests (`21_testing_strategy.md`).
3. Run nightly balance sim if cards/relics/numbers changed since last release.
4. Export Windows + macOS builds.
5. Verify each build launches and runs the smoke test.
6. Tag git commit `v{version}`.
7. Archive build artifacts under `build/{version}/` plus a `release_notes.md`.

CI hookup is deferred; once GitHub Actions is set up, steps 2–6 can run automatically for tagged commits.

## Release Notes Template

Save as `build/{version}/release_notes.md`:

```markdown
# Tower {version} — {YYYY-MM-DD}

## Highlights

- One-line summary.

## New
- Bullet list.

## Changed
- Bullet list.

## Fixed
- Bullet list.

## Known Issues
- Bullet list.

## Save Compatibility

- Schema version: N
- Migrates from: N-1 (auto)

## Build Commit

- {git short sha}
```

## Release Checklist

Run through every item before producing build artifacts.

- [ ] All MVP exit criteria from `08_mvp_scope.md` pass manually.
- [ ] Smoke test passes.
- [ ] Unit tests pass.
- [ ] Save round-trip test passes.
- [ ] Balance sim within targets (35–55% win rate, 9–11 node length).
- [ ] No `.tres` references missing assets.
- [ ] All imported assets cleared via `06_legal_originality_checklist.md`.
- [ ] Audio asset manifest entries match actual files (`20_audio_plan.md`).
- [ ] Build version updated in three places.
- [ ] Screenshot pass: combat, map, reward, event, shop, campfire, victory, defeat at 1280×720 and 1600×900.
- [ ] Generated `tower_run.json` from a fresh run loads cleanly.
- [ ] Localization: only EN-source strings in MVP, but no hard-coded Chinese-only or English-only mixed states.
- [ ] Tag git commit and archive build artifacts.

## Secrets and Signing

- **Do not commit** signing certificates or store credentials.
- Windows code-signing not in MVP scope (unsigned builds acceptable for internal testing).
- macOS notarization not in MVP scope; testers must approve unsigned builds via Gatekeeper.
- When stores are added: cert path lives in CI secrets, never in repo.

## Distribution Channels

| Channel | MVP | Notes |
| --- | --- | --- |
| Internal zip | Yes | Drop into shared drive. |
| itch.io | No | Reserved for first public alpha. |
| Steam | No | Reserved for `1.0.0`. |

## Post-Release Hotfix Policy

A hotfix bumps `PATCH` only. A hotfix is allowed to ship without a full balance sim run if:

- The change is strictly UI / text / asset.
- No card/relic numbers changed.
- Save schema unchanged.

Otherwise the full release checklist applies.

## Crash Reporting (deferred)

For MVP, crashes are caught via Godot's native log file. Players asked to share `user://logs/` if they hit a crash. A proper crash reporter (Sentry or similar) is post-MVP and would require a privacy disclosure.

## Open Questions

- Should the first public build be itch alpha or closed builds via Steam keys?
- Do we lock save schema before or after balance changes? (Currently before, with bumped version on changes.)
- Do we ship Linux unconditionally or wait for one tester to confirm?
