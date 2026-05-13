# 35 New Content Art Asset Manifest

Date: 2026-05-13

## Scope

This pass covers the art resources introduced by the expanded character, card-pool, relic, enemy, and class-event work.

Generation mode: Codex built-in `imagegen` skill.

## Output Summary

| Category | Count | Output Pattern |
| --- | ---: | --- |
| Card art | 130 | `tower_game/art/generated/cards/<card_id>.png` |
| Relic icons | 14 | `tower_game/art/generated/icons/relic_<relic_id>.png` |
| Enemy sprites | 15 | `tower_game/art/generated/sprites/<enemy_slug>.png` |
| Character sprites | 3 | `tower_game/art/generated/sprites/<class_slug>.png` |
| Event backgrounds | 9 | `tower_game/art/generated/backgrounds/event_<event_id>.png` |
| Source sheets | 14 | `tower_game/art/generated/sources/new_content_20260513/` |

## Cards

Generated card art for:

`afterimage_file`, `archive_supernova`, `ash_equation`, `astral_rewrite`, `axiom_engine`, `backstep`, `badge_check`, `black_boot`, `black_ledger`, `blackboard_sun`, `blackout_technique`, `blind_corner`, `blue_clause`, `borrowed_star`, `bright_syllable`, `burning_proof`, `catalog_pull`, `circle_ward`, `citation_storm`, `clause_armor`, `comet_clause`, `core_overload`, `core_spark`, `counterspell_note`, `cross_reference`, `curse_burn`, `curse_doubt`, `curse_regret`, `curse_wound`, `cut_the_witness`, `death_by_index`, `double_entry`, `dripping_seal`, `erase_the_room`, `event_horizon_note`, `execution_mark`, `fade_from_record`, `file_needle`, `filing_slam`, `final_angle`, `final_lantern`, `final_rebuttal`, `forced_revision`, `frost_notation`, `garrote_clause`, `glass_ray`, `grand_conjunction`, `guarded_cut`, `held_note`, `hidden_hand`, `hidden_route`, `hundred_cuts`, `hush`, `index_mark`, `infinite_margin`, `ink_blot`, `ink_wash`, `inkless_theorem`, `knife_ladder`, `knife_rain`, `lampguard`, `last_shadow`, `library_ascension`, `library_current`, `line_hold`, `living_index`, `low_profile`, `mana_audit`, `margin_slash`, `marginalia`, `marked_pin`, `midnight_suture`, `minor_formula`, `mirror_footnote`, `misfile`, `needle_guard`, `needle_storm`, `oath_engine`, `oath_jab`, `orbital_lock`, `page_of_stars`, `palm_blade`, `paper_shield`, `perfect_alibi`, `perfect_diagram`, `pin_cushion`, `pocket_silence`, `poisoned_archive`, `quick_calculation`, `quiet_puncture`, `quiet_stamp`, `quill_strike`, `red_star_formula`, `redacted_future`, `redacted_path`, `refraction`, `return_stamp`, `sealed_counter`, `sealed_margin`, `sealed_prism`, `sealed_singularity`, `secret_exit`, `shadow_inventory`, `shadow_tax`, `side_cut`, `silent_contract`, `slipstream`, `smoke_step`, `spark_copy`, `spilled_inkwell`, `spiral_binding`, `staining_hand`, `starfall_index`, `static_margin`, `status_dazed`, `status_slimed`, `status_void`, `steady_core`, `thesis_flame`, `throwing_label`, `tiny_orbit`, `toxin_thread`, `two_knives`, `unseen_payoff`, `vanishing_act`, `venom_note`, `volatile_glyph`, `warded_bolt`, `wet_signature`, `white_index`.

## Relics

Generated icons for:

`adjudicator_seal_warlock`, `binding_thread_warrior`, `black_contract`, `black_needle`, `blood_wax`, `blue_core_fragment`, `core_lantern`, `hidden_blade`, `inkstone_warlock`, `inkwells_grace`, `margin_cloak`, `orrery_pin`, `silent_boot`, `spellglass`.

## Characters

Generated and wired:

| Character | Sprite |
| --- | --- |
| Mage | `res://art/generated/sprites/mage.png` |
| Assassin | `res://art/generated/sprites/assassin.png` |
| Warlock | `res://art/generated/sprites/warlock.png` |

## Enemies

Generated and wired:

| Enemy | Sprite |
| --- | --- |
| Ink Tyrant | `res://art/generated/sprites/ink_tyrant.png` |
| Last Catalog | `res://art/generated/sprites/last_catalog.png` |
| Mirror Tribunal | `res://art/generated/sprites/mirror_tribunal.png` |
| Clause Mender | `res://art/generated/sprites/clause_mender.png` |
| Index Rat | `res://art/generated/sprites/index_rat.png` |
| Ink Moth | `res://art/generated/sprites/ink_moth.png` |
| Keyhole Mimic | `res://art/generated/sprites/keyhole_mimic.png` |
| Ledger Sentry | `res://art/generated/sprites/ledger_sentry.png` |
| Null Page | `res://art/generated/sprites/null_page.png` |
| Redaction Monk | `res://art/generated/sprites/redaction_monk.png` |
| Staple Swarm | `res://art/generated/sprites/staple_swarm.png` |
| Dust Chorus | `res://art/generated/sprites/dust_chorus.png` |
| Null Librarian | `res://art/generated/sprites/null_librarian.png` |
| Penitent Index | `res://art/generated/sprites/penitent_index.png` |
| Redaction Engine | `res://art/generated/sprites/redaction_engine.png` |

## Events

Generated and wired:

| Event | Background |
| --- | --- |
| Transform Lantern | `res://art/generated/backgrounds/event_transform_lantern.png` |
| Ink Well | `res://art/generated/backgrounds/event_ink_well.png` |
| Dust Oracle | `res://art/generated/backgrounds/event_dust_oracle.png` |
| Weighing Scales | `res://art/generated/backgrounds/event_weighing_scales.png` |
| Burned Archive | `res://art/generated/backgrounds/event_burned_archive.png` |
| Broken Standard | `res://art/generated/backgrounds/event_broken_standard.png` |
| Unpaid Contract | `res://art/generated/backgrounds/event_unpaid_contract.png` |
| Core Orrery | `res://art/generated/backgrounds/event_core_orrery.png` |
| Silent Margin | `res://art/generated/backgrounds/event_silent_margin.png` |

## Verification

- Missing referenced art files: `0`
- Card output size: `512x384`
- Relic output size: `128x128`
- Character/enemy sprite output size: `512x768`, alpha-enabled
- Event background output size: `1024x576`
