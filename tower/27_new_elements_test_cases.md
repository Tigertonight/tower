# New Elements — Manual QA Test Cases

Date: 2026-05-11
Scope: end-to-end test plan for everything added in the last batch:

- Boss phase mechanics for `b_chronicler_of_lost_pages` and `b_grand_archivist` (and the existing `b_sealed_curator` regression case).
- 6 new boss phase-2 moves.
- Relic trigger expansion (`turn_start`, `turn_end`, `card_played`, `enemy_killed`, `hp_threshold`) and the 10 new trigger-diversity relics that exercise them.
- Per-act / per-character event pool tiering in `_roll_event_id`.
- The second character `char_archivist` (data, save/load, main-menu picker, starter deck, starting relic, starting HP).

Run-format conventions:

- **ID** — stable identifier; use this when reporting bugs.
- **Pre** — prerequisites before the first step (relic to grant, character to pick, debug shortcut to use).
- **Steps** — minimal repro path.
- **Expect** — what should happen.
- **Notes** — places this hooks back into source for triage.

Useful debug hooks already in the build: pressing `F2` jumps to the map; pressing `F3` starts a `Dust Scribe` combat directly. Most relic-trigger tests benefit from being run on a low-HP enemy so you can force the killing blow / HP threshold deterministically.

---

## 1. Second Character — `char_archivist`

### TC-CHAR-01: Main-menu picker is visible and toggles selection
- Pre: Open the game from cold start.
- Steps: 1) On the main menu locate the new "Character" row under the Ascension control. 2) Click each character chip in turn.
- Expect: Both `The Vanguard` and `The Archivist` chips render. The currently selected chip is visually pressed (toggle state); only one is pressed at a time. The subtitle line under the row swaps to the selected character's `subtitle` text.
- Notes: `run_manager.gd::_show_main_menu` lines around the `char_row` block.

### TC-CHAR-02: Selection persists across menu re-entries within a session
- Pre: Cold start.
- Steps: 1) Pick `The Archivist`. 2) Click "Continue Run" or `F2` to leave the menu. 3) Return to the main menu (e.g. defeat → main menu, or restart the screen).
- Expect: `The Archivist` chip is still selected. `selected_character_id` survives screen rebuilds.

### TC-CHAR-03: Starting a new Archivist run uses Archivist data
- Pre: On the menu, select `The Archivist`. Press "Start New Run".
- Steps: 1) Skip the story intro. 2) Open the deck list (deck-summary capsule on the map).
- Expect: Max HP shows `68/68` (or `68 - ascension penalty`), starting relic is `Scribe's Focus`, deck has the Archivist starter list (4× Strike Form, 3× Guard Form, 2× Quick Read, Margin Note, Deep Breath, Copyist Focus). No `Archive Bash` or `Forward Step` in the deck.
- Notes: `run_manager.gd::_start_new_run` + `data/characters/char_archivist.tres`.

### TC-CHAR-04: Vanguard run is unchanged after the refactor (regression)
- Pre: On the menu, select `The Vanguard`. Press "Start New Run".
- Expect: Max HP `76/76`, starting relic `Sealed Badge`, the legacy 12-card starter (5 strike / 4 guard / archive_bash / quick_read / forward_step). This is the regression case for the `_starter_deck()` rewrite.

### TC-CHAR-05: Active run is unaffected by changing the menu picker
- Pre: Start an Archivist run, complete one combat, return to map.
- Steps: 1) Use the main menu (or restart) and switch the chip back to `The Vanguard`. 2) Click "Continue Run".
- Expect: The active run still loads as the Archivist (same HP, same deck, same starting relic), because `character_id` was locked in at run-start. Only "Start New Run" rolls a fresh character.
- Notes: `selected_character_id` vs `character_id` split.

### TC-CHAR-06: Save/load round-trips `character_id`
- Pre: Start an Archivist run. Quit the app entirely.
- Steps: 1) Cold-start the app. 2) Click "Continue Run".
- Expect: Run resumes as Archivist (HP, relic, deck preserved). `_load_schema_v1` reads `character_id` from the save. Manually inspect the save JSON if needed.

### TC-CHAR-07: Legacy save without `character_id` falls back to vanguard
- Pre: Hand-edit (or generate) a save file missing the `character_id` key, OR delete the field.
- Steps: 1) Continue the run.
- Expect: Run loads as Vanguard, no error. `_load_schema_v1` defaults to `char_vanguard` when the field is empty.

### TC-CHAR-08: Ascension HP penalty stacks on Archivist's lower base
- Pre: Set Ascension to A2 (or any level with `player_max_hp_penalty > 0`). Pick Archivist. Start new run.
- Expect: Max HP is `68 - penalty`. Ascension penalty correctly applies on top of the per-character base, not on top of the legacy 76.

---

## 2. Boss Phase Mechanics

### TC-BOSS-01: Sealed Curator (Act 1) phase still works (regression)
- Pre: F2 to map, route into the Act 1 boss `Sealed Curator`. Play normally.
- Expect: When boss HP drops below its configured threshold, the existing phase shift fires (this case already shipped; verify it still works after the `_announce_boss_phase()` addition).

### TC-BOSS-02: Chronicler of Lost Pages flips at <50% HP
- Pre: Reach Act 2 boss. Damage the boss to just above 50% then deliver one big hit.
- Expect: The moment HP drops below 50%, on the next `_start_player_turn` the banner reads "Phase Shift", a toast says "Chronicler of Lost Pages reaches its phase!", `sfx_boss_intro` plays, the screen shakes briefly. Boss instantly gains +4 Strength and +14 Block. Subsequent intents are drawn from the phase pool (mv_lost_pages / mv_silence_clause / mv_amend_record / mv_marginal_note).
- Notes: Boss HP threshold is 0.5 (`b_chronicler_of_lost_pages.tres`).

### TC-BOSS-03: Chronicler phase fires exactly once
- Pre: Push the Chronicler below 50%, observe the phase shift, then heal it back over 50% (e.g. via an enemy self-heal — not currently in the move pool, but a future regression).
- Expect: If HP later dips back below 50%, the phase shift does NOT re-trigger. `enemy.phase_active` is a one-way latch.

### TC-BOSS-04: Grand Archivist flips at <40% HP
- Pre: Reach Act 3 boss. Damage to just above 40% then deliver a big hit.
- Expect: Same banner / toast / sfx / shake as TC-BOSS-02. Boss gains +6 Strength and +20 Block. Subsequent intents come from mv_anathema / mv_excommunicate / mv_archival_decree / mv_heavy_stamp.
- Notes: Threshold 0.4 (`b_grand_archivist.tres`).

### TC-BOSS-05: Phase shift is silent in headless / no-audio mode
- Pre: Run smoke test or boot without audio bus.
- Expect: `_announce_boss_phase()` still emits the banner + toast and updates `enemy.phase_active`; the `am.play_sfx(...)` call is gated through `_audio()` which returns null in headless. No crash.

### TC-BOSS-06: Phase shift respects `_show_turn_banner` queue
- Pre: Trigger phase shift on the same turn the player wins.
- Expect: Banner doesn't deadlock. The "Phase Shift" banner appears, but if the killing blow took the boss to 0 HP, victory still fires (test: hit boss for damage that takes it from 60% to 0% in a single turn; phase should not fire because the boss never gets to choose_intent on a phase-active turn — verify the `was_phase_active` check is correct).

---

## 3. New Boss Phase-2 Moves

### TC-MOVE-01: Lost Pages resolves as 4 hits of 5 (+ buffs)
- Pre: Force Chronicler into phase 2, wait for an intent that shows `Lost Pages` (4-hit attack).
- Expect: On enemy turn the player takes 4 separate damage hits of 5 each (modified by Vulnerable / block / Strength). Hit numbers floating-text once per hit.

### TC-MOVE-02: Silence Clause applies Weak 2
- Pre: Force the intent.
- Expect: After resolution player has +2 Weak (existing Weak amount += 2), and took a 24-base hit (modified by Strength + Vulnerable + block).

### TC-MOVE-03: Amend Record gives boss strength + block
- Pre: Force the intent.
- Expect: After resolution boss block += 14 and boss Strength += 2. Subsequent attacks are 2 stronger.

### TC-MOVE-04: Anathema applies Frail 2 + 28 hit
- Pre: Force the intent on Grand Archivist phase 2.
- Expect: 28-base hit + player gains +2 Frail.

### TC-MOVE-05: Excommunicate is 3 hits of 10 + 1 Vulnerable
- Pre: Force the intent.
- Expect: Three separate 10-damage hits, then player gains +1 Vulnerable. (Verify status applies once, not per hit — the `status_applied` array fires once with the move.)

### TC-MOVE-06: Archival Decree gives boss 22 block + 3 Strength
- Pre: Force the intent.
- Expect: Boss block += 22, Strength += 3.

### TC-MOVE-07: New moves never appear in pre-phase pool
- Pre: Pre-phase Chronicler (HP > 50%).
- Expect: Intents drawn only from `move_pool` (cold_appraisal / marginal_note / seal_block / errata). Never see `Lost Pages` / `Silence Clause` / `Amend Record` until phase flips.

---

## 4. Relic Trigger Expansion

For each new relic, the test format is: grant the relic via debug or shop, set up the trigger condition, observe the effect. `RelicManager.trigger("combat_start", …)` fires `reset_combat_state()` on every relic instance, so per-combat latches always start fresh.

### TC-RELIC-TURN-01: `morning_ledger` grants 2 Block at turn start
- Pre: Add `morning_ledger` to `relic_ids`. Enter combat.
- Expect: Player block reads 2 immediately at the start of player turn 1, and again at the start of player turn 2 (after block resets to 0). Floating "+2 Block" text appears each turn.

### TC-RELIC-TURN-02: `dawn_kindling` grants +1 draw at turn start
- Pre: Add `dawn_kindling`. Enter combat.
- Expect: Player draws 6 cards on turn 1 (5 base + 1 from relic), 6 on turn 2, etc. Confirm draw fires BEFORE base draw effect — both happen, hand size = 6.

### TC-RELIC-TURN-03: `quiet_resolve` grants 1 Block at end of player turn
- Pre: Add `quiet_resolve`. Enter combat.
- Steps: End the player turn without spending all energy.
- Expect: When end-turn fires, player gains +1 block before the enemy turn resolves. (The block survives only if it's not consumed by an incoming attack.)

### TC-RELIC-CARD-01: `clerks_pen` adds 4 damage on every 3rd Attack
- Pre: Add `clerks_pen`. Enter combat with a deck containing several attacks.
- Steps: Play attack #1 — no bonus. Play attack #2 — no bonus. Play attack #3 — bonus 4 damage hits the enemy.
- Expect: After every 3rd Attack the enemy takes 4 extra damage (separate floating-text hit). Counter resets to 0 after firing — attack #6 fires again.
- Notes: Only `card_type == "attack"` advances the counter. Skills/Powers are ignored.

### TC-RELIC-CARD-02: `clerks_pen` counter resets between combats
- Pre: With `clerks_pen`, play 2 attacks in combat A. Win the combat. Enter combat B.
- Expect: In combat B, the bonus fires on attack #3 (not attack #1) — because `combat_start` calls `reset_combat_state()` and clears the counter.

### TC-RELIC-CARD-03: `scribes_focus` grants 1 Energy on first Skill, then nothing
- Pre: Add `scribes_focus`. Enter combat.
- Steps: Play any Skill card.
- Expect: Player energy +1 immediately. Subsequent skills in the same combat do nothing. Non-skill cards never trigger.
- Regression: Verify the once-per-combat latch resets — start a new combat, play a skill, energy +1 again.

### TC-RELIC-CARD-04: `lingering_whisper` applies Vulnerable 1 every 4th card
- Pre: Add `lingering_whisper`. Enter combat.
- Steps: Play any 4 cards (any types — counter doesn't filter).
- Expect: After the 4th card the enemy gains +1 Vulnerable. Counter resets — the 8th card triggers it again.

### TC-RELIC-KILL-01: `ember_charm` grants 4 Block on enemy kill
- Pre: Add `ember_charm`. Enter combat.
- Steps: Reduce the enemy to 0 HP.
- Expect: Just before the victory banner / rewards, the player's block jumps by 4. (Useful when victorying low-HP into a multi-room run; verify the block also applies if there were no follow-up attacks — observable via the HP/Block HUD.)
- Notes: `enemy_killed` fires before `combat_victory` — confirmed in `_check_combat_end`.

### TC-RELIC-KILL-02: `scavengers_satchel` grants 5 Gold on enemy kill
- Pre: Add `scavengers_satchel`. Enter combat. Note current gold.
- Steps: Win the combat.
- Expect: Gold tally afterwards is `prior_gold + base_combat_reward + 5`. The +5 is invisible during combat (gold is bookkept on the run, not the combat) but should appear in the post-combat tally / map HUD.
- Notes: The `gold` effect type currently goes through `set_meta("pending_gold_bonus", …)` — verify the run actually consumes that bonus into `gold` on combat end. If not, file as a bug; this test surfaces the integration gap.

### TC-RELIC-HP-01: `last_stand_oath` grants 3 Strength below 50% HP
- Pre: Add `last_stand_oath`. Enter combat with full HP.
- Steps: Take damage until HP drops below 50% of max in one hit.
- Expect: Player gains +3 Strength once. Subsequent hits in the same combat do not re-trigger. Damage cards now hit 3 harder.

### TC-RELIC-HP-02: `wax_amulet` heals 12 below 30% HP
- Pre: Add `wax_amulet`. Enter combat at full HP.
- Steps: Take damage until HP drops below 30% of max in one hit.
- Expect: Player heals 12 HP once, healing capped at max HP. Floating "+12" green text. Same combat, taking damage back below 30% does NOT re-fire.

### TC-RELIC-HP-03: Both HP threshold relics fire in the right order
- Pre: Add both `last_stand_oath` and `wax_amulet`. Take damage in a single hit from full HP to ~25%.
- Expect: Both fire — one Strength buff and one heal — in `relic_manager.relics` insertion order. Verify the heal happens after the strength gain (or document whichever order the iteration produces, since both are one-shot).

### TC-RELIC-HP-04: HP threshold latch resets between combats
- Pre: After firing `last_stand_oath` in combat A, win, enter combat B at full HP.
- Steps: Drop HP below 50% in combat B.
- Expect: Strength is granted again in combat B. Confirms `reset_combat_state()` clears `fired_this_combat`.

### TC-RELIC-MIX-01: `scribes_focus` is the Archivist's starting relic
- Pre: New Archivist run.
- Expect: `relic_ids` contains `scribes_focus` from the start. The first Skill of every combat grants +1 Energy.

### TC-RELIC-MIX-02: combat_start / combat_victory regressions still work
- Pre: Run with default Vanguard relic (`sealed_badge`) plus any old relic that uses combat_start (e.g. one of the existing 50). Win a combat.
- Expect: Existing relic effects fire as before — no regressions from the trigger refactor. This is the regression bar for the entire relic system.

---

## 5. Per-Act Event Pool Tiering

### TC-EVENT-01: Act 1 events draw from the Act 1 pool
- Pre: New run. Travel to a `?` event node on Act 1.
- Steps: Hit several `?` nodes across multiple seeds (or restart with different `run_seed`).
- Expect: Event ids observed are limited to `ev_quiet_stack`, `ev_clean_margin`, `ev_loose_page` (shared) plus `ev_red_string`, `ev_revision_desk`, `ev_ink_well` (Act 1). Never see Act 2 / Act 3 specifics.
- Notes: `run_manager.gd::_roll_event_id`.

### TC-EVENT-02: Act 2 events shift to Act 2 pool
- Pre: Reach Act 2 (defeat Act 1 boss → next-act transition).
- Expect: Pool now includes shared + `ev_transform_lantern`, `ev_dust_oracle`, `ev_weighing_scales`. Never see Act 1-only events (e.g. `ev_red_string`) unless they appear in the shared list.

### TC-EVENT-03: Act 3 events shift again
- Pre: Reach Act 3.
- Expect: Pool includes shared + `ev_burned_archive`, `ev_dust_oracle`, `ev_weighing_scales` (the latter two are reused from Act 2).

### TC-EVENT-04: `events_seen` deduplication still works
- Pre: In Act 1, hit every Act 1 event at least once.
- Expect: The next event roll falls back to repeating events from the act pool (rather than rolling Act 2 events early). Console / log shows roll-back path. Confirms the fallback `for event_id in pool: candidates.append(...)` branch is reached.

### TC-EVENT-05: Archivist gets character-specific extras
- Pre: New Archivist run. Hit several `?` events across the run.
- Expect: Archivist also sees `ev_revision_desk` and `ev_dust_oracle` even on Act 1 (because they're added to the character pool). Vanguard run on the same seed should not see those Act 2/3 events on Act 1.

### TC-EVENT-06: Saving and loading mid-event preserves the chosen event
- Pre: Hit an event, do not pick a choice. Quit.
- Steps: Cold-start, continue run.
- Expect: Either the same event re-rolls (because the choice wasn't recorded) OR a clean state advance — whichever the existing save flow specifies. Mostly testing that the new tiered pool doesn't break the save path.

---

## 6. Cross-System Smoke Tests

### TC-SMOKE-01: Full run with Archivist + new relic
- Steps: New Archivist run on Ascension 0. Buy or pick up `morning_ledger` from a shop / event reward. Beat the Act 1 boss.
- Expect: No crashes. Block fires every turn. Boss phase fires correctly. Relic UI lists both `Scribe's Focus` and `Morning Ledger`.

### TC-SMOKE-02: Multi-relic stacking on turn_start
- Pre: Build a save with Archivist + `morning_ledger` + `dawn_kindling`.
- Expect: Each player turn the player both gets +2 Block and +1 draw, plus the Archivist's first-skill Energy. Order: relic effects fire BEFORE the base 5-card draw, so the `dawn_kindling` extra card lands in the same hand.

### TC-SMOKE-03: Save-load between every screen
- Pre: Archivist run.
- Steps: Quit + relaunch on the map screen, on a combat screen (mid-turn), in a shop, on a campfire, mid-event.
- Expect: All resume cleanly with `character_id = char_archivist`. Run state survives.

### TC-SMOKE-04: Headless smoke test (`runtime_mvp_check.gd`) still passes
- Steps: Run the existing static check.
- Expect: Counts: relics ≥ 75, characters ≥ 2, enemies ≥ 18, every move id referenced in `b_chronicler_of_lost_pages.tres` and `b_grand_archivist.tres` resolves through `EnemyCatalog.build_moves()` (35 moves).

### TC-SMOKE-05: Ascension stacking on Archivist
- Pre: Archivist run on A4 (or whatever level adds curses + HP penalty).
- Expect: Starter deck includes the curses on top of the Archivist starter. HP penalty applied. Run starts cleanly.

### TC-SMOKE-06: Combat → reward → next combat regression
- Pre: Vanguard run (regression baseline).
- Steps: Play 3 combats end-to-end, picking a card reward each time.
- Expect: No relic/event/character regression; `combat_start` and `combat_victory` triggers fire as before. Reward picker still works.

---

## 7. What's Out of Scope for This Pass

These tests are NOT covered here because they're either pre-existing (and assumed unchanged) or scheduled for a later batch:

- Ascension difficulty math beyond HP penalty.
- Audio asset quality (we test that hooks fire, not whether the right sound plays).
- Shop / campfire UI layout regressions unrelated to character / relic changes.
- Map generation algorithm changes (none in this batch).
- Card balance values (none changed in this batch).

When a test in this doc fails, file a bug with the **TC-…** ID and the actual vs. expected behavior, plus the seed if reproducible.
