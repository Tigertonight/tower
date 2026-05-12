# Testing Strategy

Project codename: **Tower**

Status: Draft v1

This document defines how the Godot implementation is tested across smoke, unit, integration, regression, balance simulation, and CI layers. The current project has only one smoke script (`tower_game/scripts/tests/smoke_test.gd`); this plan extends that into a proper test pyramid without over-engineering for MVP.

## Goals

1. Catch trivial breakage (missing scenes, broken resource paths) within seconds.
2. Catch effect/relic/save logic regressions before they reach a playtest.
3. Provide a balance simulator so 30 cards × 10 relics can be tuned without 1000 manual runs.
4. Keep the bar for adding tests low so contributors actually write them.

## Test Layers

### 1. Smoke (already present)

- Runs headless: `godot_console --headless --path .\tower_game --script res://scripts/tests/smoke_test.gd`.
- Verifies main scene, combat scene, card data resources, relic data resources, theme load.
- Should run < 5 seconds on developer machine.
- Failure blocks merge.

Action items:

- [ ] Extend smoke to load every `.tres` in `data/` rather than a fixed list.
- [ ] Smoke must run before any push.

### 2. Unit Tests

Target `EffectResolver`, `DeckManager`, `RelicManager`, `MapGenerator`, status math, and save round-trip.

Folder layout:

```
tower_game/scripts/tests/
  unit/
    test_effect_resolver.gd
    test_deck_manager.gd
    test_relic_manager.gd
    test_map_generator.gd
    test_save_roundtrip.gd
  integration/
    test_combat_full.gd
    test_run_resume.gd
  sim/
    sim_balance.gd
  helpers/
    test_runner.gd
    fixtures.gd
```

`test_runner.gd` is a tiny harness:

- Discovers any `.gd` script in `unit/` or `integration/` whose class extends `TestCase`.
- Runs methods named `test_*`.
- Fails the process with non-zero exit on any assertion failure.

This avoids pulling a third-party dependency (e.g. GUT) at MVP scale.

### Required Unit Test Cases

`test_effect_resolver.gd`:

- [ ] `DealDamage(6, enemy)` reduces enemy HP by 6 when no statuses.
- [ ] `DealDamage` against `Vulnerable` deals +50% rounded down.
- [ ] `GainBlock(5, self)` adds 5 block; second cast stacks to 10.
- [ ] `DrawCards(2)` moves 2 cards from draw to hand; reshuffles when empty.
- [ ] `GainEnergy(2)` increases turn energy.
- [ ] `ApplyStatus(weak, 2, enemy)` stacks correctly.
- [ ] `ExhaustCard(self)` moves card to exhaust pile.

`test_deck_manager.gd`:

- [ ] Shuffle uses provided RNG (deterministic with seed).
- [ ] Draw N from empty draw pile triggers reshuffle from discard.
- [ ] Hand size cap respected.

`test_relic_manager.gd`:

- [ ] `Sealed Badge` heals 5 on `combat_ended`.
- [ ] `Brass Bookmark` adds 1 card on `combat_started`.
- [ ] No relic triggers on `combat_started` if relic not owned.

`test_map_generator.gd`:

- [ ] 100 random seeds: every map converges and reaches the boss.
- [ ] Layer 7 always campfire, layer 8 always boss.
- [ ] No shop→shop or campfire→campfire on any path.
- [ ] At least 2 distinct paths from start to boss for each seed.
- [ ] At least 1 elite present per map.

`test_save_roundtrip.gd`:

- [ ] Snapshot a freshly-started run, save, load, compare → identical state.
- [ ] Snapshot mid-combat (player turn start), save, load → identical hand, draw, intent.
- [ ] Save with unknown future field is loaded with field ignored.

### 3. Integration Tests

`test_combat_full.gd`:

- Spawns a deterministic combat against `e_dust_scribe`. Plays a scripted sequence of cards. Asserts final HP and reward state.

`test_run_resume.gd`:

- Starts a run with seed=42. Walks two map nodes. Saves. Loads. Asserts current_node_id, deck order, RNG state.

Integration tests run after unit tests. Budget: < 30 seconds.

### 4. Balance Simulation

`sim/sim_balance.gd` runs a headless run loop:

```text
for seed in 1..1000:
    set RNG streams from seed
    play with policy = StarterDeckPolicy()
    record: result (win/loss), turn count, hp_at_boss, deck composition
output: csv summary
```

Targets (from `17_balance_numbers.md`):

- Win rate 35–55%.
- Average run length 9–11 nodes.
- HP at boss start 50–65% of max.

The simulator does not replace human playtest; it surfaces clearly broken numbers before commits.

Run command:

```
godot_console --headless --path .\tower_game --script res://scripts/tests/sim/sim_balance.gd -- --seeds 1000 --out sim_results.csv
```

### 5. Visual / Snapshot Review

Manual screenshot review remains required for UI changes. The current project log already documents this practice. New tests should not try to compare pixel diffs of UI; instead, the contributor commits a fresh screenshot and notes any layout reasoning in the PR description.

## Definitions of Test Helpers

```text
TestCase
  setup() / teardown()
  assert_eq(a, b, msg)
  assert_true(cond, msg)
  assert_almost_eq(a, b, eps, msg)
  expect_signal(emitter, signal_name, timeout_ms)

fixtures.gd
  make_player(profile)
  make_enemy(id)
  make_combat(enemy_id)
  make_run(seed)
```

These helpers live in `scripts/tests/helpers/` and are imported by tests via `preload`.

## Determinism Rules

- All tests must seed any RNG explicitly. No reliance on global time.
- Tests must not write to `user://` outside a sandbox path; integration tests use `user://test_sandbox/`.
- Tests must clean up created files in teardown.

## CI

For MVP a single-stage CI job is sufficient:

```text
1. Install Godot 4.6.2 (cached).
2. Run smoke.
3. Run unit tests.
4. Run integration tests.
5. (Nightly only) Run sim_balance with 1000 seeds; archive csv.
```

Provider choice deferred (likely GitHub Actions). Until CI exists, contributors must run smoke + unit locally before pushing. This is enforced as a PR checklist item.

## Test Authoring Guidelines

- One file per system; one method per behaviour.
- Test names should read as the behaviour: `test_vulnerable_increases_damage_by_50_percent`.
- Avoid asserting on private fields; assert on observable state (HP, hand size, signal emission).
- Never use `await get_tree().create_timer(N)` in tests; use deterministic step functions.
- Tests should run < 100 ms each unless explicitly marked `@slow`.

## Coverage Targets

MVP target coverage:

- 100% of effects in `EffectResolver` have at least one positive test.
- 100% of relics have a trigger test.
- ≥ 80% branches in `MapGenerator`.
- 100% of statuses with tests for stack, decay, and interaction with damage/block.

These are tracked manually until coverage tooling is set up post-MVP.

## Risks Mitigated by This Plan

| Risk | Mitigation |
| --- | --- |
| Effect math regresses silently. | Unit tests on resolver + status math. |
| Map generator emits broken graphs. | 100-seed property test. |
| Save format breaks resume. | Round-trip + migration tests. |
| Balance regresses after small numeric tweak. | Nightly sim_balance vs. baseline. |

## Open Questions

- Should we adopt GUT (Godot Unit Testing) instead of a custom harness? It would cost dependency overhead but offer richer assertions.
- Should sim_balance include an "AI policy" that learns, or stay rule-based for reproducibility? MVP: rule-based.
- When should pixel-diff visual regression be added? Probably never for a fully UI-handcrafted game; remains manual.
