# ERA_A_DwarfGnome_01 — Coldridge Valley

Generated on 2026-11-03 from QuestieDB commit `c5de61ab7c629132a772cccddf7f604ac48cecf9 (vue Classic Era)` by `tools/routebuilder/build.lua`. Simulated race: Dwarf.

| Item | Value |
|---|---|
| Level band | 1-6 |
| Simulated level | 1.00 -> 6.01 |
| Time | 38 min |
| XP gained | 7645 |
| XP/h | 12045 |
| Steps | 35 |
| Quests turned in | 13 |
| Hubs | 5 |
| Median ratio (XP/s) | 4.30 |
| Grinding (level steps) | ~20 mobs |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 179 | Dwarven Outfitters | 1 | 80 | 2 |
| 2 | 233 | Coldridge Valley Mail Delivery | 3 | 190 | 3 |
| 3 | 183 | The Boar Hunter | 3 | 250 | 3 |
| 4 | 182 | The Troll Cave | 4 | 355 | 4 |
| 5 | 234 | Coldridge Valley Mail Delivery | 4 | 270 | 4 |
| 6 | 3364 | Scalding Mornbrew Delivery | 5 | 225 | 4 |
| 7 | 3365 | Bring Back the Mug | 5 | 450 | 4 |
| 8 | 218 | The Stolen Journal | 5 | 560 | 5 |
| 9 | 3361 | A Refugee's Quandary | 3 | 250 | 5 |
| 10 | 170 | A New Threat | 2 | 170 | 5 |
| 11 | 282 | Senir's Observations | 5 | 335 | 5 |
| 12 | 420 | Senir's Observations | 5 | 335 | 5 |
| 13 | 2160 | Supplies to Tannok | 5 | 110 | 5 |

## Dropped quests

| Quest | Name | Lvl | Reason |
|---|---|---|---|
| 1599 | Beginnings | 4 | class quest (ClassQuestData.lua) |
| 3106 | Simple Rune | 1 | class quest (ClassQuestData.lua) |
| 3107 | Consecrated Rune | 1 | class quest (ClassQuestData.lua) |
| 3108 | Etched Rune | 1 | class quest (ClassQuestData.lua) |
| 3109 | Encrypted Rune | 1 | class quest (ClassQuestData.lua) |
| 3110 | Hallowed Rune | 1 | class quest (ClassQuestData.lua) |
| 3112 | Simple Memorandum | 1 | class quest (ClassQuestData.lua) |
| 3113 | Encrypted Memorandum | 1 | class quest (ClassQuestData.lua) |
| 3114 | Glyphic Memorandum | 1 | class quest (ClassQuestData.lua) |
| 3115 | Tainted Memorandum | 1 | class quest (ClassQuestData.lua) |
| 5626 | In Favor of the Light | 4 | class quest (ClassQuestData.lua) |

## Candidate ratios

Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;
marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are
below 0.35 × the median ratio, or when an objective is more than 900 yd from every hub.

| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |
|---|---|---|---|---|---|---|---|---|---|---|
| 170 | A New Threat | 2 | 782 | 0 | 298 | 285 | 2.62 | 2.74 | 1 |  |
| 179 | Dwarven Outfitters | 1 | 730 | 0 | 305 | 305 | 2.68 | 2.97 | 1 |  |
| 182 | The Troll Cave | 4 | 1125 | 0 | 358 | 315 | 3.77 | 5.65 | 1 |  |
| 183 | The Boar Hunter | 3 | 910 | 0 | 266 | 266 | 3.42 | 3.42 | 1 |  |
| 218 | The Stolen Journal | 5 | 620 | 0 | 117 | 33 | 5.14 | 24.79 | 1 |  |
| 233 | Coldridge Valley Mail Delivery | 3 | 190 | 0 | 62 | 11 | 4.30 | 20.23 | 0 |  |
| 234 | Coldridge Valley Mail Delivery | 4 | 270 | 0 | 36 | 10 | 7.31 | 25.27 | 0 |  |
| 282 | Senir's Observations | 5 | 335 | 0 | 73 | 12 | 5.01 | 39.69 | 0 |  |
| 420 | Senir's Observations | 5 | 730 | 395 | 136 | 12 | 5.33 | 60.15 | 0 |  |
| 2160 | Supplies to Tannok | 5 | 527 | 417 | 145 | 14 | 3.64 | 36.97 | 0 |  |
| 3361 | A Refugee's Quandary | 3 | 250 | 0 | 205 | 127 | 1.21 | 1.97 | 3 |  |
| 3364 | Scalding Mornbrew Delivery | 5 | 225 | 0 | 66 | 18 | 4.78 | 17.45 | 0 |  |
| 3365 | Bring Back the Mug | 5 | 450 | 0 | 66 | 18 | 6.78 | 24.72 | 0 |  |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | A | 179 | Dwarven Outfitters | 1426 | 29.9, 71.2 | 0 |  |
| 2 | O | 179 | Dwarven Outfitters | 1426 | 28.9, 74.5 | 119 |  |
| 3 | T | 179 | Dwarven Outfitters | 1426 | 29.9, 71.2 | 119 |  |
| 4 | A | 233 | Coldridge Valley Mail Delivery | 1426 | 29.9, 71.2 | 0 |  |
| 5 | A | 183 | The Boar Hunter | 1426 | 22.6, 71.4 | 361 |  |
| 6 | O | 183 | The Boar Hunter | 1426 | 21.5, 71.1 | 56 |  |
| 7 | T | 233 | Coldridge Valley Mail Delivery | 1426 | 22.6, 71.4 | 56 |  |
| 8 | A | 234 | Coldridge Valley Mail Delivery | 1426 | 22.6, 71.4 | 0 |  |
| 9 | T | 183 | The Boar Hunter | 1426 | 22.6, 71.4 | 0 |  |
| 10 | A | 182 | The Troll Cave | 1426 | 25.1, 75.7 | 186 |  |
| 11 | O | 182 | The Troll Cave | 1426 | 28.8, 80.3 | 236 |  |
| 12 | T | 182 | The Troll Cave | 1426 | 25.1, 75.7 | 236 |  |
| 13 | A | 218 | The Stolen Journal | 1426 | 25.1, 75.7 | 0 |  |
| 14 | T | 234 | Coldridge Valley Mail Delivery | 1426 | 25.1, 75.7 | 0 |  |
| 15 | C | 3364 | Scalding Mornbrew Delivery | 1426 | 25.0, 76.0 | 9 |  |
| 16 | A | 3365 | Bring Back the Mug | 1426 | 28.8, 66.4 | 0 |  |
| 17 | A | 3361 | A Refugee's Quandary | 1426 | 28.6, 67.6 | 43 |  |
| 18 | A | 170 | A New Threat | 1426 | 29.7, 71.2 | 131 |  |
| 19 | O | 170 | A New Threat | 1426 | 31.0, 75.7 | 161 |  |
| 20 | O | 218 | The Stolen Journal | 1426 | 30.5, 80.2 | 147 |  |
| 21 | O | 3361 | A Refugee's Quandary | 1426 | 26.3, 79.3 | 206 |  |
| 22 | O | 3361 | A Refugee's Quandary | 1426 | 22.8, 80.0 | 176 |  |
| 23 | O | 3361 | A Refugee's Quandary | 1426 | 20.9, 76.1 | 159 |  |
| 24 | T | 3365 | Bring Back the Mug | 1426 | 25.0, 76.0 | 201 |  |
| 25 | T | 218 | The Stolen Journal | 1426 | 25.1, 75.7 | 9 |  |
| 26 | A | 282 | Senir's Observations | 1426 | 25.1, 75.7 | 0 |  |
| 27 | T | 3361 | A Refugee's Quandary | 1426 | 28.6, 67.6 | 315 |  |
| 28 | T | 170 | A New Threat | 1426 | 29.7, 71.2 | 131 |  |
| 29 | T | 282 | Senir's Observations | 1426 | 33.5, 71.8 | 186 |  |
| 30 | A | 420 | Senir's Observations | 1426 | 33.5, 71.8 | 0 |  |
| 31 | A | 2160 | Supplies to Tannok | 1426 | 33.9, 72.2 | 22 |  |
| 32 | T | 420 | Senir's Observations | 1426 | 46.7, 53.8 | 876 |  |
| 33 | T | 2160 | Supplies to Tannok | 1426 | 47.2, 52.2 | 59 |  |

Walking between tasks: 4210 yd (~10 min at 7 yd/s).

## Logistics

- step 35: `level 6` — About 20 more mobs here (Wendigo, level 6)

## Warnings

None.
