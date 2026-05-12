# Events, Shop, and Campfire Design

Project codename: **Tower**

Status: Draft v1

This document specifies the non-combat content of MVP: 5 events with full text and outcomes, the shop pricing model and pool rules, and the campfire action set. All flavor follows the tone established in `24_world_narrative.md`.

## Shared Conventions

- All events are run through `RunManager.event_rng` for deterministic resume.
- Player can never lose to an event directly (HP loss is capped to leave ≥ 1 HP).
- Outcomes that change deck/relics/gold must call back through `RunManager` so the run save sees them.
- Every event lists an `id`, an `act_filter` (which floor band can spawn it), and a `weight`.

## Event Pool — MVP

| ID | Name | Floors | Pattern | Weight |
| --- | --- | --- | --- | --- |
| `ev_quiet_stack` | The Quiet Stack | 1–4 | Pay HP for relic | 3 |
| `ev_clean_margin` | A Clean Margin | 2–6 | Pay gold to remove a card | 3 |
| `ev_red_string` | The Red String | 3–7 | Curse for power | 2 |
| `ev_revision_desk` | The Revision Desk | 2–6 | Upgrade at a cost | 3 |
| `ev_loose_page` | A Loose Page | 1–6 | Fight or flee | 2 |

Designer rule: events must total ≥ 12 weight points across MVP so the same event does not repeat in a single run; if all valid events have been seen, the generator falls back to a card reward instead of repeating.

### `ev_quiet_stack` — The Quiet Stack

Floors: 1–4

> A reading desk has been left as if mid-thought. A small object rests under the lamp.
> Picking it up will weigh you. Leaving it feels worse.

Choices:

1. **Take the object.** Lose 8 HP. Gain a random Common relic.
2. **Read the open page first.** Lose 4 HP. Gain a random Common relic. The relic is shown before you decide whether to commit.
3. **Leave the desk.** No effect.

Notes: choice 2 is the "skill check" version; reveals reward but takes some HP for the privilege.

### `ev_clean_margin` — A Clean Margin

Floors: 2–6

> Someone has left an eraser on the table. It only works on yourself.

Choices:

1. **Pay 75 gold.** Remove 1 card from your deck.
2. **Pay 30 gold.** Transform 1 card in your deck into a random card of the same type.
3. **Walk past.** No effect.

Notes: cap card removal so a deck cannot be reduced below 8 cards via this event.

### `ev_red_string` — The Red String

Floors: 3–7

> A red string has been tied around your finger. You did not tie it.
> If you accept the contract, the tower will deliver. So will the cost.

Choices:

1. **Accept the contract.** Add a `Debt Mark` curse to your deck. Gain a random Uncommon relic.
2. **Cut the string.** Lose 5 HP.
3. **Leave it.** Take 2 damage now. The string returns next event.

Notes: the "string returns" outcome should set a flag on `RunManager` so the next event roll forces this one again.

### `ev_revision_desk` — The Revision Desk

Floors: 2–6

> The desk has been waiting for you. There is a pen, a stamp, and a price.

Choices:

1. **Pay 50 gold.** Upgrade 1 card in your deck.
2. **Bleed for it.** Lose 6 HP. Upgrade 1 card in your deck.
3. **Leave the desk.** No effect.

Notes: a card already upgraded is not eligible (consistent with campfire upgrade rules).

### `ev_loose_page` — A Loose Page

Floors: 1–6

> A page peels itself from a binding and stands up. It does not look pleased.

Choices:

1. **Fight.** Triggers a single-enemy combat against `e_loose_folio`. On victory, gain 25 gold + a card reward (3 options + skip).
2. **Flee.** Take 4 damage. No reward.
3. **Speak to it.** 25% chance: it stamps you (apply 1 Weak for next combat). 75% chance: it hands you 30 gold and walks away.

Notes: the random branch is the only RNG inside an event; uses `event_rng` so resume is deterministic.

## Event Authoring Schema (proposed)

```text
EventData
  id: String
  display_name: String
  body_text: String
  floors_min: int
  floors_max: int
  weight: int
  choices: Array<EventChoiceData>
  unique: bool      # if true, never repeats per run

EventChoiceData
  label: String
  preview_text: String
  cost: Array<Effect>
  outcomes: Array<EventOutcomeBranch>

EventOutcomeBranch
  weight: int       # for randomized branches; default 1
  effects: Array<Effect>
  follow_up_text: String
```

## Shop

### Layout

The MVP shop offers a fixed structure: 3 cards, 2 relics, 2 potions, 1 card-removal slot.

```text
[3 cards]   [2 relics]   [2 potions]
                   [Remove a card]
```

### Pricing Model

Base prices (gold) per slot:

| Slot type | Common | Uncommon | Rare |
| --- | --- | --- | --- |
| Card | 50 | 75 | 150 |
| Relic | 150 | 250 | 300 |
| Potion | 50 | 70 | 100 |

Per-shop variance: roll a price modifier in `[0.9, 1.1]` per item, rounded to nearest 5 gold. Removal price = 75 gold for the first removal in a run, +25 gold per subsequent removal. Cap at 175 gold.

### Shop Pool Rules

- Cards offered must include at least 1 Attack and 1 Skill.
- Cards offered must belong to the current character (Vanguard Archivist for MVP).
- Relics offered are drawn from the Common/Uncommon pool, with at most 1 Rare per shop and only on floor ≥ 5.
- A relic already owned cannot be re-offered.
- A potion already shown in the previous shop has 50% reroll probability.

### Shop Schema (proposed)

```text
ShopOffer
  cards: Array<{card_id, price}>
  relics: Array<{relic_id, price}>
  potions: Array<{potion_id, price}>
  remove_price: int
  rerolled_for_run: bool
```

## Campfire

The campfire is a recovery node. MVP supports two actions; deferred actions are noted but not implemented.

### MVP Actions

| Action | Effect | Restrictions |
| --- | --- | --- |
| `rest` | Heal 30% of max HP, rounded down. | Can only be picked once per visit. |
| `upgrade` | Upgrade 1 non-upgraded card in the deck. | Hidden if no eligible card. |

### Deferred Actions (not in MVP)

- `dig` — spend 25 gold, gain a random non-relic reward.
- `meditate` — remove a curse or status card.
- `recall` — spend a relic to gain 2 random cards.

### Campfire Schema (proposed)

```text
CampfireOptions
  rest_heal_pct: float       # default 0.30
  upgrade_eligible: bool
  visited: bool              # set true after action chosen
```

## Authoring Checklist

For each new event:

- [ ] Tone matches `24_world_narrative.md`.
- [ ] Cleared against `06_legal_originality_checklist.md`.
- [ ] All choices have a defined outcome (no orphan branches).
- [ ] Worst-case HP loss leaves ≥ 1 HP for the player.
- [ ] Triggers `RunManager` save after resolution.

For shop changes:

- [ ] Pool obeys "at least 1 attack + 1 skill" rule.
- [ ] Prices regenerate from base × modifier; not hardcoded per item.
- [ ] Removal price increases per use.

For campfire:

- [ ] Rest is always available unless mechanically disabled by relic.
- [ ] Upgrade option hidden when ineligible (cleaner UI).

## Open Questions

- Should the boss-floor preceding campfire offer a stronger heal (e.g. 50%)?
- Should `ev_red_string` curse stay in the deck or be exhaustable on use?
- Should `ev_loose_page` "speak to it" branch use a separate `social_rng` for repeatable feel?
