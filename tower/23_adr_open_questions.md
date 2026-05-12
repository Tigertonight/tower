# Architecture Decision Records — Open Technical Questions

Project codename: **Tower**

Status: Draft v1

This document closes (or schedules) the five "Open Technical Questions" left in `02_technical_design.md`. Each entry follows a lightweight ADR format: context, decision, consequences, and revisit triggers. Decisions here are binding for MVP; later changes require a follow-up ADR.

## ADR-001: Authoring Format for Static Content

**Context.** `02_technical_design.md` left the choice between `.tres`, JSON, CSV, or hybrid open. The current prototype already uses `.tres` for cards and relics. Designers benefit from spreadsheet workflows for balance work; engineers benefit from typed Resources at runtime.

**Decision.** Use `.tres` Resources as the runtime source of truth for cards, relics, enemies, events, and potions. Allow CSV as an authoring intermediate that is converted into `.tres` via a build script.

```text
content/source/
  cards.csv     <- designer edits here
  relics.csv
  enemies.csv
content/build/
  data/cards/*.tres  <- generated, what the game loads
```

The build script (`tools/import_csv.gd`) is run on demand and on CI before tests. The CSV → `.tres` direction is one-way; `.tres` is never converted back.

**Consequences.**

- Designers can balance in spreadsheets without touching Godot.
- Runtime keeps typed Resources and the existing inspector workflow.
- Adds a small script and a build step.
- Risk: drift if someone edits the `.tres` directly. Mitigation: pre-commit hook that errors if `data/*.tres` is touched without a matching CSV change.

**Revisit when.** A designer requests live-reload from CSV in editor, or content count exceeds ~300 entries.

## ADR-002: Effect System Shape

**Context.** The 23-line `effect_resolver.gd` has hardcoded effect handling. `02_technical_design.md` listed 20+ effect types and asked whether to use Resource subclasses, dictionaries, or scriptable callbacks.

**Decision.** Use Resource subclasses driven by a registry. Each effect is a Resource (`DealDamageEffect`, `GainBlockEffect`, ...) with typed fields. A global `EffectRegistry` maps `effect_id` to Resource class. The resolver dispatches by class via a virtual `apply(context)` method.

```text
class_name DealDamageEffect extends EffectData
@export var amount: int
@export var target: TargetSpec

func apply(context: EffectContext) -> void:
    var dmg = context.compute_damage(amount, target)
    context.deal_damage(dmg, target)
```

`EffectContext` carries the player, current enemy, statuses, RNG, and emit hooks. Cards, relics, events, and enemy moves all reference effect Resources by composition.

**Consequences.**

- Reusable across cards / relics / events / enemy moves.
- Type-safe authoring in the Godot inspector.
- Adding a new effect type means adding a Resource subclass and registering it; no resolver edits.
- Slightly more boilerplate than a dictionary-based design.

**Revisit when.** Effect count crosses 60+ types and authoring fatigue becomes a real cost.

## ADR-003: Save Determinism on Resume

**Context.** The save schema (`19_save_schema.md`) supports mid-combat resume. The question is how strictly resume must reproduce the original session.

**Decision.** MVP requires deterministic resume of the **map and reward sequence**, but allows **non-deterministic combat micro-events** if they were not yet visible to the player.

Concretely:

- Map, encounter assignment, event branches, reward rolls: deterministic via seeded RNG streams.
- Mid-combat resume: snapshot draw / hand / discard / exhaust pile order verbatim. Do not reroll.
- Enemy intent for the *next* turn is captured at save time and restored verbatim. Future intents are rerolled normally.
- Damage variance (none in MVP): when added, it must use `combat_rng` so resume preserves it.

**Consequences.**

- Players who reload do not "scout" rewards by saving and reloading.
- Mid-combat saves are honest; closing during a tough turn does not let the player reroll the enemy's plan.
- Save size stays small; full RNG state per stream is serialized.

**Revisit when.** A speedrun community wants frame-perfect determinism (post-MVP).

## ADR-004: Mod Support

**Context.** Mod support is appealing for a deckbuilder; it is also a major architectural commitment.

**Decision.** **Defer** mod support to post-1.0. For MVP we will architect the data layer to *not block* future mods, but provide no public APIs.

Specifically:

- Content authoring lives in plain Resources / CSVs (ADR-001), already mod-friendly in shape.
- We do not commit to a stable script API.
- We do not load `.gd` scripts from `user://`.
- We will not promise content compatibility across versions.

**Consequences.**

- No mod-specific code to maintain.
- Future mod work is easier because content is data-driven.
- Players cannot extend the game in MVP.

**Revisit when.** The game ships and there is documented community demand. A separate ADR will define the mod surface.

## ADR-005: Mobile / Touch Input

**Context.** Mobile is interesting for the genre. The current UI is built for 1280×720 mouse + keyboard.

**Decision.** **Defer** mobile to post-1.0. Do not adapt the UI for touch in MVP. Do, however, follow two soft rules so a port is not closed off:

1. Tap-equivalent interactions: every action reachable by hover should also be reachable by click, so a touch port can map click → tap without rewriting flows.
2. Hit-target size minimum: 44 px on the smallest dimension for any interactive control.

**Consequences.**

- UI design stays focused.
- Future mobile port still requires a dedicated UI pass for hand layout, card readability, and in-combat zoom, but the underlying actions are available.

**Revisit when.** A vertical or 4:3 layout is requested or after the MVP demo cycle is complete.

## Summary Table

| ADR | Topic | Decision | Status |
| --- | --- | --- | --- |
| ADR-001 | Static content format | `.tres` runtime, CSV authoring | Accepted |
| ADR-002 | Effect system | Resource subclasses + registry | Accepted |
| ADR-003 | Save determinism | Map deterministic, intents captured, future rerolls allowed | Accepted |
| ADR-004 | Mod support | Defer; keep data layer mod-shaped | Deferred |
| ADR-005 | Mobile / touch | Defer; keep tap-equivalent flows | Deferred |

## Process for New ADRs

When a new architectural question appears:

1. Open a new entry `ADR-NNN` in this document.
2. State context, decision, consequences, revisit triggers.
3. Reference any superseded ADR explicitly.
4. Link the ADR from `02_technical_design.md` if relevant.
