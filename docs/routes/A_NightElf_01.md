# A_NightElf_01 — Shadowglen

Generated on 2026-11-07 from QuestieDB commit `80866960788084ae1592abf66a08f0d306458a95` by `tools/routebuilder/build.lua`. Simulated race: NightElf.

| Item | Value |
|---|---|
| Level band | 1-6 |
| Simulated level | 1.00 -> 6.53 |
| Time | 57 min |
| XP gained | 9496 |
| XP/h | 10037 |
| Steps | 44 |
| Quests turned in | 17 |
| Hubs | 2 |
| Median ratio (XP/s) | 2.50 |
| Hearthstone | no new bind; 0 return(s) planned, 0 bundle(s) |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 456 | The Balance of Nature | 2 | 170 | 2 |
| 2 | 458 | The Woodland Protector | 1 | 40 | 2 |
| 3 | 4495 | A Good Friend | 4 | 270 | 4 |
| 4 | 916 | Webwood Venom | 4 | 355 | 4 |
| 5 | 97236 | Fang of Githyiss | 5 | 225 est. | 4 |
| 6 | 3519 | A Friend in Need | 4 | 90 | 4 |
| 7 | 917 | Webwood Egg | 5 | 560 | 5 |
| 8 | 459 | The Woodland Protector | 3 | 250 | 5 |
| 9 | 97977 | Nature's Call | 3 | 250 est. | 5 |
| 10 | 457 | The Balance of Nature | 3 | 250 | 6 |
| 11 | 3521 | Iverron's Antidote | 4 | 355 | 6 |
| 12 | 920 | Tenaron's Summons | 5 | 45 | 6 |
| 13 | 3522 | Iverron's Antidote | 4 | 445 | 6 |
| 14 | 921 | Crown of the Earth | 5 | 335 | 6 |
| 15 | 96630 | The Adventurer | 6 | 135 est. | 6 |
| 16 | 2159 | Dolanaar Delivery | 5 | 110 | 6 |
| 17 | 928 | Crown of the Earth | 5 | 225 | 6 |

## Dropped quests

| Quest | Name | Lvl | Reason |
|---|---|---|---|
| 3116 | Simple Sigil | 1 | class quest (ClassQuestData.lua) |
| 3117 | Etched Sigil | 1 | class quest (ClassQuestData.lua) |
| 3118 | Encrypted Sigil | 1 | class quest (ClassQuestData.lua) |
| 3119 | Hallowed Sigil | 1 | class quest (ClassQuestData.lua) |
| 3120 | Verdant Sigil | 1 | class quest (ClassQuestData.lua) |
| 5622 | In Favor of Elune | 4 | class quest (ClassQuestData.lua) |
| 6072 | The Hunter's Path | 10 | class quest (ClassQuestData.lua) |
| 97979 | The Goddess Provides | 1 | low ratio |

## Candidate ratios

Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;
marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are
below 0.35 × the median ratio, or when an objective is more than 900 yd from every hub.

| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |
|---|---|---|---|---|---|---|---|---|---|---|
| 456 | The Balance of Nature | 2 | 720 | 0 | 295 | 295 | 2.23 | 2.29 | 1 |  |
| 457 | The Balance of Nature | 3 | 978 | 0 | 405 | 382 | 2.41 | 2.56 | 1 |  |
| 458 | The Woodland Protector | 1 | 40 | 0 | 53 | 27 | 2.11 | 2.86 | 0 |  |
| 459 | The Woodland Protector | 3 | 926 | 0 | 337 | 289 | 2.75 | 3.19 | 1 |  |
| 916 | Webwood Venom | 4 | 1950 | 0 | 744 | 626 | 2.64 | 3.70 | 1 |  |
| 917 | Webwood Egg | 5 | 560 | 0 | 214 | 78 | 2.71 | 7.58 | 1 |  |
| 920 | Tenaron's Summons | 5 | 45 | 0 | 46 | 29 | 2.84 | 8.14 | 0 |  |
| 921 | Crown of the Earth | 5 | 335 | 0 | 106 | 53 | 3.29 | 11.83 | 1 |  |
| 928 | Crown of the Earth | 5 | 482 | 257 | 133 | 15 | 3.61 | 30.36 | 0 |  |
| 2159 | Dolanaar Delivery | 5 | 277 | 167 | 112 | 26 | 2.47 | 10.55 | 0 |  |
| 3519 | A Friend in Need | 4 | 90 | 0 | 87 | 10 | 2.39 | 3.15 | 0 |  |
| 3521 | Iverron's Antidote | 4 | 2681 | 0 | 1118 | 971 | 2.54 | 3.06 | 3 |  |
| 3522 | Iverron's Antidote | 4 | 445 | 0 | 87 | 10 | 5.06 | 44.50 | 0 |  |
| 4495 | A Good Friend | 4 | 270 | 0 | 87 | 10 | 2.47 | 3.63 | 0 |  |
| 96630 | The Adventurer | 6 | 330 | 195 | 106 | 16 | 3.10 | 20.08 | 0 |  |
| 97236 | Fang of Githyiss | 5 | 525 | 0 | 228 | 123 | 2.29 | 4.24 | 0 |  |
| 97977 | Nature's Call | 3 | 250 | 0 | 169 | 102 | 1.48 | 2.44 | 1 |  |
| 97979 | The Goddess Provides | 1 | 40 | 0 | 88 | 88 | 0.45 | 0.45 | 1 | low ratio |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | A | 456 | The Balance of Nature | 1438 | 58.7, 44.3 | 1 |  |
| 2 | O | 456 | The Balance of Nature | 1438 | 61.7, 43.8 | 154 |  |
| 3 | A | 4495 | A Good Friend | 1438 | 60.9, 42.0 | 74 |  |
| 4 | A | 458 | The Woodland Protector | 1438 | 59.9, 42.5 | 52 |  |
| 5 | T | 456 | The Balance of Nature | 1438 | 58.7, 44.3 | 87 |  |
| 6 | A | 457 | The Balance of Nature | 1438 | 58.7, 44.3 | 0 |  |
| 7 | T | 458 | The Woodland Protector | 1438 | 57.8, 45.2 | 54 |  |
| 8 | A | 97977 | Nature's Call | 1438 | 57.8, 45.2 | 0 |  |
| 9 | A | 459 | The Woodland Protector | 1438 | 57.8, 45.2 | 0 |  |
| 10 | O | 459 | The Woodland Protector | 1438 | 55.4, 45.1 | 121 |  |
| 11 | A | 916 | Webwood Venom | 1438 | 57.8, 41.6 | 168 |  |
| 12 | O | 916 | Webwood Venom | 1438 | 56.6, 27.5 | 482 |  |
| 13 | A | 97236 | Fang of Githyiss | 1438 | 56.6, 26.3 | 42 |  |
| 14 | T | 4495 | A Good Friend | 1438 | 54.6, 33.0 | 249 |  |
| 15 | A | 3519 | A Friend in Need | 1438 | 54.6, 33.0 | 0 |  |
| 16 | O | 97977 | Nature's Call | 1438 | 54.9, 38.8 | 199 |  |
| 17 | T | 916 | Webwood Venom | 1438 | 57.8, 41.6 | 177 |  |
| 18 | A | 917 | Webwood Egg | 1438 | 57.8, 41.6 | 0 |  |
| 19 | T | 97236 | Fang of Githyiss | 1438 | 57.8, 41.6 | 0 |  |
| 20 | T | 3519 | A Friend in Need | 1438 | 60.9, 42.0 | 157 |  |
| 21 | A | 3521 | Iverron's Antidote | 1438 | 60.9, 42.0 | 0 |  |
| 22 | O | 457 | The Balance of Nature | 1438 | 62.2, 37.2 | 176 |  |
| 23 | O | 917 | Webwood Egg | 1438 | 56.8, 26.5 | 454 |  |
| 24 | O | 3521 | Iverron's Antidote | 1438 | 56.9, 31.1 | 156 |  |
| 25 | O | 3521 | Iverron's Antidote | 1438 | 57.6, 38.3 | 247 |  |
| 26 | T | 917 | Webwood Egg | 1438 | 57.8, 41.6 | 113 |  |
| 27 | A | 920 | Tenaron's Summons | 1438 | 57.8, 41.6 | 0 |  |
| 28 | O | 3521 | Iverron's Antidote | 1438 | 55.5, 44.6 | 153 | near #10 (went 623 yd away) |
| 29 | T | 459 | The Woodland Protector | 1438 | 57.8, 45.2 | 119 |  |
| 30 | T | 97977 | Nature's Call | 1438 | 57.8, 45.2 | 0 |  |
| 31 | T | 457 | The Balance of Nature | 1438 | 58.7, 44.3 | 54 |  |
| 32 | T | 3521 | Iverron's Antidote | 1438 | 60.9, 42.0 | 137 |  |
| 33 | A | 3522 | Iverron's Antidote | 1438 | 60.9, 42.0 | 0 |  |
| 34 | T | 920 | Tenaron's Summons | 1438 | 59.1, 39.5 | 126 |  |
| 35 | A | 921 | Crown of the Earth | 1438 | 59.1, 39.5 | 0 |  |
| 36 | T | 3522 | Iverron's Antidote | 1438 | 54.6, 33.0 | 316 |  |
| 37 | O | 921 | Crown of the Earth | 1438 | 60.0, 33.0 | 272 |  |
| 38 | T | 921 | Crown of the Earth | 1438 | 59.1, 39.5 | 221 |  |
| 39 | A | 928 | Crown of the Earth | 1438 | 59.1, 39.5 | 0 |  |
| 40 | A | 96630 | The Adventurer | 1438 | 59.1, 39.5 | 3 |  |
| 41 | A | 2159 | Dolanaar Delivery | 1438 | 61.2, 47.6 | 294 | near #2 (went 759 yd away) |
| 42 | T | 96630 | The Adventurer | 1438 | 57.6, 56.6 | 355 |  |
| 43 | T | 2159 | Dolanaar Delivery | 1438 | 55.6, 59.8 | 146 |  |
| 44 | T | 928 | Crown of the Earth | 1438 | 56.1, 61.7 | 70 |  |

Walking between tasks: 5442 yd (~13 min at 7 yd/s).

## Qualité

Checks of the itinerary (see `tools/routebuilder/quality.lua`): avoidable revisits (a place left,
then returned to only for accepts or turn-ins possible on the earlier visit), missed pickups
(within 40 yd), missed passing turn-ins (within 60 yd) and split objective areas (within 120 yd).
A place counts as left when the route went more than 150 yd away (220 yd for an objective area).
Reason: why the ordering kept it: `log cap`, `level` or `chain` (a constraint later in the route),
`free` (no constraint: a defect).

| Check | Count |
|---|---|
| Avoidable revisits | 0 |
| Missed pickups | 0 |
| Split areas | 0 |
| Missed passing turn-ins | 0 |

## Logistics

None.

## Warnings

- quest 97979 The Goddess Provides: spell objective without position, placed at the starter
- quest 97979 The Goddess Provides: spell objective without position, placed at the starter
