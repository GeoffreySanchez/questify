# A_NightElf_01 — Shadowglen

Generated on 2026-11-03 from QuestieDB commit `c5de61ab7c629132a772cccddf7f604ac48cecf9` by `tools/routebuilder/build.lua`. Simulated race: NightElf.

| Item | Value |
|---|---|
| Level band | 1-6 |
| Simulated level | 1.00 -> 6.53 |
| Time | 57 min |
| XP gained | 9497 |
| XP/h | 10027 |
| Steps | 44 |
| Quests turned in | 17 |
| Hubs | 2 |
| Median ratio (XP/s) | 2.50 |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 456 | The Balance of Nature | 2 | 170 | 2 |
| 2 | 458 | The Woodland Protector | 1 | 40 | 2 |
| 3 | 4495 | A Good Friend | 4 | 270 | 3 |
| 4 | 3519 | A Friend in Need | 4 | 90 | 4 |
| 5 | 916 | Webwood Venom | 4 | 355 | 4 |
| 6 | 97236 | Fang of Githyiss | 5 | 225 est. | 5 |
| 7 | 917 | Webwood Egg | 5 | 560 | 5 |
| 8 | 3521 | Iverron's Antidote | 4 | 355 | 5 |
| 9 | 920 | Tenaron's Summons | 5 | 45 | 5 |
| 10 | 3522 | Iverron's Antidote | 4 | 445 | 6 |
| 11 | 921 | Crown of the Earth | 5 | 335 | 6 |
| 12 | 457 | The Balance of Nature | 3 | 250 | 6 |
| 13 | 459 | The Woodland Protector | 3 | 250 | 6 |
| 14 | 97977 | Nature's Call | 3 | 250 est. | 6 |
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
| 2 | A | 2159 | Dolanaar Delivery | 1438 | 61.2, 47.6 | 169 |  |
| 3 | O | 456 | The Balance of Nature | 1438 | 61.7, 43.8 | 133 |  |
| 4 | A | 4495 | A Good Friend | 1438 | 60.9, 42.0 | 74 |  |
| 5 | A | 458 | The Woodland Protector | 1438 | 59.9, 42.5 | 52 |  |
| 6 | T | 456 | The Balance of Nature | 1438 | 58.7, 44.3 | 87 |  |
| 7 | A | 457 | The Balance of Nature | 1438 | 58.7, 44.3 | 0 |  |
| 8 | T | 458 | The Woodland Protector | 1438 | 57.8, 45.2 | 54 |  |
| 9 | A | 459 | The Woodland Protector | 1438 | 57.8, 45.2 | 0 |  |
| 10 | A | 97977 | Nature's Call | 1438 | 57.8, 45.2 | 0 |  |
| 11 | O | 459 | The Woodland Protector | 1438 | 55.4, 45.1 | 121 |  |
| 12 | A | 916 | Webwood Venom | 1438 | 57.8, 41.6 | 168 |  |
| 13 | T | 4495 | A Good Friend | 1438 | 54.6, 33.0 | 336 |  |
| 14 | A | 3519 | A Friend in Need | 1438 | 54.6, 33.0 | 0 |  |
| 15 | O | 916 | Webwood Venom | 1438 | 56.6, 27.5 | 212 |  |
| 16 | A | 97236 | Fang of Githyiss | 1438 | 56.6, 26.3 | 42 |  |
| 17 | O | 457 | The Balance of Nature | 1438 | 62.2, 37.2 | 464 |  |
| 18 | T | 3519 | A Friend in Need | 1438 | 60.9, 42.0 | 176 |  |
| 19 | A | 3521 | Iverron's Antidote | 1438 | 60.9, 42.0 | 0 |  |
| 20 | T | 916 | Webwood Venom | 1438 | 57.8, 41.6 | 157 |  |
| 21 | T | 97236 | Fang of Githyiss | 1438 | 57.8, 41.6 | 0 |  |
| 22 | A | 917 | Webwood Egg | 1438 | 57.8, 41.6 | 0 |  |
| 23 | O | 3521 | Iverron's Antidote | 1438 | 55.5, 44.6 | 153 | near #11 (went 623 yd away) |
| 24 | O | 97977 | Nature's Call | 1438 | 54.9, 38.8 | 198 |  |
| 25 | O | 917 | Webwood Egg | 1438 | 56.8, 26.5 | 430 | near #16 (went 618 yd away) |
| 26 | O | 3521 | Iverron's Antidote | 1438 | 56.9, 31.1 | 156 |  |
| 27 | O | 3521 | Iverron's Antidote | 1438 | 57.6, 38.3 | 247 |  |
| 28 | T | 917 | Webwood Egg | 1438 | 57.8, 41.6 | 113 |  |
| 29 | A | 920 | Tenaron's Summons | 1438 | 57.8, 41.6 | 0 |  |
| 30 | T | 3521 | Iverron's Antidote | 1438 | 60.9, 42.0 | 157 |  |
| 31 | A | 3522 | Iverron's Antidote | 1438 | 60.9, 42.0 | 0 |  |
| 32 | T | 920 | Tenaron's Summons | 1438 | 59.1, 39.5 | 126 |  |
| 33 | A | 921 | Crown of the Earth | 1438 | 59.1, 39.5 | 0 |  |
| 34 | O | 921 | Crown of the Earth | 1438 | 60.0, 33.0 | 221 |  |
| 35 | T | 3522 | Iverron's Antidote | 1438 | 54.6, 33.0 | 272 |  |
| 36 | T | 921 | Crown of the Earth | 1438 | 59.1, 39.5 | 316 |  |
| 37 | A | 928 | Crown of the Earth | 1438 | 59.1, 39.5 | 0 |  |
| 38 | A | 96630 | The Adventurer | 1438 | 59.1, 39.5 | 3 |  |
| 39 | T | 457 | The Balance of Nature | 1438 | 58.7, 44.3 | 161 |  |
| 40 | T | 459 | The Woodland Protector | 1438 | 57.8, 45.2 | 54 |  |
| 41 | T | 97977 | Nature's Call | 1438 | 57.8, 45.2 | 0 |  |
| 42 | T | 96630 | The Adventurer | 1438 | 57.6, 56.6 | 388 |  |
| 43 | T | 2159 | Dolanaar Delivery | 1438 | 55.6, 59.8 | 146 |  |
| 44 | T | 928 | Crown of the Earth | 1438 | 56.1, 61.7 | 70 |  |

Walking between tasks: 5470 yd (~13 min at 7 yd/s).

## Logistics

None.

## Warnings

- quest 97979 The Goddess Provides: spell objective without position, placed at the starter
- quest 97979 The Goddess Provides: spell objective without position, placed at the starter
