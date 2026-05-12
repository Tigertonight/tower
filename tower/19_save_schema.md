# Save Schema v1

Project codename: **Tower**

Status: Draft v1 (target schema for first-run save)

This document defines the persistent run save format, fields, save/load triggers, and the migration strategy for future schema versions. It supersedes the ad-hoc save layout currently produced by `tower_game/scripts/save/save_manager.gd`.

## File Layout

The MVP saves only the **current run**. Path:

```
user://tower_run.json
```

Future files (not in MVP):

```
user://tower_profile.json    # unlocks, stats, settings
user://tower_settings.json   # input + audio settings
user://tower_stats.json      # per-character run history
```

A schema_version field protects against breaking changes.

## v1 Schema (JSON)

```json
{
  "schema_version": 1,
  "saved_at_iso": "2026-05-11T13:42:00Z",
  "build_version": "0.1.0",
  "run": {
    "run_id": "uuid-v4",
    "seed": 1234567890,
    "rng_state": {
      "map_rng": 871312012,
      "combat_rng": 12931293,
      "reward_rng": 38172819,
      "event_rng": 9182391
    },
    "character_id": "char_vanguard",
    "act": 1,
    "current_node_id": "L3_2",

    "player": {
      "max_hp": 76,
      "hp": 64,
      "gold": 132,
      "energy_per_turn": 3,
      "potion_slots": 3
    },

    "deck": [
      { "card_id": "strike_form", "upgraded": false },
      { "card_id": "strike_form", "upgraded": true },
      { "card_id": "guard_form",  "upgraded": false }
    ],

    "relics": [
      { "relic_id": "sealed_badge", "counters": {} },
      { "relic_id": "brass_bookmark", "counters": { "uses": 2 } }
    ],

    "potions": [
      { "potion_id": "guard_draught" },
      null,
      null
    ],

    "map": {
      "generator_version": 1,
      "node_states": {
        "L0_0": "visited",
        "L1_1": "visited",
        "L2_2": "available",
        "L2_3": "locked"
      }
    },

    "history": {
      "encounters_completed": 4,
      "elites_defeated": 0,
      "events_seen": ["ev_quiet_stack"],
      "shop_visits": 1,
      "card_removals": 1
    },

    "combat_state": null
  }
}
```

### Field Reference

| Field | Type | Notes |
| --- | --- | --- |
| `schema_version` | int | 1 for MVP. Bump on breaking change. |
| `saved_at_iso` | string | ISO 8601 timestamp; informational only. |
| `build_version` | string | Game build version string. |
| `run.run_id` | string | UUIDv4 for this run; stable across saves. |
| `run.seed` | int | Root run seed. |
| `run.rng_state.*` | int | Current state of each RNG stream. |
| `run.character_id` | string | Always `char_vanguard` in MVP. |
| `run.current_node_id` | string | `L{layer}_{index}` from `18_map_generation.md`. |
| `run.player.*` | mixed | Mutable stats. |
| `run.deck[]` | array | Order is the persistent draw order; combat shuffles in memory only. |
| `run.relics[]` | array | Relic instance per-run state. |
| `run.potions[3]` | array(3) | Fixed-length, `null` for empty slots. |
| `run.map.generator_version` | int | The map regenerates from seed; this protects against generator drift. |
| `run.map.node_states` | dict<string, enum> | Only nodes that differ from default are serialized. |
| `run.history` | object | Stats used for relic conditions and meta features. |
| `run.combat_state` | object\|null | If non-null, mid-combat resume payload. |

### Combat State (mid-combat resume)

If a save is taken during combat (e.g. the player closed the game), `combat_state` is non-null:

```json
"combat_state": {
  "encounter_id": "e_dust_scribe",
  "turn": 3,
  "player_block": 4,
  "player_energy": 1,
  "player_statuses": [{ "status_id": "vulnerable", "stacks": 2 }],
  "enemy": {
    "id": "e_dust_scribe",
    "hp": 12,
    "block": 0,
    "statuses": [],
    "intent": "inkstroke",
    "move_history": ["inkstroke", "defend"]
  },
  "draw_pile_ids": ["strike_form", "guard_form+", "..."],
  "hand_ids": ["measured_cut", "..."],
  "discard_pile_ids": ["..."],
  "exhaust_pile_ids": []
}
```

Save during enemy turn is **not** allowed; saves only fire at well-defined boundaries (see Save Triggers below).

## Save Triggers

The game writes the save file at these points:

1. Run start (after character pick).
2. Map node entered (immediately on entry, before encounter starts).
3. Card reward resolved (after add-to-deck or skip).
4. Shop transaction completed.
5. Campfire action resolved.
6. Event resolved.
7. Enter combat: snapshot at start of *player turn* only.
8. End of combat (after relic post-combat triggers).
9. Run end (victory or defeat).
10. Game window close (best-effort; falls back to last successful save).

Saves are atomic: write to `user://tower_run.json.tmp` then rename.

## Load Behaviour

On Continue:

1. Read `user://tower_run.json`.
2. Validate `schema_version` against current code. If higher, reject and prompt user; if lower, run migrations.
3. Recreate map by feeding `seed` + `generator_version` to `MapGenerator`.
4. Apply `node_states` overrides.
5. Restore RNG streams.
6. If `combat_state` is non-null, jump to combat scene with the snapshot. Otherwise jump to the node corresponding to `current_node_id`.
7. Trigger the same `combat_started` / `node_entered` event the live flow would, so relic listeners run normally.

If validation fails the save is moved to `user://tower_run.broken.json` and a fresh run is forced.

## Versioning and Migration

- `schema_version` is a single integer. Increment on any breaking change.
- Each version exposes a migration function `migrate_vN_to_vN+1(json) -> json`.
- Migrations are pure functions and chained.
- Reject saves whose version > supported version with a clear message ("This save is from a newer build of Tower").
- Backwards-compatible additions (new optional field) do **not** require a version bump; readers must default missing fields.

Example migration plan (not for MVP):

- v1 → v2: add `chosen_difficulty: "standard"` default.
- v2 → v3: split `relics[].counters` into typed fields.

## Implementation Notes

- The current `save_manager.gd` only writes a small subset (deck IDs + combat progress). Bring it up to v1 by:
  1. Defining a `RunSnapshot` Resource with the fields above.
  2. Replacing `save()` with `RunSnapshot.from_run_manager()` followed by JSON serialization.
  3. Replacing `load()` with `RunSnapshot.apply_to_run_manager()`.
  4. Adding atomic write via `FileAccess` + rename.
- Avoid serializing Godot RID/Object references; everything must be plain data.
- Avoid serializing `RandomNumberGenerator` directly; serialize `state` (uint64) and re-seed on load.

## Privacy and File Hygiene

- The save contains no personally identifying information.
- Logs that include save snippets must redact any future `player_alias` / online ID fields.
- Save corruption is logged to `user://tower_run.broken.json` for support; never overwrite the live save with broken data.

## Test Plan

To be implemented in `21_testing_strategy.md`:

- Round-trip tests: save → load → re-save → diff. Must be byte-identical for stable runs.
- Mid-combat snapshot test: snapshot at turn start, restore, verify `enemy.intent` stays the same.
- Migration tests: synthetic v0 file (current ad-hoc save) migrates to v1 successfully.
- Corruption test: truncated JSON should leave a recoverable game state and not crash.

## Open Questions

- Should we serialize the full map (nodes + edges) instead of regenerating from seed? Tradeoff: simpler resume vs. larger save. MVP picks regenerate.
- Should mid-combat saves snapshot deck pile order verbatim, or accept a reshuffle on resume? MVP picks verbatim.
- Should `run_id` be exposed in UI for support purposes?
