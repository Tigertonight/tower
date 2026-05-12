# Phased Roadmap — Demo Slice → Full Game

Date: 2026-05-11
Owner: solo dev (with AI pair)
Scope: a layered, gated project plan for the Tower (Living Archive) build. Splits work into Target A — a mechanically complete vertical demo slice — and Target B — a full content/balance/platform pass toward a shippable product. The intent is to let the team (or future-you) slot any new ask into a phase, judge it against a clear gate, and not lose the thread between "demo polish" and "long-tail production".

---

## 0. North Star and Gates

**North Star.** The smallest version of the game that a stranger can sit down with, finish a 3-act run on, and feel that the loop, the meta, and the polish are *complete*, even if the content library is small.

**Gates** (all must be true before moving to the next phase):

| Gate | Definition |
| --- | --- |
| G-A1 | A new player can finish a full 3-act run on Vanguard or Archivist without confusion, with audio and key VFX in place, and at least one boss phase per act. |
| G-A2 | The above with multi-enemy combat, all P0 art assets shipped, and at least one balance pass (winrate within target band) on A0–A2. |
| G-B1 | Two characters with mechanically distinct kits (status DoT for Archivist, baseline for Vanguard); Neow, Boss Swap, and run-summary loop in place. |
| G-B2 | 200+ cards / 100+ relics / 30+ enemies, A0–A5 tuned, localization scaffold, gamepad/keyboard support. |
| G-B3 | Steam page + first build candidate, achievements + run history, accessibility pass, beta-tester loop opened. |

The gates above are *binary*: either the demo build clears the bar or it doesn't. They are NOT release gates — they are slice-completion gates inside the project plan.

---

## 1. Where the project is today (2026-05-11)

This snapshot is captured to make Phase A1 ROI judgments concrete; it should stay accurate so future planning rounds can compare against it.

- **Characters:** 2 playable (`char_vanguard`, `char_archivist`). Mechanically near-identical — both are baseline strike/guard kits with a few differentiating cards. No DoT / orb / stance.
- **Cards:** ~80, all single-target.
- **Relics:** 75, with 7 trigger types wired (`combat_start`, `combat_victory`, `turn_start`, `turn_end`, `card_played`, `enemy_killed`, `hp_threshold`).
- **Enemies:** 18, all single-enemy combats.
- **Bosses:** 3 with phase mechanics (Sealed Curator, Chronicler of Lost Pages, Grand Archivist).
- **Map:** 3 acts wired, event pool tiered per-act and per-character.
- **Audio:** AudioManager autoload + hooks. Generation pipeline exists but most assets still placeholder.
- **Art:** all art is placeholder / generated stand-ins. Archivist sprite reuses Vanguard. The 10 new relics fall back to type icons.
- **Save:** schema v1, character_id round-trips, mid-run resume across all screens.
- **Loop end-states:** combat victory → reward → map; defeat → main menu. No run summary screen, no Neow, no boss swap.

---

## 2. Phase A1 — Mechanics-complete demo slice (Target A)

**Goal:** clear gate G-A1. Everything in this phase is in service of "a stranger can finish a run and the experience feels coherent, not just functional."

Items are ordered by ROI within the phase (dependencies later, biggest player-experience impact first).

### A1.1 — Multi-enemy combat (P0, **must**)

Today every fight is 1v1. StS-style combat depends on multi-target intents, AoE cards mattering, and enemies dying in a meaningful order.

- Combat manager: support `enemies: Array[EnemyInstance]`, alive iteration, target selection.
- Intents resolve per-enemy; killed enemy removed from turn order without breaking action queue.
- Cards: `target` field — `single`, `all`, `random` — wired through `EffectResolver.resolve()`.
- Status / debuff per-enemy bookkeeping (Vulnerable / Weak / Frail already on enemies, just need it scoped properly when there are multiple).
- Encounter table: at least 6 multi-enemy elite/normal encounters across acts.
- Boss fights stay 1v1; "boss + add" is deferred to A2.

**Done when:** at least one Act 1 normal encounter, one Act 2 elite, and one Act 3 normal are 2+ enemies; cards labelled "all enemies" actually hit all enemies; killing one enemy mid-turn doesn't break the intent banner or relic triggers.

### A1.2 — Tooltips and keyword inspector (P0, **must**)

Today the player sees `Vulnerable`, `Frail`, `Weak`, `Strength`, `Block`, `Poison` (when added) etc. with no in-game explanation. A new player has no path from "I see the word" to "I know what it does." This is a much bigger barrier than it sounds.

- Lift the existing `CardInspector` into a generic `KeywordInspector`.
- Status icons in HUD: hover/tap shows a one-line definition.
- Card text: keywords highlighted; hover shows the keyword tooltip.
- Relic icons: hover shows full description (already partly there — formalize).
- Build a `data/keywords.tres` catalog; never inline text in UI.

**Done when:** every keyword that appears in any card / relic / status has a tooltip definition reachable in one hover.

### A1.3 — Archivist mechanic identity: Poison / Bleed (P0, **must**)

Right now the two characters play almost identically. The Archivist needs *one* mechanical hook that makes choosing it feel different from the Vanguard. Cheapest distinct hook is a damage-over-time stack ("Ink" or "Bleed") that ticks at end of enemy turn.

- New status: `ink` (or `bleed`) — at end of enemy turn, deals N damage equal to its stack count, then decays by 1.
- Card support: 4–6 Archivist cards that apply Ink, exhaust on use, or scale off Ink.
- One Archivist relic that interacts with Ink (e.g. "the first time an enemy dies with Ink on it, draw 2").
- Tooltip support (depends on A1.2).

**Done when:** an Archivist run plays meaningfully differently from a Vanguard run; at least one combat is winnable specifically by Ink stacking; the new status has tooltips and at least one relic synergy.

### A1.4 — Audio asset generation pass (P0, **must**)

The audio system is wired but most assets are placeholder. A play session without proper SFX feels like a prototype, regardless of mechanics.

- Generate the SFX called out in `tower/13_visual_asset_manifest.md` and `tower/26_new_elements_asset_checklist.md` (boss phase shift, paper storm, Archivist run-start, the standard combat hit/block/draw/shuffle).
- Three music loops (calm map, combat, boss).
- Loud-volume QA: no clipping, levels balanced relative to hit/block.
- Hook check: all `am.play_sfx(...)` calls in code resolve to a real asset.

**Done when:** running through a 3-act demo, every audio hook produces an audible asset; nothing falls back to placeholder beep.

### A1.5 — Core P0 art pass (P0, **must**)

The visual stand-ins are good enough for internal play but unshippable. The asset checklist already enumerates what's needed; Phase A1 owns producing them.

- `archivist.png` player sprite (replaces Vanguard placeholder).
- 10 relic icons in `tower/26_new_elements_asset_checklist.md` Section 4.
- `vfx_phase_shift_burst.png` and the boss `phase2` alternates if time permits.
- `vfx_lost_pages_storm.png` overlay.
- Character chips for the main-menu picker.

**Done when:** all P0 entries in `tower/26` are checked off; no placeholder appears in the demo build.

### A1.6 — Run summary screen (P1, **should**)

After defeat or victory, the player should see *what their run was*. Even a stripped one is a major satisfaction multiplier.

- Final HP, gold, floor reached, run length.
- Final deck list (using existing `CardPicker` read-only mode).
- Relics collected in order.
- Boss(es) defeated.
- "Continue to main menu" button.

**Done when:** every run end (victory or defeat) goes through this screen instead of dumping to main menu.

### A1.7 — Pause menu and settings (P1, **should**)

ESC currently does nothing reliable. A pause menu with volume sliders, a "give up run" button, and a "back to map" link is table stakes.

- Master / Music / SFX volume sliders, persisted to user://settings.cfg.
- "Give up run" button that triggers defeat → run summary.
- Back to game button.
- Pause should *actually* freeze the action queue.

**Done when:** ESC at any point shows the pause menu; volume changes persist between sessions.

### A1.8 — First-battle tutorial hints (P1, **should**)

Once-per-run pop-ups that point out "this is your draw pile", "this is your block", "this is the intent". Not a full tutorial — just enough nudges in the first combat that a first-time player isn't lost.

- Three to five contextual tooltips firing on first interaction.
- Stored in save as "tutorial_seen" flags so they don't re-fire.

**Done when:** a fresh save's first combat shows hints in order; subsequent runs do not.

### A1.9 — Balance simulation pipeline (P1, **internal**)

A headless script that runs N runs with random/AI play and reports winrate per act / per character / per ascension. This is the only way to get a real signal on balance before more characters land.

- Script: `tower_game/scripts/tools/headless_runs.gd` driven by a CLI flag.
- AI: simple heuristic (play highest-cost playable card → end turn); good enough for variance reduction.
- Output: CSV with one row per run, columns for character, ascension, floor reached, outcome, deck-size.
- Aggregator: a small Python script that produces a per-tier winrate table.

**Done when:** running 1000 sims for each (character × A0–A2) produces a stable winrate table the human can read in <60s.

### Phase A1 dependency graph

```
A1.1  multi-enemy combat   ─────┐
A1.2  tooltips             ─┐   │
A1.3  Ink/DoT mechanic       └──┴─→ A1.6 run summary
A1.4  audio                       ─→ A1.5 art pass (some VFX overlap)
A1.7  pause/settings        (independent)
A1.8  tutorial hints        (depends on A1.2 tooltips)
A1.9  balance pipeline      (independent; gates A2)
```

Build order in practice: A1.2 → A1.1 → A1.3 → A1.4 + A1.5 in parallel → A1.7 → A1.6 → A1.8 → A1.9.

### Effort estimate (rough, solo + AI pair)

| Item | Est. days | Notes |
| --- | --- | --- |
| A1.1 multi-enemy | 4–6 | combat manager refactor is the hairy part |
| A1.2 tooltips | 2 | mostly UI plumbing once the catalog exists |
| A1.3 Ink mechanic | 3 | + 4–6 cards + 1 relic |
| A1.4 audio | 2 | mostly running the existing pipeline |
| A1.5 art P0 | 2–3 | running the gen pipeline + curating |
| A1.6 run summary | 1.5 | mostly UI |
| A1.7 pause/settings | 1.5 | settings persistence is half the work |
| A1.8 tutorial hints | 1 | content + flags |
| A1.9 sim pipeline | 2 | static AI is enough |
| **Total A1** | **~3 weeks** | does not include slip / debugging |

---

## 3. Phase A2 — Demo slice polish and balance (Target A complete)

**Goal:** clear gate G-A2 — the demo is shippable as a vertical slice, even if the content library is small.

### A2.1 — A0–A2 balance pass

- Run the A1.9 sim pipeline.
- Target winrate band: A0 ~60%, A1 ~50%, A2 ~40% across both characters.
- Adjust card / enemy / boss numbers in `data/`. No new mechanics.

### A2.2 — Boss + add fights

- One boss in A2 or A3 spawns with one minion. Reuses A1.1 multi-enemy code.

### A2.3 — Failure-mode polish

- "No cards left to play" → end turn auto-prompt.
- Mid-combat quit + resume regression pass.
- Save corruption: if save fails to parse, archive it and start fresh with a toast.

### A2.4 — Demo build pipeline

- Standalone build script (Windows + macOS).
- Build label embedded in the main menu (`v0.A2-demo`).
- Itch / internal upload once.

**Done when:** a non-dev can download a build, finish a run, and the only complaints are content depth (which is Target B's problem).

---

## 4. Phase B1 — Mechanic depth and meta loop

**Goal:** clear gate G-B1. The game grows from "complete slice" to "complete game shape, light content."

### B1.1 — Per-character mechanical kits

- Vanguard: Block / Strength / Exhaust archetype (already most of the way).
- Archivist: Ink DoT (from A1.3) + a second axis — discard-synergy or scry.
- Optional third character planning doc (don't build yet).

### B1.2 — Neow blessings

- Pre-run choice screen between fixed seed and 4 random blessings.
- ~12 blessing options.
- Hooks into starting deck / HP / relic / curse.

### B1.3 — Boss Swap option

- After Act 1 boss reward, offer a Boss Relic swap with a ~25% downside.
- Reuses existing reward UI.

### B1.4 — Daily run / seeded run

- Seeded run UI on the main menu (not daily-as-a-service yet, just "play seed X").
- Run summary records the seed.

### B1.5 — Card upgrade depth

- Every card has an upgrade defined and tested. (Today most do, some don't.)
- Campfire upgrade flow polish.

---

## 5. Phase B2 — Content scale-out and platform polish

**Goal:** approach gate G-B2.

### B2.1 — Content scale

- 200+ cards (100+ per character).
- 100+ relics across rarities.
- 30+ enemies, 5+ elites per act, 2+ bosses per act.
- 20+ events, with proper Act tiering.
- 6 potions per act.

### B2.2 — Ascension A3–A5 tuning

- Per-level sim pass.
- A4 Heart equivalent: gated on a special unlock condition.
- A5 final boss extra phase.

### B2.3 — Localization scaffold

- Strings extracted to a single `data/loc/en.csv`.
- Build pipeline supports a second locale, even if only English ships.

### B2.4 — Gamepad + keyboard controls

- Full input remap layer.
- Card targeting via dpad / arrows.
- Tooltip hover replaced with focus.

### B2.5 — Accessibility pass

- Colorblind-safe palette toggle.
- Text-size slider (small / medium / large).
- Screen-shake intensity slider.
- "Reduce motion" toggle that disables non-essential VFX tweens.

---

## 6. Phase B3 — Steam-ready candidate

**Goal:** clear gate G-B3.

### B3.1 — Steam page assets

- Capsules (sm / md / lg / library).
- Trailer (1 min).
- 6+ screenshots covering each act and both characters.
- Long description + short description.

### B3.2 — Achievements

- 30 achievements across "first finish", "ascension milestones", "deck shapes", "secret runs".
- Steam achievements integration.

### B3.3 — Run history + stats

- Last 50 runs persisted with seed + outcome.
- Per-character winrate, average floor, favorite relics.
- Visible from the main menu.

### B3.4 — Beta-tester loop

- Discord or itch private build.
- Telemetry opt-in: anonymized run summaries posted to a single endpoint.
- Bug template + triage doc.

### B3.5 — Final balance + polish

- A0–A5 winrate band fits the design target.
- All onboarding-flow items from A1 work for first-time external testers.
- Crash-free for 1h sessions on three test rigs.

---

## 7. Out of scope (for now)

These are deliberately deferred past B3 unless market signal flips them:

- Online co-op or PvP.
- Procedural card generation (LLM-driven content) at runtime.
- Mobile port (would need a major UI rework).
- DLC characters beyond the third planning doc in B1.1.

If any of these come up in the future, they slot as a new Phase C and re-gate from G-B3.

---

## 8. How to use this doc

When a new feature request lands:

1. Identify the smallest gate it requires (G-A1, G-A2, G-B1, …).
2. Slot it as a sub-item under that phase.
3. Score it for ROI inside the phase (how much does it move that gate?).
4. If it doesn't move any gate, defer it.
5. Each phase ships in order; do not pull a B-phase item ahead of an A-phase gap unless it accidentally also closes the A gap.

When a phase wraps:

- Update `tower/03_project_log.md` with the phase outcome.
- Update this doc's Section 1 ("where the project is today") so the next planning round starts from truth.
- If a planned item was dropped, leave it in place and mark it `[deferred → B2]` rather than deleting; that's how you avoid relitigating the same decisions.

---

## 9. TL;DR for Target A

What still needs to happen before the demo is callable "done":

1. Multi-enemy combat.
2. Tooltips / keyword inspector.
3. Archivist gets a real distinct mechanic (Ink/DoT).
4. Audio asset gen pass.
5. P0 art pass (sprite + 10 icons + 2 VFX).
6. Run summary screen.
7. Pause menu + settings.
8. First-battle tutorial hints.
9. Balance simulation pipeline + one tuning pass.

Estimated ~3 weeks of focused solo work, plus a polish week. After that, gate G-A2 is in reach and the project is ready to ramp into Phase B1.
