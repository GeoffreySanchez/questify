# A_Human_03 — Westfall

Generated on 2026-11-03 from QuestieDB commit `c5de61ab7c629132a772cccddf7f604ac48cecf9` by `tools/routebuilder/build.lua`. Simulated race: Human.

| Item | Value |
|---|---|
| Level band | 11-16 |
| Simulated level | 11.00 -> 16.36 |
| Time | 148 min |
| XP gained | 55699 |
| XP/h | 22547 |
| Steps | 75 |
| Quests turned in | 25 |
| Hubs | 8 |
| Median ratio (XP/s) | 5.56 |
| Grinding (level steps) | ~39 mobs |
| Level band | grinding 37 mobs with quests up to level 19: band widened to level 22 |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 136 | Captain Sander's Hidden Treasure | 16 | 580 | 12 |
| 2 | 138 | Captain Sander's Hidden Treasure | 16 | 580 | 13 |
| 3 | 92744 | Murloc Gills | 12 | 910 est. | 13 |
| 4 | 92742 | Testing the Wells | 12 | 910 est. | 13 |
| 5 | 12 | The People's Militia | 12 | 910 | 13 |
| 6 | 139 | Captain Sander's Hidden Treasure | 16 | 580 | 14 |
| 7 | 140 | Captain Sander's Hidden Treasure | 16 | 1150 | 14 |
| 8 | 152 | The Coast Isn't Clear | 19 | 1450 | 14 |
| 9 | 103 | Keeper of the Flame | 16 | 1150 | 14 |
| 10 | 92745 | The State of the Mines | 14 | 980 est. | 15 |
| 11 | 13 | The People's Militia | 14 | 980 | 15 |
| 12 | 102 | Patrolling Westfall | 14 | 980 | 15 |
| 13 | 6181 | A Swift Message | 10 | 210 | 15 |
| 14 | 92747 | Moonbrook Espionage | 15 | 1050 est. | 15 |
| 15 | 153 | Red Leather Bandanas | 15 | 1050 | 15 |
| 16 | 14 | The People's Militia | 17 | 1600 | 15 |
| 17 | 9 | The Killing Fields | 15 | 1050 | 15 |
| 18 | 22 | Goretusk Liver Pie | 12 | 910 | 15 |
| 19 | 36 | Westfall Stew | 10 | 420 | 15 |
| 20 | 151 | Poor Old Blanchy | 14 | 1250 | 16 |
| 21 | 64 | The Forgotten Heirloom | 12 | 910 | 16 |
| 22 | 78142 | Bewitchments and Glamours | 20 | 1550 est. | 16 |
| 23 | 79093 | Rumi of Gnomeregan: The Collected Works | 20 | 1550 est. | 16 |
| 24 | 6281 | Continue to Stormwind | 10 | 335 | 16 |
| 25 | 92748 | Explosive Consultation | 16 | 580 est. | 16 |

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
| 104 | The Coastal Menace | 20 | required level 15 not reached in time (~163 mobs to farm) |
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
| 92909 | Harvesting the Harvesters | 15 | level band reached |
| 38 | Westfall Stew | 13 | level band reached |

## Candidate ratios

Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;
marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are
below 0.35 × the median ratio, or when an objective is more than 900 yd from every hub.

| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |
|---|---|---|---|---|---|---|---|---|---|---|
| 9 | The Killing Fields | 15 | 3330 | 0 | 633 | 448 | 5.26 | 7.42 | 1 |  |
| 12 | The People's Militia | 12 | 3985 | 0 | 911 | 630 | 5.10 | 6.58 | 2 |  |
| 13 | The People's Militia | 14 | 4340 | 0 | 808 | 696 | 5.81 | 6.79 | 1 |  |
| 14 | The People's Militia | 17 | 4775 | 0 | 732 | 620 | 6.52 | 7.70 | 1 |  |
| 22 | Goretusk Liver Pie | 12 | 3535 | 0 | 598 | 559 | 5.90 | 6.32 | 1 |  |
| 36 | Westfall Stew | 10 | 420 | 0 | 51 | 11 | 5.18 | 5.88 | 0 |  |
| 38 | Westfall Stew | 13 | 4832 | 0 | 974 | 907 | 4.96 | 5.33 | 3 | level band reached |
| 64 | The Forgotten Heirloom | 12 | 910 | 0 | 122 | 35 | 7.43 | 25.70 | 1 |  |
| 102 | Patrolling Westfall | 14 | 4172 | 0 | 865 | 689 | 4.82 | 6.05 | 1 |  |
| 103 | Keeper of the Flame | 16 | 2470 | 0 | 723 | 250 | 3.41 | 9.88 | 1 |  |
| 136 | Captain Sander's Hidden Treasure | 16 | 1130 | 0 | 251 | 170 | 5.29 | 10.62 | 0 |  |
| 138 | Captain Sander's Hidden Treasure | 16 | 580 | 0 | 83 | 10 | 6.50 | 28.93 | 0 |  |
| 139 | Captain Sander's Hidden Treasure | 16 | 580 | 0 | 112 | 10 | 6.23 | 22.26 | 0 |  |
| 140 | Captain Sander's Hidden Treasure | 16 | 1150 | 0 | 156 | 74 | 7.34 | 15.42 | 0 |  |
| 151 | Poor Old Blanchy | 14 | 1250 | 0 | 133 | 133 | 9.36 | 9.36 | 1 |  |
| 152 | The Coast Isn't Clear | 19 | 5010 | 0 | 1255 | 793 | 3.99 | 6.31 | 4 |  |
| 153 | Red Leather Bandanas | 15 | 4650 | 0 | 961 | 800 | 4.84 | 5.81 | 1 |  |
| 6181 | A Swift Message | 10 | 210 | 0 | 47 | 47 | 5.56 | 20.09 | 0 |  |
| 6281 | Continue to Stormwind | 10 | 1825 | 1405 | 314 | 38 | 5.80 | 47.99 | 0 |  |
| 78142 | Bewitchments and Glamours | 20 | 3013 | 1463 | 387 | 19 | 7.78 | 156.81 | 1 |  |
| 79093 | Rumi of Gnomeregan: The Collected Works | 20 | 2713 | 1163 | 259 | 26 | 10.47 | 103.69 | 1 |  |
| 92742 | Testing the Wells | 12 | 910 | 0 | 283 | 33 | 3.95 | 13.25 | 2 |  |
| 92744 | Murloc Gills | 12 | 2450 | 0 | 592 | 356 | 4.21 | 8.66 | 1 |  |
| 92745 | The State of the Mines | 14 | 2084 | 0 | 560 | 256 | 4.28 | 11.30 | 2 |  |
| 92747 | Moonbrook Espionage | 15 | 1050 | 0 | 256 | 117 | 5.19 | 20.50 | 1 |  |
| 92748 | Explosive Consultation | 16 | 2201 | 1621 | 346 | 12 | 6.35 | 173.02 | 0 |  |
| 92909 | Harvesting the Harvesters | 15 | 4990 | 0 | 884 | 884 | 5.64 | 5.64 | 1 | level band reached |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | A | 12 | The People's Militia | 1436 | 56.3, 47.5 | 0 |  |
| 2 | A | 102 | Patrolling Westfall | 1436 | 56.4, 47.6 | 3 |  |
| 3 | A | 153 | Red Leather Bandanas | 1436 | 54.0, 53.0 | 151 |  |
| 4 | A | 92742 | Testing the Wells | 1436 | 52.5, 53.0 | 52 |  |
| 5 | A | 92744 | Murloc Gills | 1436 | 52.5, 53.0 | 21 |  |
| 6 | A | 78142 | Bewitchments and Glamours | 1436 | 45.4, 70.4 | 476 |  |
| 7 | O | 78142 | Bewitchments and Glamours | 1436 | 45.4, 70.4 | 0 |  |
| 8 | A | 103 | Keeper of the Flame | 1436 | 30.0, 86.0 | 650 |  |
| 9 | A | 152 | The Coast Isn't Clear | 1436 | 30.0, 86.0 | 0 |  |
| 10 | O | 102 | Patrolling Westfall | 1436 | 31.0, 68.8 | 404 |  |
| 11 | O | 92742 | Testing the Wells | 1436 | 46.1, 38.1 | 887 |  |
| 12 | A | 9 | The Killing Fields | 1436 | 56.0, 31.2 | 384 |  |
| 13 | A | 22 | Goretusk Liver Pie | 1436 | 56.4, 30.5 | 21 |  |
| 14 | A | 151 | Poor Old Blanchy | 1436 | 59.9, 19.4 | 286 |  |
| 15 | A | 36 | Westfall Stew | 1436 | 59.9, 19.4 | 0 |  |
| 16 | A | 64 | The Forgotten Heirloom | 1436 | 60.0, 19.4 | 1 |  |
| 17 | O | 151 | Poor Old Blanchy | 1436 | 57.3, 18.3 | 97 |  |
| 18 | O | 92742 | Testing the Wells | 1436 | 56.6, 18.7 | 24 |  |
| 19 | O | 103 | Keeper of the Flame | 1436 | 52.8, 23.8 | 177 |  |
| 20 | O | 64 | The Forgotten Heirloom | 1436 | 49.3, 19.3 | 161 |  |
| 21 | O | 12 | The People's Militia | 1436 | 44.8, 26.0 | 222 |  |
| 22 | O | 92744 | Murloc Gills | 1436 | 34.5, 17.0 | 415 |  |
| 23 | A | 136 | Captain Sander's Hidden Treasure | 1436 | 34.5, 17.0 | 0 |  |
| 24 | O | 12 | The People's Militia | 1436 | 31.6, 33.8 | 404 |  |
| 25 | T | 136 | Captain Sander's Hidden Treasure | 1436 | 25.9, 47.8 | 382 |  |
| 26 | A | 138 | Captain Sander's Hidden Treasure | 1436 | 25.9, 47.8 | 0 |  |
| 27 | O | 9 | The Killing Fields | 1436 | 38.8, 51.5 | 458 |  |
| 28 | T | 138 | Captain Sander's Hidden Treasure | 1436 | 40.5, 47.8 | 106 |  |
| 29 | A | 139 | Captain Sander's Hidden Treasure | 1436 | 40.5, 47.8 | 0 |  |
| 30 | T | 92744 | Murloc Gills | 1436 | 52.5, 53.0 | 435 | near #5 (went 1101 yd away) |
| 31 | T | 92742 | Testing the Wells | 1436 | 52.5, 53.0 | 0 | near #5 (went 1101 yd away) |
| 32 | A | 92745 | The State of the Mines | 1436 | 52.5, 53.0 | 0 |  |
| 33 | T | 12 | The People's Militia | 1436 | 56.3, 47.5 | 185 | near #2 (went 1286 yd away) |
| 34 | A | 13 | The People's Militia | 1436 | 56.3, 47.5 | 0 | near #2 (went 1286 yd away) |
| 35 | O | 22 | Goretusk Liver Pie | 1436 | 53.7, 42.9 | 141 |  |
| 36 | O | 153 | Red Leather Bandanas | 1436 | 45.3, 22.8 | 554 | near #21 (went 895 yd away) |
| 37 | O | 92745 | The State of the Mines | 1436 | 45.3, 20.0 | 63 | near #21 (went 937 yd away) |
| 38 | O | 152 | The Coast Isn't Clear | 1436 | 43.5, 9.6 | 251 |  |
| 39 | T | 139 | Captain Sander's Hidden Treasure | 1436 | 40.6, 17.0 | 201 |  |
| 40 | A | 140 | Captain Sander's Hidden Treasure | 1436 | 40.6, 17.0 | 0 |  |
| 41 | T | 140 | Captain Sander's Hidden Treasure | 1436 | 26.0, 16.9 | 513 |  |
| 42 | O | 152 | The Coast Isn't Clear | 1436 | 29.8, 27.6 | 283 |  |
| 43 | O | 92745 | The State of the Mines | 1436 | 30.0, 47.3 | 459 | near #26 (went 998 yd away) |
| 44 | O | 152 | The Coast Isn't Clear | 1436 | 27.2, 53.7 | 177 | near #26 (went 1175 yd away) |
| 45 | O | 152 | The Coast Isn't Clear | 1436 | 27.3, 70.9 | 402 | near #10 (went 1658 yd away) |
| 46 | T | 152 | The Coast Isn't Clear | 1436 | 30.0, 86.0 | 364 | near #9 (went 1875 yd away) |
| 47 | T | 103 | Keeper of the Flame | 1436 | 30.0, 86.0 | 0 | near #9 (went 1875 yd away) |
| 48 | O | 13 | The People's Militia | 1436 | 43.7, 68.9 | 623 | near #7 (went 1383 yd away) |
| 49 | A | 79093 | Rumi of Gnomeregan: The Collected Works | 1436 | 52.7, 53.8 | 472 | near #32 (went 1271 yd away) |
| 50 | O | 79093 | Rumi of Gnomeregan: The Collected Works | 1436 | 52.7, 53.8 | 0 | near #32 (went 1271 yd away) |
| 51 | T | 92745 | The State of the Mines | 1436 | 52.5, 53.0 | 20 |  |
| 52 | A | 92747 | Moonbrook Espionage | 1436 | 52.5, 53.0 | 0 |  |
| 53 | T | 13 | The People's Militia | 1436 | 56.3, 47.5 | 185 | near #35 (went 1286 yd away) |
| 54 | A | 14 | The People's Militia | 1436 | 56.3, 47.5 | 0 | near #35 (went 1286 yd away) |
| 55 | T | 102 | Patrolling Westfall | 1436 | 56.4, 47.6 | 3 |  |
| 56 | A | 6181 | A Swift Message | 1436 | 57.0, 47.2 | 22 |  |
| 57 | T | 6181 | A Swift Message | 1436 | 56.5, 52.6 | 128 |  |
| 58 | A | 6281 | Continue to Stormwind | 1436 | 56.5, 52.6 | 0 |  |
| 59 | O | 14 | The People's Militia | 1436 | 52.1, 76.6 | 580 |  |
| 60 | O | 92747 | Moonbrook Espionage | 1436 | 43.1, 68.8 | 362 | near #48 (went 701 yd away) |
| 61 | T | 92747 | Moonbrook Espionage | 1436 | 52.5, 53.0 | 494 |  |
| 62 | A | 92748 | Explosive Consultation | 1436 | 52.5, 53.0 | 0 |  |
| 63 | T | 153 | Red Leather Bandanas | 1436 | 54.0, 53.0 | 52 |  |
| 64 | T | 14 | The People's Militia | 1436 | 56.3, 47.5 | 151 | near #58 (went 694 yd away) |
| 65 | T | 9 | The Killing Fields | 1436 | 56.0, 31.2 | 380 | near #13 (went 1569 yd away) |
| 66 | T | 22 | Goretusk Liver Pie | 1436 | 56.4, 30.5 | 21 | near #13 (went 1591 yd away) |
| 67 | T | 36 | Westfall Stew | 1436 | 56.4, 30.5 | 0 |  |
| 68 | T | 151 | Poor Old Blanchy | 1436 | 59.9, 19.4 | 286 | near #18 (went 1873 yd away) |
| 69 | T | 64 | The Forgotten Heirloom | 1436 | 60.0, 19.4 | 1 | near #18 (went 1875 yd away) |
| 70 | T | 78142 | Bewitchments and Glamours | 1453 | 48.9, 86.5 | 854 |  |
| 71 | T | 79093 | Rumi of Gnomeregan: The Collected Works | 1453 | 48.9, 86.5 | 0 |  |
| 72 | T | 6281 | Continue to Stormwind | 1453 | 77.2, 61.0 | 572 |  |
| 73 | T | 92748 | Explosive Consultation | 1453 | 61.9, 30.6 | 441 |  |

Walking between tasks: 15483 yd (~37 min at 7 yd/s).

## Logistics

- step 5: `sethearth 1436 52.86 53.71`
- step 37: `level 14` — About 39 mobs here (Murloc Netter, level 14)

## Warnings

None.
