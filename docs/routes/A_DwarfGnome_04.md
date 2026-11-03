# A_DwarfGnome_04 — Westfall

Generated on 2026-11-03 from QuestieDB commit `c5de61ab7c629132a772cccddf7f604ac48cecf9` by `tools/routebuilder/build.lua`. Simulated race: Dwarf.

| Item | Value |
|---|---|
| Level band | 14-16 |
| Simulated level | 15.00 -> 16.61 |
| Time | 74 min |
| XP gained | 21281 |
| XP/h | 17158 |
| Steps | 38 |
| Quests turned in | 12 |
| Hubs | 8 |
| Median ratio (XP/s) | 6.12 |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 12 | The People's Militia | 12 | 910 | 15 |
| 2 | 92742 | Testing the Wells | 12 | 910 est. | 15 |
| 3 | 92744 | Murloc Gills | 12 | 910 est. | 15 |
| 4 | 136 | Captain Sander's Hidden Treasure | 16 | 580 | 15 |
| 5 | 138 | Captain Sander's Hidden Treasure | 16 | 580 | 15 |
| 6 | 139 | Captain Sander's Hidden Treasure | 16 | 580 | 16 |
| 7 | 13 | The People's Militia | 14 | 980 | 16 |
| 8 | 92745 | The State of the Mines | 14 | 980 est. | 16 |
| 9 | 92747 | Moonbrook Espionage | 15 | 1050 est. | 16 |
| 10 | 14 | The People's Militia | 17 | 1600 | 16 |
| 11 | 64 | The Forgotten Heirloom | 12 | 910 | 16 |
| 12 | 92748 | Explosive Consultation | 16 | 580 est. | 16 |

## Dropped quests

| Quest | Name | Lvl | Reason |
|---|---|---|---|
| 36 | Westfall Stew | 10 | quest level 10 below the band |
| 48 | Sweet Amber | 44 | quest level 44 above the band |
| 49 | Sweet Amber | 44 | quest level 44 above the band |
| 50 | Sweet Amber | 44 | quest level 44 above the band |
| 51 | Sweet Amber | 44 | quest level 44 above the band |
| 53 | Sweet Amber | 44 | quest level 44 above the band |
| 65 | The Defias Brotherhood | 18 | finisher outside the chapter zones |
| 68 | The Legend of Stalvan | 28 | quest level 28 above the band |
| 104 | The Coastal Menace | 20 | quest level 20 above the band |
| 109 | Report to Gryan Stoutmantle | 10 | quest level 10 below the band |
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
| 92109 | My First Alchemy Set | 10 | quest level 10 below the band |
| 92110 | My First Real Potion | 10 | quest level 10 below the band |
| 92910 | Harvesting the Harvesters | 15 | requires a profession |
| 92911 | Harvesting the Harvesters | 15 | requires a profession |
| 93928 | Of Mice and Milk | 15 | Questie blacklist |
| 94503 | Call of Water | 23 | class quest (ClassQuestData.lua) |
| 38 | Westfall Stew | 13 | prerequisite unavailable |
| 135 | The Defias Brotherhood | 18 | prerequisite unavailable |
| 142 | The Defias Brotherhood | 18 | prerequisite unavailable |
| 155 | The Defias Brotherhood | 18 | prerequisite unavailable |
| 214 | Red Silk Bandanas | 17 | prerequisite unavailable |
| 92753 | Destruction in Deadmines | 18 | prerequisite unavailable |
| 92819 | Destruction in Deadmines | 18 | prerequisite unavailable |
| 151 | Poor Old Blanchy | 14 | level band reached |
| 103 | Keeper of the Flame | 16 | level band reached |
| 102 | Patrolling Westfall | 14 | level band reached |
| 140 | Captain Sander's Hidden Treasure | 16 | level band reached |
| 9 | The Killing Fields | 15 | level band reached |
| 152 | The Coast Isn't Clear | 19 | level band reached |
| 153 | Red Leather Bandanas | 15 | level band reached |
| 22 | Goretusk Liver Pie | 12 | level band reached |
| 92909 | Harvesting the Harvesters | 15 | level band reached |

## Candidate ratios

Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;
marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are
below 0.35 × the median ratio, or when an objective is more than 900 yd from every hub.

| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |
|---|---|---|---|---|---|---|---|---|---|---|
| 9 | The Killing Fields | 15 | 3150 | 0 | 632 | 446 | 4.98 | 7.06 | 1 | level band reached |
| 12 | The People's Militia | 12 | 4218 | 1283 | 905 | 779 | 5.94 | 6.96 | 2 |  |
| 13 | The People's Militia | 14 | 5188 | 1283 | 802 | 684 | 7.21 | 8.51 | 1 |  |
| 14 | The People's Militia | 17 | 6093 | 1283 | 726 | 608 | 8.39 | 10.02 | 1 |  |
| 22 | Goretusk Liver Pie | 12 | 2785 | 0 | 600 | 556 | 4.64 | 5.00 | 1 | level band reached |
| 64 | The Forgotten Heirloom | 12 | 910 | 0 | 122 | 40 | 7.43 | 22.24 | 1 |  |
| 102 | Patrolling Westfall | 14 | 5203 | 1283 | 861 | 680 | 6.04 | 7.65 | 1 | level band reached |
| 103 | Keeper of the Flame | 16 | 2230 | 0 | 723 | 250 | 3.08 | 8.92 | 1 | level band reached |
| 136 | Captain Sander's Hidden Treasure | 16 | 1030 | 0 | 251 | 170 | 5.05 | 8.94 | 0 |  |
| 138 | Captain Sander's Hidden Treasure | 16 | 580 | 0 | 83 | 10 | 6.50 | 16.53 | 0 |  |
| 139 | Captain Sander's Hidden Treasure | 16 | 580 | 0 | 112 | 10 | 6.23 | 11.58 | 0 |  |
| 140 | Captain Sander's Hidden Treasure | 16 | 1150 | 0 | 156 | 156 | 7.34 | 7.34 | 0 | level band reached |
| 151 | Poor Old Blanchy | 14 | 1250 | 0 | 133 | 133 | 9.35 | 9.35 | 1 | level band reached |
| 152 | The Coast Isn't Clear | 19 | 4837 | 0 | 1255 | 830 | 3.85 | 5.83 | 4 | level band reached |
| 153 | Red Leather Bandanas | 15 | 4493 | 1283 | 961 | 800 | 4.67 | 5.61 | 1 | level band reached |
| 92742 | Testing the Wells | 12 | 2193 | 1283 | 283 | 83 | 6.80 | 17.74 | 2 |  |
| 92744 | Murloc Gills | 12 | 3453 | 1283 | 592 | 356 | 6.12 | 12.01 | 1 |  |
| 92745 | The State of the Mines | 14 | 3193 | 1283 | 560 | 297 | 6.39 | 15.08 | 2 |  |
| 92747 | Moonbrook Espionage | 15 | 2333 | 1283 | 256 | 117 | 7.50 | 29.61 | 1 |  |
| 92748 | Explosive Consultation | 16 | 2014 | 1434 | 346 | 12 | 5.81 | 158.28 | 0 |  |
| 92909 | Harvesting the Harvesters | 15 | 3780 | 0 | 883 | 883 | 4.28 | 4.28 | 1 | level band reached |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | F |  | flight path | 1453 | 71.3, 72.2 | 421 |  |
| 2 | A | 64 | The Forgotten Heirloom | 1436 | 60.0, 19.4 | 1107 |  |
| 3 | A | 12 | The People's Militia | 1436 | 56.3, 47.5 | 669 |  |
| 4 | A | 92742 | Testing the Wells | 1436 | 52.5, 53.0 | 185 |  |
| 5 | A | 92744 | Murloc Gills | 1436 | 52.5, 53.0 | 0 |  |
| 6 | O | 92742 | Testing the Wells | 1436 | 56.6, 18.7 | 827 | near #2 (went 812 yd away) |
| 7 | O | 64 | The Forgotten Heirloom | 1436 | 49.3, 19.3 | 255 |  |
| 8 | O | 12 | The People's Militia | 1436 | 44.8, 26.0 | 222 |  |
| 9 | O | 92744 | Murloc Gills | 1436 | 34.5, 17.0 | 415 |  |
| 10 | A | 136 | Captain Sander's Hidden Treasure | 1436 | 34.5, 17.0 | 0 |  |
| 11 | O | 12 | The People's Militia | 1436 | 31.6, 33.8 | 404 |  |
| 12 | O | 92742 | Testing the Wells | 1436 | 46.1, 38.1 | 516 |  |
| 13 | T | 12 | The People's Militia | 1436 | 56.3, 47.5 | 420 | near #3 (went 1043 yd away) |
| 14 | A | 13 | The People's Militia | 1436 | 56.3, 47.5 | 0 | near #3 (went 1043 yd away) |
| 15 | T | 92742 | Testing the Wells | 1436 | 52.5, 53.0 | 185 | near #5 (went 1048 yd away) |
| 16 | T | 92744 | Murloc Gills | 1436 | 52.5, 53.0 | 0 | near #5 (went 1048 yd away) |
| 17 | A | 92745 | The State of the Mines | 1436 | 52.5, 53.0 | 0 |  |
| 18 | O | 13 | The People's Militia | 1436 | 43.7, 68.9 | 482 |  |
| 19 | T | 136 | Captain Sander's Hidden Treasure | 1436 | 25.9, 47.8 | 794 |  |
| 20 | A | 138 | Captain Sander's Hidden Treasure | 1436 | 25.9, 47.8 | 0 |  |
| 21 | O | 92745 | The State of the Mines | 1436 | 30.0, 47.3 | 143 |  |
| 22 | T | 138 | Captain Sander's Hidden Treasure | 1436 | 40.5, 47.8 | 368 |  |
| 23 | A | 139 | Captain Sander's Hidden Treasure | 1436 | 40.5, 47.8 | 0 |  |
| 24 | T | 139 | Captain Sander's Hidden Treasure | 1436 | 40.6, 17.0 | 717 |  |
| 25 | O | 92745 | The State of the Mines | 1436 | 45.3, 20.0 | 177 | near #8 (went 1141 yd away) |
| 26 | T | 13 | The People's Militia | 1436 | 56.3, 47.5 | 748 | near #14 (went 1064 yd away) |
| 27 | A | 14 | The People's Militia | 1436 | 56.3, 47.5 | 0 | near #14 (went 1064 yd away) |
| 28 | F |  | flight path | 1436 | 56.5, 52.6 | 119 |  |
| 29 | T | 92745 | The State of the Mines | 1436 | 52.5, 53.0 | 142 | near #17 (went 937 yd away) |
| 30 | A | 92747 | Moonbrook Espionage | 1436 | 52.5, 53.0 | 0 |  |
| 31 | O | 14 | The People's Militia | 1436 | 52.1, 76.6 | 551 |  |
| 32 | O | 92747 | Moonbrook Espionage | 1436 | 43.1, 68.8 | 362 | near #18 (went 1212 yd away) |
| 33 | T | 92747 | Moonbrook Espionage | 1436 | 52.5, 53.0 | 494 |  |
| 34 | A | 92748 | Explosive Consultation | 1436 | 52.5, 53.0 | 0 |  |
| 35 | T | 14 | The People's Militia | 1436 | 56.3, 47.5 | 185 | near #28 (went 694 yd away) |
| 36 | T | 64 | The Forgotten Heirloom | 1436 | 60.0, 19.4 | 669 | near #6 (went 1364 yd away) |
| 37 | T | 92748 | Explosive Consultation | 1453 | 61.9, 30.6 | 1526 |  |

Walking between tasks: 13116 yd (~31 min at 7 yd/s).

## Logistics

- step 1: `fp 1453 71.29 72.23`
- step 3: `fp 1436 56.55 52.64`
- step 7: `sethearth 1436 52.86 53.71`

## Warnings

None.
