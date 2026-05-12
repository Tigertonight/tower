# World and Narrative Design

Project codename: **Tower**
Working title: **Living Archive**

Status: Draft v1

This document defines the original world, factions, player motivation, narrative arc, and writing tone for the MVP. It is the source of truth for any flavor text, event copy, card name themes, enemy backstories, and boss reveals. All names and concepts here are original to the project; nothing should be ported from existing IPs.

## One-Sentence Pitch

A disgraced field archivist climbs the **Living Archive**, a tower where every act of recording has gained a body, to seal the document that erased their name.

## Premise

Civilizations across the inner provinces sealed their forbidden knowledge inside a single climbing structure called the **Living Archive**. For generations the tower obediently held its records. After an unrecorded event the archive began to *enact* what it stored: oaths started enforcing themselves, debts grew claws, cancelled contracts stalked the corridors, and the binding ink began to think.

The player is a **Vanguard Archivist** — a member of the field branch sent in when something inside the tower escapes. They wake at the gate with a missing name, a sealed badge, and a vague order to climb until they find the page that erased them.

## Themes

- **Memory has weight.** What is written down can outlive the person.
- **Discipline beats power.** Survivors of the archive are measured, not heroic.
- **Every page is a contract.** Even helpful pages cost something to read.
- **You are also a record.** The player is partially erased; the climb is also a recovery.

These themes drive card naming (`Oath Pressure`, `Burnt Clause`, `Revision`, `Final Argument`), relic naming (`Sealed Badge`, `Contract Nail`, `Red String`), and event tone.

## Setting Layout

The tower has many floors but the MVP only covers the **lower archive** — roughly the first act.

- **Outer Gate** — entry, intro, no combat.
- **Reading Halls** — early floors, scribes and bound paper, light combats.
- **Stamp Wing** — wax, seals, contracts; first elite zone.
- **Burnt Stack** — destroyed records that refuse deletion; fire/exhaust theme.
- **Curator's Threshold** — boss floor: the librarian who stamped the player out.

Beyond the MVP (out of scope but reserved):

- **Auditor's Spire** — Act 2 antagonist faction.
- **Index Without Pages** — endgame floor.
- **Margin** — secret content area.

## Factions

| Faction | Role | Visual cue | Notes |
| --- | --- | --- | --- |
| Field Branch | The player's order. Quiet, practical, badge-and-coat. | Brass badge, dark coat, ink-stained gloves. | Source of starter relics. |
| Bound Scribes | Common enemies; ink-and-paper bodies. | Floating folio, gloved hands, no face. | Use Weak/Vulnerable theme. |
| Wax Guard | Elite enforcers, animated by seal stamps. | Red wax masks, heavy stamps. | Block-heavy, retaliation theme. |
| The Curators | Bosses; the original administrators of the tower. | Robed silhouettes, missing eyes, ledger-chains. | Each curator owns a wing. |
| The Margin | Erased entries. Player is one of them. | Translucent, partially missing limbs. | Player faction; appears in events. |

Factions exist so future content (Act 2, new characters) can extend without rewriting the world.

## Player Motivation

- **Surface motive:** complete the field assignment and survive the climb.
- **Personal motive:** find and reclaim the entry that erased the player's name.
- **Long-term motive (post-MVP):** decide whether to seal the archive, free it, or take the curator's seat.

The MVP only resolves the surface motive. Personal motive is teased through events but not resolved until later acts.

## Narrative Beats (MVP Act 1)

1. **Gate prologue** — short text screen. The player is briefed by an absent superior. Player is given the Sealed Badge and told only "climb until something writes back."
2. **Reading Halls** — first combats. Bound Scribes treat the player as a misfiled page.
3. **First event** — `The Quiet Stack`: a calm room offers a trade (lose HP, gain a relic). Establishes the cost-of-knowledge tone.
4. **Stamp Wing elite** — first wax-sealed enforcer; teaches retaliation/block punishment.
5. **Mid-act campfire** — the badge whispers the player's first forgotten word. Worldbuilding via overheard memory.
6. **Burnt Stack** — fast, dangerous floors. Burned Page status appears here.
7. **Curator's Threshold** — boss intro: the curator opens a ledger, finds the player's entry, and stamps it shut. Combat begins.
8. **Boss defeat** — the player retrieves a torn page with a single legible word: their first name. Run ends. (Later acts continue from here.)

## Tone of Voice

Writing tone for events, card flavor, and dialogue:

- **Quiet, dry, precise.** Avoid melodrama and exclamation marks.
- **Short sentences.** Two-line maximum for card flavor, three-line maximum for event prompts.
- **Bureaucratic vocabulary used eerily.** Words like *clause*, *margin*, *ledger*, *amend*, *revoke*, *file*, *index*, *errata*.
- **No modern slang.** No real-world dates, brands, or place names.
- **Speak around horror, not at it.** Imply rather than describe.
- **Respect the reader.** No on-screen tutorial-explainer voice; rules go in mechanical text, not flavor text.

### Voice examples

Acceptable card flavor:

> "She sealed the wound the way she sealed letters." — Wax Seal
> "Read the first line aloud. Then read it again, quieter." — Quick Read

Avoid:

> "BAM! Crush them with the power of YOUR DECK!"  ✗ — wrong tone
> "Use this card when fighting goblin warriors."  ✗ — generic fantasy
> "Slay the monsters of the spire!"  ✗ — references existing IP

## Naming Conventions

- **Cards** — verb-object or short noun phrase. Two-word maximum where possible. Examples: `Strike Form`, `Oath Pressure`, `Final Argument`.
- **Relics** — concrete objects with adjective. Examples: `Sealed Badge`, `Brass Bookmark`, `Red String`.
- **Enemies** — role + material. Examples: `Dust Scribe`, `Wax Sentinel`, `Margin Hound`.
- **Bosses** — title-case full names with role. Examples: `Sealed Curator`, `The First Stamp`.
- **Status effects** — single word, lowercase ID, capitalized in UI. `vulnerable`, `weak`, `frail`, `momentum`, `guard`.

## Originality Filter

Every name, line of writing, enemy concept, and boss reveal must clear `06_legal_originality_checklist.md` before being merged. In particular, this project does **not** use:

- "Spire", "Slay", "Ironclad", "Silent", "Watcher", "Defect", or any direct token from existing roguelike deckbuilders.
- Card names that are also card names in published deckbuilders.
- Relic concepts that are 1:1 mechanical clones of named items in published deckbuilders.

## Open Narrative Questions

- Is the Vanguard Archivist's missing name revealed at end of Act 1, or saved for Act 2?
- Do curators speak, or only stamp/edit the player's stat sheet?
- Do failed runs leave a marginalia trail readable in the next run? (Soft meta-progression hook.)
