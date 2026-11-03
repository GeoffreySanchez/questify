# A_Human_03 — Westfall

Generated on 2026-11-03 from QuestieDB commit `c5de61ab7c629132a772cccddf7f604ac48cecf9` by `tools/routebuilder/build.lua`. Simulated race: Human.

| Item | Value |
|---|---|
| Level band | 11-16 |
| Simulated level | 12.00 -> 16.04 |
| Time | 130 min |
| XP gained | 49119 |
| XP/h | 22606 |
| Steps | 69 |
| Quests turned in | 23 |
| Hubs | 8 |
| Median ratio (XP/s) | 5.29 |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 136 | Captain Sander's Hidden Treasure | 16 | 580 | 12 |
| 2 | 138 | Captain Sander's Hidden Treasure | 16 | 580 | 13 |
| 3 | 12 | The People's Militia | 12 | 910 | 13 |
| 4 | 6181 | A Swift Message | 10 | 210 | 13 |
| 5 | 92744 | Murloc Gills | 12 | 910 est. | 13 |
| 6 | 92742 | Testing the Wells | 12 | 910 est. | 13 |
| 7 | 13 | The People's Militia | 14 | 980 | 14 |
| 8 | 139 | Captain Sander's Hidden Treasure | 16 | 580 | 14 |
| 9 | 140 | Captain Sander's Hidden Treasure | 16 | 1150 | 14 |
| 10 | 103 | Keeper of the Flame | 16 | 1150 | 14 |
| 11 | 152 | The Coast Isn't Clear | 19 | 1450 | 15 |
| 12 | 92745 | The State of the Mines | 14 | 980 est. | 15 |
| 13 | 92747 | Moonbrook Espionage | 15 | 1050 est. | 15 |
| 14 | 153 | Red Leather Bandanas | 15 | 1050 | 15 |
| 15 | 102 | Patrolling Westfall | 14 | 980 | 15 |
| 16 | 14 | The People's Militia | 17 | 1600 | 15 |
| 17 | 9 | The Killing Fields | 15 | 1050 | 15 |
| 18 | 22 | Goretusk Liver Pie | 12 | 910 | 15 |
| 19 | 36 | Westfall Stew | 10 | 420 | 15 |
| 20 | 151 | Poor Old Blanchy | 14 | 1250 | 15 |
| 21 | 64 | The Forgotten Heirloom | 12 | 910 | 15 |
| 22 | 6281 | Continue to Stormwind | 10 | 420 | 16 |
| 23 | 92748 | Explosive Consultation | 16 | 580 est. | 16 |

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
| 104 | The Coastal Menace | 20 | quest level 20 above the band |
| 117 | Thunderbrew | 15 | repeatable |
| 144 | Messenger to Westfall | 14 | finisher outside the chapter zones |
| 166 | The Defias Brotherhood | 22 | quest level 22 above the band |
| 1651 | The Tome of Valor | 25 | class quest (ClassQuestData.lua) |
| 1652 | The Tome of Valor | 25 | class quest (ClassQuestData.lua) |
| 2359 | Klaven's Tower | 24 | class quest (ClassQuestData.lua) |
| 3861 | CLUCK! | 1 | quest level 1 below the band |
| 8675 | Skychaser the Elder | 60 | Questie blacklist |
| 78142 | Bewitchments and Glamours | 20 | quest level 20 above the band |
| 79008 | ... and that note you found | 22 | quest level 22 above the band |
| 79093 | Rumi of Gnomeregan: The Collected Works | 20 | quest level 20 above the band |
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
| 9 | The Killing Fields | 15 | 3350 | 0 | 633 | 448 | 5.29 | 7.46 | 1 |  |
| 12 | The People's Militia | 12 | 3850 | 0 | 911 | 683 | 5.04 | 6.27 | 2 |  |
| 13 | The People's Militia | 14 | 4355 | 0 | 808 | 696 | 5.84 | 6.82 | 1 |  |
| 14 | The People's Militia | 17 | 4795 | 0 | 732 | 620 | 6.55 | 7.73 | 1 |  |
| 22 | Goretusk Liver Pie | 12 | 3535 | 0 | 598 | 559 | 5.90 | 6.32 | 1 |  |
| 36 | Westfall Stew | 10 | 420 | 0 | 51 | 11 | 5.21 | 5.82 | 0 |  |
| 38 | Westfall Stew | 13 | 4857 | 0 | 974 | 920 | 4.99 | 5.28 | 3 | level band reached |
| 64 | The Forgotten Heirloom | 12 | 910 | 0 | 122 | 41 | 7.43 | 22.19 | 1 |  |
| 102 | Patrolling Westfall | 14 | 4200 | 0 | 865 | 689 | 4.85 | 6.09 | 1 |  |
| 103 | Keeper of the Flame | 16 | 2470 | 0 | 723 | 250 | 3.41 | 9.88 | 1 |  |
| 136 | Captain Sander's Hidden Treasure | 16 | 1130 | 0 | 251 | 170 | 5.29 | 10.62 | 0 |  |
| 138 | Captain Sander's Hidden Treasure | 16 | 580 | 0 | 83 | 10 | 6.50 | 28.93 | 0 |  |
| 139 | Captain Sander's Hidden Treasure | 16 | 580 | 0 | 112 | 10 | 6.23 | 22.26 | 0 |  |
| 140 | Captain Sander's Hidden Treasure | 16 | 1150 | 0 | 156 | 74 | 7.34 | 15.42 | 0 |  |
| 151 | Poor Old Blanchy | 14 | 1250 | 0 | 133 | 133 | 9.36 | 9.36 | 1 |  |
| 152 | The Coast Isn't Clear | 19 | 5025 | 0 | 1255 | 701 | 4.00 | 7.17 | 4 |  |
| 153 | Red Leather Bandanas | 15 | 4326 | 0 | 961 | 800 | 4.50 | 5.40 | 1 |  |
| 6181 | A Swift Message | 10 | 210 | 0 | 47 | 47 | 5.57 | 20.13 | 0 |  |
| 6281 | Continue to Stormwind | 10 | 1829 | 1409 | 314 | 38 | 5.82 | 48.11 | 0 |  |
| 92742 | Testing the Wells | 12 | 910 | 0 | 283 | 33 | 3.96 | 12.02 | 2 |  |
| 92744 | Murloc Gills | 12 | 2450 | 0 | 592 | 356 | 4.22 | 8.28 | 1 |  |
| 92745 | The State of the Mines | 14 | 2090 | 0 | 560 | 297 | 4.29 | 10.13 | 2 |  |
| 92747 | Moonbrook Espionage | 15 | 1050 | 0 | 256 | 117 | 5.20 | 20.53 | 1 |  |
| 92748 | Explosive Consultation | 16 | 2206 | 1626 | 346 | 12 | 6.37 | 173.39 | 0 |  |
| 92909 | Harvesting the Harvesters | 15 | 4748 | 0 | 884 | 884 | 5.37 | 5.37 | 1 | level band reached |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | A | 12 | The People's Militia | 1436 | 56.3, 47.5 | 0 |  |
| 2 | A | 153 | Red Leather Bandanas | 1436 | 54.0, 53.0 | 151 |  |
| 3 | A | 92744 | Murloc Gills | 1436 | 52.5, 53.0 | 52 |  |
| 4 | A | 92742 | Testing the Wells | 1436 | 52.5, 53.0 | 21 |  |
| 5 | A | 9 | The Killing Fields | 1436 | 56.0, 31.2 | 522 |  |
| 6 | A | 22 | Goretusk Liver Pie | 1436 | 56.4, 30.5 | 21 |  |
| 7 | A | 151 | Poor Old Blanchy | 1436 | 59.9, 19.4 | 286 |  |
| 8 | A | 36 | Westfall Stew | 1436 | 59.9, 19.4 | 0 |  |
| 9 | A | 64 | The Forgotten Heirloom | 1436 | 60.0, 19.4 | 1 |  |
| 10 | O | 151 | Poor Old Blanchy | 1436 | 57.3, 18.3 | 97 |  |
| 11 | O | 92742 | Testing the Wells | 1436 | 56.6, 18.7 | 24 |  |
| 12 | O | 64 | The Forgotten Heirloom | 1436 | 49.3, 19.3 | 255 |  |
| 13 | O | 153 | Red Leather Bandanas | 1436 | 45.3, 22.8 | 161 |  |
| 14 | O | 12 | The People's Militia | 1436 | 44.8, 26.0 | 76 |  |
| 15 | A | 136 | Captain Sander's Hidden Treasure | 1436 | 34.5, 17.0 | 415 |  |
| 16 | O | 92744 | Murloc Gills | 1436 | 34.5, 17.0 | 0 |  |
| 17 | O | 12 | The People's Militia | 1436 | 31.6, 33.8 | 404 |  |
| 18 | T | 136 | Captain Sander's Hidden Treasure | 1436 | 25.9, 47.8 | 382 |  |
| 19 | A | 138 | Captain Sander's Hidden Treasure | 1436 | 25.9, 47.8 | 0 |  |
| 20 | O | 9 | The Killing Fields | 1436 | 38.8, 51.5 | 458 |  |
| 21 | T | 138 | Captain Sander's Hidden Treasure | 1436 | 40.5, 47.8 | 106 |  |
| 22 | A | 139 | Captain Sander's Hidden Treasure | 1436 | 40.5, 47.8 | 0 |  |
| 23 | O | 92742 | Testing the Wells | 1436 | 46.1, 38.1 | 297 |  |
| 24 | O | 22 | Goretusk Liver Pie | 1436 | 53.7, 42.9 | 289 | near #1 (went 978 yd away) |
| 25 | T | 12 | The People's Militia | 1436 | 56.3, 47.5 | 141 | near #1 (went 1064 yd away) |
| 26 | A | 13 | The People's Militia | 1436 | 56.3, 47.5 | 0 |  |
| 27 | A | 102 | Patrolling Westfall | 1436 | 56.4, 47.6 | 3 |  |
| 28 | A | 6181 | A Swift Message | 1436 | 57.0, 47.2 | 22 |  |
| 29 | T | 6181 | A Swift Message | 1436 | 56.5, 52.6 | 128 |  |
| 30 | A | 6281 | Continue to Stormwind | 1436 | 56.5, 52.6 | 0 |  |
| 31 | O | 13 | The People's Militia | 1436 | 43.7, 68.9 | 588 |  |
| 32 | A | 152 | The Coast Isn't Clear | 1436 | 30.0, 86.0 | 623 |  |
| 33 | A | 103 | Keeper of the Flame | 1436 | 30.0, 86.0 | 0 |  |
| 34 | T | 92744 | Murloc Gills | 1436 | 52.5, 53.0 | 1101 | near #30 (went 1101 yd away) |
| 35 | T | 92742 | Testing the Wells | 1436 | 52.5, 53.0 | 0 | near #30 (went 1101 yd away) |
| 36 | A | 92745 | The State of the Mines | 1436 | 52.5, 53.0 | 0 |  |
| 37 | T | 13 | The People's Militia | 1436 | 56.3, 47.5 | 185 | near #30 (went 1286 yd away) |
| 38 | A | 14 | The People's Militia | 1436 | 56.3, 47.5 | 0 | near #30 (went 1286 yd away) |
| 39 | O | 103 | Keeper of the Flame | 1436 | 52.8, 23.8 | 566 |  |
| 40 | O | 92745 | The State of the Mines | 1436 | 45.3, 20.0 | 278 | near #14 (went 1629 yd away) |
| 41 | O | 152 | The Coast Isn't Clear | 1436 | 43.5, 9.6 | 251 |  |
| 42 | T | 139 | Captain Sander's Hidden Treasure | 1436 | 40.6, 17.0 | 201 |  |
| 43 | A | 140 | Captain Sander's Hidden Treasure | 1436 | 40.6, 17.0 | 0 |  |
| 44 | T | 140 | Captain Sander's Hidden Treasure | 1436 | 26.0, 16.9 | 513 |  |
| 45 | O | 152 | The Coast Isn't Clear | 1436 | 29.8, 27.6 | 283 |  |
| 46 | O | 92745 | The State of the Mines | 1436 | 30.0, 47.3 | 459 | near #19 (went 998 yd away) |
| 47 | O | 152 | The Coast Isn't Clear | 1436 | 27.2, 53.7 | 177 | near #19 (went 1175 yd away) |
| 48 | O | 102 | Patrolling Westfall | 1436 | 31.0, 68.8 | 376 |  |
| 49 | O | 152 | The Coast Isn't Clear | 1436 | 27.3, 70.9 | 139 |  |
| 50 | T | 103 | Keeper of the Flame | 1436 | 30.0, 86.0 | 364 | near #33 (went 1844 yd away) |
| 51 | T | 152 | The Coast Isn't Clear | 1436 | 30.0, 86.0 | 0 | near #33 (went 1844 yd away) |
| 52 | O | 14 | The People's Militia | 1436 | 52.1, 76.6 | 802 |  |
| 53 | T | 92745 | The State of the Mines | 1436 | 52.5, 53.0 | 551 | near #36 (went 1252 yd away) |
| 54 | A | 92747 | Moonbrook Espionage | 1436 | 52.5, 53.0 | 0 | near #36 (went 1252 yd away) |
| 55 | O | 92747 | Moonbrook Espionage | 1436 | 43.1, 68.8 | 494 | near #31 (went 1382 yd away) |
| 56 | T | 92747 | Moonbrook Espionage | 1436 | 52.5, 53.0 | 494 |  |
| 57 | A | 92748 | Explosive Consultation | 1436 | 52.5, 53.0 | 0 |  |
| 58 | T | 153 | Red Leather Bandanas | 1436 | 54.0, 53.0 | 52 |  |
| 59 | T | 102 | Patrolling Westfall | 1436 | 56.4, 47.6 | 151 | near #38 (went 1287 yd away) |
| 60 | T | 14 | The People's Militia | 1436 | 56.3, 47.5 | 3 | near #38 (went 1286 yd away) |
| 61 | T | 9 | The Killing Fields | 1436 | 56.0, 31.2 | 380 | near #6 (went 1569 yd away) |
| 62 | T | 22 | Goretusk Liver Pie | 1436 | 56.4, 30.5 | 21 | near #6 (went 1591 yd away) |
| 63 | T | 36 | Westfall Stew | 1436 | 56.4, 30.5 | 0 |  |
| 64 | T | 151 | Poor Old Blanchy | 1436 | 59.9, 19.4 | 286 | near #11 (went 1873 yd away) |
| 65 | T | 64 | The Forgotten Heirloom | 1436 | 60.0, 19.4 | 1 | near #11 (went 1875 yd away) |
| 66 | T | 6281 | Continue to Stormwind | 1453 | 77.2, 61.0 | 1268 |  |
| 67 | T | 92748 | Explosive Consultation | 1453 | 61.9, 30.6 | 441 |  |

Walking between tasks: 15385 yd (~37 min at 7 yd/s).

## Logistics

- step 4: `sethearth 1436 52.86 53.71`
- step 35: `hearth 1436`

## Warnings

None.
