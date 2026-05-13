# Card Playability Regression Plan

Project codename: **Tower / Living Archive**

Date: 2026-05-13
Scope: regression and playability testing for the aggressive card-pool expansion defined in `30_card_character_system_design.md`.

## Purpose

The next card expansion is not just a content-count task. The goal is to prove that:

- Vanguard and Archivist no longer feel like the same character with different starting HP.
- Each character can find multiple viable build paths in normal rewards, shop offers, events, and transforms.
- Public cards improve smoothing without erasing character identity.
- Curse/status/generated cards create texture without polluting normal rewards.
- Newly added cards do not break combat, reward generation, localization, save/load, or UI readability.

This plan should be run after every card-content wave.

The long-term roster is now Warrior, Warlock, Mage, and Assassin. During the current transition, `char_vanguard` maps to Warrior, and `char_archivist` should be treated as a Warlock candidate until the class migration is complete. See `32_four_character_roster_design.md`.

## Target Card-Pool Gates

### Gate C1 — Playable Improvement

Minimum target for the next expansion wave:

| Pool | Current | C1 Target | Delta |
| --- | ---: | ---: | ---: |
| Vanguard exclusive reward cards | 32 | 45 | +13 |
| Archivist exclusive reward cards | 31 | 45 | +14 |
| Public reward cards | 15 | 30 | +15 |
| Status / curse / generated cards | 7 | 12-15 | +5-8 |

Passing C1 means the two current characters feel distinct enough for a playtest build.

Implementation snapshot, 2026-05-13:

- Vanguard exclusive reward cards: **45** (`14 common / 17 uncommon / 14 rare`).
- Archivist/Warlock-candidate exclusive reward cards: **45** (`24 common / 14 uncommon / 7 rare`).
- Mage exclusive reward cards: **45** (`15 common / 18 uncommon / 12 rare`), data-ready but not player-selectable yet.
- Assassin exclusive reward cards: **45** (`15 common / 18 uncommon / 12 rare`), data-ready but not player-selectable yet.
- Warrior and Warlock-candidate now pass the C1 exclusive card-count gate.
- Mage and Assassin now pass the C1 exclusive card-count gate as future characters.
- Public and status/curse/generated expansion remains a separate C1 follow-up.
- Class-aware relic rewards/shops and one class event per class are now part of the regression surface.

### Gate C2 — Demo Depth

| Pool | C2 Target |
| --- | ---: |
| Vanguard exclusive reward cards | 60 |
| Archivist exclusive reward cards | 60 |
| Public reward cards | 35 |
| Status / curse / generated cards | 18-24 |

Passing C2 means a 3-act demo has enough card variety to support repeated runs.

### Gate C3 — Benchmark Scale

| Pool | C3 Target |
| --- | ---: |
| Vanguard exclusive reward cards | 72-75 |
| Archivist exclusive reward cards | 72-75 |
| Public reward cards | 35-45 |
| Status / curse / generated cards | 25-35 |

C3 is the long-term benchmark-scale target, not the immediate sprint target.

## Regression Layers

Run these layers in order. Stop at the first failed layer and fix before continuing.

1. **Static data audit**: resource fields, pool counts, illegal reward cards, missing art/localization.
2. **Headless load smoke**: Godot loads all resources and scenes.
3. **Reward-pool deterministic checks**: generated offers obey pool rules.
4. **Card effect checks**: every new effect resolves without crashing and produces expected state.
5. **Character archetype test runs**: scripted/manual runs for each archetype.
6. **Economy and shop checks**: shop offers, transform, remove, events.
7. **UI readability checks**: card text, hover, reward modal, deck modal, Chinese localization.
8. **Balance sampling**: short deterministic seed set, then longer simulation when available.

## Static Data Audit

### TC-CARD-DATA-01: Pool counts hit the gate

Pre: After adding a content wave.

Steps:

1. Count all `.tres` files under `tower_game/data/cards`.
2. Group by `pool_id`.
3. Group rewardable cards by `pool_id` and `rarity`.

Expect:

- C1 minimum counts are met before calling the content wave complete.
- Vanguard and Archivist each have at least:
  - 12 common reward cards.
  - 12 uncommon reward cards.
  - 6 rare reward cards.
- Public has at least:
  - 10 common reward cards.
  - 8 uncommon reward cards.
  - 4 rare reward cards.

### TC-CARD-DATA-02: Illegal cards cannot appear in normal rewards

Expect:

- `pool_id in ["status", "curse", "generated", "event"]` implies `rewardable = false`, unless the card has a written exception.
- `card_type in ["curse", "status"]` implies `rewardable = false`.
- `rarity in ["basic", "special"]` implies `rewardable = false` for normal rewards.

### TC-CARD-DATA-03: Ownership is explicit

Expect:

- `pool_id = "vanguard"` implies `character_id = "char_vanguard"`.
- `pool_id = "archivist"` implies `character_id = "char_archivist"`.
- `pool_id = "public"` implies `character_id = ""`.
- Every rewardable character card has at least one `archetype_tags` entry.

### TC-CARD-DATA-04: Rarity and cost distribution is sane

Expect per character at C1:

- Cost 0 reward cards: 4-8. Most should exhaust, be conditional, or have low ceiling.
- Cost 1 reward cards: largest group.
- Cost 2 reward cards: enough to make energy choices meaningful.
- Cost 3+ cards: rare or high-risk.
- Powers: at least 5 per character by C1; at least 8 by C2.

Failure examples:

- A character has many attacks but only 2 powers.
- A character has no common block cards.
- A character has too many rare finishers and not enough common setup.

## Headless Load Smoke

### TC-CARD-SMOKE-01: Godot project loads

Command:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path tower_game --quit
```

Expect:

- Exit code 0.
- No parse errors for `.gd` or `.tres`.
- Object leak warnings at headless exit are noted but do not fail this test unless new fatal errors appear.

### TC-CARD-SMOKE-02: Existing runtime checks still pass

Use existing scripts when available:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path tower_game --script res://scripts/tests/smoke_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path tower_game --script res://scripts/tests/runtime_mvp_check.gd
```

Expect:

- All card resources load.
- Both character data files load.
- Combat scene and run scene still instantiate.

## Reward-Pool Regression

### TC-REWARD-01: Vanguard rewards do not offer Archivist cards

Pre:

- Start a Vanguard run.
- Use 20 deterministic reward rolls across several seeds.

Expect:

- Every card offer has `pool_id = "vanguard"` or `pool_id = "public"`.
- No `archivist`, `status`, `curse`, `generated`, or `event` card appears.

### TC-REWARD-02: Archivist rewards do not offer Vanguard cards

Same as TC-REWARD-01, but for Archivist.

Expect:

- Every card offer has `pool_id = "archivist"` or `pool_id = "public"`.

### TC-REWARD-03: Public card ratio is visible but not dominant

Sample:

- 100 reward cards offered for Vanguard.
- 100 reward cards offered for Archivist.

Expect:

- Public cards appear roughly 10-25% of normal combat rewards.
- If public cards exceed 35%, character identity will feel diluted.
- If public cards are below 5%, public cards may be too invisible.

### TC-REWARD-04: Rarity fallback does not break pool rules

Pre:

- Force a rarity with a small candidate pool, especially rare cards early in content development.

Expect:

- If the rolled pool has no matching rarity, fallback may relax rarity, but not ownership.
- Vanguard fallback should still be Vanguard/Public only.
- Archivist fallback should still be Archivist/Public only.

### TC-REWARD-05: Duplicate prevention still works

Expect:

- A 3-card reward never contains the same `card_id` twice.
- Shop card offers never contain the same `card_id` twice.

## Shop / Event / Transform Regression

### TC-SHOP-01: Shop respects current character pool

Pre:

- Open shop as Vanguard and Archivist across 10 seeds each.

Expect:

- Shop cards are current-character or public.
- Relics and potions can remain shared unless relic ownership is added later.

### TC-SHOP-02: Shop has useful offer shape

Expect:

- At least one attack or one card that can solve damage.
- At least one skill or defensive/utility card.
- Prices still respect rarity.
- Card removal service is still available.

### TC-TRANSFORM-01: Transform respects current character pool

Pre:

- Transform a Vanguard card.
- Transform an Archivist card.

Expect:

- Replacement card matches the original type when possible.
- Replacement card comes from current-character/public pool.
- No curse/status/generated card appears from normal transform unless the event explicitly says so.

### TC-EVENT-CARD-01: Event card rewards obey pool intent

Expect:

- Generic events use current-character/public rewardable pool.
- Character-specific events may bias toward that character's archetype.
- Events that intentionally add curse/status cards must bypass normal reward selection explicitly.

## Card Effect Regression

### TC-EFFECT-01: Every new card can be instantiated in CardView

Expect:

- Card art loads or falls back cleanly.
- Cost, title, rarity, type, and description render.
- No title/button text overflows in Chinese or English.

### TC-EFFECT-02: Every new card can be played if playable

For each new non-power playable card:

- Build a minimal combat.
- Put the card in hand.
- Give enough energy.
- Play it against a legal target.

Expect:

- Energy decreases correctly.
- Card moves to discard or exhaust correctly.
- All effects resolve.
- No action queue deadlock.

### TC-EFFECT-03: Powers fire and do not stack incorrectly

For every new Power:

Expect:

- It can be played once.
- Its effect persists for the combat.
- Per-turn triggers reset at the correct time.
- Multiple copies either stack or do not stack according to the card text.

### TC-EFFECT-04: Status and curse cards behave correctly

Expect:

- Status cards created during combat leave the deck after combat.
- Curse cards persist until removed.
- End-of-turn effects fire exactly once per turn when in hand.
- Ethereal/retain/exhaust rules are respected.

## Character Archetype Regression

Each archetype test is a short manual or scripted seeded run. The player should try to force that build path by picking relevant cards.

### Vanguard Archetypes

#### TC-VAN-GUARD-01: Guard Tempo

Goal:

- Player is rewarded for blocking before attacking.

Must appear by C1:

- At least 5 common/uncommon cards with `guard_tempo`.
- At least 1 power or rare payoff.

Pass:

- By floor 5, a player can assemble 3+ cards that care about Block-before-Attack.
- Combat turns feel different from simply playing the highest damage card.

#### TC-VAN-OATH-01: Oath Strength

Goal:

- Strength and multi-hit scaling form a clear attack build.

Pass:

- At least one run reaches a clear spike turn where Strength changes damage output noticeably.
- Multi-hit cards are not useless without Strength.

#### TC-VAN-FURNACE-01: Paper Furnace

Goal:

- Exhaust is a positive deck-sculpting engine, not just a drawback.

Pass:

- Player can exhaust weak cards/statuses for block, draw, or damage payoff.
- At least one common/uncommon card starts the build before rare cards appear.

#### TC-VAN-WALL-01: Unbroken Wall

Goal:

- Defensive decks have a way to win.

Pass:

- Block-heavy deck can convert defense into damage or keep enough Block to survive elites.
- Does not create infinite stall in normal fights.

### Archivist Archetypes

#### TC-ARC-INK-01: Ink Ledger

Goal:

- Ink stacking and Ink payoff cards create delayed-damage gameplay.

Pass:

- Player can win at least one normal combat by letting Ink tick.
- Ink payoff cards are exciting but not dead with low Ink stacks.

#### TC-ARC-FLOW-01: Page Flow

Goal:

- Draw/discard gives control and burst turns.

Pass:

- Player can dig for specific cards.
- Extra draw does not frequently create hand overflow or energy starvation without payoff.

#### TC-ARC-SEAL-01: Seal Control

Goal:

- Debuffs let the lower-HP Archivist survive.

Pass:

- Weak/Frail/Vulnerable application meaningfully changes incoming/outgoing damage.
- Seal-control deck does not feel like a weaker Vanguard block deck.

#### TC-ARC-MARGIN-01: Marginalia

Goal:

- Retain/setup cards create planned burst turns.

Pass:

- Retained cards visibly improve the next turn.
- The player has enough UI information to understand why the retained/setup turn worked.

## Playability Scorecard

After each manual run, score 1-5:

| Dimension | 1 | 3 | 5 |
| --- | --- | --- | --- |
| Character identity | Same as other character | Some unique turns | Clearly distinct from floor 1 |
| Draft clarity | Picks feel random | Some cards suggest a build | Rewards create obvious strategic tension |
| Combo density | Mostly standalone cards | Some 2-card combos | Multiple 2-4 card engines emerge |
| Survivability | Dies without clear counterplay | Survives with good picks | Multiple defensive plans exist |
| Damage scaling | No late-game scaling | One obvious scaling route | Several scaling routes exist |
| UI readability | Text/intent unclear | Mostly understandable | Card text and tooltips explain decisions |
| Fun factor | Flat | Promising | "One more run" pull |

Gate C1 pass threshold:

- Average score >= 3.5 for both characters.
- No dimension below 3 for either character.
- Character identity score >= 4 for both characters.

## Fixed-Seed Manual Test Matrix

Use the same seed set for both characters after each content wave:

| Seed | Purpose |
| ---: | --- |
| 1001 | Easy early card rewards; checks early identity. |
| 1002 | Low defense offers; checks survivability. |
| 1003 | Low attack offers; checks damage access. |
| 1004 | Shop-heavy path; checks economy and public cards. |
| 1005 | Elite-heavy path; checks scaling pressure. |
| 1006 | Event-heavy path; checks transform/remove/reward integration. |
| 1007 | Bad rarity luck; checks common card floor. |
| 1008 | Rare-heavy luck; checks power spikes. |

Minimum manual pass:

- 8 seeds x 2 characters = 16 short runs to Act 1 boss or death.
- Record picked cards, build direction, floor reached, death cause if any.

## Balance Sampling

Before a full simulator exists:

- Run 20 manual/assisted seeds per character at A0.
- Target Act 1 boss reach rate: 70-90%.
- Target Act 1 boss clear rate: 50-75%.
- If a character clears below 40%, its commons are too weak or too narrow.
- If a character clears above 85%, starter/reward pool may be overtuned.

After the simulator exists:

- 500 seeds per character after C1.
- 1000 seeds per character after C2.
- Track:
  - Win/loss.
  - Floor reached.
  - Cards picked by pool/archetype.
  - Average deck size.
  - Damage taken per combat.
  - Most picked cards.
  - Cards never picked.

## UI and Localization Regression

### TC-UI-CARD-01: Card text fits

Check every new card in:

- Combat hand.
- Hover inspector.
- Reward modal.
- Shop.
- Deck modal.
- Chinese language.
- English language.

Expect:

- No title overflow.
- No description clipping.
- No button/card overlap.
- Keyword text remains readable.

### TC-UI-CARD-02: Archetype meaning is visible

Expect:

- Card names and descriptions hint at their build direction.
- A new player can recognize that Ink cards belong together.
- A new player can recognize that Vanguard block/guard cards belong together.

## Failure Triage Rules

When a card fails playability:

1. If it is numerically weak but strategically clear, tune numbers.
2. If it is strong but boring, add a condition or synergy hook.
3. If it needs a rare payoff to function, add a common/uncommon bridge.
4. If it belongs to every deck, reduce its floor or move it to public rare.
5. If it is never picked, either buff, simplify, or cut it.
6. If it creates a degenerate loop, add once-per-turn, exhaust, or cost constraints.

## Done Definition for the Next Card Wave

The next content wave is done only when:

- C1 card counts are met.
- Static data audit passes.
- Godot headless load passes.
- Reward-pool tests pass for both characters.
- Shop and transform do not leak off-class cards.
- At least 4 Vanguard archetype tests and 4 Archivist archetype tests have been run.
- Playability scorecard average is >= 3.5 for both characters.
- Every new card has Chinese text that fits in card UI.
- Any failed tests are listed as known issues with severity.
