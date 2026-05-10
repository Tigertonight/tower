# First Character Design

Project codename: **Tower**

Status: Draft

## Character Overview

Name: **Vanguard Archivist**

Working fantasy:

A disciplined explorer trained to survive forbidden archives. They use guard forms, measured strikes, and oath-bound techniques to endure hostile memories and animated guardians.

Gameplay role:

- Beginner-friendly.
- Balanced offense and defense.
- Tests all core systems without relying on advanced mechanics.

## Core Mechanics

### Guard

Guard represents disciplined defensive posture.

Initial MVP rule:

- Some cards gain bonus effects if the player has block.
- Some cards grant Guard as a status.
- Guard can increase block gain or convert defense into damage.

MVP implementation can start simple:

```text
Guard: the next attack this turn deals +2 damage if the player has block.
```

This can later evolve into a richer character mechanic.

### Momentum

Momentum represents forward pressure.

Initial MVP rule:

```text
Momentum: temporary strength that lasts until end of turn.
```

### Retaliate

Retaliate rewards defense before offense.

Initial MVP rule:

```text
If the player gained block this turn, this card gains a bonus.
```

## Starting Stats

| Stat | Value |
| --- | --- |
| Max HP | 76 |
| Starting HP | 76 |
| Starting gold | 99 |
| Base energy | 3 |
| Base draw | 5 |
| Potion slots | 3 |

## Starting Relic

Name: **Sealed Badge**

Effect:

```text
At the end of combat, heal 5 HP.
```

Design reason:

- Simple sustain helps early testing.
- Easy to implement.
- Clearly validates relic trigger flow.

## Starting Deck

| Card | Count |
| --- | --- |
| Strike Form | 5 |
| Guard Form | 4 |
| Archive Bash | 1 |

Total: 10 cards.

## Starter Cards

### Strike Form

Type: Attack  
Cost: 1  
Rarity: Basic  
Effect:

```text
Deal 6 damage.
```

Upgrade:

```text
Deal 9 damage.
```

### Guard Form

Type: Skill  
Cost: 1  
Rarity: Basic  
Effect:

```text
Gain 5 block.
```

Upgrade:

```text
Gain 8 block.
```

### Archive Bash

Type: Attack  
Cost: 2  
Rarity: Basic  
Effect:

```text
Deal 8 damage. Apply 2 Vulnerable.
```

Upgrade:

```text
Deal 10 damage. Apply 3 Vulnerable.
```

## MVP Card Pool

Target: 30 cards.

### Common Cards

| Name | Type | Cost | Effect |
| --- | --- | --- | --- |
| Measured Cut | Attack | 1 | Deal 7 damage. If you have block, deal 9 instead. |
| Shield Tap | Attack | 1 | Deal 5 damage. Gain 3 block. |
| Forward Step | Skill | 0 | Gain 3 block. Gain 1 Momentum. |
| Brace | Skill | 1 | Gain 8 block. |
| Quick Read | Skill | 1 | Draw 2 cards. |
| Heavy Page | Attack | 2 | Deal 14 damage. |
| Ink Mark | Skill | 1 | Apply 2 Vulnerable. |
| Defensive Note | Skill | 1 | Gain 6 block. Draw 1 card. |
| Clean Strike | Attack | 1 | Deal 8 damage. |
| Hold Line | Skill | 2 | Gain 14 block. |

### Uncommon Cards

| Name | Type | Cost | Effect |
| --- | --- | --- | --- |
| Counterseal | Skill | 1 | Gain 7 block. Next attack this turn deals +4 damage. |
| Oath Pressure | Attack | 1 | Deal 4 damage twice. |
| Tactical Memory | Skill | 0 | Draw 1 card. If you have block, gain 1 energy. Exhaust. |
| Guarded Advance | Attack | 2 | Deal 10 damage. Gain block equal to unblocked damage dealt. |
| Archive Tempo | Power | 1 | The first time each turn you gain block, gain 1 Momentum. |
| Break Rhythm | Skill | 1 | Apply 2 Weak. Draw 1 card. |
| Steel Margin | Power | 2 | At the start of your turn, gain 3 block. |
| Revision | Skill | 1 | Discard 1 card. Draw 2 cards. |
| Focused Blow | Attack | 2 | Deal 12 damage. Deal +4 for each Momentum. |
| Burnt Clause | Attack | 1 | Deal 9 damage. Exhaust a random card in your hand. |

### Rare Cards

| Name | Type | Cost | Effect |
| --- | --- | --- | --- |
| Final Argument | Attack | 3 | Deal 24 damage. If you have block, apply 3 Vulnerable. |
| Unbroken Form | Power | 2 | Block is reduced by half instead of fully removed at end of turn. |
| Perfect Rebuttal | Skill | 2 | Gain 12 block. Deal damage to all enemies equal to your block. Exhaust. |
| Archive Surge | Skill | 1 | Gain 2 energy. Draw 2 cards. Exhaust. |
| Law of Return | Power | 2 | Whenever you lose block from enemy damage, deal 3 damage to the attacker. |

### Status and Curse Placeholders

| Name | Type | Effect |
| --- | --- | --- |
| Burned Page | Status | Unplayable. At end of turn, take 2 damage. Exhaust. |
| Debt Mark | Curse | Unplayable. When drawn, lose 1 HP. |

## First Relic Set

| Name | Rarity | Effect |
| --- | --- | --- |
| Sealed Badge | Starter | At end of combat, heal 5 HP. |
| Brass Bookmark | Common | At combat start, draw 1 extra card. |
| Wax Seal | Common | The first time each combat you gain block, gain 2 more. |
| Broken Lens | Common | Attacks against Vulnerable enemies deal +2 damage. |
| Old Canteen | Common | When you enter a campfire, heal 4 HP. |
| Iron Index | Uncommon | Every 3rd attack you play deals +6 damage. |
| Red String | Uncommon | At turn start, if you have no block, gain 3 block. |
| Contract Nail | Uncommon | Whenever you exhaust a card, gain 2 block. |
| Locked Compass | Rare | At the start of combat, apply 1 Weak to all enemies. |
| Tower Key | Boss | Gain 1 energy each turn. You can no longer use potions. |

## First Potion Set

| Name | Effect |
| --- | --- |
| Red Ink Vial | Deal 12 damage to an enemy. |
| Guard Draught | Gain 12 block. |
| Clarity Drop | Draw 3 cards. |
| Spark Tonic | Gain 2 energy this turn. |
| Solvent | Remove all debuffs from yourself. |

## Notes for Implementation

- Start with the three basic cards and three common cards.
- Implement all 30 cards only after the card effect pipeline is stable.
- Use placeholder names freely during development, but run them through the originality checklist before public release.
