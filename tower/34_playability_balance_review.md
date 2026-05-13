# 34 Playability and Balance Review

Date: 2026-05-13

## Review Standard

Use a commercial release bar, not a prototype bar:

- A new player should understand why they won or lost.
- A normal A0 run should feel recoverable after early mistakes.
- Each playable character needs a distinct deckbuilding promise.
- Enemies must test archetypes instead of only raising damage and HP.
- Automated balance sims must include combat, rewards, shops, events, campfires, relics, and potions before win-rate numbers are treated as certification.

## Current Content Snapshot

| Area | Current Count | Review |
| --- | ---: | --- |
| Cards | 205 | Strong raw volume. Pools are now large enough for class identity work. |
| Card pools | Vanguard 48, Archivist 45, Mage 45, Assassin 45, Public 15 | Vanguard/Archivist are selectable; Mage/Assassin remain prototype-only. |
| Relics | 89 | Good global volume, but class relic density is thin: 4-5 per class pool. |
| Potions | 17 | MVP-plus count, needs clearer class synergies. |
| Enemies | 33 | Close to a serious roguelike baseline by count, but encounter identity needs more unique rules. |
| Events | 13 embedded events | Enough for an MVP act loop, but not enough for repeated commercial runs. |

## Backend Simulation Setup

Command pattern:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path tower_game --script res://scripts/tools/headless_runs.gd -- --char=<character_id> --asc=<0-2> --runs=<N> --out=<csv>
```

Simulator fixes made during this review:

- `EnemyInstance.resolve_intent()` accepts a `Variant` combat driver so the headless simulator can reuse the production enemy instance.
- `EffectResolver.resolve()` accepts a `Variant` combat driver for the same reason.
- `headless_runs.gd` now uses the expanded enemy roster and newer bosses instead of the older placeholder encounter list.

Important limitation:

The simulator currently tests starter-deck combat pressure only. It does not yet simulate card rewards, relic drops, potion use, shops, events, campfire upgrades, removes, or route decisions. Treat these results as a lower-bound pressure test, not final run balance.

## Simulation Results

| Character | Ascension | Runs | Win Rate | Avg Floors | Median Floors | Common Death Floors |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Vanguard | A0 | 200 | 0.0% | 7.98 | 8 | 8 |
| Vanguard | A1 | 200 | 0.0% | 7.98 | 8 | 8 |
| Vanguard | A2 | 200 | 0.0% | 7.80 | 8 | 8 |
| Archivist | A0 | 200 | 0.0% | 7.57 | 8 | 8, 7 |
| Archivist | A1 | 200 | 0.0% | 7.57 | 8 | 8, 7 |
| Archivist | A2 | 200 | 0.0% | 6.91 | 7 | 7, 8 |
| Mage prototype | A0 | 100 | 0.0% | 6.99 | 7 | 7, 8 |
| Assassin prototype | A0 | 100 | 0.0% | 8.00 | 8 | 8 |

Interpretation:

- The current combat path reliably kills starter decks around floor 7-8.
- A1 currently has almost no separation from A0, which means ascension modifiers are either too mild or hidden by the same early choke point.
- A2 starts pulling deaths earlier, especially Archivist, so the pressure layer is working but the base curve is already too punishing.
- Prototypes can execute, but their results should not be used as character balance because they are not selectable and some mechanics are still approximated.

## Slay the Spire Comparison

Content quantity is no longer the main gap. The sharper gap is systemic texture.

Slay the Spire has four strong class card ecosystems, a large list of normal monsters/elites/bosses, and a run structure where fights, shops, relics, potions, events, and campfires all change deck direction. Tower is now approaching comparable raw content counts in cards and enemies, but still falls short in:

- enemy encounter signatures;
- class-specific relic density;
- fully implemented class mechanics;
- reward-aware balance simulation;
- long-run event variety;
- readable tactical feedback during hard fights.

## Commercial Readiness Verdict

Not ready for a sellable release yet.

It is now a credible content prototype, but it does not pass a commercial balance/readability bar. The main failure is not missing raw data; it is that the run loop cannot yet prove enjoyable difficulty progression.

## Recommended Next Steps

P0:

- Upgrade `headless_runs.gd` into a route-aware run simulator: pick rewards, skip bad cards, upgrade key cards, use potions, apply relics, and model shop/campfire/event choices.
- Tune Act 1 around a target A0 bot win rate near 45-60% once reward simulation exists.
- Give every elite and boss one unmistakable rule, not only stronger stats.

P1:

- Promote Mage and Assassin only after their mechanics are fully implemented and visible in UI.
- Increase class relics from 4-5 each to 10-15 each, with at least 3 build-defining relics per class.
- Expand events from 13 to 25-35, with class-specific branches and risk/reward choices.

P2:

- Add balance dashboards: floor death heatmap, card pick rate, card win-rate delta, relic impact, potion usage, boss damage intake.
- Build a weekly regression suite using fixed seeds for easy/medium/hard routes.
