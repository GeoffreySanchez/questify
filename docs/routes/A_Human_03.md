# A_Human_03 — Westfall

Generated on 2026-11-04 from QuestieDB commit `c5de61ab7c629132a772cccddf7f604ac48cecf9` by `tools/routebuilder/build.lua`. Simulated race: Human.

| Item | Value |
|---|---|
| Level band | 11-16 |
| Simulated level | 11.00 -> 16.09 |
| Time | 133 min |
| XP gained | 51837 |
| XP/h | 23333 |
| Steps | 72 |
| Quests turned in | 24 |
| Hubs | 8 |
| Median ratio (XP/s) | 5.62 |
| Level band | grinding 76 mobs with quests up to level 19: band widened to level 22 |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 136 | Captain Sander's Hidden Treasure | 16 | 580 | 12 |
| 2 | 138 | Captain Sander's Hidden Treasure | 16 | 580 | 12 |
| 3 | 92742 | Testing the Wells | 12 | 910 est. | 12 |
| 4 | 92744 | Murloc Gills | 12 | 910 est. | 12 |
| 5 | 12 | The People's Militia | 12 | 910 | 12 |
| 6 | 139 | Captain Sander's Hidden Treasure | 16 | 580 | 13 |
| 7 | 140 | Captain Sander's Hidden Treasure | 16 | 1150 | 13 |
| 8 | 103 | Keeper of the Flame | 16 | 1150 | 14 |
| 9 | 152 | The Coast Isn't Clear | 19 | 1450 | 14 |
| 10 | 13 | The People's Militia | 14 | 980 | 14 |
| 11 | 102 | Patrolling Westfall | 14 | 980 | 14 |
| 12 | 6181 | A Swift Message | 10 | 210 | 14 |
| 13 | 153 | Red Leather Bandanas | 15 | 1050 | 15 |
| 14 | 92745 | The State of the Mines | 14 | 980 est. | 15 |
| 15 | 92747 | Moonbrook Espionage | 15 | 1050 est. | 15 |
| 16 | 14 | The People's Militia | 17 | 1600 | 15 |
| 17 | 9 | The Killing Fields | 15 | 1050 | 15 |
| 18 | 22 | Goretusk Liver Pie | 12 | 910 | 15 |
| 19 | 151 | Poor Old Blanchy | 14 | 1250 | 15 |
| 20 | 64 | The Forgotten Heirloom | 12 | 910 | 15 |
| 21 | 78142 | Bewitchments and Glamours | 20 | 1550 est. | 15 |
| 22 | 79093 | Rumi of Gnomeregan: The Collected Works | 20 | 1550 est. | 16 |
| 23 | 6281 | Continue to Stormwind | 10 | 335 | 16 |
| 24 | 92748 | Explosive Consultation | 16 | 580 est. | 16 |

## Dropped quests

| Quest | Name | Lvl | Reason |
|---|---|---|---|
| 48 | Sweet Amber | 44 | quest level 44 above the band |
| 49 | Sweet Amber | 44 | quest level 44 above the band |
| 50 | Sweet Amber | 44 | quest level 44 above the band |
| 51 | Sweet Amber | 44 | quest level 44 above the band |
| 53 | Sweet Amber | 44 | quest level 44 above the band |
| 65 | The Defias Brotherhood | 18 | finisher outside the chapter zones |
| 68 | The Legend of Stalvan | 28 | quest level 28 above the band |
| 117 | Thunderbrew | 15 | repeatable |
| 144 | Messenger to Westfall | 14 | finisher outside the chapter zones |
| 1651 | The Tome of Valor | 25 | class quest (ClassQuestData.lua) |
| 1652 | The Tome of Valor | 25 | class quest (ClassQuestData.lua) |
| 2359 | Klaven's Tower | 24 | class quest (ClassQuestData.lua) |
| 3861 | CLUCK! | 1 | quest level 1 below the band |
| 8675 | Skychaser the Elder | 60 | Questie blacklist |
| 79008 | ... and that note you found | 22 | finisher outside the chapter zones |
| 79192 | Stepping Stones | 24 | quest level 24 above the band |
| 92109 | My First Alchemy Set | 10 | requires a profession |
| 92110 | My First Real Potion | 10 | requires a profession |
| 92910 | Harvesting the Harvesters | 15 | requires a profession |
| 92911 | Harvesting the Harvesters | 15 | requires a profession |
| 93928 | Of Mice and Milk | 15 | Questie blacklist |
| 94503 | Call of Water | 23 | class quest (ClassQuestData.lua) |
| 135 | The Defias Brotherhood | 18 | prerequisite unavailable |
| 142 | The Defias Brotherhood | 18 | prerequisite unavailable |
| 155 | The Defias Brotherhood | 18 | prerequisite unavailable |
| 166 | The Defias Brotherhood | 22 | prerequisite unavailable |
| 214 | Red Silk Bandanas | 17 | prerequisite unavailable |
| 92753 | Destruction in Deadmines | 18 | prerequisite unavailable |
| 92819 | Destruction in Deadmines | 18 | prerequisite unavailable |
| 36 | Westfall Stew | 10 | level band reached |
| 92909 | Harvesting the Harvesters | 15 | level band reached |
| 38 | Westfall Stew | 13 | level band reached |
| 104 | The Coastal Menace | 20 | required level 15 not reached in time (~78 mobs to farm) |

## Candidate ratios

Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;
marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are
below 0.35 × the median ratio, or when an objective is more than 900 yd from every hub.

| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |
|---|---|---|---|---|---|---|---|---|---|---|
| 9 | The Killing Fields | 15 | 3330 | 0 | 633 | 448 | 5.26 | 7.42 | 1 |  |
| 12 | The People's Militia | 12 | 3985 | 0 | 911 | 683 | 5.10 | 6.34 | 2 |  |
| 13 | The People's Militia | 14 | 4340 | 0 | 808 | 696 | 5.81 | 6.79 | 1 |  |
| 14 | The People's Militia | 17 | 4775 | 0 | 732 | 620 | 6.52 | 7.70 | 1 |  |
| 22 | Goretusk Liver Pie | 12 | 3535 | 0 | 598 | 559 | 5.90 | 6.32 | 1 |  |
| 36 | Westfall Stew | 10 | 420 | 0 | 51 | 11 | 5.18 | 5.79 | 0 | level band reached |
| 38 | Westfall Stew | 13 | 4832 | 0 | 974 | 920 | 4.96 | 5.25 | 3 | level band reached |
| 64 | The Forgotten Heirloom | 12 | 910 | 0 | 122 | 41 | 7.43 | 22.19 | 1 |  |
| 102 | Patrolling Westfall | 14 | 4172 | 0 | 865 | 632 | 4.82 | 6.60 | 1 |  |
| 103 | Keeper of the Flame | 16 | 2470 | 0 | 723 | 250 | 3.41 | 9.88 | 1 |  |
| 104 | The Coastal Menace | 20 | 1695 | 0 | 97 | 97 | 17.38 | 17.38 | 1 |  |
| 136 | Captain Sander's Hidden Treasure | 16 | 1130 | 0 | 251 | 170 | 5.29 | 10.62 | 0 |  |
| 138 | Captain Sander's Hidden Treasure | 16 | 580 | 0 | 83 | 10 | 6.50 | 28.93 | 0 |  |
| 139 | Captain Sander's Hidden Treasure | 16 | 580 | 0 | 112 | 10 | 6.23 | 22.26 | 0 |  |
| 140 | Captain Sander's Hidden Treasure | 16 | 1150 | 0 | 156 | 74 | 7.34 | 15.42 | 0 |  |
| 151 | Poor Old Blanchy | 14 | 1250 | 0 | 133 | 133 | 9.36 | 9.36 | 1 |  |
| 152 | The Coast Isn't Clear | 19 | 5010 | 0 | 1255 | 727 | 3.99 | 6.88 | 4 |  |
| 153 | Red Leather Bandanas | 15 | 4650 | 0 | 961 | 800 | 4.84 | 5.81 | 1 |  |
| 6181 | A Swift Message | 10 | 210 | 0 | 47 | 47 | 5.61 | 20.26 | 0 |  |
| 6281 | Continue to Stormwind | 10 | 1843 | 1423 | 314 | 38 | 5.86 | 48.47 | 0 |  |
| 78142 | Bewitchments and Glamours | 20 | 3032 | 1482 | 387 | 19 | 7.83 | 157.79 | 1 |  |
| 79093 | Rumi of Gnomeregan: The Collected Works | 20 | 2728 | 1178 | 259 | 26 | 10.53 | 104.26 | 1 |  |
| 92742 | Testing the Wells | 12 | 910 | 0 | 283 | 33 | 3.96 | 12.03 | 2 |  |
| 92744 | Murloc Gills | 12 | 2450 | 0 | 592 | 356 | 4.22 | 8.28 | 1 |  |
| 92745 | The State of the Mines | 14 | 2084 | 0 | 560 | 297 | 4.29 | 10.14 | 2 |  |
| 92747 | Moonbrook Espionage | 15 | 1050 | 0 | 256 | 117 | 5.22 | 20.61 | 1 |  |
| 92748 | Explosive Consultation | 16 | 2222 | 1642 | 346 | 12 | 6.41 | 174.66 | 0 |  |
| 92909 | Harvesting the Harvesters | 15 | 4990 | 0 | 884 | 884 | 5.64 | 5.64 | 1 | level band reached |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | A | 12 | The People's Militia | 1436 | 56.3, 47.5 | 0 |  |
| 2 | A | 102 | Patrolling Westfall | 1436 | 56.4, 47.6 | 3 |  |
| 3 | A | 6181 | A Swift Message | 1436 | 57.0, 47.2 | 22 |  |
| 4 | A | 153 | Red Leather Bandanas | 1436 | 54.0, 53.0 | 171 |  |
| 5 | A | 92742 | Testing the Wells | 1436 | 52.5, 53.0 | 52 |  |
| 6 | A | 92744 | Murloc Gills | 1436 | 52.5, 53.0 | 0 |  |
| 7 | A | 79093 | Rumi of Gnomeregan: The Collected Works | 1436 | 52.7, 53.8 | 20 |  |
| 8 | O | 92742 | Testing the Wells | 1436 | 46.1, 38.1 | 433 |  |
| 9 | A | 9 | The Killing Fields | 1436 | 56.0, 31.2 | 384 |  |
| 10 | A | 22 | Goretusk Liver Pie | 1436 | 56.4, 30.5 | 21 |  |
| 11 | A | 151 | Poor Old Blanchy | 1436 | 59.9, 19.4 | 286 |  |
| 12 | A | 64 | The Forgotten Heirloom | 1436 | 60.0, 19.4 | 1 |  |
| 13 | O | 92742 | Testing the Wells | 1436 | 56.6, 18.7 | 117 |  |
| 14 | O | 64 | The Forgotten Heirloom | 1436 | 49.3, 19.3 | 255 |  |
| 15 | O | 12 | The People's Militia | 1436 | 44.8, 26.0 | 222 |  |
| 16 | A | 136 | Captain Sander's Hidden Treasure | 1436 | 34.5, 17.0 | 415 |  |
| 17 | O | 92744 | Murloc Gills | 1436 | 34.5, 17.0 | 0 |  |
| 18 | O | 12 | The People's Militia | 1436 | 31.6, 33.8 | 404 |  |
| 19 | T | 136 | Captain Sander's Hidden Treasure | 1436 | 25.9, 47.8 | 382 |  |
| 20 | A | 138 | Captain Sander's Hidden Treasure | 1436 | 25.9, 47.8 | 0 |  |
| 21 | A | 103 | Keeper of the Flame | 1436 | 30.0, 86.0 | 904 |  |
| 22 | A | 152 | The Coast Isn't Clear | 1436 | 30.0, 86.0 | 0 |  |
| 23 | T | 138 | Captain Sander's Hidden Treasure | 1436 | 40.5, 47.8 | 964 |  |
| 24 | A | 139 | Captain Sander's Hidden Treasure | 1436 | 40.5, 47.8 | 0 |  |
| 25 | T | 92742 | Testing the Wells | 1436 | 52.5, 53.0 | 435 | near #7 (went 1101 yd away) |
| 26 | T | 92744 | Murloc Gills | 1436 | 52.5, 53.0 | 0 | near #7 (went 1101 yd away) |
| 27 | A | 92745 | The State of the Mines | 1436 | 52.5, 53.0 | 0 |  |
| 28 | T | 12 | The People's Militia | 1436 | 56.3, 47.5 | 185 | near #3 (went 1286 yd away) |
| 29 | A | 13 | The People's Militia | 1436 | 56.3, 47.5 | 0 | near #3 (went 1286 yd away) |
| 30 | O | 22 | Goretusk Liver Pie | 1436 | 53.7, 42.9 | 141 |  |
| 31 | O | 103 | Keeper of the Flame | 1436 | 52.8, 23.8 | 447 |  |
| 32 | O | 153 | Red Leather Bandanas | 1436 | 45.3, 22.8 | 263 | near #15 (went 1570 yd away) |
| 33 | O | 92745 | The State of the Mines | 1436 | 45.3, 20.0 | 63 | near #15 (went 1629 yd away) |
| 34 | O | 152 | The Coast Isn't Clear | 1436 | 43.5, 9.6 | 251 |  |
| 35 | T | 139 | Captain Sander's Hidden Treasure | 1436 | 40.6, 17.0 | 201 |  |
| 36 | A | 140 | Captain Sander's Hidden Treasure | 1436 | 40.6, 17.0 | 0 |  |
| 37 | T | 140 | Captain Sander's Hidden Treasure | 1436 | 26.0, 16.9 | 513 |  |
| 38 | O | 152 | The Coast Isn't Clear | 1436 | 29.8, 27.6 | 283 |  |
| 39 | O | 92745 | The State of the Mines | 1436 | 30.0, 47.3 | 459 | near #20 (went 998 yd away) |
| 40 | O | 152 | The Coast Isn't Clear | 1436 | 27.2, 53.7 | 177 | near #20 (went 1175 yd away) |
| 41 | O | 102 | Patrolling Westfall | 1436 | 31.0, 68.8 | 376 |  |
| 42 | O | 152 | The Coast Isn't Clear | 1436 | 27.3, 70.9 | 139 |  |
| 43 | T | 103 | Keeper of the Flame | 1436 | 30.0, 86.0 | 364 | near #22 (went 1844 yd away) |
| 44 | T | 152 | The Coast Isn't Clear | 1436 | 30.0, 86.0 | 0 | near #22 (went 1844 yd away) |
| 45 | O | 13 | The People's Militia | 1436 | 43.7, 68.9 | 623 |  |
| 46 | O | 9 | The Killing Fields | 1436 | 38.8, 51.5 | 441 | near #24 (went 991 yd away) |
| 47 | T | 13 | The People's Militia | 1436 | 56.3, 47.5 | 621 | near #30 (went 1286 yd away) |
| 48 | A | 14 | The People's Militia | 1436 | 56.3, 47.5 | 0 | near #30 (went 1286 yd away) |
| 49 | T | 102 | Patrolling Westfall | 1436 | 56.4, 47.6 | 3 |  |
| 50 | T | 6181 | A Swift Message | 1436 | 56.5, 52.6 | 117 |  |
| 51 | A | 6281 | Continue to Stormwind | 1436 | 56.5, 52.6 | 0 |  |
| 52 | T | 153 | Red Leather Bandanas | 1436 | 54.0, 53.0 | 90 |  |
| 53 | T | 92745 | The State of the Mines | 1436 | 52.5, 53.0 | 52 |  |
| 54 | A | 92747 | Moonbrook Espionage | 1436 | 52.5, 53.0 | 0 |  |
| 55 | O | 92747 | Moonbrook Espionage | 1436 | 43.1, 68.8 | 494 | near #45 (went 679 yd away) |
| 56 | A | 78142 | Bewitchments and Glamours | 1436 | 45.4, 70.4 | 88 | near #45 (went 656 yd away) |
| 57 | O | 78142 | Bewitchments and Glamours | 1436 | 45.4, 70.4 | 0 |  |
| 58 | O | 14 | The People's Militia | 1436 | 52.1, 76.6 | 274 |  |
| 59 | O | 79093 | Rumi of Gnomeregan: The Collected Works | 1436 | 52.7, 53.8 | 532 |  |
| 60 | T | 92747 | Moonbrook Espionage | 1436 | 52.5, 53.0 | 20 |  |
| 61 | A | 92748 | Explosive Consultation | 1436 | 52.5, 53.0 | 0 |  |
| 62 | T | 14 | The People's Militia | 1436 | 56.3, 47.5 | 185 | near #51 (went 694 yd away) |
| 63 | T | 9 | The Killing Fields | 1436 | 56.0, 31.2 | 380 | near #10 (went 1569 yd away) |
| 64 | T | 22 | Goretusk Liver Pie | 1436 | 56.4, 30.5 | 21 | near #10 (went 1591 yd away) |
| 65 | O | 151 | Poor Old Blanchy | 1436 | 57.3, 18.3 | 286 | near #13 (went 1845 yd away) |
| 66 | T | 151 | Poor Old Blanchy | 1436 | 59.9, 19.4 | 96 | near #13 (went 1873 yd away) |
| 67 | T | 64 | The Forgotten Heirloom | 1436 | 60.0, 19.4 | 1 |  |
| 68 | T | 78142 | Bewitchments and Glamours | 1453 | 48.9, 86.5 | 854 |  |
| 69 | T | 79093 | Rumi of Gnomeregan: The Collected Works | 1453 | 48.9, 86.5 | 0 |  |
| 70 | T | 6281 | Continue to Stormwind | 1453 | 77.2, 61.0 | 572 |  |
| 71 | T | 92748 | Explosive Consultation | 1453 | 61.9, 30.6 | 441 |  |

Walking between tasks: 15571 yd (~37 min at 7 yd/s).

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

- step 8: `sethearth 1436 52.86 53.71`

## Warnings

None.
