# 36 Full Game Acceptance Report

Date: 2026-05-13

## Acceptance Standard

This review uses a commercial release bar: if a player can notice friction, confusion, untranslated text, cramped layout, silent failure, or weak feedback in normal play, it is recorded even when the game does not crash.

## Coverage

Validated by automated runtime checks, a new acceptance traversal script, and one manual Godot window pass.

Commands run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path tower_game --script res://scripts/tests/smoke_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path tower_game --script res://scripts/tests/runtime_mvp_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path tower_game --script res://scripts/tests/runtime_scene_check.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path tower_game --script res://scripts/tools/acceptance_story_walk.gd
```

Manual window pass:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path tower_game
```

Covered screens:

- Main menu
- Character select
- Story intro
- Route map
- Combat
- Shop
- Campfire
- Deck picker / card picker paths
- Run summary defeat/victory
- All event/story nodes and all three choices where present

Covered story/event nodes:

- `ev_quiet_stack`
- `ev_clean_margin`
- `ev_red_string`
- `ev_revision_desk`
- `ev_ink_well`
- `ev_loose_page`
- `ev_transform_lantern`
- `ev_dust_oracle`
- `ev_weighing_scales`
- `ev_burned_archive`
- `ev_broken_standard`
- `ev_unpaid_contract`
- `ev_core_orrery`
- `ev_silent_margin`

Result: all event nodes and choice branches can be opened and clicked without a hard crash or null screen.

## High Priority Findings

### P0 - Campfire Layout Breaks the Viewport

The acceptance script detected the campfire panel at `968x2516`, with action buttons reaching far below the 720p viewport. This confirms the earlier player-facing concern: campfire is not a polished choice screen yet.

Impact:

- The most important rest/upgrade/remove/transform decision screen feels broken.
- Button heights explode because multiline button layout is not constrained.
- A commercial player would read this as unfinished UI.

Recommended fix:

- Replace multiline `Button.text = "%s\n%s"` with a custom action row component: icon, title label, hint label.
- Fixed action row height around `84-96`.
- No scrollbars unless the viewport is genuinely too small.

### P0 - Shop Layout Overflows Vertically

Shop view content reaches about `1019px` high. Some potion/remove/leave controls can fall below the visible 720p window.

Impact:

- The shop cannot be trusted as a repeat-use core screen.
- Buying/removing cards can become visually cramped or partially inaccessible.

Recommended fix:

- Split shop into tabs or compact sections: Cards / Relics / Potions / Services.
- Keep the leave button pinned to the bottom-right.
- Use fixed product tile heights.

### P0 - Run Summary Modal Overflows

Defeat and victory summary panels are about `772px` high, exceeding the 720p viewport.

Impact:

- The end-of-run moment looks broken.
- Buttons can sit too close to or beyond the lower edge.

Recommended fix:

- Make the panel height max `620`.
- Put deck/relic details in a scroll-free compact summary or a secondary details button.

### P0 - Character Select Does Not Match the Four-Class Design

Current visible selectable roster only shows Warlock/Archivist and Warrior/Vanguard in the manual pass. Mage and Assassin have data/art but remain `is_playable = false`.

Impact:

- The game currently presents fewer roles than the designed four-role system.
- The new Mage/Assassin art and data are not actually visible in normal character selection.

Recommended fix:

- Either promote Mage/Assassin to playable when their mechanics are ready, or visibly mark them as locked/coming soon with polished cards.
- Localize class names and trait text.

## Medium Priority Findings

### P1 - Chinese Mode Still Has English Text

Observed in manual pass:

- Character select title mixes `Warrior — 先锋`.
- Trait text remains English: `Durable weapon fighter... Keywords...`.
- Combat top-left title remains `Dust Scribe`.
- Combat log remains English: `Dust Scribe rises from the archive floor.`
- Intent text remains English: `Attack 6`.

Impact:

- Chinese localization feels partial.
- This directly reduces polish and makes the game feel like a prototype.

Recommended fix:

- Localize `CharacterData.display_name`, `class_display_name`, `class_trait_summary`, `class_keywords`.
- Localize enemy names in combat title/log, not only the enemy label.
- Localize intent text and combat log fragments.

### P1 - Event Choice Screens Always Use ScrollContainer

Every event choice screen uses a `ScrollContainer`; the script flagged it for all event nodes. Some events look fine now, but the visible-scrollbar risk remains, and earlier user feedback already called scrollbars in narrative UI “很奇怪”.

Impact:

- Story events should feel like authored scenes, not forms.
- Scrollbars make the presentation feel utilitarian.

Recommended fix:

- Use fixed-height choice rows and only enable scrolling on small viewports.
- Remove scrollbars for three-choice event screens.

### P1 - Some Event Choice Buttons Inflate to Extreme Height

`ev_revision_desk` and `ev_dust_oracle` produced choice buttons around `520px` high during automated layout inspection.

Impact:

- These events are at high risk of visual breakage in real play.
- The player may see only one or two choices at a time.

Recommended fix:

- Same as campfire: build custom choice row controls instead of multiline buttons.

### P1 - Event Choices Can Fail Silently

Examples:

- Clean Margin: if the player lacks gold or target cards, pressing a paid option just advances.
- Upgrade/remove/transform options may open a picker or immediately leave depending on hidden eligibility.

Impact:

- The player can click a choice and feel nothing happened.
- Risk/reward choices become unclear.

Recommended fix:

- Disable unavailable choices with visible reason text.
- If a choice is unavailable, keep the player on the event and show a short toast.

### P1 - Transform Lantern Reward Timing Does Not Match Text

`_event_transform_card_for_gold()` currently subtracts the price and immediately adds 20 gold, while the choice text says “gain 20 gold next combat.”

Impact:

- Mechanics and text disagree.
- This erodes trust in event choices.

Recommended fix:

- Either update the text to “refund 20 gold now” or implement a delayed next-combat reward flag.

### P1 - Loose Page Speak Has a No-Feedback Branch

`_event_loose_page_speak()` has a 25% path that adds 0 gold and advances with no explicit result.

Impact:

- Player may feel the click did nothing.

Recommended fix:

- Show a result line/toast for both outcomes, or remove the empty branch.

### P1 - Combat Readability Still Needs Polish

Manual pass shows:

- Card art is visible and improved, but card rules text is still too small during hand play.
- Combat log is tiny and partially lost against the background.
- Enemy intent is readable but still plain text-heavy.

Impact:

- The core card-battle loop is playable, but not yet premium-feeling.

Recommended fix:

- Increase card text readable area or hide rules on hand cards and rely on hover inspector.
- Make combat log a clearer toast/battle feed.
- Localize/log enemy action phrases.

## Lower Priority Findings

### P2 - Anchor Warnings Indicate Layout Fragility

`runtime_scene_check` and acceptance traversal both produced repeated Godot warnings:

```text
Nodes with non-equal opposite anchors will have their size overridden after _ready().
```

Impact:

- Not an immediate crash.
- Strong signal that some UI sizing relies on fragile order-of-operations.

Recommended fix:

- Audit controls using fixed offsets plus non-equal anchors.
- Prefer containers and explicit custom minimum sizes.

### P2 - Campfire Copy Typo

`Toke: remove a card` likely should be `Stoke`, `Burn`, or another intentional term. If it is intentional, it still reads odd in UI.

### P2 - Main Menu Save State Copy Could Be Clearer

The main menu shows existing save state clearly, but “新游戏” overwrites current run. It has a hint line, not a confirmation. For a sellable game, destructive new-run behavior should confirm.

## Screenshots

Manual combat screenshot:

`tower/acceptance_screenshots/combat_card_hand.png`

## Pass/Fail Summary

Technical traversal: pass.

Commercial UX acceptance: fail for now.

The game can load and all story nodes can be traversed, but the current build still has several player-visible issues that would hurt first-session trust:

- campfire/shop/summary overflow;
- partial Chinese localization;
- event choice scrollbars and oversized buttons;
- silent event failure paths;
- incomplete four-character presentation;
- combat readability still below sellable-card-game expectations.
