# Card and Character System Redesign

Project codename: **Tower / Living Archive**

Date: 2026-05-13
Branch: `codex/card-depth-character-archetypes`
Status: Design proposal for the next implementation pass

## Goal

The current build has enough individual cards to feel bigger than the early MVP, but the run-to-run identity is still shallow because:

- `char_vanguard` and `char_archivist` mostly draw from the same reward pool.
- `CardData` has no ownership fields such as `pool_id`, `character_id`, or `archetype_tags`.
- Reward generation currently excludes only `basic` / `special` and unplayable types, so almost every non-basic card can appear for every character.
- The two playable characters have different starter decks and relics, but not enough exclusive cards, keywords, or reward shaping to produce different deck-building decisions.
- Public cards exist in practice, but they are not designed as a deliberate "colorless/common library" layer.

This document proposes a Slay-the-Spire-grade structure adapted to Tower's current codebase, world, and production scope.

## External Reference Takeaways

Research sources:

- Slay the Spire card rewards: https://slay-the-spire.fandom.com/wiki/Card_Rewards
- Slay the Spire card/category index: https://slaythespire.wiki.gg/wiki/Cards
- Slay the Spire relic structure: https://slay-the-spire.fandom.com/wiki/Relics
- Slay the Spire character pages: Ironclad / Silent / Defect / Watcher on the official community wiki and Fandom pages.

Useful patterns to adopt, without copying names, art, exact rules text, or exact layouts:

1. **Characters need exclusive card pools.** The reference game makes each character's core cards and starting relic define a mechanical identity from floor 1.
2. **Public cards should be rare seasoning, not the main meal.** Shared cards are best used for utility, smoothing, and odd build bridges; they should not erase character identity.
3. **A character needs 3-4 archetypes, not 1 gimmick.** Strong roguelike deckbuilders let a character branch into multiple builds that can hybridize.
4. **Reward variance must be constrained.** Three-card rewards should usually be from the selected character's card pool, with rarity rolls and duplicate prevention.
5. **Starter relics should teach the character.** The relic is not just a stat bonus; it nudges the player's first build decisions.
6. **Keywords are economy.** The same few statuses, triggers, and card tags should combine in many ways. Tower should add fewer mechanics, but make each one appear across attacks, skills, powers, relics, events, enemies, and potions.

## Current Tower Snapshot

As of this design pass:

- Characters: 2 implemented.
  - `char_vanguard`: 76 HP, `sealed_badge`, 12-card starter deck.
  - `char_archivist`: 68 HP, `scribes_focus`, 12-card starter deck.
- Cards: 88 `.tres` files.
  - 3 basic.
  - 78 reward-playable cards: 37 attacks, 34 skills, 7 powers.
  - 7 special/status/curse cards.
  - Rarity split among playable rewards: 33 common, 28 uncommon, 17 rare.
- Existing implemented effect vocabulary:
  - Damage, all-enemy damage, block, draw, energy, heal, lose HP, max HP.
  - Status apply, all-enemy status apply, Strength, Dexterity.
  - Ink status and `damage_per_target_ink`.
  - Add card to hand/discard, discard/exhaust random hand card.
  - Innate, retain, ethereal, exhaust-on-play, end-of-turn card effects.
- Existing structural gap:
  - No card ownership metadata.
  - No generated-only / reward-only / shop-only tags.
  - No build-archetype tags.
  - No character-specific reward pools.
  - No public-card probability control.

## Design Target

### Four-Class Roster Direction

The long-term roster should use four player-readable classes:

| Class | World title | Current / future ID | Main Mechanics |
| --- | --- | --- | --- |
| Warrior | Vanguard Archivist | `char_vanguard` | Block, Strength, Guard, Exhaust |
| Warlock | Hex Archivist / Contract Scribe | `char_warlock` or migrated `char_archivist` | Hex, Curse, Sacrifice, Doom |
| Mage | Core Arcanist / Index Mage | `char_mage` | Charge, Focus, generated spells, spell chains |
| Assassin | Shadow Operator / Margin Knife | `char_assassin` | Mark, Combo, Poison/Bleed, Discard |

See `32_four_character_roster_design.md` for the full class design, starter relics, archetypes, and migration strategy.

### Long-Term Comparable Scale

To feel comparable in depth to the genre benchmark, Tower should eventually target:

| Layer | Target |
| --- | ---: |
| Playable characters | 4 |
| Character cards | 65-75 per character |
| Public cards | 35-45 |
| Status / curse / generated cards | 30-50 |
| Relics | 100+ |
| Potions | 30+ |
| Distinct character mechanics | 1 primary + 2-3 secondary per character |

That is the long game, not the next sprint.

### Aggressive Card-Pool Roadmap

The first proposal used `45 / 45 / 30` as a safe implementation milestone. After comparing against the genre benchmark, Tower should use a more ambitious card-pool roadmap:

| Layer | Target |
| --- | ---: |
| Current implemented reward pools | Vanguard 32 / Archivist 31 / Public 15 |
| Playable improvement milestone | Vanguard 45 / Archivist 45 / Public 30 |
| Demo-depth milestone | Vanguard 60 / Archivist 60 / Public 35 |
| Benchmark-scale target | Vanguard 72-75 / Archivist 72-75 / Public 35-45 |
| Status / curse / generated cards | 25-35 at benchmark scale |

Implementation should still happen in controlled waves. The next content wave should add about **45-50 cards**:

- Vanguard: +13 exclusive reward cards.
- Archivist: +14 exclusive reward cards.
- Public: +15 public reward cards.
- Status / curse / generated cards: +5-8 supporting cards.

This gets the project to the playable improvement milestone without pretending the final card library is done. After that, the second wave should push each character toward 60 exclusive cards and add more powers/engines rather than more filler attacks.

## Core Rule: Pools

Every card should belong to exactly one primary pool:

```text
pool_id:
  vanguard
  archivist
  public
  status
  curse
  generated
  event
```

`CardData` should gain:

```gdscript
@export var pool_id: String = "public"
@export var character_id: String = ""
@export var archetype_tags: Array[String] = []
@export var keyword_tags: Array[String] = []
@export var rewardable: bool = true
@export var shop_weight: float = 1.0
@export var reward_weight: float = 1.0
@export var unlock_tier: int = 0
```

Reward rule:

```text
Normal card reward:
  85% selected character pool
  15% public pool

Elite card reward:
  80% selected character pool
  20% public pool

Boss card reward:
  70% selected character pool
  30% public pool
  Rare-only or rare-biased depending on act.

Shop:
  60% selected character pool
  35% public pool
  5% off-class only if a special relic/event enables it.
```

No off-class cards appear by default. Off-class cards should require a named relic/event because they are powerful precisely when they break the rules.

## Character 1: Vanguard

Fantasy: a field archivist in a heavy coat, using disciplined posture, oath pressure, shield work, and controlled document violence.

Role:

- Beginner-readable.
- Strong defensive baseline.
- Builds around block, Strength, repeated attacks, and exhausting excess paper.
- Wins through planned tempo rather than delayed DoT.

Starting identity:

| Field | Value |
| --- | --- |
| ID | `char_vanguard` |
| HP | 76 |
| Starter relic | `sealed_badge` |
| Starter deck | 5 Strike Form, 4 Guard Form, 1 Archive Bash, 1 Quick Read, 1 Forward Step |

Primary keywords:

- **Guard**: next attack this turn gains bonus if player has Block.
- **Momentum**: temporary attack bonus that expires at end of turn.
- **Brace**: mark that the first Block gained each turn is improved.
- **Exhaust**: used as deck-thinning and payoff, not as a punishment.

Archetypes:

| Archetype | Gameplay Question | Core Payoff |
| --- | --- | --- |
| Guard Tempo | Can I block before attacking this turn? | Hybrid attack/block cards overperform. |
| Oath Strength | Can I stack Strength and multi-hit safely? | Multi-hit attacks scale sharply. |
| Paper Furnace | Can I exhaust weak cards/statuses for value? | Smaller deck, block and draw from exhaust triggers. |
| Unbroken Wall | Can I carry or convert Block? | Block becomes damage or persistent defense. |

### Vanguard Card Suite Target

Playable improvement target split:

| Rarity | Count | Notes |
| --- | ---: | --- |
| Basic | 3 | Existing basic cards stay Vanguard-owned. |
| Common | 18-20 | Floor-1 survival and clear attacks. |
| Uncommon | 18-20 | Build direction and synergy. |
| Rare | 9-11 | Scaling engines and finishers. |

Demo-depth target: about 60 exclusive cards. Benchmark-scale target: 72-75 exclusive cards.

Keep or migrate existing cards into Vanguard:

- Basic: `strike_form`, `guard_form`, `archive_bash`.
- Guard Tempo: `measured_cut`, `shield_tap`, `forward_step`, `brace`, `counterseal`, `hardcopy`, `cited_blow`, `steel_binding`, `brass_guard`.
- Oath Strength: `oath_pressure`, `long_quotation`, `twin_dot`, `page_break`, `last_word`, `unyielding`.
- Paper Furnace: `book_throw`, `burnt_clause`, `second_wind`, `copyist_focus`, `final_oath`.
- Unbroken Wall: `ironbound`, `living_archive`, `holy_quiet`, `quiet_shelf`.

New Vanguard cards to add or rename from generic pool:

| ID | Rarity | Type | Cost | Archetype | Rules Sketch |
| --- | --- | --- | ---: | --- | --- |
| `guarded_cut` | Common | Attack | 1 | Guard Tempo | Deal 7. If you have Block, gain 3 Block. |
| `line_hold` | Common | Skill | 2 | Unbroken Wall | Gain 15 Block. |
| `badge_check` | Common | Skill | 0 | Guard Tempo | Gain 2 Block. Gain 1 Momentum. |
| `paper_shield` | Common | Skill | 1 | Paper Furnace | Gain 7 Block. Exhaust a Status or Curse in hand if possible. |
| `oath_jab` | Common | Attack | 0 | Oath Strength | Deal 3. If you have Momentum, draw 1. |
| `filing_slam` | Uncommon | Attack | 2 | Guard Tempo | Deal 11. Gain Block equal to unblocked damage. |
| `forced_revision` | Uncommon | Skill | 1 | Paper Furnace | Exhaust 1 card. Draw 2. |
| `clause_armor` | Uncommon | Power | 1 | Unbroken Wall | First time each turn you gain Block, gain 1 Momentum. |
| `return_stamp` | Uncommon | Skill | 1 | Paper Furnace | Whenever you exhaust a card this turn, gain 3 Block. Exhaust. |
| `double_entry` | Uncommon | Attack | 1 | Oath Strength | Deal 5 twice. If target is Vulnerable, deal 6 twice. |
| `sealed_counter` | Rare | Power | 2 | Unbroken Wall | At end of turn, keep half your Block. |
| `final_rebuttal` | Rare | Skill | 2 | Unbroken Wall | Gain 14 Block. Deal damage to all enemies equal to half your Block. Exhaust. |
| `oath_engine` | Rare | Power | 2 | Oath Strength | Whenever you gain Momentum, gain 1 Strength next turn. |
| `archive_surge` | Rare | Skill | 1 | Paper Furnace | Gain 2 Energy. Draw 2. Exhaust. |

## Character 2: Archivist

Fantasy: a fast, precise keeper of forbidden indexes. The Archivist wins by marking enemies, manipulating pages, and turning knowledge debt into delayed damage.

Role:

- Lower HP, higher tactical ceiling.
- More draw/discard, more debuffs, more delayed payoff.
- Builds around Ink, hand sculpting, retained cards, and sealing enemy options.

Starting identity:

| Field | Value |
| --- | --- |
| ID | `char_archivist` |
| HP | 68 |
| Starter relic | `scribes_focus` |
| Starter deck | 3 Strike Form, 3 Guard Form, 1 Quick Read, 2 Ink Blot, 1 Quill Strike, 1 Staining Hand, 1 Deep Breath |

Primary keywords:

- **Ink**: end-of-turn damage on the affected side, then decays by 1. Already partially implemented.
- **Index**: the next card matching a condition gains a bonus. This can start as status-backed "next attack/skill" modifiers.
- **Seal**: short debuff that reduces enemy output or blocks a specific status application. First implementation can map to Weak/Frail/Vulnerable plus card-specific text.
- **Retain**: lets setup cards stay in hand.

Archetypes:

| Archetype | Gameplay Question | Core Payoff |
| --- | --- | --- |
| Ink Ledger | Can I stack Ink faster than it decays? | Delayed damage and Ink-scaling attacks. |
| Page Flow | Can I draw/discard into the exact hand? | Extra energy, free cards, and big payoff turns. |
| Seal Control | Can I survive by suppressing enemy output? | Weak/Frail/Vulnerable plus defensive tricks. |
| Marginalia | Can I retain/setup notes for a later burst? | Retained cards improve or unlock effects. |

### Archivist Card Suite Target

Playable improvement target split:

| Rarity | Count | Notes |
| --- | ---: | --- |
| Basic | 4 | Needs two character starters beyond shared strike/guard names. |
| Common | 18-20 | Ink and draw must show up early. |
| Uncommon | 18-20 | Build-definition cards. |
| Rare | 9-11 | Scaling engines and combo finishers. |

Demo-depth target: about 60 exclusive cards. Benchmark-scale target: 72-75 exclusive cards.

Keep or migrate existing cards into Archivist:

- Ink Ledger: `ink_blot`, `quill_strike`, `staining_hand`, `marginalia`, `spilled_inkwell`, `dripping_seal`.
- Page Flow: `quick_read`, `page_turn`, `sift_pages`, `clean_glasses`, `quiet_revision`, `margin_note`, `thumb_jab`, `reading_glance`.
- Seal Control: `silent_step`, `reading_glance`, `second_pair`, `wax_seal`, `red_pen`, `vow_of_silence`, `break_rhythm`.
- Marginalia: `bookmark`, `folded_corner`, `reread`, `candle_count`, `red_string`, `silver_underline`.

New Archivist cards to add:

| ID | Rarity | Type | Cost | Archetype | Rules Sketch |
| --- | --- | --- | ---: | --- | --- |
| `index_mark` | Basic | Skill | 1 | Ink Ledger | Apply 2 Ink. |
| `file_needle` | Basic | Attack | 1 | Page Flow | Deal 5. Draw 1. |
| `wet_signature` | Common | Attack | 1 | Ink Ledger | Deal 6. If target has Ink, apply 1 Weak. |
| `catalog_pull` | Common | Skill | 0 | Page Flow | Draw 1. Discard 1. |
| `quiet_stamp` | Common | Skill | 1 | Seal Control | Apply 2 Weak. |
| `held_note` | Common | Skill | 1 | Marginalia | Retain. Gain 5 Block. Next turn draw 1. |
| `ink_wash` | Common | Skill | 1 | Ink Ledger | Apply 2 Ink to all enemies. Exhaust. |
| `misfile` | Uncommon | Skill | 0 | Page Flow | Discard 1 random card. Gain 1 Energy. |
| `index_loop` | Uncommon | Power | 1 | Page Flow | The first time each turn you draw outside normal draw, gain 1 Block. |
| `sealed_margin` | Uncommon | Skill | 1 | Seal Control | Apply 1 Weak and 1 Frail to all enemies. Exhaust. |
| `black_ledger` | Uncommon | Power | 2 | Ink Ledger | Ink decays 1 less at end of enemy turn. Minimum decay 0. |
| `cross_reference` | Uncommon | Attack | 1 | Marginalia | Deal 7. If any card was retained this turn, deal 12 instead. |
| `citation_storm` | Rare | Attack | 2 | Ink Ledger | Deal 4 damage for each Ink on target, then remove half its Ink. |
| `living_index` | Rare | Power | 2 | Page Flow | Whenever you draw your third card in a turn, gain 1 Energy. |
| `redacted_future` | Rare | Skill | 1 | Seal Control | Apply 3 Weak. Enemy loses 3 Strength this turn only. Exhaust. |
| `marginal_world` | Rare | Power | 2 | Marginalia | Retained cards cost 1 less next turn, once each. |

## Public Card Pool

Public cards should not be "generic leftovers." They should be useful glue:

- Emergency block.
- Simple card draw.
- Small status application.
- Safe attacks.
- Gold/HP tradeoffs.
- Rare build bridges that do not outshine character cards.

Playable improvement target split:

| Rarity | Count |
| --- | ---: |
| Common | 13-15 |
| Uncommon | 10-12 |
| Rare | 5-6 |

Demo-depth target: 30-35 public cards. Benchmark-scale target: 35-45 public cards.

Public cards should avoid:

- Deep character keywords like Guard, Momentum, Ink, Index, Seal.
- Scaling engines that become best-in-slot for every character.
- Character fantasy names that make ownership unclear.

Candidate existing public cards:

- `papercut`, `filing_edge`, `ledger_strike`, `ledger_edge`, `binder_smack`, `closed_file`, `field_order`, `deep_breath`, `footnote_charge`, `library_vow`, `steel_quill`.

New public cards:

| ID | Rarity | Type | Cost | Rules Sketch |
| --- | --- | --- | ---: | --- |
| `plain_cut` | Common | Attack | 1 | Deal 8. |
| `borrowed_cover` | Common | Skill | 1 | Gain 7 Block. |
| `loose_candle` | Common | Skill | 0 | Draw 1. Exhaust. |
| `page_rain` | Common | Attack | 1 | Deal 4 to all enemies. |
| `field_medicine` | Uncommon | Skill | 1 | Heal 4 HP. Exhaust. |
| `sharp_bookmark` | Uncommon | Attack | 0 | Deal 5. Exhaust. |
| `expedite` | Uncommon | Skill | 1 | Gain 1 Energy. Draw 1. Exhaust. |
| `dangerous_margin` | Uncommon | Skill | 0 | Gain 2 Strength. Lose 3 HP. Exhaust. |
| `borrowed_authority` | Rare | Power | 2 | At combat start after this is played, gain 1 Strength and 1 Dexterity. |
| `forbidden_appendix` | Rare | Skill | 0 | Draw 3. Add a random Curse to discard. Exhaust. |

## Generated / Status / Curse Cards

These should never be normal reward cards unless explicitly marked.

Status:

- `status_dazed`: unplayable, ethereal.
- `status_slimed`: playable tax card, exhausts.
- `status_void`: unplayable, drains energy when drawn if supported later.
- `burned_page`: unplayable, end-of-turn lose HP, exhaust.
- `ink_splatter`: playable tax card: cost 1, exhaust, no effect.

Curse:

- `curse_doubt`: end-of-turn self Weak.
- `curse_regret`: end-of-turn lose HP.
- `curse_wound`: unplayable deck clog.
- `curse_burn`: end-of-turn damage, exhaust.
- `debt_mark`: lose HP when drawn after draw triggers are implemented.

Generated:

- `mirrored_note`: retain, exhaust, draw 1.
- `sealed_copy`: 0-cost copy token generated by relics/events.
- `field_order_temp`: temporary Momentum/Block support for Vanguard.
- `ink_trace`: temporary Ink support for Archivist.

## Relic Alignment

The current relic count is already strong. The missing piece is ownership and archetype reinforcement.

Add to `RelicData` later:

```gdscript
@export var pool_id: String = "public"
@export var character_id: String = ""
@export var archetype_tags: Array[String] = []
```

Vanguard support relics:

| ID | Rarity | Supports | Rules Sketch |
| --- | --- | --- | --- |
| `sealed_badge` | Starter | Sustain | Heal after combat. Existing. |
| `field_lantern` | Common | Guard Tempo | First Skill each combat gives +2 Block. |
| `warden_glove` | Common | Oath Strength | First attack after gaining Block deals +3. |
| `binding_thread` | Uncommon | Paper Furnace | Whenever you exhaust a card, gain 2 Block. |
| `oath_crown` | Rare | Oath Strength | First time you gain Strength each combat, gain +1 more. |
| `unbroken_oath` | Rare | Unbroken Wall | Start each combat with 8 Block. |

Archivist support relics:

| ID | Rarity | Supports | Rules Sketch |
| --- | --- | --- | --- |
| `scribes_focus` | Starter | Page Flow | Start combat with extra draw or first extra draw bonus. Existing. |
| `inkstone` | Common | Ink Ledger | First Ink application each combat applies +1. |
| `silent_inkwell` | Common | Page Flow | First discard each turn gains 2 Block. |
| `red_string_relic` | Uncommon | Marginalia | Retain the leftmost card on turn 1. |
| `adjudicator_seal` | Rare | Seal Control | First enemy debuff each combat applies +1 stack. |
| `inkwells_grace` | Rare | Ink Ledger | When an enemy dies with Ink, draw 1 and gain 1 Energy once per turn. |

## Reward Algorithm

Keep Tower's current rarity probabilities for now because they already resemble the reference structure:

| Node | Common | Uncommon | Rare |
| --- | ---: | ---: | ---: |
| Normal | 60% | 37% | 3% |
| Elite | 40-50% | 40-50% | 10% |
| Boss | rare-biased or rare-only |

Add pool resolution before candidate selection:

```text
1. Roll rarity.
2. Roll source pool using selected character and node type.
3. Filter by:
   rewardable == true
   rarity == rolled rarity
   pool_id in [selected_character_pool, public]
   not duplicate in current offer
   unlock_tier <= run_unlock_tier
4. Apply reward_weight.
5. Pick.
6. If no candidate, relax pool to public, then relax rarity.
```

Add a rare pity value later:

```text
rare_offset starts at -5.
Each common reward roll increases it by +1.
Rare resets it to -5.
Clamp to +40.
```

This is not needed for the first implementation pass, but it is the right long-term shape.

## Implementation Phases

### Phase 1: Data Ownership, No New Mechanics

Goal: immediately stop shared-pool sameness.

- Add `pool_id`, `character_id`, `archetype_tags`, `keyword_tags`, `rewardable` to `CardData`.
- Backfill existing `.tres` cards into Vanguard / Archivist / Public / Status / Curse / Generated.
- Update `RunManager._reward_card_pool`, `_reward_card_candidates_for_rarity`, `_reward_card_candidates_for_type`, and shop offer generation to respect pool rules.
- Keep all existing card effects unchanged.
- Add a small debug report listing reward pool counts by character.

Gate:

- Vanguard reward screen never offers Archivist-only Ink cards unless a test flag enables mixed pools.
- Archivist reward screen never offers Vanguard-only Guard/Wall cards unless a test flag enables mixed pools.
- Public cards can appear for both.

### Phase 2: Character-Exclusive Fill

Goal: each current character reaches 45 exclusive cards.

- Add missing Vanguard cards until it has 3 basic + 42 reward cards.
- Add missing Archivist cards until it has 4 basic + 41 reward cards.
- Create 30 public reward cards.
- Add image asset checklist rows for every new card.
- Add localization rows for names/descriptions.

Gate:

- Each character has at least 12 common, 12 uncommon, 6 rare cards in its own rewardable pool.
- Each character has at least 4 powers that change the rest of combat.
- Each character has at least 3 deck archetypes that can win a run.

### Phase 3: Mechanics With Real Combo Texture

Goal: make cards care about turn sequencing.

Add effect support:

- `damage_if_blocked`
- `block_if_played_attack_this_turn`
- `draw_then_discard`
- `discard_then_effect`
- `exhaust_chosen_card`
- `damage_per_status`
- `retain_card`
- `next_attack_bonus`
- `first_time_per_turn` power hooks
- `on_draw` curse/status hooks

Add combat bookkeeping:

- Cards played this turn by type.
- Block gained this turn.
- Cards drawn outside normal turn draw.
- Cards discarded/exhausted this turn.
- Retained cards count.
- Per-turn power trigger memory.

Gate:

- Vanguard can build around Block-before-Attack, Exhaust, or Strength.
- Archivist can build around Ink, Draw/Discard, Seal, or Retain.
- At least one rare per archetype feels like a real engine.

### Phase 4: Balance and Presentation

Goal: the system feels curated, not just bigger.

- Headless sim by character and ascension.
- Reward frequency audit: no archetype should be starved of commons.
- Card inspector should show pool/keyword tags only in debug mode.
- Character select should preview:
  - Core mechanic.
  - Starter relic.
  - Three archetype badges.
  - Starter deck cards.

Gate:

- A0 winrate target: 55-65% for a simple heuristic runner.
- New player can describe how Vanguard and Archivist differ after one combat each.

## Migration Map for Existing Cards

First-pass pool assignment:

```text
Vanguard:
  archive_bash, strike_form, guard_form,
  measured_cut, shield_tap, forward_step, brace,
  counterseal, oath_pressure, hardcopy, cited_blow,
  brass_guard, steel_binding, book_throw, burnt_clause,
  second_wind, copyist_focus, final_oath, ironbound,
  living_archive, holy_quiet, quiet_shelf, unyielding,
  long_quotation, twin_dot, page_break, last_word

Archivist:
  ink_blot, quill_strike, staining_hand, marginalia,
  spilled_inkwell, dripping_seal, quick_read, page_turn,
  sift_pages, clean_glasses, quiet_revision, margin_note,
  thumb_jab, reading_glance, silent_step, second_pair,
  wax_seal, red_pen, vow_of_silence, break_rhythm,
  bookmark, folded_corner, reread, candle_count,
  red_string, silver_underline

Public:
  papercut, filing_edge, ledger_strike, ledger_edge,
  binder_smack, closed_file, field_order, deep_breath,
  footnote_charge, library_vow, steel_quill, index_thrust,
  final_argument, final_clause, closing_argument

Status / Curse / Generated:
  status_*, curse_*, any temporary or event-created cards
```

Cards not listed should be assigned during implementation by reading their actual effect text. If a card has no clear identity, prefer `public` for now, then revisit after playtesting.

## Originality Rules

Tower can learn from genre structure, but should stay original:

- Do not copy existing card names, relic names, exact rules text, exact starter decks, art silhouettes, or UI assets.
- Keep Tower's "archive / oath / ink / margin / seal" language as the naming backbone.
- Character mechanics should be expressed through Tower nouns:
  - Guard / Momentum / Oath / Furnace for Vanguard.
  - Ink / Index / Seal / Marginalia for Archivist.
- Public cards should feel like expedition tools, not generic fantasy spells.

## Recommendation

Do the next implementation in this order:

1. Add pool metadata to card data and reward generation.
2. Backfill existing cards into Vanguard / Archivist / Public.
3. Add the first aggressive content wave: about 45-50 cards total, reaching Vanguard 45 / Archivist 45 / Public 30 plus supporting status/curse/generated cards.
4. Run the card-playability regression plan in `31_card_playability_regression_plan.md`.
5. Then expand toward the demo-depth milestone of Vanguard 60 / Archivist 60 / Public 35.
6. Treat Vanguard 72-75 / Archivist 72-75 / Public 35-45 as the benchmark-scale target, not the immediate implementation target.

This gives the player an immediate improvement in role identity without waiting for the full content library.

## Implementation Log

### 2026-05-13 — Phase 1 Data Ownership

Implemented:

- `CardData` now exposes `pool_id`, `character_id`, `archetype_tags`, `keyword_tags`, `rewardable`, `shop_weight`, `reward_weight`, and `unlock_tier`.
- All existing 88 card resources have been backfilled into `vanguard`, `archivist`, `public`, `status`, or `curse` pools.
- `curse` and `status` cards are explicitly `rewardable = false`.
- `RunManager` reward, transform, and shop card candidate generation now filters to the current character pool plus `public`.
- `CombatManager` reward generation now receives `character_id` and applies character/public pool weighting for normal, elite, and boss rewards.

Current eligible reward counts:

| Character | Exclusive | Public | Total Eligible |
| --- | ---: | ---: | ---: |
| Vanguard | 32 | 15 | 47 |
| Archivist | 31 | 15 | 46 |

Next content target:

- Raise Vanguard exclusive reward cards from 32 to 45.
- Raise Archivist exclusive reward cards from 31 to 45.
- Raise Public reward cards from 15 to 30.
