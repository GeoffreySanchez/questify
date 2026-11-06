# H_Tauren_01 — Camp Narache

Generated on 2026-11-07 from QuestieDB commit `80866960788084ae1592abf66a08f0d306458a95` by `tools/routebuilder/build.lua`. Simulated race: Tauren.

| Item | Value |
|---|---|
| Level band | 1-6 |
| Simulated level | 1.00 -> 7.34 |
| Time | 65 min |
| XP gained | 12712 |
| XP/h | 11775 |
| Steps | 38 |
| Quests turned in | 15 |
| Hubs | 5 |
| Median ratio (XP/s) | 2.90 |
| Hearthstone | no new bind; 0 return(s) planned, 0 bundle(s) |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 752 | A Humble Task | 2 | 85 | 3 |
| 2 | 747 | The Hunt Begins | 2 | 170 | 3 |
| 3 | 753 | A Humble Task | 3 | 250 | 3 |
| 4 | 755 | Rites of the Earthmother | 3 | 250 | 3 |
| 5 | 750 | The Hunt Continues | 3 | 250 | 4 |
| 6 | 99079 | Longwalker Malah | 9 | 780 est. | 5 |
| 7 | 780 | The Battleboars | 4 | 445 | 6 |
| 8 | 3376 | Break Sharptusk! | 5 | 670 | 6 |
| 9 | 757 | Rite of Strength | 4 | 445 | 6 |
| 10 | 781 | Attack on Camp Narache | 4 | 355 | 6 |
| 11 | 99081 | Grim Tidings | 9 | 780 est. | 6 |
| 12 | 99101 | Our Ancient Enemy | 9 | 780 est. | 7 |
| 13 | 745 | Sharing the Land | 8 | 540 | 7 |
| 14 | 763 | Rites of the Earthmother | 5 | 335 | 7 |
| 15 | 749 | The Ravaged Caravan | 8 | 530 | 7 |

## Dropped quests

| Quest | Name | Lvl | Reason |
|---|---|---|---|
| 746 | Dwarven Digging | 8 | objective item source not in zone |
| 758 | Thunderhorn Cleansing | 8 | exploration point not in zone |
| 759 | Wildmane Totem | 10 | quest level 10 above the band |
| 760 | Wildmane Cleansing | 10 | quest level 10 above the band |
| 764 | The Venture Co. | 10 | quest level 10 above the band |
| 765 | Supervisor Fizsprocket | 12 | quest level 12 above the band |
| 861 | The Hunter's Way | 10 | quest level 10 above the band |
| 1462 | Earth Sapta | 4 | class quest (ClassQuestData.lua) |
| 1505 | Veteran Uzzek | 10 | class quest (ClassQuestData.lua) |
| 1518 | Call of Earth | 4 | class quest (ClassQuestData.lua) |
| 1519 | Call of Earth | 4 | class quest (ClassQuestData.lua) |
| 1520 | Call of Earth | 4 | class quest (ClassQuestData.lua) |
| 1521 | Call of Earth | 4 | class quest (ClassQuestData.lua) |
| 2984 | Call of Fire | 10 | class quest (ClassQuestData.lua) |
| 2986 | Call of Water | 20 | class quest (ClassQuestData.lua) |
| 3091 | Simple Note | 1 | class quest (ClassQuestData.lua) |
| 3092 | Etched Note | 1 | class quest (ClassQuestData.lua) |
| 3093 | Rune-Inscribed Note | 1 | class quest (ClassQuestData.lua) |
| 3094 | Verdant Note | 1 | class quest (ClassQuestData.lua) |
| 5928 | Heeding the Call | 10 | class quest (ClassQuestData.lua) |
| 7662 | New Kodo - Teal | 1 | Questie blacklist |
| 7663 | New Kodo - Green | 1 | Questie blacklist |
| 96661 | Camping 101: Cooking | 6 | objective npc not in zone |
| 97927 | Camping 101: Alchemy | 6 | requires a profession |
| 97928 | Camping 101: Blacksmithing | 6 | requires a profession |
| 97929 | Camping 101: Enchanting | 6 | requires a profession |
| 97930 | Camping 101: Engineering | 6 | requires a profession |
| 97931 | Camping 101: First Aid | 6 | requires a profession |
| 97932 | Camping 101: Fishing | 6 | requires a profession |
| 97933 | Camping 101: Herbalism | 6 | requires a profession |
| 97934 | Camping 101: Leatherworking | 6 | requires a profession |
| 97935 | Camping 101: Mining | 6 | requires a profession |
| 97936 | Camping 101: Skinning | 6 | requires a profession |
| 97937 | Camping 101: Tailoring | 6 | requires a profession |
| 98427 | Ceasing Operations | 12 | quest level 12 above the band |
| 98435 | Thunderhorn's Report | 10 | quest level 10 above the band |
| 99080 | Drive Them Out | 11 | quest level 11 above the band |
| 99082 | The High Chieftain | 11 | quest level 11 above the band |
| 1656 | A Task Unfinished | 5 | low ratio |
| 99108 | Sparring Match | 6 | level band reached |
| 96659 | The Adventurer | 6 | level band reached |
| 96605 | The Great Outdoors | 6 | level band reached |
| 95805 | Grace of An'she and Mu'sha | 4 | level band reached |
| 767 | Rite of Vision | 6 | level band reached |
| 761 | Swoop Hunting | 6 | level band reached |
| 98430 | The Longwalkers | 8 | level band reached |
| 743 | Dangers of the Windfury | 8 | level band reached |
| 754 | Winterhoof Cleansing | 6 | level band reached |
| 756 | Thunderhorn Totem | 7 | level band reached |
| 748 | Poison Water | 5 | level band reached |

## Candidate ratios

Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;
marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are
below 0.35 × the median ratio, or when an objective is more than 900 yd from every hub.

| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |
|---|---|---|---|---|---|---|---|---|---|---|
| 743 | Dangers of the Windfury | 8 | 1740 | 0 | 632 | 454 | 2.75 | 3.83 | 1 | level band reached |
| 745 | Sharing the Land | 8 | 1961 | 0 | 802 | 576 | 2.44 | 3.40 | 2 |  |
| 747 | The Hunt Begins | 2 | 1720 | 0 | 720 | 720 | 2.39 | 2.62 | 1 |  |
| 748 | Poison Water | 5 | 2230 | 0 | 881 | 721 | 2.90 | 3.40 | 2 | level band reached |
| 749 | The Ravaged Caravan | 8 | 706 | 176 | 104 | 27 | 6.75 | 25.62 | 0 |  |
| 750 | The Hunt Continues | 3 | 1075 | 0 | 489 | 364 | 2.40 | 2.88 | 1 |  |
| 752 | A Humble Task | 2 | 212 | 127 | 62 | 16 | 2.46 | 5.27 | 0 |  |
| 753 | A Humble Task | 3 | 250 | 0 | 107 | 61 | 2.34 | 4.77 | 1 |  |
| 754 | Winterhoof Cleansing | 6 | 540 | 0 | 124 | 116 | 3.34 | 3.74 | 1 | level band reached |
| 755 | Rites of the Earthmother | 3 | 250 | 0 | 93 | 16 | 2.34 | 4.92 | 0 |  |
| 756 | Thunderhorn Totem | 7 | 4205 | 0 | 1310 | 1163 | 3.21 | 3.61 | 1 | level band reached |
| 757 | Rite of Strength | 4 | 1545 | 0 | 738 | 477 | 2.65 | 4.43 | 1 |  |
| 761 | Swoop Hunting | 6 | 1300 | 0 | 306 | 306 | 4.24 | 4.24 | 1 | level band reached |
| 763 | Rites of the Earthmother | 5 | 544 | 209 | 100 | 26 | 5.06 | 14.73 | 0 |  |
| 767 | Rite of Vision | 6 | 88 | 33 | 28 | 20 | 3.14 | 4.34 | 0 | level band reached |
| 780 | The Battleboars | 4 | 2205 | 0 | 858 | 780 | 2.57 | 2.83 | 1 |  |
| 781 | Attack on Camp Narache | 4 | 355 | 0 | 274 | 113 | 1.29 | 3.12 | 0 |  |
| 1656 | A Task Unfinished | 5 | 110 | 0 | 186 | 129 | 0.59 | 0.85 | 0 | low ratio |
| 3376 | Break Sharptusk! | 5 | 730 | 0 | 326 | 86 | 2.23 | 8.45 | 1 |  |
| 95805 | Grace of An'she and Mu'sha | 4 | 180 | 0 | 216 | 30 | 0.83 | 5.81 | 0 | level band reached |
| 96605 | The Great Outdoors | 6 | 540 | 0 | 63 | 63 | 8.56 | 8.56 | 1 | level band reached |
| 96659 | The Adventurer | 6 | 284 | 149 | 91 | 17 | 4.88 | 10.76 | 0 | level band reached |
| 98430 | The Longwalkers | 8 | 700 | 0 | 168 | 168 | 4.15 | 4.15 | 1 | level band reached |
| 99079 | Longwalker Malah | 9 | 780 | 0 | 109 | 16 | 8.69 | 44.42 | 0 |  |
| 99081 | Grim Tidings | 9 | 780 | 0 | 109 | 16 | 10.67 | 42.36 | 0 |  |
| 99101 | Our Ancient Enemy | 9 | 780 | 0 | 21 | 21 | 36.99 | 36.99 | 0 |  |
| 99108 | Sparring Match | 6 | 540 | 0 | 49 | 49 | 10.85 | 10.85 | 1 | level band reached |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | A | 752 | A Humble Task | 1412 | 43.9, 76.7 | 1 |  |
| 2 | A | 747 | The Hunt Begins | 1412 | 44.5, 77.5 | 49 |  |
| 3 | O | 747 | The Hunt Begins | 1412 | 44.8, 84.5 | 289 |  |
| 4 | T | 752 | A Humble Task | 1412 | 48.8, 80.9 | 286 |  |
| 5 | A | 753 | A Humble Task | 1412 | 48.8, 80.9 | 0 |  |
| 6 | O | 753 | A Humble Task | 1412 | 49.0, 81.2 | 16 |  |
| 7 | T | 747 | The Hunt Begins | 1412 | 44.5, 77.5 | 315 |  |
| 8 | A | 750 | The Hunt Continues | 1412 | 44.5, 77.5 | 0 |  |
| 9 | A | 3376 | Break Sharptusk! | 1412 | 44.2, 77.0 | 26 |  |
| 10 | T | 753 | A Humble Task | 1412 | 43.9, 76.7 | 23 |  |
| 11 | A | 755 | Rites of the Earthmother | 1412 | 43.9, 76.7 | 0 |  |
| 12 | T | 755 | Rites of the Earthmother | 1412 | 42.5, 90.1 | 558 |  |
| 13 | A | 757 | Rite of Strength | 1412 | 42.5, 90.1 | 0 |  |
| 14 | O | 750 | The Hunt Continues | 1412 | 50.8, 88.7 | 513 |  |
| 15 | T | 750 | The Hunt Continues | 1412 | 44.5, 77.5 | 602 | near #11 (went 602 yd away) |
| 16 | A | 780 | The Battleboars | 1412 | 44.5, 77.5 | 0 | near #11 (went 602 yd away) |
| 17 | A | 99079 | Longwalker Malah | 1412 | 46.7, 63.8 | 577 |  |
| 18 | A | 745 | Sharing the Land | 1412 | 46.7, 63.4 | 18 |  |
| 19 | O | 745 | Sharing the Land | 1412 | 36.0, 65.0 | 661 |  |
| 20 | O | 745 | Sharing the Land | 1412 | 51.9, 73.7 | 1044 |  |
| 21 | A | 749 | The Ravaged Caravan | 1412 | 54.8, 64.3 | 423 |  |
| 22 | T | 99079 | Longwalker Malah | 1412 | 57.6, 63.2 | 181 |  |
| 23 | A | 99081 | Grim Tidings | 1412 | 57.6, 63.2 | 0 |  |
| 24 | O | 3376 | Break Sharptusk! | 1412 | 61.0, 78.0 | 642 |  |
| 25 | O | 757 | Rite of Strength | 1412 | 60.9, 78.4 | 19 |  |
| 26 | A | 781 | Attack on Camp Narache | 1412 | 59.8, 82.2 | 168 |  |
| 27 | O | 780 | The Battleboars | 1412 | 54.3, 86.1 | 372 |  |
| 28 | T | 780 | The Battleboars | 1412 | 44.5, 77.5 | 702 | near #16 (went 1018 yd away) |
| 29 | T | 3376 | Break Sharptusk! | 1412 | 44.2, 77.0 | 26 | near #16 (went 1037 yd away) |
| 30 | T | 757 | Rite of Strength | 1412 | 43.9, 76.7 | 23 |  |
| 31 | T | 781 | Attack on Camp Narache | 1412 | 43.9, 76.7 | 0 |  |
| 32 | A | 763 | Rites of the Earthmother | 1412 | 43.9, 76.7 | 0 |  |
| 33 | T | 99081 | Grim Tidings | 1412 | 46.7, 63.8 | 553 | near #18 (went 1104 yd away) |
| 34 | A | 99101 | Our Ancient Enemy | 1412 | 46.7, 63.8 | 0 | near #18 (went 1104 yd away) |
| 35 | T | 99101 | Our Ancient Enemy | 1412 | 46.7, 63.4 | 18 |  |
| 36 | T | 745 | Sharing the Land | 1412 | 46.7, 63.4 | 0 |  |
| 37 | T | 763 | Rites of the Earthmother | 1412 | 46.7, 63.4 | 0 |  |
| 38 | T | 749 | The Ravaged Caravan | 1412 | 51.9, 53.4 | 520 |  |

Walking between tasks: 8638 yd (~21 min at 7 yd/s).

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

None.
