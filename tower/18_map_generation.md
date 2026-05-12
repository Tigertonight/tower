# Procedural Map Generation

Project codename: **Tower**

Status: Draft v1

This document specifies the algorithm and constraints for the MVP procedural map. It replaces the static authored map currently used in `RouteMapView`. The generator must be deterministic given a seed so that resumed runs reproduce the same layout.

## Map Shape

- **Layers (rows):** 9. Layer 0 is the start, layer 8 is the boss.
- **Width:** 6 columns max per layer, 0–6 active nodes.
- **Direction:** the player climbs from layer 0 to layer 8.
- **Edges:** each node connects forward to 1–3 nodes in the next layer.
- **Crossings:** edges between adjacent layers may not cross each other (visual rule, enforced at generation).

```
Layer 8                  [BOSS]
Layer 7         [campfire required somewhere on this layer]
Layer 6   . . . . .
Layer 5   . . . .
Layer 4   . . . . .
Layer 3   . . .
Layer 2   . . . .
Layer 1   . . .
Layer 0      [start, exactly 1 node]
```

(Visual is illustrative only; actual node count is computed below.)

## Layer Node Counts

| Layer | Min nodes | Max nodes | Notes |
| --- | --- | --- | --- |
| 0 | 1 | 1 | Single start. |
| 1 | 2 | 3 | First branching. |
| 2 | 3 | 5 | Widest variation. |
| 3 | 3 | 5 |  |
| 4 | 3 | 5 | First elite layer. |
| 5 | 2 | 4 |  |
| 6 | 3 | 5 | Second elite layer. |
| 7 | 1 | 1 | Forced campfire layer. |
| 8 | 1 | 1 | Boss. |

Layer 0 is always one node (`start`). Layer 7 always one node (`campfire`). Layer 8 always one node (`boss`).

## Node Type Probabilities

For non-fixed layers the type is rolled per node from a base table modified by floor.

| Type | Floors 1–3 | Floors 4–6 |
| --- | --- | --- |
| `combat` | 60% | 45% |
| `event`  | 22% | 22% |
| `shop`   | 8%  | 12% |
| `campfire`| 6% | 8%  |
| `elite`  | 0%  | 13% |
| `treasure`| 4% | 0%  |

Notes:

- Treasure only spawns in the early floors (1–3) for MVP.
- Elites only spawn at floors 4 and 6.
- Boss is always layer 8 (`boss`).

## Constraints

The generator **must enforce** all of the following after rolling node types and edges. Violations are repaired by retyping nodes (cheapest fix) or by reseeding the layer.

1. **No shop directly after shop** along any path. (`parent.type == shop` and `child.type == shop` forbidden.)
2. **No campfire directly after campfire** along any path.
3. **At least one elite** somewhere across the run path set (i.e. the union of nodes reachable from start to boss).
4. **At least one campfire before boss.** Layer 7 enforces this.
5. **Every layer 0 path** (every starting node) must lead to the boss. No dead ends.
6. **Each interior node** has at least one parent and one child.
7. **No edge crossings** between adjacent layers.
8. **At least 2 distinct routes** from start to boss exist (path diversity).

## Algorithm

```text
1. Initialize RNG = map_rng(seed_for_act).
2. For each layer 1..6 roll node count using min/max table.
3. Place nodes on a normalized x-axis [0,1] within each layer.
4. For each node in layer L, connect forward to 1..3 nearest unconnected neighbors in layer L+1
   such that no edge crosses an already-placed edge.
5. Verify reachability: every node in layer 1 must reach layer 8.
   - If not, add an edge from the unreachable node to its closest forward-layer neighbor.
6. Roll node types using probability table.
7. Apply constraints:
   - 1, 2: walk every parent->child edge; if violated, retype the child to `combat`.
   - 3: if no elite exists, retype one `combat` on layer 4 to `elite`.
   - 8: count distinct paths via DFS; if < 2, add a forward edge from the most isolated node.
8. Force layer 0 = `start`, layer 7 = `campfire`, layer 8 = `boss`.
9. Freeze map data and persist to RunManager.
```

The generator is total: it always converges. Repairs are cheap and bounded by O(layers × max_width).

## Output Schema

```text
MapData
  seed: int
  layers: Array<MapLayer>

MapLayer
  index: int
  nodes: Array<MapNode>

MapNode
  id: String           # "L{layer}_{index}"
  layer: int
  column: int          # 0..max_width-1
  type: enum(start, combat, elite, event, shop, campfire, treasure, boss)
  encounter_id: String # set for combat/elite/boss; empty otherwise
  edges_out: Array<String>   # node ids in the next layer
  visited: bool
```

## Encounter Assignment

- `combat` nodes → encounter pool by floor band, picked once when visited (not at generation).
- `elite` nodes → `elite_pool` (`el_wax_sentinel`, `el_first_clause`).
- `boss` node → fixed `b_sealed_curator` for MVP.
- `treasure` nodes → grant a random non-boss relic on entry.
- `event` nodes → roll from event pool at entry, respecting `unique` and `floor_filter`.

Encounters are rolled at *visit time*, not at generation, so re-entering a saved run picks up the player at the same node but uses the saved encounter id.

## Determinism

- One seed per run. Map generation uses `map_rng = SeededRNG(seed)` so the layout is reproducible.
- Encounter and reward rolls use `combat_rng` and `reward_rng` respectively (see `17_balance_numbers.md`).
- Save schema `19_save_schema.md` stores the seed and the current node id; the map is regenerated from seed on resume rather than reserialized in full.

## UI Interaction Rules

- Player can only click nodes that are children of their current node (or layer 0 nodes at the start).
- Visited nodes are dimmed with their type icon.
- Hover preview displays node type, expected encounter pool (combat / elite / boss only), and any active relic effects that change reward odds.
- The route map view must respect the existing 1280×720 safe area (see `12_frontend_ui_upgrade_plan.md`).

## Validation / Tests

Add to `21_testing_strategy.md`:

- 100 random seeds: every map must converge with no orphaned nodes.
- For each seed: ≥ 2 distinct paths from start to boss.
- For each seed: at least 1 elite exists.
- For each seed: layer 7 is a campfire and layer 8 is the boss.
- For each seed: no shop→shop and no campfire→campfire transitions on any path.
- Visual: render seed = 1, 42, 999 and screenshot for manual review.

## Migration from Current Static Map

Current state: `RouteMapView` uses an authored fixed map.

Migration steps:

1. Add `MapGenerator` class with the algorithm above.
2. Replace static map construction in `RunManager` with `MapGenerator.generate(run_seed)`.
3. Keep current authored map as a debug fallback flag (`--debug-fixed-map`).
4. Add tests for constraints (1–8).
5. Update save schema to store `map_seed` and `current_node_id` only.
6. Remove authored map after 1 week of stable procedural runs.

## Open Questions

- Should the player be allowed to see the map preview *before* choosing the starting node? (Currently yes — full preview from layer 0.)
- Should treasure nodes be capped at 1 per run? Currently no cap, but probability already keeps them rare.
- Should there be a guarantee of one event before floor 4? Currently no, but worth measuring during balance sims.
