# Questify vs APR Forever: comparison

Generated on 2026-11-06 by `luajit tools/apr/compare.lua`. APR (Azeroth Pilot Reloaded, free software under GPL-3.0) v7.5.5, commit `c5960471d63f836c57c6973148eacdc8f748b6f9`, read at run time from a local clone (`.cache/apr`, outside the repository) through a sandbox: nothing from APR is copied here. This page holds only counts, map IDs and quest IDs; an APR route is named by its rank in APR's play order (`nextRoute` graph), its map and its level band.

Questify: 73 chapters from `Questify/Guides/Guides.xml` (QuestieDB commit `80866960788084ae1592abf66a08f0d306458a95`). APR: 96 route files of the Forever client list, 127 routes. XP: QuestieDB Forever view of the route builder (quest XP for a player in the chapter's band, nearest to the quest level).

## Summary

A side is **clearly ahead** on a chapter when, on the same slice of the route, the quests that only it does (that the other addon does nowhere for the faction) are worth at least 15 % of the chapter's quest XP more than the other side's, with at least 5 such quests. "APR-only": general quests (not class quests) that APR does in the slice and no Questify chapter of the faction does, except those of a level more than 2 above the chapter's band. "Questify-only": general quests of the chapter that no APR route of the faction does. Only quest XP is compared: travel time, kill time and grinding are not.

- APR clearly ahead: A_Skyborne_01 (APR-only 25 quests / 12 315 XP, Questify-only 6 / 4 070 XP, chapter 46 335 XP); A_01 (APR-only 11 quests / 12 860 XP, Questify-only 4 / 3 795 XP, chapter 45 590 XP); A_02 (APR-only 13 quests / 15 120 XP, Questify-only 6 / 5 815 XP, chapter 33 640 XP); A_03 (APR-only 13 quests / 19 000 XP, Questify-only 3 / 6 000 XP, chapter 76 400 XP); A_04 (APR-only 28 quests / 45 375 XP, Questify-only 16 / 25 630 XP, chapter 51 575 XP); A_08 (APR-only 11 quests / 16 195 XP, Questify-only 4 / 8 690 XP, chapter 27 080 XP); A_07 (APR-only 13 quests / 17 475 XP, Questify-only 0 / 0 XP, chapter 12 590 XP); A_09 (APR-only 10 quests / 20 560 XP, Questify-only 1 / 630 XP, chapter 19 500 XP); A_10 (APR-only 29 quests / 38 950 XP, Questify-only 0 / 0 XP, chapter 37 430 XP); A_11 (APR-only 10 quests / 23 200 XP, Questify-only 5 / 12 950 XP, chapter 47 975 XP); A_12 (APR-only 29 quests / 57 635 XP, Questify-only 1 / 1 350 XP, chapter 56 670 XP); A_13 (APR-only 25 quests / 62 640 XP, Questify-only 1 / 1 425 XP, chapter 32 690 XP); A_15 (APR-only 7 quests / 17 760 XP, Questify-only 1 / 1 725 XP, chapter 28 785 XP); A_16 (APR-only 15 quests / 33 900 XP, Questify-only 3 / 4 500 XP, chapter 29 905 XP); A_17 (APR-only 20 quests / 53 455 XP, Questify-only 2 / 9 700 XP, chapter 58 550 XP); A_18 (APR-only 11 quests / 18 120 XP, Questify-only 3 / 7 050 XP, chapter 44 440 XP); A_19 (APR-only 9 quests / 23 345 XP, Questify-only 0 / 0 XP, chapter 81 295 XP); A_22 (APR-only 12 quests / 41 900 XP, Questify-only 1 / 280 XP, chapter 83 280 XP); A_24 (APR-only 22 quests / 101 310 XP, Questify-only 1 / 580 XP, chapter 79 700 XP); A_26 (APR-only 9 quests / 40 580 XP, Questify-only 0 / 0 XP, chapter 85 750 XP); A_27 (APR-only 52 quests / 239 815 XP, Questify-only 3 / 1 800 XP, chapter 66 300 XP); A_23 (APR-only 29 quests / 146 380 XP, Questify-only 3 / 14 900 XP, chapter 129 800 XP); A_29 (APR-only 20 quests / 96 230 XP, Questify-only 7 / 27 050 XP, chapter 75 900 XP); A_30 (APR-only 8 quests / 36 050 XP, Questify-only 2 / 13 200 XP, chapter 104 550 XP); H_OrcTroll_01 (APR-only 5 quests / 2 610 XP, Questify-only 1 / 170 XP, chapter 5 165 XP); H_Tauren_01 (APR-only 5 quests / 2 140 XP, Questify-only 0 / 0 XP, chapter 6 665 XP); H_01 (APR-only 19 quests / 14 380 XP, Questify-only 1 / 1 950 XP, chapter 47 810 XP); H_04 (APR-only 12 quests / 20 650 XP, Questify-only 4 / 6 200 XP, chapter 61 160 XP); H_08 (APR-only 9 quests / 16 375 XP, Questify-only 2 / 5 600 XP, chapter 43 975 XP); H_09 (APR-only 14 quests / 21 250 XP, Questify-only 4 / 2 615 XP, chapter 50 075 XP); H_11 (APR-only 11 quests / 27 885 XP, Questify-only 8 / 18 500 XP, chapter 44 750 XP); H_12 (APR-only 12 quests / 25 320 XP, Questify-only 3 / 5 050 XP, chapter 26 450 XP); H_14 (APR-only 12 quests / 29 795 XP, Questify-only 2 / 4 830 XP, chapter 42 540 XP); H_16 (APR-only 25 quests / 64 380 XP, Questify-only 3 / 7 050 XP, chapter 67 630 XP); H_17 (APR-only 14 quests / 44 400 XP, Questify-only 1 / 4 400 XP, chapter 68 100 XP); H_24 (APR-only 12 quests / 42 800 XP, Questify-only 4 / 14 300 XP, chapter 54 150 XP); H_25 (APR-only 7 quests / 25 900 XP, Questify-only 0 / 0 XP, chapter 31 270 XP); H_26 (APR-only 25 quests / 102 380 XP, Questify-only 1 / 4 200 XP, chapter 77 690 XP); H_27 (APR-only 9 quests / 36 330 XP, Questify-only 0 / 0 XP, chapter 85 750 XP); H_28 (APR-only 31 quests / 135 830 XP, Questify-only 3 / 12 180 XP, chapter 117 800 XP); H_29 (APR-only 44 quests / 182 010 XP, Questify-only 9 / 32 610 XP, chapter 139 420 XP)
- Questify clearly ahead: A_DwarfGnome_03 (APR-only 7 quests / 5 060 XP, Questify-only 11 / 12 125 XP, chapter 22 465 XP); A_DwarfGnome_04 (APR-only 5 quests / 4 780 XP, Questify-only 9 / 8 080 XP, chapter 15 195 XP); A_Human_03 (APR-only 10 quests / 7 650 XP, Questify-only 11 / 11 080 XP, chapter 21 740 XP); H_Undead_03 (APR-only 2 quests / 200 XP, Questify-only 10 / 8 170 XP, chapter 27 275 XP); H_15 (APR-only 1 quest / 2 280 XP, Questify-only 5 / 11 810 XP, chapter 22 460 XP)
- Close: A_DwarfGnome_01 (APR-only 1 quest / 630 XP, Questify-only 0 / 0 XP, chapter 4 255 XP); A_DwarfGnome_02 (APR-only 8 quests / 5 510 XP, Questify-only 6 / 3 805 XP, chapter 22 825 XP); A_Human_01 (APR-only 4 quests / 2 160 XP, Questify-only 0 / 0 XP, chapter 4 270 XP); A_Human_02 (APR-only 11 quests / 6 455 XP, Questify-only 6 / 4 115 XP, chapter 23 490 XP); A_NightElf_01 (APR-only 1 quest / 630 XP, Questify-only 0 / 0 XP, chapter 4 110 XP); A_NightElf_02 (APR-only 9 quests / 6 710 XP, Questify-only 10 / 6 355 XP, chapter 26 350 XP); A_NightElf_03 (APR-only 16 quests / 15 270 XP, Questify-only 6 / 6 545 XP, chapter 58 570 XP); A_05 (APR-only 2 quests / 5 700 XP, Questify-only 2 / 2 200 XP, chapter 11 560 XP); A_20 (APR-only 2 quests / 8 600 XP, Questify-only 0 / 0 XP, chapter 37 685 XP); A_21 (APR-only 4 quests / 19 100 XP, Questify-only 1 / 7 100 XP, chapter 34 370 XP); H_OrcTroll_02 (APR-only 6 quests / 3 065 XP, Questify-only 2 / 1 540 XP, chapter 25 275 XP); H_Tauren_02 (APR-only 7 quests / 3 835 XP, Questify-only 2 / 1 120 XP, chapter 22 075 XP); H_Undead_01 (APR-only 2 quests / 1 080 XP, Questify-only 0 / 0 XP, chapter 3 710 XP); H_Undead_02 (APR-only 6 quests / 3 590 XP, Questify-only 7 / 4 970 XP, chapter 26 760 XP); H_Skyborne_01 (APR-only 27 quests / 13 185 XP, Questify-only 18 / 12 950 XP, chapter 47 225 XP); H_02 (APR-only 12 quests / 11 670 XP, Questify-only 7 / 8 235 XP, chapter 47 625 XP); H_03 (APR-only 15 quests / 16 055 XP, Questify-only 7 / 12 250 XP, chapter 64 315 XP); H_05 (APR-only 4 quests / 9 900 XP, Questify-only 11 / 15 155 XP, chapter 35 105 XP); H_06 (APR-only 5 quests / 12 550 XP, Questify-only 6 / 9 035 XP, chapter 29 325 XP); H_07 (APR-only 4 quests / 7 400 XP, Questify-only 3 / 3 780 XP, chapter 19 680 XP); H_10 (APR-only 3 quests / 7 700 XP, Questify-only 1 / 2 750 XP, chapter 27 325 XP); H_18 (APR-only 9 quests / 35 850 XP, Questify-only 6 / 27 920 XP, chapter 78 330 XP); H_21 (APR-only 11 quests / 47 000 XP, Questify-only 7 / 39 900 XP, chapter 94 000 XP); H_23 (APR-only 0 quests / 0 XP, Questify-only 0 / 0 XP, chapter 37 600 XP); H_30 (APR-only 4 quests / 21 250 XP, Questify-only 2 / 13 200 XP, chapter 104 550 XP)
- No APR counterpart: A_28, H_13

Alliance: 352 distinct APR-only quests over all slices. Why our route builder left them out (its chapter report, `docs/routes/<chapter>.md`): not a candidate of the chapter 166; prerequisite unavailable 60; finisher outside the chapter zones 33; level band reached 26; objective item source not in zone 19; requires a profession 18; event 8; quest level below the band 7; manual drop (overrides.lua) 5; exclusive with another quest 2; objective npc not in zone 2; repeatable 2; dungeon quest not picked up 1; exploration point not in zone 1; low ratio 1; objective object not in zone 1.

Horde: 290 distinct APR-only quests over all slices. Why our route builder left them out (its chapter report, `docs/routes/<chapter>.md`): not a candidate of the chapter 112; prerequisite unavailable 45; finisher outside the chapter zones 35; level band reached 34; objective item source not in zone 18; manual drop (overrides.lua) 11; requires a profession 11; event 8; low ratio 4; prerequisite dropped 3; repeatable 3; far 2; objective npc not in zone 2; exclusive with another quest 1; exploration point not in zone 1.

## Chapters

Matching: APR leveling routes of the same faction, open to a race of the chapter and to at least 4 classes, whose level band is within 2 levels of the chapter's, sharing at least 3 general quests with the chapter and at least 10 % of them or 25 % of the route's quests. The APR *slice* runs from the first to the last APR step that names a general quest of the chapter, over the matched routes in play order. Class quests (open to at most 3 classes at APR, or in a chain of `ClassQuestData.lua`) are left out of the coverage columns and counted on their own.

| Chapter | Band | APR routes | Quests | Q in matched APR | Q anywhere in APR | APR slice in chapter | APR-only | Q-only | Order: same pairs | Kendall tau | Class quests APR / Q | Hearth use APR / Q | Hearth bind APR / Q |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A_DwarfGnome_01 | 1-6 | #6 | 15 | 15 (100 %) | 15 (100 %) | 15 / 19 (79 %) | 1 | 0 | 87 % | 0.75 | 0-4 / 0 | 1 / 0 | 0 / 0 |
| A_DwarfGnome_02 | 6-11 | #6 | 38 | 32 (84 %) | 32 (84 %) | 32 / 46 (70 %) | 8 | 6 | 94 % | 0.87 | 0-5 / 0 | 1 / 1 | 2 / 1 |
| A_DwarfGnome_03 | 11-14 | #6, #24 | 27 | 8 (30 %) | 16 (59 %) | 8 / 17 (47 %) | 7 | 11 | 66 % | 0.32 | 0-8 / 0 | 0 / 1 | 1-2 / 1 |
| A_DwarfGnome_04 | 14-16 | #18, #31 | 17 | 5 (29 %) | 8 (47 %) | 5 / 16 (31 %) | 5 | 9 | 85 % | 0.70 | 0 / 0 | 0-1 / 0 | 1 / 0 |
| A_Human_01 | 1-6 | #1 | 21 | 21 (100 %) | 21 (100 %) | 19 / 27 (70 %) | 4 | 0 | 91 % | 0.83 | 0-4 / 0 | 0 / 0 | 0 / 0 |
| A_Human_02 | 6-11 | #1 | 43 | 36 (84 %) | 37 (86 %) | 33 / 52 (63 %) | 11 | 6 | 82 % | 0.64 | 0-6 / 0 | 1 / 0 | 1-2 / 0 |
| A_Human_03 | 11-16 | #1, #31 | 23 | 11 (48 %) | 12 (52 %) | 11 / 36 (31 %) | 10 | 11 | 67 % | 0.33 | 0-8 / 0 | 0 / 0 | 1-2 / 0 |
| A_NightElf_01 | 1-6 | #2 | 17 | 17 (100 %) | 17 (100 %) | 17 / 25 (68 %) | 1 | 0 | 86 % | 0.72 | 0-4 / 0 | 0 / 0 | 0-1 / 0 |
| A_NightElf_02 | 6-11 | #2 | 44 | 34 (77 %) | 34 (77 %) | 34 / 46 (74 %) | 9 | 10 | 82 % | 0.64 | 0-6 / 0 | 0-1 / 1 | 0-1 / 1 |
| A_NightElf_03 | 11-19 | #32, #45, #49 | 60 | 54 (90 %) | 54 (90 %) | 53 / 91 (58 %) | 16 | 6 | 84 % | 0.68 | 0-7 / 0 | 1-5 / 1 | 2-4 / 1 |
| A_Skyborne_01 | 1-15 | #4 | 73 | 67 (92 %) | 67 (92 %) | 67 / 92 (73 %) | 25 | 6 | 93 % | 0.85 | 0-5 / 0 | 1-3 / 0 | 2 / 0 |
| A_01 | 16-19 | #32, #45, #49 | 46 | 42 (91 %) | 42 (91 %) | 41 / 76 (54 %) | 11 | 4 | 69 % | 0.38 | 0-6 / 0 | 2-5 / 1 | 1-3 / 1 |
| A_02 | 20-22 | #32, #45, #49 | 25 | 19 (76 %) | 19 (76 %) | 19 / 67 (28 %) | 13 | 6 | 61 % | 0.22 | 0-7 / 0 | 2-5 / 0 | 1-3 / 0 |
| A_03 | 22-26 | #57 | 56 | 42 (75 %) | 53 (95 %) | 42 / 57 (74 %) | 13 | 3 | 81 % | 0.63 | 0-3 / 0 | 2-3 / 3 | 1-2 / 1 |
| A_04 | 26-29 | #52, #61 | 32 | 15 (47 %) | 16 (50 %) | 14 / 42 (33 %) | 28 | 16 | 72 % | 0.43 | 0-1 / 0 | 3 / 0 | 1 / 0 |
| A_05 | 29-30 | #68 | 8 | 6 (75 %) | 6 (75 %) | 6 / 8 (75 %) | 2 | 2 | 88 % | 0.75 | 0 / 0 | 0 / 0 | 1 / 0 |
| A_08 | 30-32 | #63 | 12 | 8 (67 %) | 8 (67 %) | 8 / 22 (36 %) | 11 | 4 | 80 % | 0.60 | 0 / 0 | 0 / 0 | 0 / 0 |
| A_07 | 32-33 | #64 | 9 | 9 (100 %) | 9 (100 %) | 9 / 38 (24 %) | 13 | 0 | 86 % | 0.71 | 0 / 0 | 2 / 1 | 1 / 0 |
| A_09 | 33-34 | #69, #74 | 13 | 12 (92 %) | 12 (92 %) | 12 / 38 (32 %) | 10 | 1 | 73 % | 0.46 | 0-4 / 0 | 2-3 / 0 | 1 / 0 |
| A_10 | 34-35 | #64, #72, #77 | 22 | 22 (100 %) | 22 (100 %) | 22 / 69 (32 %) | 29 | 0 | 82 % | 0.65 | 0-4 / 0 | 2 / 1 | 2 / 0 |
| A_11 | 35-37 | #74 | 19 | 11 (58 %) | 14 (74 %) | 11 / 21 (52 %) | 10 | 5 | 82 % | 0.64 | 0 / 0 | 1-2 / 1 | 0 / 0 |
| A_12 | 37-39 | #72, #77, #89 | 28 | 25 (89 %) | 27 (96 %) | 25 / 84 (30 %) | 29 | 1 | 75 % | 0.50 | 0-1 / 0 | 3-4 / 4 | 3-4 / 1 |
| A_13 | 39-40 | #83 | 13 | 12 (92 %) | 12 (92 %) | 12 / 37 (32 %) | 25 | 1 | 89 % | 0.77 | 0-3 / 0 | 10 / 0 | 1 / 0 |
| A_15 | 40-41 | #85 | 18 | 7 (39 %) | 17 (94 %) | 7 / 14 (50 %) | 7 | 1 | 88 % | 0.76 | 0 / 0 | 0 / 1 | 0 / 0 |
| A_16 | 41-42 | #88 | 13 | 10 (77 %) | 10 (77 %) | 10 / 25 (40 %) | 15 | 3 | 77 % | 0.55 | 0 / 0 | 0 / 1 | 0 / 0 |
| A_17 | 42-44 | #89 | 19 | 13 (68 %) | 17 (89 %) | 13 / 45 (29 %) | 20 | 2 | 60 % | 0.20 | 0 / 0 | 1-2 / 2 | 1 / 0 |
| A_18 | 44-45 | #93 | 14 | 6 (43 %) | 11 (79 %) | 6 / 17 (35 %) | 11 | 3 | 80 % | 0.60 | 0-1 / 0 | 0 / 2 | 0 / 1 |
| A_19 | 45-46 | #96 | 27 | 22 (81 %) | 27 (100 %) | 22 / 31 (71 %) | 9 | 0 | 83 % | 0.65 | 0 / 0 | 4 / 0 | 1 / 0 |
| A_20 | 46-48 | #101 | 11 | 11 (100 %) | 11 (100 %) | 11 / 20 (55 %) | 2 | 0 | 70 % | 0.40 | 0 / 0 | 2 / 1 | 0 / 0 |
| A_21 | 48-50 | #104 | 8 | 7 (88 %) | 7 (88 %) | 7 / 14 (50 %) | 4 | 1 | 42 % | -0.17 | 0 / 0 | 0 / 1 | 0 / 0 |
| A_22 | 50-52 | #105, #106 | 18 | 17 (94 %) | 17 (94 %) | 17 / 29 (59 %) | 12 | 1 | 38 % | -0.25 | 0 / 0 | 1 / 0 | 0 / 0 |
| A_28 | 52-53 | none | 11 | - | - | - | - | - | - | - | - | - | - |
| A_24 | 53-54 | #109, #115 | 18 | 17 (94 %) | 17 (94 %) | 17 / 41 (41 %) | 22 | 1 | 68 % | 0.37 | 0-2 / 0 | 1 / 0 | 0 / 0 |
| A_26 | 54-56 | #113 | 19 | 15 (79 %) | 19 (100 %) | 15 / 24 (63 %) | 9 | 0 | 71 % | 0.41 | 0 / 0 | 0 / 1 | 0 / 0 |
| A_27 | 56-57 | #115, #120, #122 | 20 | 17 (85 %) | 17 (85 %) | 17 / 101 (17 %) | 52 | 3 | 67 % | 0.34 | 0-1 / 0 | 4 / 1 | 4 / 0 |
| A_23 | 57-58 | #120 | 29 | 25 (86 %) | 26 (90 %) | 25 / 64 (39 %) | 29 | 3 | 74 % | 0.48 | 0 / 0 | 2 / 0 | 1 / 0 |
| A_29 | 58-59 | #120 | 17 | 10 (59 %) | 10 (59 %) | 10 / 40 (25 %) | 20 | 7 | 72 % | 0.44 | 0 / 0 | 2 / 0 | 1 / 0 |
| A_30 | 59-60 | #122 | 16 | 14 (88 %) | 14 (88 %) | 14 / 22 (64 %) | 8 | 2 | 87 % | 0.74 | 0 / 0 | 0 / 1 | 0 / 0 |
| H_OrcTroll_01 | 1-6 | #7 | 15 | 14 (93 %) | 14 (93 %) | 14 / 31 (45 %) | 5 | 1 | 85 % | 0.69 | 0-5 / 0 | 0 / 0 | 1 / 0 |
| H_OrcTroll_02 | 6-12 | #7 | 38 | 36 (95 %) | 36 (95 %) | 33 / 43 (77 %) | 6 | 2 | 81 % | 0.62 | 0-11 / 0 | 0-1 / 2 | 1 / 1 |
| H_Tauren_01 | 1-6 | #5 | 15 | 15 (100 %) | 15 (100 %) | 15 / 35 (43 %) | 5 | 0 | 86 % | 0.73 | 0-4 / 0 | 0 / 0 | 1 / 0 |
| H_Tauren_02 | 6-12 | #5 | 35 | 33 (94 %) | 33 (94 %) | 32 / 46 (70 %) | 7 | 2 | 82 % | 0.64 | 0-7 / 0 | 0-1 / 0 | 2 / 0 |
| H_Undead_01 | 1-6 | #3 | 13 | 13 (100 %) | 13 (100 %) | 13 / 23 (57 %) | 2 | 0 | 95 % | 0.91 | 0-4 / 0 | 0 / 0 | 1 / 0 |
| H_Undead_02 | 6-12 | #3 | 45 | 38 (84 %) | 38 (84 %) | 37 / 46 (80 %) | 6 | 7 | 84 % | 0.67 | 0-10 / 0 | 1-2 / 2 | 1-2 / 1 |
| H_Undead_03 | 12-15 | #25 | 38 | 24 (63 %) | 28 (74 %) | 24 / 27 (89 %) | 2 | 10 | 65 % | 0.31 | 0-3 / 0 | 0-1 / 1 | 0 / 0 |
| H_Skyborne_01 | 1-15 | #4, #14 | 73 | 55 (75 %) | 55 (75 %) | 55 / 87 (63 %) | 27 | 18 | 94 % | 0.87 | 0-10 / 0 | 1-3 / 1 | 3 / 1 |
| H_01 | 12-17 | #5, #27, #37 | 49 | 46 (94 %) | 48 (98 %) | 45 / 81 (56 %) | 19 | 1 | 74 % | 0.47 | 0-12 / 0 | 3-4 / 0 | 4-5 / 0 |
| H_02 | 17-21 | #27, #37 | 36 | 27 (75 %) | 29 (81 %) | 25 / 60 (42 %) | 12 | 7 | 60 % | 0.20 | 0-11 / 0 | 1-2 / 2 | 2-3 / 1 |
| H_03 | 21-25 | #37, #58, #59 | 37 | 30 (81 %) | 30 (81 %) | 28 / 72 (39 %) | 15 | 7 | 69 % | 0.38 | 0-12 / 0 | 3 / 1 | 3 / 1 |
| H_04 | 25-28 | #58, #62 | 32 | 27 (84 %) | 28 (88 %) | 27 / 55 (49 %) | 12 | 4 | 88 % | 0.76 | 0-3 / 0 | 2-3 / 2 | 4 / 1 |
| H_05 | 28-30 | #65 | 21 | 6 (29 %) | 10 (48 %) | 6 / 12 (50 %) | 4 | 11 | 70 % | 0.39 | 0-2 / 0 | 0 / 2 | 0 / 1 |
| H_06 | 30-32 | #65 | 17 | 8 (47 %) | 11 (65 %) | 8 / 17 (47 %) | 5 | 6 | 93 % | 0.86 | 0-2 / 0 | 0 / 1 | 0 / 0 |
| H_07 | 32-33 | #70 | 11 | 7 (64 %) | 8 (73 %) | 7 / 12 (58 %) | 4 | 3 | 91 % | 0.82 | 0-1 / 0 | 0 / 1 | 0 / 1 |
| H_08 | 33-35 | #73 | 17 | 14 (82 %) | 15 (88 %) | 14 / 24 (58 %) | 9 | 2 | 75 % | 0.51 | 0 / 0 | 0 / 1 | 0 / 1 |
| H_09 | 35-37 | #70, #76 | 30 | 25 (83 %) | 26 (87 %) | 25 / 44 (57 %) | 14 | 4 | 85 % | 0.71 | 0-1 / 0 | 1-3 / 2 | 2 / 1 |
| H_10 | 37-38 | #79 | 14 | 13 (93 %) | 13 (93 %) | 13 / 16 (81 %) | 3 | 1 | 86 % | 0.72 | 0 / 0 | 0 / 0 | 0 / 0 |
| H_11 | 38-39 | #81 | 18 | 10 (56 %) | 10 (56 %) | 10 / 24 (42 %) | 11 | 8 | 96 % | 0.91 | 0-4 / 0 | 0 / 3 | 0 / 1 |
| H_12 | 39-40 | #82 | 10 | 7 (70 %) | 7 (70 %) | 7 / 19 (37 %) | 12 | 3 | 82 % | 0.63 | 0 / 0 | 0 / 0 | 0 / 0 |
| H_13 | 40-41 | none | 14 | - | - | - | - | - | - | - | - | - | - |
| H_14 | 41-43 | #90, #98 | 14 | 12 (86 %) | 12 (86 %) | 12 / 27 (44 %) | 12 | 2 | 82 % | 0.63 | 0 / 0 | 1 / 0 | 1 / 0 |
| H_15 | 43-44 | #91 | 9 | 3 (33 %) | 4 (44 %) | 3 / 6 (50 %) | 1 | 5 | 93 % | 0.87 | 0 / 0 | 0 / 1 | 0 / 0 |
| H_16 | 44-46 | #92, #99 | 20 | 17 (85 %) | 17 (85 %) | 17 / 42 (40 %) | 25 | 3 | 67 % | 0.34 | 0 / 0 | 3-5 / 2 | 2 / 1 |
| H_17 | 46-47 | #95, #102 | 19 | 18 (95 %) | 18 (95 %) | 18 / 32 (56 %) | 14 | 1 | 72 % | 0.45 | 0 / 0 | 3-4 / 0 | 1 / 0 |
| H_18 | 47-48 | #97, #103 | 21 | 13 (62 %) | 15 (71 %) | 13 / 34 (38 %) | 9 | 6 | 56 % | 0.12 | 0 / 0 | 0 / 1 | 0 / 1 |
| H_21 | 48-51 | #100 | 19 | 12 (63 %) | 12 (63 %) | 12 / 23 (52 %) | 11 | 7 | 66 % | 0.31 | 0 / 0 | 0 / 0 | 0 / 0 |
| H_23 | 51-52 | #103 | 7 | 7 (100 %) | 7 (100 %) | 7 / 7 (100 %) | 0 | 0 | 56 % | 0.12 | 0 / 0 | 0 / 1 | 0 / 0 |
| H_24 | 52-53 | #108 | 13 | 9 (69 %) | 9 (69 %) | 9 / 21 (43 %) | 12 | 4 | 51 % | 0.03 | 0 / 0 | 0 / 0 | 0 / 0 |
| H_25 | 53-54 | #110 | 7 | 7 (100 %) | 7 (100 %) | 7 / 14 (50 %) | 7 | 0 | 73 % | 0.45 | 0-3 / 0 | 0 / 1 | 0 / 1 |
| H_26 | 54-55 | #114, #117 | 17 | 16 (94 %) | 16 (94 %) | 16 / 52 (31 %) | 25 | 1 | 67 % | 0.35 | 0-2 / 0 | 3-4 / 1 | 2 / 0 |
| H_27 | 55-56 | #116 | 19 | 14 (74 %) | 19 (100 %) | 14 / 23 (61 %) | 9 | 0 | 79 % | 0.57 | 0 / 0 | 0 / 1 | 0 / 0 |
| H_28 | 56-57 | #114, #117, #121 | 26 | 23 (88 %) | 23 (88 %) | 22 / 64 (34 %) | 31 | 3 | 79 % | 0.57 | 0-1 / 0 | 4-6 / 2 | 3 / 1 |
| H_29 | 57-59 | #119 | 31 | 22 (71 %) | 22 (71 %) | 22 / 66 (33 %) | 44 | 9 | 85 % | 0.70 | 0 / 0 | 0 / 0 | 0 / 0 |
| H_30 | 59-60 | #121 | 16 | 14 (88 %) | 14 (88 %) | 13 / 17 (76 %) | 4 | 2 | 87 % | 0.73 | 0-1 / 0 | 0 / 1 | 0 / 0 |

Quests: general quests of the chapter. Class quests, hearth use and hearth bind are per class (`a-b` = lowest-highest over the 9 classes; one number when every class has the same). Hearth use at APR includes the "use it if it is ready" steps. Order: first `accept`, `complete` and `turnin` of each quest, steps open to at least 4 classes, compared on the events present on both sides (Kendall tau: 1 = same order, 0 = unrelated, -1 = reversed).

## Details per chapter

### A_DwarfGnome_01 — Coldridge Valley (1-6)

- Races: Dwarf, Gnome. APR routes: #6 (Dun Morogh (1426), 1-11): 15 shared of 95. Slice: 133 of 401 steps.
- Questify -> APR: 15 of 15 general quests in the matched routes (100 %), 15 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 15 of 19 general quests in this chapter (79 %).
  - In another Questify chapter: 96608, 96629, 98322
  - In no Questify chapter (APR-only): 384 (630 XP)
    - not a candidate of the chapter: 384
- Order: 37 shared events, 582 of 666 pairs in the same order (87 %), Kendall tau 0.75.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 3364 | turnin 170 | 14 | 16 |
  | accept 182 | complete 170 | 10 | 9 |
  | complete 182 | accept 3361 | 7 | 9 |
  | turnin 3364 | complete 3361 | 6 | 10 |
  | accept 3365 | turnin 218 | 7 | 6 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 2 | none |
  | PALADIN | 1 | 0 | 0 | 1 | none |
  | HUNTER | 1 | 0 | 0 | 1 | none |
  | ROGUE | 2 | 0 | 0 | 2 | none |
  | PRIEST | 3 | 0 | 0 | 3 | none |
  | SHAMAN | 4 | 0 | 0 | 4 | none |
  | MAGE | 1 | 0 | 0 | 1 | none |
  | WARLOCK | 2 | 0 | 0 | 2 | none |

- Hearthstone: APR uses it 1 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 1; 1 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### A_DwarfGnome_02 — Dun Morogh (6-11)

- Races: Dwarf, Gnome. APR routes: #6 (Dun Morogh (1426), 1-11): 32 shared of 95. Slice: 231 of 401 steps.
- Questify -> APR: 32 of 38 general quests in the matched routes (84 %), 32 anywhere in APR (84 %).
  - Absent from APR (Questify-only): 415, 95212, 98326, 99159, 99160, 99161 (3 805 XP)
  - In another APR route: none
- APR -> Questify (slice): 32 of 46 general quests in this chapter (70 %).
  - In another Questify chapter: 224, 420, 2160, 6387, 6388, 6391
  - In no Questify chapter (APR-only): 267, 308, 384, 400, 412, 416, 418, 98321 (5 510 XP)
  - Left out, quest level above 13 (band + 2): 307, 1338, 1339
    - level band reached: 384, 400, 412, 98321
    - not a candidate of the chapter: 267, 416, 418
    - repeatable: 308
- Order: 80 shared events, 2957 of 3160 pairs in the same order (94 %), Kendall tau 0.87.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 312 | turnin 313 | 20 | 16 |
  | accept 96391 | turnin 314 | 15 | 17 |
  | complete 96390 | complete 314 | 13 | 17 |
  | complete 312 | turnin 98323 | 14 | 12 |
  | complete 319 | accept 287 | 7 | 7 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 5 | 0 | 0 | 4 | 86667 |
  | PRIEST | 2 | 0 | 0 | 2 | none |
  | SHAMAN | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 1 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 1; 1 "if ready" steps open to all) and binds it 2 times (maps Dun Morogh (1426), Loch Modan (1432)); Questify uses it 1 times and binds it 1 times (maps Dun Morogh (1426)).

### A_DwarfGnome_03 — Loch Modan (11-14)

- Races: Dwarf, Gnome. APR routes: #6 (Dun Morogh (1426), 1-11): 8 shared of 95; #24 (Loch Modan (1432), 12-14): 3 shared of 26. Slice: 205 of 567 steps.
- Questify -> APR: 8 of 27 general quests in the matched routes (30 %), 16 anywhere in APR (59 %).
  - Absent from APR (Questify-only): 237, 263, 273, 297, 309, 454, 78148, 79091, 79093, 86585, 86613 (12 125 XP)
  - In another APR route: 257, 258, 298, 301, 302, 436, 2039, 86758
- APR -> Questify (slice): 8 of 17 general quests in this chapter (47 %).
  - In another Questify chapter: 291, 414
  - In no Questify chapter (APR-only): 267, 353, 416, 418, 6661, 6662, 86667 (5 060 XP)
    - level band reached: 267, 416, 418
    - not a candidate of the chapter: 353, 6661, 6662
    - objective item source not in zone: 86667
- Order: 18 shared events, 101 of 153 pairs in the same order (66 %), Kendall tau 0.32.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 224 | accept 307 | 11 | 11 |
  | turnin 224 | accept 1338 | 9 | 13 |
  | accept 6391 | turnin 1339 | 5 | 4 |
  | complete 307 | turnin 1338 | 3 | 2 |
  | turnin 307 | turnin 6392 | 1 | 2 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 4 | 0 | 0 | 4 | none |
  | PALADIN | 8 | 0 | 0 | 7 | 1645 |
  | HUNTER | 1 | 0 | 0 | 1 | none |
  | PRIEST | 1 | 0 | 0 | 1 | none |
  | SHAMAN | 5 | 0 | 0 | 5 | none |
  | WARLOCK | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 1-2 times (maps Loch Modan (1432), Ironforge (1455)); Questify uses it 1 times and binds it 1 times (maps Loch Modan (1432)).

### A_DwarfGnome_04 — Westfall (14-16)

- Races: Dwarf, Gnome. APR routes: #18 (Elwynn Forest (1429), 11-12): 3 shared of 28; #31 (Westfall (1436), 13-15): 5 shared of 17. Slice: 66 of 178 steps.
- Questify -> APR: 5 of 17 general quests in the matched routes (29 %), 8 anywhere in APR (47 %).
  - Absent from APR (Questify-only): 13, 14, 136, 138, 139, 140, 92745, 92747, 92748 (8 080 XP)
  - In another APR route: 167, 168, 2040
- APR -> Questify (slice): 5 of 16 general quests in this chapter (31 %).
  - In another Questify chapter: 9, 22, 102, 109, 153, 184
  - In no Questify chapter (APR-only): 36, 38, 65, 399, 92909 (4 780 XP)
    - finisher outside the chapter zones: 65
    - level band reached: 92909
    - not a candidate of the chapter: 399
    - prerequisite unavailable: 38
    - quest level below the band: 36
- Order: 15 shared events, 89 of 105 pairs in the same order (85 %), Kendall tau 0.70.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 92744 | turnin 64 | 5 | 5 |
  | turnin 92742 | turnin 151 | 3 | 3 |
  | accept 92744 | accept 92742 | 1 | 1 |
  | complete 92744 | complete 64 | 1 | 1 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0-1 times (WARRIOR 1, PALADIN 1, HUNTER 0, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 0; 1 "if ready" steps open to all) and binds it 1 times (maps Stormwind City (1453)); Questify uses it 0 times and binds it 0 times (maps none).

### A_Human_01 — Northshire (1-6)

- Races: Human. APR routes: #1 (Elwynn Forest (1429), 1-11): 21 shared of 119. Slice: 162 of 633 steps.
- Questify -> APR: 21 of 21 general quests in the matched routes (100 %), 21 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 19 of 27 general quests in this chapter (70 %).
  - In another Questify chapter: 60, 62, 95998, 96626
  - In no Questify chapter (APR-only): 91775, 97921, 97923, 97924 (2 160 XP)
    - not a candidate of the chapter: 91775, 97921, 97923, 97924
- Order: 46 shared events, 945 of 1035 pairs in the same order (91 %), Kendall tau 0.83.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 18 | turnin 33 | 15 | 13 |
  | complete 7 | turnin 5261 | 8 | 8 |
  | complete 91743 | complete 18 | 7 | 7 |
  | turnin 7 | accept 33 | 6 | 9 |
  | accept 96627 | turnin 6 | 6 | 5 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 1 | 0 | 0 | 1 | none |
  | PALADIN | 1 | 0 | 0 | 1 | none |
  | HUNTER | 1 | 0 | 0 | 1 | none |
  | ROGUE | 1 | 0 | 0 | 1 | none |
  | PRIEST | 4 | 0 | 2 | 2 | none |
  | MAGE | 3 | 0 | 2 | 1 | none |
  | WARLOCK | 2 | 0 | 0 | 2 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### A_Human_02 — Elwynn Forest (6-11)

- Races: Human. APR routes: #1 (Elwynn Forest (1429), 1-11): 36 shared of 119. Slice: 352 of 633 steps.
- Questify -> APR: 36 of 43 general quests in the matched routes (84 %), 37 anywhere in APR (86 %).
  - Absent from APR (Questify-only): 46, 91723, 91724, 91732, 99130, 99131 (4 115 XP)
  - In another APR route: 147
- APR -> Questify (slice): 33 of 52 general quests in this chapter (63 %).
  - In another Questify chapter: 12, 22, 54, 64, 2158, 6181, 6281, 91772
  - In no Questify chapter (APR-only): 36, 38, 47, 5545, 91746, 91751, 91775, 91777, 97921, 97923, 97924 (6 455 XP)
  - Left out, quest level above 13 (band + 2): 9, 102, 151, 244, 1097
    - level band reached: 47, 5545, 91746, 91775, 91777
    - not a candidate of the chapter: 36, 38
    - requires a profession: 91751, 97921, 97923, 97924
- Order: 77 shared events, 2395 of 2926 pairs in the same order (82 %), Kendall tau 0.64.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 83 | turnin 87 | 33 | 33 |
  | accept 83 | turnin 84 | 33 | 32 |
  | turnin 83 | complete 87 | 31 | 41 |
  | accept 37 | accept 84 | 32 | 31 |
  | turnin 35 | turnin 86 | 32 | 31 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 1 | 0 | 0 | 1 | none |
  | PALADIN | 1 | 0 | 0 | 1 | none |
  | HUNTER | 4 | 0 | 0 | 4 | none |
  | PRIEST | 3 | 0 | 0 | 3 | none |
  | WARLOCK | 6 | 0 | 3 | 2 | 59 |

- Hearthstone: APR uses it 1 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 1; 1 "if ready" steps open to all) and binds it 1-2 times (maps Elwynn Forest (1429), Stormwind City (1453)); Questify uses it 0 times and binds it 0 times (maps none).

### A_Human_03 — Westfall (11-16)

- Races: Human. APR routes: #1 (Elwynn Forest (1429), 1-11): 8 shared of 119; #31 (Westfall (1436), 13-15): 8 shared of 19. Slice: 244 of 712 steps.
- Questify -> APR: 11 of 23 general quests in the matched routes (48 %), 12 anywhere in APR (52 %).
  - Absent from APR (Questify-only): 13, 14, 136, 138, 139, 140, 152, 79093, 92745, 92747, 92748 (11 080 XP)
  - In another APR route: 103
- APR -> Questify (slice): 11 of 36 general quests in this chapter (31 %).
  - In another Questify chapter: 61, 109, 184, 314, 417, 419, 432, 433, 95213, 95214, 96390, 96391, 96392, 96393, 96408
  - In no Questify chapter (APR-only): 36, 38, 65, 353, 399, 1097, 6261, 6285, 6661, 92909 (7 650 XP)
    - finisher outside the chapter zones: 65
    - level band reached: 36, 38, 92909
    - not a candidate of the chapter: 353, 399, 1097, 6261, 6285, 6661
- Order: 28 shared events, 252 of 378 pairs in the same order (67 %), Kendall tau 0.33.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 12 | turnin 6281 | 14 | 15 |
  | turnin 92744 | turnin 64 | 10 | 10 |
  | turnin 92742 | complete 151 | 9 | 10 |
  | complete 12 | accept 6281 | 8 | 14 |
  | complete 64 | turnin 6181 | 8 | 7 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 4 | 0 | 0 | 4 | none |
  | PRIEST | 3 | 0 | 0 | 3 | none |
  | WARLOCK | 8 | 0 | 0 | 3 | 59, 83, 123, 176, 244 |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 1-2 times (maps Stormwind City (1453)); Questify uses it 0 times and binds it 0 times (maps none).

### A_NightElf_01 — Shadowglen (1-6)

- Races: NightElf. APR routes: #2 (Teldrassil (1438), 1-11): 17 shared of 82. Slice: 138 of 495 steps.
- Questify -> APR: 17 of 17 general quests in the matched routes (100 %), 17 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 17 of 25 general quests in this chapter (68 %).
  - In another Questify chapter: 475, 488, 932, 997, 2438, 96606, 96634
  - In no Questify chapter (APR-only): 87288 (630 XP)
  - Left out, quest level above 8 (band + 2): 99046
    - not a candidate of the chapter: 87288
- Order: 35 shared events, 511 of 595 pairs in the same order (86 %), Kendall tau 0.72.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 97236 | complete 3521 | 9 | 11 |
  | complete 457 | accept 3522 | 9 | 11 |
  | turnin 97236 | turnin 459 | 8 | 9 |
  | complete 917 | turnin 3521 | 7 | 6 |
  | turnin 457 | turnin 3522 | 5 | 10 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 1 | 0 | 0 | 1 | none |
  | HUNTER | 1 | 0 | 0 | 1 | none |
  | PRIEST | 4 | 0 | 0 | 3 | 97979 |
  | DRUID | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0-1 times (maps Teldrassil (1438)); Questify uses it 0 times and binds it 0 times (maps none).

### A_NightElf_02 — Teldrassil (6-11)

- Races: NightElf. APR routes: #2 (Teldrassil (1438), 1-11): 34 shared of 82. Slice: 387 of 495 steps.
- Questify -> APR: 34 of 44 general quests in the matched routes (77 %), 34 anywhere in APR (77 %).
  - Absent from APR (Questify-only): 483, 486, 2498, 2499, 2519, 98046, 98065, 98391, 98403, 99053 (6 355 XP)
  - In another APR route: none
- APR -> Questify (slice): 34 of 46 general quests in this chapter (74 %).
  - In another Questify chapter: 928, 2159, 96630
  - In no Questify chapter (APR-only): 919, 2459, 2520, 4161, 6343, 87288, 98067, 99050, 99073 (6 710 XP)
    - event: 2520
    - level band reached: 919, 87288, 98067
    - not a candidate of the chapter: 6343
    - objective item source not in zone: 2459, 99050
    - prerequisite unavailable: 99073
    - requires a profession: 4161
- Order: 49 shared events, 963 of 1176 pairs in the same order (82 %), Kendall tau 0.64.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 2438 | turnin 96634 | 15 | 14 |
  | accept 487 | turnin 488 | 13 | 13 |
  | complete 487 | accept 489 | 13 | 13 |
  | accept 937 | turnin 489 | 12 | 12 |
  | accept 99047 | complete 489 | 11 | 12 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 2 | none |
  | HUNTER | 4 | 0 | 0 | 4 | none |
  | ROGUE | 2 | 0 | 0 | 2 | none |
  | PRIEST | 3 | 0 | 0 | 3 | none |
  | DRUID | 6 | 0 | 0 | 6 | none |

- Hearthstone: APR uses it 0-1 times (WARRIOR 1, PALADIN 0, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0-1 times (maps Teldrassil (1438)); Questify uses it 1 times and binds it 1 times (maps Teldrassil (1438)).

### A_NightElf_03 — Darkshore (11-19)

- Races: NightElf. APR routes: #32 (Darkshore (1439), 11-19): 54 shared of 107; #45 (Darkshore (1439), 20-21): 17 shared of 33; #49 (Stonetalon Mountains (1442), 21-23): 7 shared of 32. Slice: 936 of 1040 steps.
- Questify -> APR: 54 of 60 general quests in the matched routes (90 %), 54 anywhere in APR (90 %).
  - Absent from APR (Questify-only): 990, 1275, 5713, 87760, 98013, 98028 (6 545 XP)
  - In another APR route: none
- APR -> Questify (slice): 53 of 91 general quests in this chapter (58 %).
  - In another Questify chapter: 224, 257, 298, 301, 307, 314, 436, 952, 970, 991, 1007, 1008, 1010, 1020, 1023, 1070, 1338, 1339, 2039, 4740, 6342, 86758
  - In no Questify chapter (APR-only): 267, 385, 416, 418, 730, 968, 995, 1056, 1134, 1141, 2178, 5321, 86614, 95065, 97914, 97926 (15 270 XP)
  - Left out, quest level above 21 (band + 2): 973, 1009, 1025, 1033, 1034, 1054, 3765
    - exclusive with another quest: 995
    - exploration point not in zone: 5321
    - finisher outside the chapter zones: 968, 97914
    - not a candidate of the chapter: 267, 385, 416, 418, 730, 1056, 1134, 86614, 95065, 97926
    - objective item source not in zone: 1141
    - requires a profession: 2178
- Order: 137 shared events, 7814 of 9316 pairs in the same order (84 %), Kendall tau 0.68.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 98025 | accept 1138 | 54 | 52 |
  | accept 948 | complete 982 | 52 | 50 |
  | complete 1002 | turnin 982 | 49 | 60 |
  | turnin 4732 | turnin 1003 | 58 | 49 |
  | accept 4732 | turnin 4725 | 42 | 50 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 0 | 97220, 97222 |
  | HUNTER | 5 | 0 | 1 | 0 | 741, 942, 97220, 97222 |
  | ROGUE | 2 | 0 | 0 | 0 | 97220, 97222 |
  | DRUID | 7 | 0 | 0 | 6 | 6343 |

- Hearthstone: APR uses it 1-5 times (WARRIOR 5, PALADIN 1, HUNTER 5, ROGUE 5, PRIEST 5, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 5; 4 "if ready" steps open to all) and binds it 2-4 times (maps Darkshore (1439), Ashenvale (1440)); Questify uses it 1 times and binds it 1 times (maps Darkshore (1439)).

### A_Skyborne_01 — Zephras Isle (1-15)

- Races: Skyborne. APR routes: #4 (Zephras Isle (2521), 1-13): 67 shared of 114. Slice: 714 of 773 steps.
- Questify -> APR: 67 of 73 general quests in the matched routes (92 %), 67 anywhere in APR (92 %).
  - Absent from APR (Questify-only): 92947, 93089, 93835, 93958, 94369, 94493 (4 070 XP)
  - In another APR route: none
- APR -> Questify (slice): 67 of 92 general quests in this chapter (73 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 92461, 92463, 92473, 92474, 92515, 92516, 92544, 92553, 92597, 93319, 93552, 93951, 94484, 94897, 97963, 97964, 97965, 97967, 97968, 97969, 97970, 97971, 97973, 98285, 98286 (12 315 XP)
    - exclusive with another quest: 94484
    - level band reached: 92461, 92463, 92473, 92474, 92515, 92516, 92544, 92553, 92597, 93319, 93951
    - low ratio: 93552
    - objective item source not in zone: 94897
    - requires a profession: 97963, 97964, 97965, 97967, 97968, 97969, 97970, 97971, 97973, 98285, 98286
- Order: 174 shared events, 13946 of 15051 pairs in the same order (93 %), Kendall tau 0.85.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 92709 | complete 92643 | 48 | 48 |
  | accept 98512 | complete 92850 | 36 | 47 |
  | accept 92709 | accept 92850 | 29 | 29 |
  | turnin 94487 | turnin 92643 | 28 | 26 |
  | turnin 94485 | accept 92644 | 30 | 24 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 2 | none |
  | HUNTER | 5 | 0 | 0 | 5 | none |
  | ROGUE | 1 | 0 | 0 | 1 | none |
  | MAGE | 3 | 0 | 0 | 2 | 93797 |
  | DRUID | 3 | 0 | 0 | 3 | none |

- Hearthstone: APR uses it 1-3 times (WARRIOR 3, PALADIN 1, HUNTER 3, ROGUE 3, PRIEST 1, SHAMAN 1, MAGE 3, WARLOCK 1, DRUID 3; 3 "if ready" steps open to all) and binds it 2 times (maps Zephras Isle (2521)); Questify uses it 0 times and binds it 0 times (maps none).

### A_01 — Darkshore (16-19)

- Races: Dwarf, Gnome, Human, Skyborne. APR routes: #32 (Darkshore (1439), 11-19): 42 shared of 81; #45 (Darkshore (1439), 20-21): 17 shared of 32; #49 (Stonetalon Mountains (1442), 21-23): 8 shared of 36. Slice: 908 of 953 steps.
- Questify -> APR: 42 of 46 general quests in the matched routes (91 %), 42 anywhere in APR (91 %).
  - Absent from APR (Questify-only): 990, 5713, 87760, 98028 (3 795 XP)
  - In another APR route: none
- APR -> Questify (slice): 41 of 76 general quests in this chapter (54 %).
  - In another Questify chapter: 953, 954, 955, 956, 957, 958, 963, 970, 982, 983, 991, 1001, 1002, 1003, 1007, 1008, 1010, 1020, 1023, 1070, 1071, 1085, 1093, 98025
  - In no Questify chapter (APR-only): 741, 942, 968, 995, 1056, 1072, 1075, 1134, 1141, 2178, 5321 (12 860 XP)
  - Left out, quest level above 21 (band + 2): 973, 1009, 1025, 1033, 1034, 1054, 3765
    - exclusive with another quest: 995
    - exploration point not in zone: 5321
    - finisher outside the chapter zones: 741, 968
    - not a candidate of the chapter: 942, 1056, 1072, 1075, 1134
    - objective item source not in zone: 1141
    - quest level below the band: 2178
- Order: 102 shared events, 3548 of 5151 pairs in the same order (69 %), Kendall tau 0.38.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 729 | turnin 4812 | 62 | 63 |
  | accept 731 | accept 2139 | 60 | 61 |
  | turnin 731 | turnin 4813 | 67 | 59 |
  | complete 731 | turnin 2138 | 58 | 63 |
  | turnin 986 | complete 4812 | 53 | 59 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 1 | 0 | none |
  | WARLOCK | 4 | 0 | 0 | 3 | 1094 |
  | DRUID | 6 | 0 | 0 | 6 | none |

- Hearthstone: APR uses it 2-5 times (WARRIOR 4, PALADIN 2, HUNTER 4, ROGUE 2, PRIEST 2, SHAMAN 2, MAGE 2, WARLOCK 2, DRUID 5; 2 "if ready" steps open to all) and binds it 1-3 times (maps Darkshore (1439), Ashenvale (1440)); Questify uses it 1 times and binds it 1 times (maps Darkshore (1439)).

### A_02 — Ashenvale and Stonetalon Mountains (20-22)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #32 (Darkshore (1439), 11-19): 15 shared of 107; #45 (Darkshore (1439), 20-21): 11 shared of 33; #49 (Stonetalon Mountains (1442), 21-23): 15 shared of 36. Slice: 835 of 1202 steps.
- Questify -> APR: 19 of 25 general quests in the matched routes (76 %), 19 anywhere in APR (76 %).
  - Absent from APR (Questify-only): 990, 5713, 78132, 78133, 78134, 78270 (5 815 XP)
  - In another APR route: none
- APR -> Questify (slice): 19 of 67 general quests in this chapter (28 %).
  - In another Questify chapter: 729, 731, 944, 947, 948, 949, 950, 951, 952, 963, 965, 966, 982, 986, 993, 1002, 1003, 1138, 2078, 2098, 2138, 2139, 4723, 4725, 4727, 4728, 4730, 4731, 4732, 4733, 4740, 4762, 4763, 4813, 98042
  - In no Questify chapter (APR-only): 730, 741, 942, 968, 995, 1016, 1056, 1072, 1075, 1134, 2178, 3765, 5321 (15 120 XP)
    - far: 1134
    - finisher outside the chapter zones: 1072, 1075
    - manual drop (overrides.lua): 1056
    - not a candidate of the chapter: 730, 741, 942, 968, 995, 2178, 3765, 5321
    - objective item source not in zone: 1016
- Order: 48 shared events, 686 of 1128 pairs in the same order (61 %), Kendall tau 0.22.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 1070 | accept 973 | 25 | 27 |
  | accept 1071 | turnin 1020 | 25 | 25 |
  | accept 1093 | accept 1033 | 25 | 25 |
  | accept 1085 | turnin 970 | 23 | 29 |
  | turnin 1085 | complete 1033 | 29 | 22 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 0 | 0 | 994 |
  | WARLOCK | 4 | 0 | 0 | 3 | 1094 |
  | DRUID | 7 | 0 | 0 | 6 | 6343 |

- Hearthstone: APR uses it 2-5 times (WARRIOR 4, PALADIN 2, HUNTER 5, ROGUE 4, PRIEST 4, SHAMAN 2, MAGE 2, WARLOCK 2, DRUID 5; 4 "if ready" steps open to all) and binds it 1-3 times (maps Darkshore (1439), Ashenvale (1440)); Questify uses it 0 times and binds it 0 times (maps none).

### A_03 — Redridge Mountains and Duskwood (22-26)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #57 (Duskwood (1431), 24-27): 42 shared of 71. Slice: 280 of 322 steps.
- Questify -> APR: 42 of 56 general quests in the matched routes (75 %), 53 anywhere in APR (95 %).
  - Absent from APR (Questify-only): 96137, 96138, 96139 (6 000 XP)
  - In another APR route: 133, 134, 160, 181, 251, 252, 253, 377, 401, 95999, 98387
- APR -> Questify (slice): 42 of 57 general quests in this chapter (74 %).
  - In another Questify chapter: 103, 173
  - In no Questify chapter (APR-only): 34, 67, 68, 69, 70, 72, 74, 90, 94, 104, 126, 1076, 1078 (19 000 XP)
  - Left out, quest level above 28 (band + 2): 269, 335
    - finisher outside the chapter zones: 67, 69
    - manual drop (overrides.lua): 34
    - not a candidate of the chapter: 68, 70, 72, 74, 94, 104, 1076, 1078
    - prerequisite unavailable: 126
    - requires a profession: 90
- Order: 89 shared events, 3184 of 3916 pairs in the same order (81 %), Kendall tau 0.63.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 58 | turnin 127 | 39 | 35 |
  | accept 159 | complete 127 | 36 | 35 |
  | turnin 57 | turnin 150 | 39 | 33 |
  | turnin 156 | turnin 20 | 35 | 33 |
  | complete 156 | accept 150 | 31 | 31 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | PALADIN | 3 | 0 | 0 | 3 | none |
  | ROGUE | 2 | 0 | 0 | 2 | none |
  | DRUID | 2 | 0 | 0 | 2 | none |

- Hearthstone: APR uses it 2-3 times (WARRIOR 2, PALADIN 2, HUNTER 2, ROGUE 3, PRIEST 2, SHAMAN 2, MAGE 2, WARLOCK 2, DRUID 3; 2 "if ready" steps open to all) and binds it 1-2 times (maps Duskwood (1431)); Questify uses it 3 times and binds it 1 times (maps Duskwood (1431)).

### A_04 — Wetlands (26-29)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #52 (Wetlands (1437), 22-24): 4 shared of 16; #61 (Wetlands (1437), 27-29): 15 shared of 42. Slice: 284 of 298 steps.
- Questify -> APR: 15 of 32 general quests in the matched routes (47 %), 16 anywhere in APR (50 %).
  - Absent from APR (Questify-only): 303, 304, 87491, 95646, 95647, 98072, 98189, 98216, 98223, 98230, 98240, 98245, 98283, 98291, 98815, 98824 (25 630 XP)
  - In another APR route: 288
- APR -> Questify (slice): 14 of 42 general quests in this chapter (33 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 269, 270, 275, 276, 277, 279, 281, 284, 285, 286, 293, 321, 324, 335, 337, 463, 469, 471, 484, 631, 632, 633, 634, 637, 647, 943, 968, 2923 (45 375 XP)
  - Left out, quest level above 31 (band + 2): 538
    - finisher outside the chapter zones: 293, 634
    - manual drop (overrides.lua): 631
    - not a candidate of the chapter: 269, 270, 335, 337, 637, 647, 968, 2923
    - objective item source not in zone: 943
    - objective object not in zone: 633
    - prerequisite unavailable: 275, 277, 281, 284, 285, 286, 321, 324, 471, 632
    - quest level below the band: 276, 279, 463, 469, 484
- Order: 36 shared events, 451 of 630 pairs in the same order (72 %), Kendall tau 0.43.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 472 | turnin 306 | 27 | 25 |
  | accept 98221 | complete 294 | 16 | 16 |
  | turnin 98221 | turnin 305 | 17 | 15 |
  | accept 472 | accept 305 | 11 | 11 |
  | turnin 464 | accept 306 | 10 | 12 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 1 | 0 | none |
  | MAGE | 1 | 0 | 1 | 0 | none |
  | WARLOCK | 1 | 0 | 1 | 0 | none |

- Hearthstone: APR uses it 3 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 3, MAGE 3, WARLOCK 3, DRUID 3; 3 "if ready" steps open to all) and binds it 1 times (maps Wetlands (1437)); Questify uses it 0 times and binds it 0 times (maps none).

### A_05 — Hillsbrad Foothills (29-30)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #68 (Hillsbrad Foothills (1424), 32-33): 6 shared of 27. Slice: 48 of 104 steps.
- Questify -> APR: 6 of 8 general quests in the matched routes (75 %), 6 anywhere in APR (75 %).
  - Absent from APR (Questify-only): 98059, 98071 (2 200 XP)
  - In another APR route: none
- APR -> Questify (slice): 6 of 8 general quests in this chapter (75 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 563, 689 (5 700 XP)
  - Left out, quest level above 32 (band + 2): 505, 510, 511, 514, 522, 564, 565
    - finisher outside the chapter zones: 563
    - not a candidate of the chapter: 689
- Order: 15 shared events, 92 of 105 pairs in the same order (88 %), Kendall tau 0.75.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 555 | accept 560 | 6 | 7 |
  | turnin 555 | turnin 562 | 1 | 2 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 1 times (maps Hillsbrad Foothills (1424)); Questify uses it 0 times and binds it 0 times (maps none).

### A_08 — Ashenvale (30-32)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #63 (Ashenvale (1440), 29-30): 8 shared of 26. Slice: 86 of 132 steps.
- Questify -> APR: 8 of 12 general quests in the matched routes (67 %), 8 anywhere in APR (67 %).
  - Absent from APR (Questify-only): 1012, 86757, 98027, 98418 (8 690 XP)
  - In another APR route: none
- APR -> Questify (slice): 8 of 22 general quests in this chapter (36 %).
  - In another Questify chapter: 973, 1025, 1054
  - In no Questify chapter (APR-only): 1016, 1024, 1026, 1027, 1028, 1029, 1030, 1037, 1045, 1046, 1055 (16 195 XP)
    - finisher outside the chapter zones: 1037
    - objective item source not in zone: 1016, 1046
    - prerequisite unavailable: 1026, 1027, 1028, 1029, 1030, 1045, 1055
    - quest level below the band: 1024
- Order: 22 shared events, 185 of 231 pairs in the same order (80 %), Kendall tau 0.60.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 1035 | accept 1140 | 9 | 11 |
  | complete 1011 | complete 1022 | 5 | 10 |
  | turnin 1011 | turnin 1022 | 6 | 5 |
  | accept 1011 | turnin 1021 | 4 | 4 |
  | turnin 4581 | accept 1031 | 4 | 2 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### A_07 — Duskwood (32-33)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #64 (Duskwood (1431), 29-32): 9 shared of 66. Slice: 123 of 237 steps.
- Questify -> APR: 9 of 9 general quests in the matched routes (100 %), 9 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 9 of 38 general quests in this chapter (24 %).
  - In another Questify chapter: 58, 101, 133, 134, 159, 160, 181, 185, 190, 215, 251, 252, 253, 377, 401, 583
  - In no Questify chapter (APR-only): 55, 74, 75, 78, 79, 80, 97, 98, 325, 335, 1243, 1244, 1245 (17 475 XP)
    - finisher outside the chapter zones: 1245
    - not a candidate of the chapter: 74, 75, 78, 325, 335, 1243
    - prerequisite unavailable: 55, 79, 80, 97, 98, 1244
- Order: 21 shared events, 180 of 210 pairs in the same order (86 %), Kendall tau 0.71.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 227 | accept 221 | 4 | 4 |
  | accept 229 | accept 222 | 4 | 4 |
  | turnin 225 | turnin 173 | 4 | 4 |
  | turnin 227 | complete 221 | 4 | 4 |
  | turnin 228 | turnin 221 | 4 | 4 |

- Class quests: none on either side.
- Hearthstone: APR uses it 2 times (WARRIOR 2, PALADIN 2, HUNTER 2, ROGUE 2, PRIEST 2, SHAMAN 2, MAGE 2, WARLOCK 2, DRUID 2; 2 "if ready" steps open to all) and binds it 1 times (maps Duskwood (1431)); Questify uses it 1 times and binds it 0 times (maps none).

### A_09 — Thousand Needles (33-34)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #69 (Thousand Needles (1441), 33-34): 10 shared of 41; #74 (Desolace (1443), 35-37): 3 shared of 30. Slice: 201 of 264 steps.
- Questify -> APR: 12 of 13 general quests in the matched routes (92 %), 12 anywhere in APR (92 %).
  - Absent from APR (Questify-only): 1221 (630 XP)
  - In another APR route: none
- APR -> Questify (slice): 12 of 38 general quests in this chapter (32 %).
  - In another Questify chapter: 1219, 1220, 1253, 1282, 1284, 1319, 1320, 1387, 1437, 1438, 1439, 1440, 1465, 5561, 5741, 6161
  - In no Questify chapter (APR-only): 1039, 1040, 1135, 1179, 1370, 1382, 1384, 1453, 1458, 1459 (20 560 XP)
  - Left out, quest level above 36 (band + 2): 1183, 1186, 1187, 1252, 1259, 1285, 1373, 1454, 1455, 1456, 1457, 5501, 6027
    - not a candidate of the chapter: 1039, 1135, 1179, 1370, 1382, 1384, 1453, 1458, 1459
    - prerequisite unavailable: 1040
- Order: 26 shared events, 238 of 325 pairs in the same order (73 %), Kendall tau 0.46.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 1112 | turnin 1175 | 13 | 11 |
  | accept 5762 | complete 1175 | 13 | 10 |
  | accept 1111 | complete 1105 | 9 | 10 |
  | turnin 1111 | turnin 1104 | 11 | 7 |
  | accept 1180 | turnin 1105 | 7 | 5 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 4 | 0 | 0 | 4 | none |
  | WARLOCK | 4 | 0 | 0 | 4 | none |

- Hearthstone: APR uses it 2-3 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 3, MAGE 3, WARLOCK 2, DRUID 3; 3 "if ready" steps open to all) and binds it 1 times (maps Desolace (1443)); Questify uses it 0 times and binds it 0 times (maps none).

### A_10 — Stranglethorn Vale (34-35)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #64 (Duskwood (1431), 29-32): 4 shared of 66; #72 (Stranglethorn Vale (1434), 34-35): 17 shared of 46; #77 (Stranglethorn Vale (1434), 36-38): 10 shared of 26. Slice: 324 of 495 steps.
- Questify -> APR: 22 of 22 general quests in the matched routes (100 %), 22 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 22 of 69 general quests in this chapter (32 %).
  - In another Questify chapter: 189, 213, 222, 223, 228, 229, 231, 253, 575, 577, 578, 601, 605, 616, 1115, 1180, 1181, 1182
  - In no Questify chapter (APR-only): 55, 198, 201, 325, 335, 336, 337, 514, 563, 622, 627, 689, 690, 700, 1040, 1041, 1042, 1043, 1078, 1183, 1245, 1246, 1247, 1248, 1301, 1447, 1453, 2904, 2923 (38 950 XP)
  - Left out, quest level above 37 (band + 2): 193, 196, 202, 205, 538
    - not a candidate of the chapter: 55, 198, 201, 325, 335, 336, 337, 514, 563, 622, 627, 689, 690, 700, 1040, 1041, 1042, 1043, 1078, 1183, 1245, 1246, 1247, 1248, 1301, 1447, 1453, 2904, 2923
- Order: 55 shared events, 1223 of 1485 pairs in the same order (82 %), Kendall tau 0.65.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 192 | turnin 203 | 16 | 15 |
  | accept 194 | turnin 190 | 14 | 15 |
  | turnin 191 | turnin 204 | 18 | 13 |
  | complete 191 | turnin 200 | 13 | 12 |
  | complete 194 | accept 328 | 13 | 12 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 2 | none |
  | HUNTER | 1 | 0 | 0 | 0 | 1107 |
  | WARLOCK | 4 | 0 | 0 | 4 | none |

- Hearthstone: APR uses it 2 times (WARRIOR 2, PALADIN 2, HUNTER 2, ROGUE 2, PRIEST 2, SHAMAN 2, MAGE 2, WARLOCK 2, DRUID 2; 2 "if ready" steps open to all) and binds it 2 times (maps Stranglethorn Vale (1434)); Questify uses it 1 times and binds it 0 times (maps none).

### A_11 — Desolace (35-37)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #74 (Desolace (1443), 35-37): 11 shared of 30. Slice: 78 of 142 steps.
- Questify -> APR: 11 of 19 general quests in the matched routes (58 %), 14 anywhere in APR (74 %).
  - Absent from APR (Questify-only): 5821, 5943, 6132, 92743, 93224 (12 950 XP)
  - In another APR route: 261, 635, 6134
- APR -> Questify (slice): 11 of 21 general quests in this chapter (52 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 1370, 1373, 1382, 1384, 1454, 1455, 1456, 1457, 1458, 1459 (23 200 XP)
    - finisher outside the chapter zones: 1457
    - manual drop (overrides.lua): 1370, 1373, 1382, 1384
    - prerequisite unavailable: 1454, 1455, 1456, 1458, 1459
- Order: 30 shared events, 357 of 435 pairs in the same order (82 %), Kendall tau 0.64.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 1439 | accept 5561 | 8 | 8 |
  | turnin 1438 | complete 6161 | 7 | 7 |
  | accept 1439 | complete 1387 | 7 | 6 |
  | accept 1438 | accept 5741 | 6 | 6 |
  | complete 5501 | turnin 5741 | 6 | 6 |

- Class quests: none on either side.
- Hearthstone: APR uses it 1-2 times (WARRIOR 2, PALADIN 2, HUNTER 2, ROGUE 2, PRIEST 2, SHAMAN 2, MAGE 2, WARLOCK 1, DRUID 2; 2 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### A_12 — Stranglethorn Vale and Swamp of Sorrows (37-39)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #72 (Stranglethorn Vale (1434), 34-35): 10 shared of 46; #77 (Stranglethorn Vale (1434), 36-38): 7 shared of 26; #89 (Stranglethorn Vale (1434), 41-43): 12 shared of 48. Slice: 440 of 442 steps.
- Questify -> APR: 25 of 28 general quests in the matched routes (89 %), 27 anywhere in APR (96 %).
  - Absent from APR (Questify-only): 93176 (1 350 XP)
  - In another APR route: 1389, 1392
- APR -> Questify (slice): 25 of 84 general quests in this chapter (30 %).
  - In another Questify chapter: 185, 186, 187, 188, 190, 191, 192, 194, 195, 196, 200, 202, 203, 204, 207, 213, 215, 228, 231, 328, 329, 330, 331, 339, 340, 341, 342, 574, 583, 5762
  - In no Questify chapter (APR-only): 55, 198, 201, 325, 337, 338, 514, 538, 542, 543, 563, 603, 610, 611, 622, 627, 669, 689, 700, 1040, 1041, 1042, 1043, 1116, 1183, 1258, 1364, 1453, 2904 (57 635 XP)
  - Left out, quest level above 41 (band + 2): 197, 208, 580, 604, 609, 617, 621, 623, 624, 625, 1118, 1119, 1395, 1398, 1425, 1477, 2864, 2872
    - finisher outside the chapter zones: 1041, 1183
    - level band reached: 198, 201, 1116
    - not a candidate of the chapter: 55, 325, 337, 514, 538, 542, 543, 563, 603, 669, 689, 700, 1040, 1042, 1043, 1258, 1364, 1453, 2904
    - objective item source not in zone: 338, 627
    - prerequisite unavailable: 610, 611, 622
- Order: 61 shared events, 1371 of 1830 pairs in the same order (75 %), Kendall tau 0.50.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 595 | complete 1182 | 28 | 26 |
  | accept 599 | turnin 1182 | 26 | 24 |
  | accept 606 | accept 1182 | 21 | 26 |
  | complete 587 | accept 602 | 20 | 29 |
  | turnin 595 | turnin 605 | 20 | 23 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 1 | 0 | 0 | 1 | none |
  | HUNTER | 1 | 0 | 0 | 0 | 1107 |
  | WARLOCK | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 3-4 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 3, MAGE 3, WARLOCK 4, DRUID 3; 3 "if ready" steps open to all) and binds it 3-4 times (maps Stranglethorn Vale (1434), Stormwind City (1453)); Questify uses it 4 times and binds it 1 times (maps Stranglethorn Vale (1434)).

### A_13 — Arathi Highlands (39-40)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #83 (Arathi Highlands (1417), 39-40): 12 shared of 49. Slice: 221 of 246 steps.
- Questify -> APR: 12 of 13 general quests in the matched routes (92 %), 12 anywhere in APR (92 %).
  - Absent from APR (Questify-only): 96800 (1 425 XP)
  - In another APR route: none
- APR -> Questify (slice): 12 of 37 general quests in this chapter (32 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 500, 512, 522, 523, 525, 537, 538, 540, 542, 543, 551, 554, 603, 642, 651, 652, 653, 657, 658, 659, 660, 661, 664, 669, 1052 (62 640 XP)
  - Left out, quest level above 42 (band + 2): 1449, 1450, 1451, 1452
    - finisher outside the chapter zones: 551, 603, 653, 661, 669
    - level band reached: 642, 651, 652, 664
    - not a candidate of the chapter: 500, 512, 522, 523, 525, 537, 538, 540, 542, 543, 554, 659, 1052
    - prerequisite unavailable: 657, 658, 660
- Order: 26 shared events, 288 of 325 pairs in the same order (89 %), Kendall tau 0.77.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 666 | turnin 602 | 11 | 12 |
  | complete 662 | complete 694 | 6 | 8 |
  | turnin 694 | turnin 684 | 2 | 2 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 3 | 0 | 0 | 3 | none |

- Hearthstone: APR uses it 10 times (WARRIOR 10, PALADIN 10, HUNTER 10, ROGUE 10, PRIEST 10, SHAMAN 10, MAGE 10, WARLOCK 10, DRUID 10; 10 "if ready" steps open to all) and binds it 1 times (maps Hillsbrad Foothills (1424)); Questify uses it 0 times and binds it 0 times (maps none).

### A_15 — Dustwallow Marsh (40-41)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #85 (Wetlands (1437), 40-40): 7 shared of 22. Slice: 45 of 65 steps.
- Questify -> APR: 7 of 18 general quests in the matched routes (39 %), 17 anywhere in APR (94 %).
  - Absent from APR (Questify-only): 7070 (1 725 XP)
  - In another APR route: 1219, 1220, 1252, 1253, 1259, 1282, 1284, 1285, 1319, 1320
- APR -> Questify (slice): 7 of 14 general quests in this chapter (50 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 1187, 1203, 1258, 1260, 1266, 1267, 1324 (17 760 XP)
    - event: 1324
    - not a candidate of the chapter: 1187, 1260
    - objective item source not in zone: 1203, 1258
    - prerequisite unavailable: 1266, 1267
- Order: 17 shared events, 120 of 136 pairs in the same order (88 %), Kendall tau 0.76.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 1218 | complete 1177 | 5 | 2 |
  | accept 1287 | turnin 1206 | 2 | 3 |
  | turnin 1177 | complete 1222 | 3 | 2 |
  | accept 1204 | accept 1286 | 3 | 1 |
  | accept 1222 | complete 1206 | 1 | 1 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### A_16 — Badlands (41-42)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #88 (Badlands (1418), 41-41): 10 shared of 30. Slice: 61 of 116 steps.
- Questify -> APR: 10 of 13 general quests in the matched routes (77 %), 10 anywhere in APR (77 %).
  - Absent from APR (Questify-only): 721, 2198, 2418 (4 500 XP)
  - In another APR route: none
- APR -> Questify (slice): 10 of 25 general quests in this chapter (40 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 687, 692, 705, 713, 714, 715, 716, 734, 738, 739, 777, 1106, 1108, 1137, 2500 (33 900 XP)
  - Left out, quest level above 44 (band + 2): 778
    - finisher outside the chapter zones: 739, 1137
    - not a candidate of the chapter: 687, 738, 1106, 2500
    - objective item source not in zone: 705, 713, 714, 715, 716
    - prerequisite unavailable: 692, 734, 777, 1108
- Order: 27 shared events, 272 of 351 pairs in the same order (77 %), Kendall tau 0.55.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 710 | accept 720 | 9 | 11 |
  | accept 711 | turnin 719 | 10 | 9 |
  | complete 710 | turnin 718 | 9 | 9 |
  | turnin 710 | accept 733 | 9 | 9 |
  | complete 711 | turnin 703 | 8 | 7 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### A_17 — Stranglethorn Vale (42-44)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #89 (Stranglethorn Vale (1434), 41-43): 13 shared of 48. Slice: 150 of 184 steps.
- Questify -> APR: 13 of 19 general quests in the matched routes (68 %), 17 anywhere in APR (89 %).
  - Absent from APR (Questify-only): 206, 613 (9 700 XP)
  - In another APR route: 213, 348, 608, 8551
- APR -> Questify (slice): 13 of 45 general quests in this chapter (29 %).
  - In another Questify chapter: 193, 205, 209, 576, 587, 595, 597, 599, 600, 606, 607, 628
  - In no Questify chapter (APR-only): 338, 603, 610, 611, 622, 623, 624, 625, 627, 669, 1116, 1118, 1119, 1258, 1364, 1395, 1398, 1425, 1477, 2864 (53 455 XP)
  - Left out, quest level above 46 (band + 2): 580
    - dungeon quest not picked up: 2864
    - finisher outside the chapter zones: 623, 624, 1119
    - not a candidate of the chapter: 603, 625, 669, 1118, 1258, 1364, 1395, 1398, 1425, 1477
    - objective item source not in zone: 338, 627, 1116
    - prerequisite unavailable: 610, 611, 622
- Order: 31 shared events, 279 of 465 pairs in the same order (60 %), Kendall tau 0.20.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 2872 | complete 197 | 19 | 27 |
  | turnin 609 | turnin 197 | 15 | 15 |
  | turnin 621 | accept 208 | 14 | 12 |
  | turnin 604 | accept 197 | 11 | 19 |
  | complete 621 | complete 196 | 10 | 11 |

- Class quests: none on either side.
- Hearthstone: APR uses it 1-2 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 2, DRUID 1; 1 "if ready" steps open to all) and binds it 1 times (maps Stranglethorn Vale (1434)); Questify uses it 2 times and binds it 0 times (maps none).

### A_18 — Tanaris (44-45)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #93 (Tanaris (1446), 43-44): 6 shared of 24. Slice: 56 of 88 steps.
- Questify -> APR: 6 of 14 general quests in the matched routes (43 %), 11 anywhere in APR (79 %).
  - Absent from APR (Questify-only): 2768, 2865, 3042 (7 050 XP)
  - In another APR route: 82, 992, 1691, 2781, 2875
- APR -> Questify (slice): 6 of 17 general quests in this chapter (35 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 1119, 1120, 1122, 1137, 1188, 1189, 1190, 1194, 2864, 3022, 3520 (18 120 XP)
    - finisher outside the chapter zones: 1189, 3022
    - not a candidate of the chapter: 1119, 1120, 1122, 1137, 1188, 1190, 1194, 2864
    - objective npc not in zone: 3520
- Order: 10 shared events, 36 of 45 pairs in the same order (80 %), Kendall tau 0.60.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 1690 | accept 2873 | 4 | 3 |
  | complete 1690 | accept 8366 | 3 | 3 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 0 | 0 | 3161 |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 2 times and binds it 1 times (maps Tanaris (1446)).

### A_19 — Feralas (45-46)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #96 (Feralas (1444), 44-48): 22 shared of 32. Slice: 173 of 179 steps.
- Questify -> APR: 22 of 27 general quests in the matched routes (81 %), 27 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: 2844, 2845, 7003, 7721, 7733
- APR -> Questify (slice): 22 of 31 general quests in this chapter (71 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 1452, 2939, 2940, 2941, 2972, 3022, 3520, 3661, 4267 (23 345 XP)
  - Left out, quest level above 48 (band + 2): 3445
    - finisher outside the chapter zones: 2939, 2972, 4267
    - not a candidate of the chapter: 1452, 2940, 2941, 3022, 3520, 3661
- Order: 51 shared events, 1052 of 1275 pairs in the same order (83 %), Kendall tau 0.65.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 2821 | turnin 2870 | 26 | 21 |
  | accept 2766 | complete 2869 | 18 | 16 |
  | accept 4281 | turnin 2871 | 15 | 15 |
  | accept 2767 | complete 2870 | 14 | 15 |
  | turnin 4131 | accept 2871 | 14 | 14 |

- Class quests: none on either side.
- Hearthstone: APR uses it 4 times (WARRIOR 4, PALADIN 4, HUNTER 4, ROGUE 4, PRIEST 4, SHAMAN 4, MAGE 4, WARLOCK 4, DRUID 4; 4 "if ready" steps open to all) and binds it 1 times (maps Feralas (1444)); Questify uses it 0 times and binds it 0 times (maps none).

### A_20 — Tanaris (46-48)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #101 (Tanaris (1446), 48-50): 11 shared of 54. Slice: 128 of 200 steps.
- Questify -> APR: 11 of 11 general quests in the matched routes (100 %), 11 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 11 of 20 general quests in this chapter (55 %).
  - In another Questify chapter: 1691, 2781, 2873, 2875, 3884, 8365, 8366
  - In no Questify chapter (APR-only): 2876, 3520 (8 600 XP)
  - Left out, quest level above 50 (band + 2): 3444, 3445, 3844, 3845, 3908, 4141, 4284, 4289, 4290, 4291, 4292
    - not a candidate of the chapter: 2876
    - objective npc not in zone: 3520
- Order: 26 shared events, 228 of 325 pairs in the same order (70 %), Kendall tau 0.40.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 3362 | complete 648 | 14 | 12 |
  | complete 2605 | accept 2874 | 14 | 10 |
  | accept 3362 | complete 3161 | 8 | 12 |
  | turnin 2605 | accept 113 | 5 | 7 |
  | accept 2605 | complete 10 | 5 | 6 |

- Class quests: none on either side.
- Hearthstone: APR uses it 2 times (WARRIOR 2, PALADIN 2, HUNTER 2, ROGUE 2, PRIEST 2, SHAMAN 2, MAGE 2, WARLOCK 2, DRUID 2; 2 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### A_21 — Stranglethorn Vale (48-50)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #104 (Stranglethorn Vale (1434), 50-50): 7 shared of 15. Slice: 48 of 87 steps.
- Questify -> APR: 7 of 8 general quests in the matched routes (88 %), 7 anywhere in APR (88 %).
  - Absent from APR (Questify-only): 8554 (7 100 XP)
  - In another APR route: none
- APR -> Questify (slice): 7 of 14 general quests in this chapter (50 %).
  - In another Questify chapter: 348, 608, 8551
  - In no Questify chapter (APR-only): 580, 836, 1122, 3721 (19 100 XP)
    - not a candidate of the chapter: 836, 1122
    - objective item source not in zone: 580
    - prerequisite unavailable: 3721
- Order: 9 shared events, 15 of 36 pairs in the same order (42 %), Kendall tau -0.17.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 8552 | turnin 2874 | 5 | 6 |
  | accept 8553 | accept 594 | 5 | 4 |
  | turnin 8553 | turnin 594 | 5 | 4 |
  | turnin 648 | turnin 2767 | 1 | 1 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### A_22 — Searing Gorge and Blasted Lands (50-52)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #105 (Searing Gorge (1427), 50-51): 10 shared of 26; #106 (Blasted Lands (1419), 51-51): 7 shared of 10. Slice: 177 of 195 steps.
- Questify -> APR: 17 of 18 general quests in the matched routes (94 %), 17 anywhere in APR (94 %).
  - Absent from APR (Questify-only): 4128 (280 XP)
  - In another APR route: none
- APR -> Questify (slice): 17 of 29 general quests in this chapter (59 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 3181, 3182, 3368, 3441, 3442, 3443, 3452, 3453, 3454, 3462, 3463, 3481 (41 900 XP)
  - Left out, quest level above 54 (band + 2): 2783, 2801, 7791, 7793, 7794, 7795
    - event: 3441, 3453
    - finisher outside the chapter zones: 3181, 3368
    - not a candidate of the chapter: 3182
    - prerequisite unavailable: 3442, 3443, 3452, 3454, 3462, 3463, 3481
- Order: 41 shared events, 308 of 820 pairs in the same order (38 %), Kendall tau -0.25.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 2521 | complete 7724 | 29 | 29 |
  | turnin 2521 | turnin 4451 | 31 | 28 |
  | accept 3501 | accept 4451 | 26 | 29 |
  | turnin 3501 | turnin 4449 | 29 | 23 |
  | accept 2581 | complete 7701 | 22 | 26 |

- Class quests: none on either side.
- Hearthstone: APR uses it 1 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 1; 1 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### A_28 — Burning Steppes (52-53)

No APR leveling route shares enough quests with this chapter.

### A_24 — Felwood (53-54)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #109 (Felwood (1448), 52-52): 9 shared of 29; #115 (Felwood (1448), 54-56): 8 shared of 47. Slice: 300 of 484 steps.
- Questify -> APR: 17 of 18 general quests in the matched routes (94 %), 17 anywhere in APR (94 %).
  - Absent from APR (Questify-only): 5249 (580 XP)
  - In another APR route: none
- APR -> Questify (slice): 17 of 41 general quests in this chapter (41 %).
  - In another Questify chapter: 980, 5082
  - In no Questify chapter (APR-only): 978, 3908, 3909, 3912, 3913, 3914, 3941, 3942, 4084, 4261, 4441, 4442, 4512, 5084, 5085, 5086, 5158, 5159, 5165, 6031, 8467, 8470 (101 310 XP)
  - Left out, quest level above 56 (band + 2): 5242
    - finisher outside the chapter zones: 4261, 5158
    - manual drop (overrides.lua): 6031, 8470
    - not a candidate of the chapter: 978, 3908, 3909, 3912, 3913, 3914, 3941, 3942, 4512, 5084, 5086, 5159
    - objective item source not in zone: 4441
    - prerequisite unavailable: 4084, 4442, 5085, 5165
    - repeatable: 8467
- Order: 42 shared events, 588 of 861 pairs in the same order (68 %), Kendall tau 0.37.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 5204 | turnin 5157 | 19 | 17 |
  | accept 5203 | complete 5157 | 16 | 16 |
  | complete 5203 | complete 4906 | 20 | 15 |
  | turnin 5203 | turnin 4906 | 18 | 15 |
  | accept 5202 | accept 4906 | 16 | 15 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 0 | 0 | 979 |
  | WARLOCK | 2 | 0 | 0 | 2 | none |

- Hearthstone: APR uses it 1 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 1; 1 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### A_26 — Un'Goro Crater (54-56)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #113 (Un'Goro Crater (1449), 53-54): 15 shared of 44. Slice: 79 of 139 steps.
- Questify -> APR: 15 of 19 general quests in the matched routes (79 %), 19 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: 3844, 4141, 4290, 4291
- APR -> Questify (slice): 15 of 24 general quests in this chapter (63 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 4244, 4245, 4285, 4287, 4288, 4321, 4496, 4502, 4513 (40 580 XP)
    - event: 4285, 4287, 4288, 4321
    - not a candidate of the chapter: 4496, 4502, 4513
    - objective item source not in zone: 4244
    - prerequisite unavailable: 4245
- Order: 37 shared events, 471 of 666 pairs in the same order (71 %), Kendall tau 0.41.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 4243 | turnin 4292 | 23 | 22 |
  | accept 4243 | turnin 4284 | 19 | 30 |
  | accept 3884 | complete 4292 | 11 | 20 |
  | complete 4301 | turnin 4491 | 8 | 10 |
  | turnin 4492 | accept 4301 | 8 | 9 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### A_27 — Winterspring (56-57)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #115 (Felwood (1448), 54-56): 14 shared of 47; #120 (Eastern Plaguelands (1423), 57-59): 4 shared of 66; #122 (Winterspring (1452), 59-60): 4 shared of 57. Slice: 642 of 882 steps.
- Questify -> APR: 17 of 20 general quests in the matched routes (85 %), 17 anywhere in APR (85 %).
  - Absent from APR (Questify-only): 5249, 6603, 6604 (1 800 XP)
  - In another APR route: none
- APR -> Questify (slice): 17 of 101 general quests in this chapter (17 %).
  - In another Questify chapter: 4971, 4972, 4984, 4985, 5058, 5060, 5092, 5097, 5203, 5204, 5211, 5215, 5216, 5217, 5219, 5220, 5222, 5223, 5225, 5226, 5237, 5385, 5401, 5533, 5537, 5542, 5543, 5544, 6004, 6021, 6023, 6025
  - In no Questify chapter (APR-only): 978, 979, 3378, 3908, 3909, 3912, 3913, 3914, 3941, 3942, 4084, 4261, 4513, 4808, 4809, 4901, 4986, 5050, 5051, 5059, 5066, 5084, 5085, 5086, 5087, 5121, 5123, 5128, 5142, 5149, 5152, 5153, 5154, 5163, 5165, 5168, 5181, 5210, 5241, 5242, 5250, 5742, 5781, 5845, 5846, 5903, 5904, 6026, 6031, 6389, 8467, 8470 (239 815 XP)
  - Left out, quest level above 59 (band + 2): 5281, 6024, 6184, 6185, 6186, 7791, 7793, 7794, 7795, 9124, 9126, 9128, 9131, 9136
    - finisher outside the chapter zones: 3912, 4901, 5084, 5128
    - not a candidate of the chapter: 978, 979, 3378, 3908, 3913, 3914, 3941, 3942, 4084, 4261, 4513, 4808, 4986, 5050, 5051, 5059, 5066, 5085, 5142, 5149, 5152, 5153, 5154, 5165, 5168, 5181, 5210, 5241, 5242, 5250, 5742, 5781, 5845, 5846, 5903, 5904, 6026, 6031, 6389, 8467, 8470
    - objective item source not in zone: 3909, 5086
    - objective npc not in zone: 5163
    - prerequisite unavailable: 4809, 5087, 5121, 5123
- Order: 32 shared events, 332 of 496 pairs in the same order (67 %), Kendall tau 0.34.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 3783 | complete 5082 | 23 | 22 |
  | accept 8464 | turnin 5082 | 22 | 20 |
  | accept 6030 | accept 5082 | 10 | 10 |
  | complete 4842 | complete 5245 | 15 | 9 |
  | accept 6028 | turnin 980 | 8 | 10 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 0 | 0 | 4902 |

- Hearthstone: APR uses it 4 times (WARRIOR 4, PALADIN 4, HUNTER 4, ROGUE 4, PRIEST 4, SHAMAN 4, MAGE 4, WARLOCK 4, DRUID 4; 4 "if ready" steps open to all) and binds it 4 times (maps Eastern Plaguelands (1423), Hillsbrad Foothills (1424), Winterspring (1452)); Questify uses it 1 times and binds it 0 times (maps none).

### A_23 — Western Plaguelands (57-58)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #120 (Eastern Plaguelands (1423), 57-59): 25 shared of 66. Slice: 256 of 276 steps.
- Questify -> APR: 25 of 29 general quests in the matched routes (86 %), 26 anywhere in APR (90 %).
  - Absent from APR (Questify-only): 211, 5343, 5382 (14 900 XP)
  - In another APR route: 5021
- APR -> Questify (slice): 25 of 64 general quests in this chapter (39 %).
  - In another Questify chapter: 5211, 5245, 5281, 5542, 5543, 5544, 5601, 6021, 6024, 6030
  - In no Questify chapter (APR-only): 4986, 5050, 5051, 5059, 5142, 5149, 5152, 5153, 5154, 5168, 5181, 5210, 5241, 5742, 5781, 5845, 5846, 5903, 5904, 6026, 6184, 6185, 6186, 6389, 9124, 9126, 9128, 9131, 9136 (146 380 XP)
    - finisher outside the chapter zones: 4986, 6186
    - not a candidate of the chapter: 5050, 5149, 5152, 5168, 5181, 5241, 5742, 5781, 5845, 5846, 6026, 6184, 9124, 9126, 9128, 9131, 9136
    - objective item source not in zone: 5051, 5903, 6185
    - prerequisite unavailable: 5142, 5153, 5154, 5210, 5904, 6389
    - repeatable: 5059
- Order: 62 shared events, 1402 of 1891 pairs in the same order (74 %), Kendall tau 0.48.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 6004 | accept 5058 | 32 | 33 |
  | complete 6004 | turnin 5058 | 32 | 33 |
  | complete 4972 | turnin 5060 | 22 | 22 |
  | turnin 4972 | complete 5219 | 22 | 22 |
  | accept 4971 | accept 5219 | 20 | 23 |

- Class quests: none on either side.
- Hearthstone: APR uses it 2 times (WARRIOR 2, PALADIN 2, HUNTER 2, ROGUE 2, PRIEST 2, SHAMAN 2, MAGE 2, WARLOCK 2, DRUID 2; 2 "if ready" steps open to all) and binds it 1 times (maps Eastern Plaguelands (1423)); Questify uses it 0 times and binds it 0 times (maps none).

### A_29 — Eastern Plaguelands (58-59)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #120 (Eastern Plaguelands (1423), 57-59): 10 shared of 66. Slice: 179 of 276 steps.
- Questify -> APR: 10 of 17 general quests in the matched routes (59 %), 10 anywhere in APR (59 %).
  - Absent from APR (Questify-only): 5212, 5214, 5243, 5251, 5282, 6164, 9664 (27 050 XP)
  - In another APR route: none
- APR -> Questify (slice): 10 of 40 general quests in this chapter (25 %).
  - In another Questify chapter: 4971, 4972, 4985, 5223, 5225, 5226, 5537, 6004, 6023, 6025
  - In no Questify chapter (APR-only): 4986, 5142, 5149, 5152, 5153, 5154, 5168, 5181, 5210, 5241, 5742, 5781, 5845, 5846, 5903, 5904, 6026, 6185, 6186, 6389 (96 230 XP)
    - event: 5742
    - finisher outside the chapter zones: 5152, 5846
    - not a candidate of the chapter: 4986, 5142, 5153, 5154, 5210, 5903, 5904, 6185, 6186, 6389
    - objective item source not in zone: 5149, 5168, 6026
    - prerequisite unavailable: 5181, 5241, 5781, 5845
- Order: 23 shared events, 182 of 253 pairs in the same order (72 %), Kendall tau 0.44.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 6024 | complete 5543 | 14 | 12 |
  | complete 6024 | turnin 5281 | 13 | 8 |
  | turnin 6024 | turnin 5542 | 6 | 8 |
  | turnin 5245 | turnin 5601 | 6 | 7 |
  | complete 6021 | complete 5544 | 2 | 4 |

- Class quests: none on either side.
- Hearthstone: APR uses it 2 times (WARRIOR 2, PALADIN 2, HUNTER 2, ROGUE 2, PRIEST 2, SHAMAN 2, MAGE 2, WARLOCK 2, DRUID 2; 2 "if ready" steps open to all) and binds it 1 times (maps Eastern Plaguelands (1423)); Questify uses it 0 times and binds it 0 times (maps none).

### A_30 — Silithus (59-60)

- Races: Dwarf, Gnome, Human, NightElf, Skyborne. APR routes: #122 (Winterspring (1452), 59-60): 14 shared of 57. Slice: 66 of 267 steps.
- Questify -> APR: 14 of 16 general quests in the matched routes (88 %), 14 anywhere in APR (88 %).
  - Absent from APR (Questify-only): 9415, 9419 (13 200 XP)
  - In another APR route: none
- APR -> Questify (slice): 14 of 22 general quests in this chapter (64 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 1125, 1126, 5527, 6844, 8275, 8307, 8313, 8317 (36 050 XP)
    - finisher outside the chapter zones: 6844
    - not a candidate of the chapter: 5527, 8275
    - prerequisite unavailable: 1125, 1126
    - requires a profession: 8307, 8313, 8317
- Order: 39 shared events, 645 of 741 pairs in the same order (87 %), Kendall tau 0.74.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 8279 | turnin 8308 | 12 | 12 |
  | complete 8318 | complete 8304 | 10 | 18 |
  | accept 8323 | turnin 8304 | 9 | 6 |
  | turnin 8278 | complete 8283 | 6 | 6 |
  | accept 8287 | turnin 8283 | 9 | 4 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### H_OrcTroll_01 — Valley of Trials (1-6)

- Races: Orc, Troll. APR routes: #7 (Durotar (1411), 1-12): 14 shared of 93. Slice: 333 of 681 steps.
- Questify -> APR: 14 of 15 general quests in the matched routes (93 %), 14 anywhere in APR (93 %).
  - Absent from APR (Questify-only): 97279 (170 XP)
  - In another APR route: none
- APR -> Questify (slice): 14 of 31 general quests in this chapter (45 %).
  - In another Questify chapter: 784, 786, 815, 817, 818, 823, 825, 830, 831, 96604, 96655, 96825
  - In no Questify chapter (APR-only): 791, 2161, 96821, 96822, 96873 (2 610 XP)
  - Left out, quest level above 8 (band + 2): 806, 808, 826, 837, 97223, 97225
    - not a candidate of the chapter: 791, 2161, 96821, 96822, 96873
- Order: 37 shared events, 564 of 666 pairs in the same order (85 %), Kendall tau 0.69.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 789 | accept 804 | 12 | 13 |
  | complete 789 | complete 790 | 12 | 11 |
  | turnin 5441 | turnin 804 | 10 | 13 |
  | complete 4402 | turnin 790 | 8 | 12 |
  | accept 6394 | turnin 4402 | 8 | 5 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 2 | none |
  | HUNTER | 2 | 0 | 0 | 2 | none |
  | ROGUE | 2 | 0 | 0 | 2 | none |
  | PRIEST | 3 | 0 | 0 | 3 | none |
  | SHAMAN | 5 | 0 | 0 | 5 | none |
  | MAGE | 2 | 0 | 0 | 2 | none |
  | WARLOCK | 4 | 0 | 0 | 4 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 1 times (maps Durotar (1411)); Questify uses it 0 times and binds it 0 times (maps none).

### H_OrcTroll_02 — Durotar (6-12)

- Races: Orc, Troll. APR routes: #7 (Durotar (1411), 1-12): 36 shared of 93. Slice: 493 of 681 steps.
- Questify -> APR: 36 of 38 general quests in the matched routes (95 %), 36 anywhere in APR (95 %).
  - Absent from APR (Questify-only): 99051, 99052 (1 540 XP)
  - In another APR route: none
- APR -> Questify (slice): 33 of 43 general quests in this chapter (77 %).
  - In another Questify chapter: 805, 96652, 96876, 99123
  - In no Questify chapter (APR-only): 791, 809, 2161, 96821, 96822, 96873 (3 065 XP)
    - exploration point not in zone: 809
    - level band reached: 791, 96821, 96822
    - low ratio: 2161
    - requires a profession: 96873
- Order: 87 shared events, 3022 of 3741 pairs in the same order (81 %), Kendall tau 0.62.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 96877 | turnin 825 | 32 | 41 |
  | accept 97281 | turnin 786 | 28 | 31 |
  | accept 97326 | accept 828 | 27 | 29 |
  | turnin 831 | turnin 828 | 26 | 26 |
  | turnin 97249 | turnin 806 | 25 | 29 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 10 | 0 | 3 | 4 | 812, 813, 816 |
  | ROGUE | 1 | 0 | 0 | 1 | none |
  | PRIEST | 4 | 0 | 0 | 4 | none |
  | SHAMAN | 11 | 0 | 3 | 4 | 812, 813, 816, 842 |
  | WARLOCK | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 0-1 times (WARRIOR 1, PALADIN 0, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 0; 1 "if ready" steps open to all) and binds it 1 times (maps Durotar (1411)); Questify uses it 2 times and binds it 1 times (maps Durotar (1411)).

### H_Tauren_01 — Camp Narache (1-6)

- Races: Tauren. APR routes: #5 (Mulgore (1412), 1-12): 15 shared of 90. Slice: 194 of 457 steps.
- Questify -> APR: 15 of 15 general quests in the matched routes (100 %), 15 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 15 of 35 general quests in this chapter (43 %).
  - In another Questify chapter: 743, 748, 751, 754, 756, 761, 767, 771, 772, 96605, 96659, 96661, 98430, 99108, 99411
  - In no Questify chapter (APR-only): 746, 766, 1656, 95805, 96130 (2 140 XP)
    - level band reached: 95805
    - low ratio: 1656
    - not a candidate of the chapter: 766, 96130
    - objective item source not in zone: 746
- Order: 33 shared events, 456 of 528 pairs in the same order (86 %), Kendall tau 0.73.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 745 | turnin 781 | 8 | 10 |
  | accept 99079 | turnin 780 | 7 | 7 |
  | accept 99081 | accept 763 | 6 | 6 |
  | accept 745 | complete 780 | 5 | 7 |
  | accept 749 | turnin 3376 | 5 | 7 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 1 | 0 | 0 | 1 | none |
  | HUNTER | 1 | 0 | 0 | 1 | none |
  | SHAMAN | 4 | 0 | 0 | 4 | none |
  | DRUID | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 1 times (maps Mulgore (1412)); Questify uses it 0 times and binds it 0 times (maps none).

### H_Tauren_02 — Mulgore (6-12)

- Races: Tauren. APR routes: #5 (Mulgore (1412), 1-12): 33 shared of 90. Slice: 351 of 457 steps.
- Questify -> APR: 33 of 35 general quests in the matched routes (94 %), 33 anywhere in APR (94 %).
  - Absent from APR (Questify-only): 98427, 98435 (1 120 XP)
  - In another APR route: none
- APR -> Questify (slice): 32 of 46 general quests in this chapter (70 %).
  - In another Questify chapter: 745, 749, 763, 870, 99079, 99081, 99101
  - In no Questify chapter (APR-only): 746, 766, 768, 854, 1656, 76160, 96130 (3 835 XP)
    - level band reached: 746, 766, 96130
    - low ratio: 1656
    - not a candidate of the chapter: 854
    - objective item source not in zone: 76160
    - requires a profession: 768
- Order: 85 shared events, 2934 of 3570 pairs in the same order (82 %), Kendall tau 0.64.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 98424 | turnin 99411 | 30 | 32 |
  | accept 751 | accept 99411 | 28 | 26 |
  | complete 761 | turnin 96661 | 46 | 23 |
  | accept 99080 | turnin 99108 | 21 | 23 |
  | turnin 98424 | accept 775 | 20 | 21 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 1 | 0 | 0 | 1 | none |
  | HUNTER | 5 | 0 | 0 | 4 | 76240 |
  | SHAMAN | 4 | 0 | 0 | 3 | 76240 |
  | DRUID | 7 | 0 | 1 | 5 | 76240 |

- Hearthstone: APR uses it 0-1 times (WARRIOR 1, PALADIN 0, HUNTER 1, ROGUE 0, PRIEST 0, SHAMAN 1, MAGE 0, WARLOCK 0, DRUID 1; 0 "if ready" steps open to all) and binds it 2 times (maps Mulgore (1412), Thunder Bluff (1456)); Questify uses it 0 times and binds it 0 times (maps none).

### H_Undead_01 — Deathknell (1-6)

- Races: Undead. APR routes: #3 (Tirisfal Glades (1420), 1-12): 13 shared of 97. Slice: 191 of 750 steps.
- Questify -> APR: 13 of 13 general quests in the matched routes (100 %), 13 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 13 of 23 general quests in this chapter (57 %).
  - In another Questify chapter: 365, 404, 427, 5481, 86784, 96607, 96658, 99134
  - In no Questify chapter (APR-only): 367, 99141 (1 080 XP)
    - not a candidate of the chapter: 367, 99141
- Order: 33 shared events, 504 of 528 pairs in the same order (95 %), Kendall tau 0.91.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 6395 | complete 380 | 5 | 7 |
  | turnin 6395 | turnin 380 | 6 | 5 |
  | accept 6395 | turnin 3901 | 1 | 2 |
  | turnin 98389 | accept 381 | 2 | 1 |
  | complete 364 | accept 376 | 1 | 1 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 1 | 0 | 0 | 1 | none |
  | PALADIN | 4 | 0 | 0 | 4 | none |
  | ROGUE | 1 | 0 | 0 | 1 | none |
  | PRIEST | 2 | 0 | 0 | 2 | none |
  | MAGE | 1 | 0 | 0 | 1 | none |
  | WARLOCK | 2 | 0 | 0 | 2 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 1 times (maps Tirisfal Glades (1420)); Questify uses it 0 times and binds it 0 times (maps none).

### H_Undead_02 — Tirisfal Glades (6-12)

- Races: Undead. APR routes: #3 (Tirisfal Glades (1420), 1-12): 38 shared of 97. Slice: 554 of 750 steps.
- Questify -> APR: 38 of 45 general quests in the matched routes (84 %), 38 anywhere in APR (84 %).
  - Absent from APR (Questify-only): 357, 366, 372, 408, 409, 411, 99156 (4 970 XP)
  - In another APR route: none
- APR -> Questify (slice): 37 of 46 general quests in this chapter (80 %).
  - In another Questify chapter: 8, 383, 96656
  - In no Questify chapter (APR-only): 367, 368, 369, 492, 99141, 99144 (3 590 XP)
    - far: 367
    - level band reached: 99144
    - objective item source not in zone: 99141
    - prerequisite dropped: 368, 369, 492
- Order: 98 shared events, 3970 of 4753 pairs in the same order (84 %), Kendall tau 0.67.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 361 | accept 97558 | 41 | 41 |
  | complete 426 | complete 97558 | 33 | 34 |
  | turnin 407 | turnin 97558 | 32 | 36 |
  | accept 361 | complete 427 | 28 | 32 |
  | complete 95314 | accept 96895 | 28 | 30 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 3 | 0 | 0 | 3 | none |
  | PALADIN | 10 | 0 | 0 | 10 | none |
  | ROGUE | 5 | 0 | 0 | 5 | none |
  | PRIEST | 3 | 0 | 0 | 3 | none |
  | MAGE | 4 | 0 | 1 | 2 | 79095 |
  | WARLOCK | 4 | 0 | 1 | 3 | none |

- Hearthstone: APR uses it 1-2 times (WARRIOR 2, PALADIN 2, HUNTER 1, ROGUE 2, PRIEST 2, SHAMAN 1, MAGE 2, WARLOCK 2, DRUID 1; 2 "if ready" steps open to all) and binds it 1-2 times (maps Tirisfal Glades (1420), Undercity (1458)); Questify uses it 2 times and binds it 1 times (maps Tirisfal Glades (1420)).

### H_Undead_03 — Silverpine Forest (12-15)

- Races: Undead. APR routes: #25 (Silverpine Forest (1421), 12-14): 24 shared of 34. Slice: 300 of 341 steps.
- Questify -> APR: 24 of 38 general quests in the matched routes (63 %), 28 anywhere in APR (74 %).
  - Absent from APR (Questify-only): 428, 443, 444, 446, 448, 450, 460, 461, 491, 98298 (8 170 XP)
  - In another APR route: 440, 6324, 92401, 92421
- APR -> Questify (slice): 24 of 27 general quests in this chapter (89 %).
  - In another Questify chapter: 445
  - In no Questify chapter (APR-only): 481, 482 (200 XP)
    - level band reached: 481, 482
- Order: 55 shared events, 972 of 1485 pairs in the same order (65 %), Kendall tau 0.31.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 6321 | turnin 429 | 32 | 34 |
  | accept 6323 | accept 430 | 33 | 31 |
  | accept 91921 | turnin 449 | 27 | 23 |
  | turnin 438 | complete 429 | 21 | 24 |
  | accept 438 | accept 3221 | 20 | 19 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | ROGUE | 3 | 0 | 0 | 3 | none |
  | PRIEST | 1 | 0 | 0 | 0 | 79096 |
  | MAGE | 1 | 0 | 0 | 0 | 79096 |
  | WARLOCK | 1 | 0 | 0 | 0 | 79096 |

- Hearthstone: APR uses it 0-1 times (WARRIOR 1, PALADIN 1, HUNTER 0, ROGUE 1, PRIEST 1, SHAMAN 0, MAGE 1, WARLOCK 1, DRUID 0; 1 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### H_Skyborne_01 — Zephras Isle (1-15)

- Races: Skyborne. APR routes: #4 (Zephras Isle (2521), 1-13): 52 shared of 113; #14 (Zephras Isle (2521), 10-13): 4 shared of 7. Slice: 715 of 744 steps.
- Questify -> APR: 55 of 73 general quests in the matched routes (75 %), 55 anywhere in APR (75 %).
  - Absent from APR (Questify-only): 92640, 92642, 92643, 92644, 92645, 92646, 92693, 92880, 92881, 92947, 93065, 93090, 93320, 93836, 93949, 93958, 94493, 94568 (12 950 XP)
  - In another APR route: none
- APR -> Questify (slice): 55 of 87 general quests in this chapter (63 %).
  - In another Questify chapter: 97242, 97246, 97249, 97275, 97326
  - In no Questify chapter (APR-only): 1061, 92461, 92463, 92473, 92474, 92515, 92516, 92544, 92553, 93319, 93552, 93951, 94484, 94897, 95350, 97963, 97964, 97965, 97967, 97968, 97969, 97970, 97971, 97973, 98024, 98285, 98286 (13 185 XP)
    - exclusive with another quest: 94484
    - level band reached: 92461, 92463, 92473, 92474, 92515, 92516, 92544, 92553, 93319, 93951
    - low ratio: 93552
    - not a candidate of the chapter: 1061, 95350, 97973, 98024, 98286
    - objective item source not in zone: 94897
    - requires a profession: 97963, 97964, 97965, 97967, 97968, 97969, 97970, 97971, 98285
- Order: 135 shared events, 8478 of 9045 pairs in the same order (94 %), Kendall tau 0.87.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 94488 | turnin 92703 | 29 | 31 |
  | turnin 94486 | complete 98512 | 21 | 20 |
  | accept 94488 | turnin 98512 | 20 | 20 |
  | accept 94489 | complete 93172 | 15 | 15 |
  | accept 98512 | accept 92682 | 15 | 15 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 6 | 0 | 0 | 2 | 445, 96895, 96897, 96898 |
  | HUNTER | 7 | 0 | 0 | 5 | 840, 842 |
  | ROGUE | 5 | 0 | 0 | 1 | 445, 96895, 96897, 96898 |
  | SHAMAN | 10 | 0 | 0 | 8 | 840, 842 |
  | DRUID | 9 | 0 | 0 | 5 | 445, 96895, 96897, 96898 |

- Hearthstone: APR uses it 1-3 times (WARRIOR 3, PALADIN 1, HUNTER 3, ROGUE 3, PRIEST 1, SHAMAN 3, MAGE 3, WARLOCK 1, DRUID 3; 3 "if ready" steps open to all) and binds it 3 times (maps Orgrimmar (1454), Zephras Isle (2521)); Questify uses it 1 times and binds it 1 times (maps Zephras Isle (2521)).

### H_01 — The Barrens (12-17)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #5 (Mulgore (1412), 1-12): 10 shared of 90; #27 (The Barrens (1413), 12-17): 41 shared of 82; #37 (Stonetalon Mountains (1442), 17-22): 14 shared of 96. Slice: 986 of 1581 steps.
- Questify -> APR: 46 of 49 general quests in the matched routes (94 %), 48 anywhere in APR (98 %).
  - Absent from APR (Questify-only): 898 (1 950 XP)
  - In another APR route: 959, 1486
- APR -> Questify (slice): 45 of 81 general quests in this chapter (56 %).
  - In another Questify chapter: 860, 882, 905, 907, 1062, 1358, 3261, 3281, 6401, 6461, 6523, 6548, 6629, 97242, 97246, 97249, 97275
  - In no Questify chapter (APR-only): 264, 821, 853, 854, 855, 865, 896, 924, 1061, 1063, 1490, 3301, 6362, 6363, 6364, 6384, 6385, 6386, 98024 (14 380 XP)
  - Left out, quest level above 19 (band + 2): 868, 874, 878, 883, 884, 899, 913, 1068, 1069, 1093, 1094, 1095, 1483, 4021, 5052, 6284, 97003
    - event: 924
    - exclusive with another quest: 854
    - far: 865
    - finisher outside the chapter zones: 853, 1063, 3301, 6362, 6384
    - level band reached: 821, 855, 896
    - not a candidate of the chapter: 264, 1061, 1490, 6363, 6364, 6385, 6386, 98024
- Order: 119 shared events, 5170 of 7021 pairs in the same order (74 %), Kendall tau 0.47.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 95774 | accept 895 | 73 | 55 |
  | accept 95495 | turnin 888 | 51 | 54 |
  | accept 95507 | turnin 97253 | 50 | 60 |
  | turnin 869 | turnin 5041 | 52 | 50 |
  | accept 95494 | turnin 895 | 50 | 49 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 5 | 0 | 0 | 5 | none |
  | HUNTER | 5 | 0 | 1 | 0 | 6382, 6383, 6541, 6544 |
  | ROGUE | 5 | 0 | 0 | 5 | none |
  | PRIEST | 2 | 0 | 0 | 2 | none |
  | SHAMAN | 10 | 0 | 0 | 9 | 840 |
  | WARLOCK | 4 | 0 | 0 | 4 | none |
  | DRUID | 12 | 0 | 0 | 8 | 886, 98341, 98404, 98738 |

- Hearthstone: APR uses it 3-4 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 4, MAGE 3, WARLOCK 3, DRUID 4; 3 "if ready" steps open to all) and binds it 4-5 times (maps The Barrens (1413), Thunder Bluff (1456)); Questify uses it 0 times and binds it 0 times (maps none).

### H_02 — Stonetalon Mountains and The Barrens (17-21)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #27 (The Barrens (1413), 12-17): 11 shared of 82; #37 (Stonetalon Mountains (1442), 17-22): 24 shared of 96. Slice: 571 of 1124 steps.
- Questify -> APR: 27 of 36 general quests in the matched routes (75 %), 29 anywhere in APR (81 %).
  - Absent from APR (Questify-only): 6421, 6481, 6542, 78270, 79192, 79980, 97250 (8 235 XP)
  - In another APR route: 897, 1487
- APR -> Questify (slice): 25 of 60 general quests in this chapter (42 %).
  - In another Questify chapter: 848, 851, 852, 863, 868, 875, 876, 877, 880, 881, 902, 903, 1489, 4921, 5052, 6562, 92706, 95494, 95495, 95507, 95508, 95621, 95774
  - In no Questify chapter (APR-only): 264, 821, 853, 855, 865, 896, 1061, 1063, 1490, 3301, 4021, 6386 (11 670 XP)
  - Left out, quest level above 23 (band + 2): 874, 1058, 1095, 1096, 6393
    - finisher outside the chapter zones: 853, 1063, 3301
    - level band reached: 821, 855, 865, 896
    - not a candidate of the chapter: 264, 1061, 1490, 6386
    - objective item source not in zone: 4021
- Order: 60 shared events, 1066 of 1770 pairs in the same order (60 %), Kendall tau 0.20.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 1060 | turnin 3281 | 42 | 42 |
  | accept 884 | complete 3281 | 41 | 37 |
  | accept 6301 | turnin 883 | 30 | 49 |
  | complete 1062 | accept 899 | 27 | 27 |
  | complete 1068 | complete 878 | 27 | 25 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 1 | 0 | 0 | 1 | none |
  | HUNTER | 5 | 0 | 2 | 0 | 3921, 6383, 6544 |
  | ROGUE | 2 | 0 | 0 | 2 | none |
  | PRIEST | 2 | 0 | 0 | 2 | none |
  | SHAMAN | 5 | 0 | 0 | 4 | 869 |
  | WARLOCK | 5 | 0 | 0 | 5 | none |
  | DRUID | 11 | 0 | 0 | 8 | 98341, 98404, 98738 |

- Hearthstone: APR uses it 1-2 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 2; 1 "if ready" steps open to all) and binds it 2-3 times (maps The Barrens (1413), Thunder Bluff (1456)); Questify uses it 2 times and binds it 1 times (maps The Barrens (1413)).

### H_03 — Ashenvale and Stonetalon Mountains (21-25)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #37 (Stonetalon Mountains (1442), 17-22): 12 shared of 96; #58 (The Barrens (1413), 24-26): 10 shared of 40; #59 (Ashenvale (1440), 26-28): 20 shared of 27. Slice: 672 of 839 steps.
- Questify -> APR: 30 of 37 general quests in the matched routes (81 %), 30 anywhere in APR (81 %).
  - Absent from APR (Questify-only): 1089, 6621, 78132, 78133, 78134, 78149, 86576 (12 250 XP)
  - In another APR route: none
- APR -> Questify (slice): 28 of 72 general quests in this chapter (39 %).
  - In another Questify chapter: 843, 846, 849, 852, 868, 873, 874, 876, 879, 884, 885, 893, 897, 906, 1060, 1062, 1068, 1489, 6284, 6301, 6401, 6461, 6523, 6629, 95494, 95495, 95507, 95508, 95621
  - In no Questify chapter (APR-only): 235, 264, 742, 853, 855, 1063, 1064, 1065, 1067, 1086, 1095, 1096, 1195, 1490, 4021 (16 055 XP)
  - Left out, quest level above 27 (band + 2): 1153, 2842, 6504
    - not a candidate of the chapter: 235, 264, 742, 853, 855, 1063, 1064, 1065, 1067, 1086, 1095, 1195, 1490, 4021
    - prerequisite unavailable: 1096
- Order: 69 shared events, 1623 of 2346 pairs in the same order (69 %), Kendall tau 0.38.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 216 | accept 6562 | 55 | 49 |
  | complete 6462 | turnin 98252 | 40 | 40 |
  | accept 6482 | turnin 98251 | 38 | 43 |
  | complete 6482 | complete 98251 | 36 | 45 |
  | turnin 6462 | turnin 6283 | 48 | 35 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 2 | none |
  | HUNTER | 2 | 0 | 0 | 0 | 3921, 6541 |
  | ROGUE | 8 | 0 | 2 | 4 | 6564, 6922 |
  | PRIEST | 2 | 0 | 0 | 2 | none |
  | SHAMAN | 2 | 0 | 0 | 2 | none |
  | WARLOCK | 5 | 0 | 0 | 5 | none |
  | DRUID | 12 | 0 | 0 | 9 | 98341, 98404, 98738 |

- Hearthstone: APR uses it 3 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 3, MAGE 3, WARLOCK 3, DRUID 3; 3 "if ready" steps open to all) and binds it 3 times (maps The Barrens (1413), Thunder Bluff (1456)); Questify uses it 1 times and binds it 1 times (maps Stonetalon Mountains (1442)).

### H_04 — Southern Barrens and Thousand Needles (25-28)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #58 (The Barrens (1413), 24-26): 12 shared of 40; #62 (Thousand Needles (1441), 28-30): 17 shared of 40. Slice: 456 of 564 steps.
- Questify -> APR: 27 of 32 general quests in the matched routes (84 %), 28 anywhere in APR (88 %).
  - Absent from APR (Questify-only): 891, 78143, 78145, 79097 (6 200 XP)
  - In another APR route: 5052
- APR -> Questify (slice): 27 of 55 general quests in this chapter (49 %).
  - In another Questify chapter: 884, 897, 1058, 1060, 1068, 1087, 1088, 6282, 6283, 6284, 6301, 6381, 6382, 6393, 6401, 6562
  - In no Questify chapter (APR-only): 235, 742, 1086, 1095, 1096, 1131, 1195, 1196, 1197, 4966, 5062, 5088 (20 650 XP)
  - Left out, quest level above 30 (band + 2): 1136
    - event: 4966
    - finisher outside the chapter zones: 1095, 5062
    - not a candidate of the chapter: 235, 742, 1086, 1096, 1131, 1195, 1196, 5088
    - prerequisite unavailable: 1197
- Order: 70 shared events, 2127 of 2415 pairs in the same order (88 %), Kendall tau 0.76.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 4767 | complete 1153 | 24 | 17 |
  | complete 4767 | accept 5147 | 19 | 17 |
  | turnin 857 | turnin 849 | 15 | 15 |
  | accept 4770 | complete 4841 | 13 | 12 |
  | complete 5151 | turnin 4841 | 12 | 12 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 3 | 0 | 0 | 3 | none |
  | SHAMAN | 3 | 0 | 0 | 3 | none |

- Hearthstone: APR uses it 2-3 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 3, MAGE 3, WARLOCK 3, DRUID 2; 3 "if ready" steps open to all) and binds it 4 times (maps The Barrens (1413), Thousand Needles (1441), Thunder Bluff (1456)); Questify uses it 2 times and binds it 1 times (maps The Barrens (1413)).

### H_05 — Hillsbrad Foothills (28-30)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #65 (Hillsbrad Foothills (1424), 30-33): 6 shared of 29. Slice: 129 of 248 steps.
- Questify -> APR: 6 of 21 general quests in the matched routes (29 %), 10 anywhere in APR (48 %).
  - Absent from APR (Questify-only): 541, 547, 550, 78143, 78145, 78149, 79097, 96986, 97287, 98094, 98095 (15 155 XP)
  - In another APR route: 501, 502, 527, 528
- APR -> Questify (slice): 6 of 12 general quests in this chapter (50 %).
  - In another Questify chapter: 556, 676
  - In no Questify chapter (APR-only): 546, 567, 677, 7321 (9 900 XP)
  - Left out, quest level above 32 (band + 2): 533, 544, 642, 655, 671, 672, 674, 675, 1136, 1164
    - level band reached: 546, 567
    - not a candidate of the chapter: 677
    - requires a profession: 7321
- Order: 15 shared events, 73 of 105 pairs in the same order (70 %), Kendall tau 0.39.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 509 | accept 552 | 9 | 8 |
  | turnin 509 | complete 552 | 9 | 8 |
  | turnin 539 | turnin 552 | 3 | 2 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 2 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 2 times and binds it 1 times (maps Hillsbrad Foothills (1424)).

### H_06 — Alterac Mountains and Arathi Highlands (30-32)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #65 (Hillsbrad Foothills (1424), 30-33): 8 shared of 29. Slice: 89 of 248 steps.
- Questify -> APR: 8 of 17 general quests in the matched routes (47 %), 11 anywhere in APR (65 %).
  - Absent from APR (Questify-only): 535, 1361, 79948, 79949, 96984, 97287 (9 035 XP)
  - In another APR route: 498, 545, 557
- APR -> Questify (slice): 8 of 17 general quests in this chapter (47 %).
  - In another Questify chapter: 509, 532, 539, 552
  - In no Questify chapter (APR-only): 546, 567, 671, 677, 7321 (12 550 XP)
  - Left out, quest level above 34 (band + 2): 642, 1164
    - level band reached: 546, 567, 671, 677
    - requires a profession: 7321
- Order: 21 shared events, 195 of 210 pairs in the same order (93 %), Kendall tau 0.86.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 676 | complete 544 | 6 | 6 |
  | accept 544 | accept 533 | 1 | 2 |
  | accept 655 | turnin 676 | 1 | 1 |
  | complete 533 | complete 556 | 1 | 1 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 2 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### H_07 — Thousand Needles (32-33)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #70 (Thousand Needles (1441), 33-34): 7 shared of 28. Slice: 61 of 95 steps.
- Questify -> APR: 7 of 11 general quests in the matched routes (64 %), 8 anywhere in APR (73 %).
  - Absent from APR (Questify-only): 1361, 1362, 98070 (3 780 XP)
  - In another APR route: 1145
- APR -> Questify (slice): 7 of 12 general quests in this chapter (58 %).
  - In another Questify chapter: 1151
  - In no Questify chapter (APR-only): 1106, 1146, 1147, 1148 (7 400 XP)
  - Left out, quest level above 35 (band + 2): 1112, 1114, 1115, 1178
    - finisher outside the chapter zones: 1106
    - not a candidate of the chapter: 1146
    - prerequisite unavailable: 1147, 1148
- Order: 17 shared events, 124 of 136 pairs in the same order (91 %), Kendall tau 0.82.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 5762 | complete 1105 | 6 | 5 |
  | complete 1110 | complete 1104 | 1 | 1 |
  | turnin 1175 | turnin 1176 | 1 | 1 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | SHAMAN | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 1 times (maps Thousand Needles (1441)).

### H_08 — Desolace (33-35)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #73 (Desolace (1443), 34-35): 14 shared of 27. Slice: 107 of 159 steps.
- Questify -> APR: 14 of 17 general quests in the matched routes (82 %), 15 anywhere in APR (88 %).
  - Absent from APR (Questify-only): 5821, 5943 (5 600 XP)
  - In another APR route: 5581
- APR -> Questify (slice): 14 of 24 general quests in this chapter (58 %).
  - In another Questify chapter: 5361
  - In no Questify chapter (APR-only): 1368, 1370, 1373, 1432, 1433, 1434, 1435, 1436, 5386 (16 375 XP)
  - Left out, quest level above 37 (band + 2): 5501
    - finisher outside the chapter zones: 1436
    - manual drop (overrides.lua): 1368, 1370, 1373
    - not a candidate of the chapter: 1432
    - objective item source not in zone: 5386
    - prerequisite unavailable: 1433, 1434, 1435
- Order: 38 shared events, 530 of 703 pairs in the same order (75 %), Kendall tau 0.51.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 5763 | complete 1366 | 28 | 22 |
  | accept 6143 | turnin 1481 | 13 | 11 |
  | complete 5381 | accept 1482 | 10 | 12 |
  | complete 5561 | accept 1481 | 10 | 10 |
  | complete 6161 | turnin 1366 | 10 | 10 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 1 times (maps Desolace (1443)).

### H_09 — Stranglethorn Vale (35-37)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #70 (Thousand Needles (1441), 33-34): 6 shared of 28; #76 (Stranglethorn Vale (1434), 35-37): 25 shared of 35. Slice: 212 of 295 steps.
- Questify -> APR: 25 of 30 general quests in the matched routes (83 %), 26 anywhere in APR (87 %).
  - Absent from APR (Questify-only): 339, 341, 342, 635 (2 615 XP)
  - In another APR route: 628
- APR -> Questify (slice): 25 of 44 general quests in this chapter (57 %).
  - In another Questify chapter: 1104, 1105, 1175, 1176, 5361
  - In no Questify chapter (APR-only): 570, 596, 1106, 1115, 1116, 1148, 1178, 1180, 1181, 1182, 1183, 1184, 1436, 2842 (21 250 XP)
  - Left out, quest level above 39 (band + 2): 196, 209, 600
    - finisher outside the chapter zones: 1183
    - level band reached: 570, 596
    - not a candidate of the chapter: 1106, 1115, 1148, 1178, 1180, 1184, 1436, 2842
    - objective item source not in zone: 1116
    - prerequisite unavailable: 1181, 1182
- Order: 63 shared events, 1669 of 1953 pairs in the same order (85 %), Kendall tau 0.71.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 638 | accept 195 | 25 | 26 |
  | turnin 575 | turnin 629 | 17 | 18 |
  | accept 577 | turnin 582 | 15 | 20 |
  | complete 575 | complete 568 | 17 | 15 |
  | turnin 195 | complete 629 | 15 | 14 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | SHAMAN | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 1-3 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 3, WARLOCK 1, DRUID 1; 1 "if ready" steps open to all) and binds it 2 times (maps The Barrens (1413), Stranglethorn Vale (1434), Orgrimmar (1454)); Questify uses it 2 times and binds it 1 times (maps Stranglethorn Vale (1434)).

### H_10 — Dustwallow Marsh (37-38)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #79 (Dustwallow Marsh (1445), 37-38): 13 shared of 18. Slice: 37 of 140 steps.
- Questify -> APR: 13 of 14 general quests in the matched routes (93 %), 13 anywhere in APR (93 %).
  - Absent from APR (Questify-only): 1202 (2 750 XP)
  - In another APR route: none
- APR -> Questify (slice): 13 of 16 general quests in this chapter (81 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 1203, 1270, 1276 (7 700 XP)
    - finisher outside the chapter zones: 1270, 1276
    - objective item source not in zone: 1203
- Order: 31 shared events, 400 of 465 pairs in the same order (86 %), Kendall tau 0.72.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 1201 | accept 1273 | 11 | 10 |
  | complete 1201 | turnin 1321 | 10 | 10 |
  | accept 1239 | turnin 1322 | 5 | 5 |
  | turnin 1206 | accept 1323 | 5 | 5 |
  | turnin 1239 | turnin 1273 | 4 | 4 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### H_11 — Arathi Highlands (38-39)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #81 (Arathi Highlands (1417), 38-39): 10 shared of 35. Slice: 112 of 148 steps.
- Questify -> APR: 10 of 18 general quests in the matched routes (56 %), 10 anywhere in APR (56 %).
  - Absent from APR (Questify-only): 635, 639, 640, 641, 643, 644, 645, 646 (18 500 XP)
  - In another APR route: none
- APR -> Questify (slice): 10 of 24 general quests in this chapter (42 %).
  - In another Questify chapter: 545, 557, 675
  - In no Questify chapter (APR-only): 566, 642, 651, 662, 664, 678, 687, 688, 701, 702, 847 (27 885 XP)
  - Left out, quest level above 41 (band + 2): 652, 6622
    - level band reached: 642, 651, 662, 664, 678, 687, 688, 701, 702, 847
    - prerequisite unavailable: 566
- Order: 22 shared events, 221 of 231 pairs in the same order (96 %), Kendall tau 0.91.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 638 | accept 507 | 6 | 5 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 4 | 0 | 0 | 3 | 1714 |
  | ROGUE | 1 | 0 | 0 | 0 | 673 |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 3 times and binds it 1 times (maps Arathi Highlands (1417)).

### H_12 — Badlands (39-40)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #82 (Badlands (1418), 39-40): 7 shared of 20. Slice: 50 of 101 steps.
- Questify -> APR: 7 of 10 general quests in the matched routes (70 %), 7 anywhere in APR (70 %).
  - Absent from APR (Questify-only): 709, 2202, 2418 (5 050 XP)
  - In another APR route: none
- APR -> Questify (slice): 7 of 19 general quests in this chapter (37 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 687, 703, 705, 713, 714, 715, 716, 734, 777, 1106, 1108, 1137 (25 320 XP)
  - Left out, quest level above 42 (band + 2): 778
    - finisher outside the chapter zones: 1137
    - level band reached: 703
    - not a candidate of the chapter: 687, 1106
    - objective item source not in zone: 705, 713, 714, 715, 716
    - prerequisite unavailable: 734, 777, 1108
- Order: 18 shared events, 125 of 153 pairs in the same order (82 %), Kendall tau 0.63.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 1420 | accept 782 | 9 | 14 |
  | complete 782 | turnin 1419 | 2 | 3 |
  | complete 2258 | accept 710 | 1 | 2 |
  | turnin 782 | turnin 2258 | 1 | 2 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### H_13 — Stranglethorn Vale (40-41)

No APR leveling route shares enough quests with this chapter.

### H_14 — Swamp of Sorrows (41-43)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #90 (Swamp of Sorrows (1435), 41-400): 7 shared of 22; #98 (Swamp of Sorrows (1435), 45-46): 6 shared of 16. Slice: 144 of 176 steps.
- Questify -> APR: 12 of 14 general quests in the matched routes (86 %), 12 anywhere in APR (86 %).
  - Absent from APR (Questify-only): 1430, 93176 (4 830 XP)
  - In another APR route: none
- APR -> Questify (slice): 12 of 27 general quests in this chapter (44 %).
  - In another Questify chapter: 577, 628, 669
  - In no Questify chapter (APR-only): 209, 600, 1116, 1117, 1183, 1205, 1270, 1276, 1373, 1429, 2864, 2872 (29 795 XP)
  - Left out, quest level above 45 (band + 2): 2621, 2622, 2623, 2784, 2801
    - finisher outside the chapter zones: 1429
    - not a candidate of the chapter: 209, 600, 1116, 1117, 1183, 1205, 1270, 1276, 1373, 2864, 2872
- Order: 29 shared events, 331 of 406 pairs in the same order (82 %), Kendall tau 0.63.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 624 | turnin 1392 | 15 | 23 |
  | complete 1424 | accept 1392 | 7 | 10 |
  | complete 699 | turnin 1393 | 5 | 7 |
  | accept 699 | complete 1393 | 4 | 5 |
  | complete 698 | accept 1393 | 5 | 4 |

- Class quests: none on either side.
- Hearthstone: APR uses it 1 times (WARRIOR 1, PALADIN 1, HUNTER 1, ROGUE 1, PRIEST 1, SHAMAN 1, MAGE 1, WARLOCK 1, DRUID 1; 1 "if ready" steps open to all) and binds it 1 times (maps The Barrens (1413)); Questify uses it 0 times and binds it 0 times (maps none).

### H_15 — Desolace (43-44)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #91 (Desolace (1443), 41-41): 3 shared of 8. Slice: 20 of 32 steps.
- Questify -> APR: 3 of 9 general quests in the matched routes (33 %), 4 anywhere in APR (44 %).
  - Absent from APR (Questify-only): 7028, 7029, 92743, 93225, 94872 (11 810 XP)
  - In another APR route: 5501
- APR -> Questify (slice): 3 of 6 general quests in this chapter (50 %).
  - In another Questify chapter: 1484, 5581
  - In no Questify chapter (APR-only): 1374 (2 280 XP)
    - manual drop (overrides.lua): 1374
- Order: 6 shared events, 14 of 15 pairs in the same order (93 %), Kendall tau 0.87.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 6132 | turnin 6134 | 1 | 1 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### H_16 — Tanaris (44-46)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #92 (Tanaris (1446), 41-43): 4 shared of 25; #99 (Tanaris (1446), 46-48): 13 shared of 37. Slice: 238 of 304 steps.
- Questify -> APR: 17 of 20 general quests in the matched routes (85 %), 17 anywhere in APR (85 %).
  - Absent from APR (Questify-only): 2768, 2865, 3042 (7 050 XP)
  - In another APR route: none
- APR -> Questify (slice): 17 of 42 general quests in this chapter (40 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 243, 379, 654, 1117, 1118, 1119, 1120, 1122, 1137, 1166, 1168, 1169, 1183, 1186, 1187, 1188, 1190, 1194, 1205, 1261, 1262, 2872, 2876, 3161, 3520 (64 380 XP)
  - Left out, quest level above 48 (band + 2): 1560, 2605, 2606, 2641, 3362, 3380
    - low ratio: 3161
    - not a candidate of the chapter: 243, 654, 1117, 1118, 1119, 1120, 1122, 1137, 1166, 1168, 1169, 1183, 1186, 1187, 1188, 1190, 1194, 1205, 1261, 1262, 2872, 2876
    - objective npc not in zone: 3520
    - prerequisite unavailable: 379
- Order: 45 shared events, 663 of 990 pairs in the same order (67 %), Kendall tau 0.34.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 10 | turnin 1707 | 27 | 26 |
  | turnin 5863 | turnin 1691 | 26 | 24 |
  | turnin 82 | turnin 2781 | 29 | 21 |
  | complete 5863 | complete 1707 | 22 | 20 |
  | complete 82 | accept 1691 | 20 | 20 |

- Class quests: none on either side.
- Hearthstone: APR uses it 3-5 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 5, MAGE 3, WARLOCK 3, DRUID 3; 3 "if ready" steps open to all) and binds it 2 times (maps Tanaris (1446)); Questify uses it 2 times and binds it 1 times (maps Tanaris (1446)).

### H_17 — Feralas (46-47)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #95 (Feralas (1444), 43-44): 15 shared of 26; #102 (Feralas (1444), 49-50): 3 shared of 26. Slice: 214 of 229 steps.
- Questify -> APR: 18 of 19 general quests in the matched routes (95 %), 18 anywhere in APR (95 %).
  - Absent from APR (Questify-only): 7721 (4 400 XP)
  - In another APR route: none
- APR -> Questify (slice): 18 of 32 general quests in this chapter (56 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 1205, 1262, 2974, 2976, 3002, 3121, 3122, 3123, 3124, 3125, 3520, 7541, 7732, 7738 (44 400 XP)
  - Left out, quest level above 49 (band + 2): 3062, 3126, 3127, 3128, 3129, 3380, 3444, 3844, 3845, 3884, 3908, 4284, 4289, 4290, 4291, 4292, 4300
    - finisher outside the chapter zones: 2976, 3002, 3121, 7732
    - level band reached: 2974
    - not a candidate of the chapter: 1205, 1262, 3122, 3520, 7541
    - objective item source not in zone: 3123
    - prerequisite unavailable: 3124, 3125
    - repeatable: 7738
- Order: 49 shared events, 850 of 1176 pairs in the same order (72 %), Kendall tau 0.45.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 3063 | accept 2979 | 25 | 25 |
  | complete 3063 | turnin 2903 | 24 | 22 |
  | complete 7003 | accept 2903 | 23 | 22 |
  | accept 7003 | turnin 2902 | 24 | 21 |
  | turnin 3063 | complete 7731 | 18 | 22 |

- Class quests: none on either side.
- Hearthstone: APR uses it 3-4 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 4, MAGE 3, WARLOCK 3, DRUID 3; 3 "if ready" steps open to all) and binds it 1 times (maps Feralas (1444)); Questify uses it 0 times and binds it 0 times (maps none).

### H_18 — Stranglethorn Vale (47-48)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #97 (Stranglethorn Vale (1434), 44-45): 10 shared of 29; #103 (Blasted Lands (1419), 50-51): 4 shared of 20. Slice: 125 of 209 steps.
- Questify -> APR: 13 of 21 general quests in the matched routes (62 %), 15 anywhere in APR (71 %).
  - Absent from APR (Questify-only): 591, 592, 594, 630, 8553, 8554 (27 920 XP)
  - In another APR route: 584, 585
- APR -> Questify (slice): 13 of 34 general quests in this chapter (38 %).
  - In another Questify chapter: 197, 208, 595, 597, 599, 604, 606, 607, 609, 617, 624, 628
  - In no Questify chapter (APR-only): 349, 571, 573, 580, 598, 836, 1118, 1119, 3721 (35 850 XP)
  - Left out, quest level above 50 (band + 2): 615
    - finisher outside the chapter zones: 1119
    - not a candidate of the chapter: 836, 1118
    - objective item source not in zone: 571, 580
    - prerequisite unavailable: 573, 598, 3721
    - repeatable: 349
- Order: 30 shared events, 244 of 435 pairs in the same order (56 %), Kendall tau 0.12.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 2874 | complete 348 | 20 | 17 |
  | turnin 8552 | turnin 576 | 16 | 15 |
  | turnin 648 | accept 589 | 13 | 22 |
  | accept 608 | complete 586 | 13 | 14 |
  | accept 587 | accept 586 | 14 | 10 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 1 times (maps Stranglethorn Vale (1434)).

### H_21 — The Hinterlands (48-51)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #100 (The Hinterlands (1425), 48-49): 12 shared of 33. Slice: 59 of 149 steps.
- Questify -> APR: 12 of 19 general quests in the matched routes (63 %), 12 anywhere in APR (63 %).
  - Absent from APR (Questify-only): 7845, 7846, 7847, 7849, 7850, 7861, 7862 (39 900 XP)
  - In another APR route: none
- APR -> Questify (slice): 12 of 23 general quests in this chapter (52 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 77, 81, 580, 626, 2641, 2782, 2933, 2934, 2995, 3123, 7843 (47 000 XP)
    - far: 7843
    - finisher outside the chapter zones: 81, 2782, 2933
    - not a candidate of the chapter: 580, 626, 2641, 2934, 2995, 3123
    - prerequisite unavailable: 77
- Order: 34 shared events, 368 of 561 pairs in the same order (66 %), Kendall tau 0.31.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 485 | turnin 7816 | 22 | 24 |
  | turnin 485 | turnin 7815 | 18 | 26 |
  | complete 7828 | complete 7816 | 16 | 15 |
  | complete 7830 | turnin 7840 | 19 | 12 |
  | complete 7839 | complete 7840 | 11 | 10 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### H_23 — Blasted Lands (51-52)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #103 (Blasted Lands (1419), 50-51): 7 shared of 20. Slice: 50 of 99 steps.
- Questify -> APR: 7 of 7 general quests in the matched routes (100 %), 7 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 7 of 7 general quests in this chapter (100 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): none (0 XP)
- Order: 14 shared events, 51 of 91 pairs in the same order (56 %), Kendall tau 0.12.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 2581 | turnin 2601 | 10 | 7 |
  | accept 2521 | turnin 2603 | 6 | 9 |
  | accept 3501 | turnin 2585 | 3 | 5 |
  | accept 2583 | accept 2603 | 2 | 4 |
  | accept 2585 | accept 2601 | 2 | 4 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### H_24 — Searing Gorge and Burning Steppes (52-53)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #108 (Searing Gorge (1427), 51-52): 9 shared of 22. Slice: 89 of 147 steps.
- Questify -> APR: 9 of 13 general quests in the matched routes (69 %), 9 anywhere in APR (69 %).
  - Absent from APR (Questify-only): 4023, 4123, 4136, 7701 (14 300 XP)
  - In another APR route: none
- APR -> Questify (slice): 9 of 21 general quests in this chapter (43 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 3442, 3443, 3452, 3453, 3454, 3462, 3463, 3481, 3821, 4022, 4449, 4808 (42 800 XP)
    - event: 3453
    - finisher outside the chapter zones: 4808
    - low ratio: 4449
    - not a candidate of the chapter: 3821
    - prerequisite unavailable: 3442, 3443, 3452, 3454, 3462, 3463, 3481, 4022
- Order: 25 shared events, 154 of 300 pairs in the same order (51 %), Kendall tau 0.03.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 4726 | complete 7724 | 15 | 16 |
  | turnin 4296 | turnin 4451 | 19 | 12 |
  | accept 4726 | accept 7729 | 12 | 15 |
  | turnin 4726 | complete 7728 | 12 | 14 |
  | accept 4296 | complete 7727 | 12 | 13 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### H_25 — Azshara (53-54)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #110 (Azshara (1447), 52-53): 7 shared of 26. Slice: 73 of 120 steps.
- Questify -> APR: 7 of 7 general quests in the matched routes (100 %), 7 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: none
- APR -> Questify (slice): 7 of 14 general quests in this chapter (50 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 3504, 3505, 3506, 3507, 3518, 3541, 3568 (25 900 XP)
    - finisher outside the chapter zones: 3507, 3518, 3541
    - not a candidate of the chapter: 3504, 3568
    - prerequisite unavailable: 3505, 3506
- Order: 19 shared events, 124 of 171 pairs in the same order (73 %), Kendall tau 0.45.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 3561 | turnin 3601 | 6 | 6 |
  | complete 3517 | turnin 5536 | 6 | 6 |
  | turnin 3517 | complete 3601 | 6 | 6 |
  | turnin 3561 | accept 5534 | 6 | 6 |
  | accept 3565 | complete 5534 | 6 | 5 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 2 | 0 | 0 | 2 | none |
  | PRIEST | 3 | 0 | 0 | 3 | none |
  | MAGE | 3 | 0 | 0 | 3 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 1 times (maps Azshara (1447)).

### H_26 — Felwood (54-55)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #114 (Felwood (1448), 53-54): 9 shared of 22; #117 (Felwood (1448), 55-56): 7 shared of 45. Slice: 320 of 355 steps.
- Questify -> APR: 16 of 17 general quests in the matched routes (94 %), 16 anywhere in APR (94 %).
  - Absent from APR (Questify-only): 5887 (4 200 XP)
  - In another APR route: none
- APR -> Questify (slice): 16 of 52 general quests in this chapter (31 %).
  - In another Questify chapter: 980, 3783, 4521, 5054, 5082, 5084, 5085, 5086, 5087, 5601, 6030
  - In no Questify chapter (APR-only): 3507, 3541, 3542, 3562, 3563, 3908, 3909, 3912, 3913, 3914, 3941, 3942, 4084, 4120, 4147, 4494, 4502, 4808, 4842, 5158, 5159, 5165, 6029, 6031, 8470 (102 380 XP)
  - Left out, quest level above 57 (band + 2): 4721, 4741, 5055, 5121, 5242, 8464
    - finisher outside the chapter zones: 5158
    - manual drop (overrides.lua): 6031, 8470
    - not a candidate of the chapter: 3507, 3541, 3542, 3562, 3563, 3908, 3909, 3912, 3913, 3914, 3941, 3942, 4120, 4147, 4494, 4502, 4808, 4842, 5159, 6029
    - prerequisite unavailable: 4084, 5165
- Order: 41 shared events, 552 of 820 pairs in the same order (67 %), Kendall tau 0.35.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | turnin 5203 | accept 8462 | 19 | 24 |
  | accept 5204 | turnin 8462 | 22 | 19 |
  | complete 5203 | turnin 8460 | 21 | 18 |
  | accept 5202 | complete 4505 | 16 | 18 |
  | complete 5204 | accept 5083 | 14 | 19 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 0 | 0 | 969 |
  | PRIEST | 1 | 0 | 0 | 1 | none |
  | WARLOCK | 2 | 0 | 0 | 2 | none |

- Hearthstone: APR uses it 3-4 times (WARRIOR 3, PALADIN 3, HUNTER 3, ROGUE 3, PRIEST 3, SHAMAN 4, MAGE 3, WARLOCK 3, DRUID 3; 3 "if ready" steps open to all) and binds it 2 times (maps The Barrens (1413), Winterspring (1452)); Questify uses it 1 times and binds it 0 times (maps none).

### H_27 — Un'Goro Crater (55-56)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #116 (Un'Goro Crater (1449), 54-55): 14 shared of 36. Slice: 80 of 156 steps.
- Questify -> APR: 14 of 19 general quests in the matched routes (74 %), 19 anywhere in APR (100 %).
  - Absent from APR (Questify-only): none (0 XP)
  - In another APR route: 3844, 3884, 4284, 4290, 4291
- APR -> Questify (slice): 14 of 23 general quests in this chapter (61 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 4147, 4244, 4245, 4285, 4287, 4288, 4321, 4496, 4502 (36 330 XP)
    - event: 4285, 4287, 4288, 4321
    - finisher outside the chapter zones: 4147
    - not a candidate of the chapter: 4496, 4502
    - objective item source not in zone: 4244
    - prerequisite unavailable: 4245
- Order: 36 shared events, 496 of 630 pairs in the same order (79 %), Kendall tau 0.57.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 4243 | complete 4292 | 26 | 22 |
  | turnin 4243 | turnin 4292 | 21 | 22 |
  | complete 4503 | accept 4301 | 7 | 7 |
  | complete 4501 | complete 4289 | 6 | 8 |
  | accept 974 | turnin 4289 | 8 | 5 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

### H_28 — Felwood and Winterspring (56-57)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #114 (Felwood (1448), 53-54): 3 shared of 22; #117 (Felwood (1448), 55-56): 17 shared of 45; #121 (Winterspring (1452), 58-60): 7 shared of 54. Slice: 407 of 687 steps.
- Questify -> APR: 23 of 26 general quests in the matched routes (88 %), 23 anywhere in APR (88 %).
  - Absent from APR (Questify-only): 5056, 5057, 6603 (12 180 XP)
  - In another APR route: none
- APR -> Questify (slice): 22 of 64 general quests in this chapter (34 %).
  - In another Questify chapter: 4102, 4505, 4506, 5156, 5157, 5202, 5203, 5204, 5385, 6162, 8461
  - In no Questify chapter (APR-only): 1123, 1124, 3507, 3541, 3542, 3562, 3563, 3908, 3909, 3912, 3913, 3914, 3941, 3942, 4005, 4084, 4147, 4494, 4502, 4808, 4809, 4842, 4883, 5158, 5159, 5163, 5165, 5242, 6029, 6031, 8470 (135 830 XP)
  - Left out, quest level above 59 (band + 2): 5527
    - far: 4842
    - finisher outside the chapter zones: 3912, 4005, 4883, 5158, 6029
    - manual drop (overrides.lua): 6031, 8470
    - not a candidate of the chapter: 1123, 1124, 3507, 3541, 3542, 3562, 3563, 3908, 3913, 3914, 3941, 3942, 4147, 4494, 4502, 4808, 5159
    - objective item source not in zone: 3909
    - objective npc not in zone: 5163
    - prerequisite unavailable: 4084, 4809, 5165, 5242
- Order: 51 shared events, 1001 of 1275 pairs in the same order (79 %), Kendall tau 0.57.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | accept 5601 | complete 5082 | 36 | 26 |
  | accept 6030 | turnin 5082 | 42 | 24 |
  | accept 4741 | turnin 8465 | 15 | 14 |
  | complete 5055 | accept 8464 | 13 | 14 |
  | accept 5054 | accept 5082 | 9 | 14 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 1 | 0 | none |
  | PRIEST | 1 | 0 | 0 | 1 | none |

- Hearthstone: APR uses it 4-6 times (WARRIOR 4, PALADIN 4, HUNTER 4, ROGUE 4, PRIEST 4, SHAMAN 6, MAGE 4, WARLOCK 4, DRUID 4; 4 "if ready" steps open to all) and binds it 3 times (maps The Barrens (1413), Winterspring (1452)); Questify uses it 2 times and binds it 1 times (maps Winterspring (1452)).

### H_29 — Western Plaguelands and Eastern Plaguelands (57-59)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #119 (Western Plaguelands (1422), 56-58): 22 shared of 74. Slice: 260 of 312 steps.
- Questify -> APR: 22 of 31 general quests in the matched routes (71 %), 22 anywhere in APR (71 %).
  - Absent from APR (Questify-only): 5212, 5214, 5243, 5251, 5282, 5382, 5503, 5529, 9665 (32 610 XP)
  - In another APR route: none
- APR -> Questify (slice): 22 of 66 general quests in this chapter (33 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 838, 964, 3542, 3564, 3568, 3569, 3570, 4987, 5023, 5049, 5050, 5059, 5098, 5149, 5152, 5153, 5154, 5210, 5230, 5231, 5232, 5233, 5234, 5235, 5236, 5241, 5742, 5781, 5845, 5846, 5901, 5902, 5961, 6022, 6390, 7813, 7814, 7817, 7818, 9124, 9126, 9128, 9131, 9136 (182 010 XP)
    - event: 5742
    - finisher outside the chapter zones: 4987, 5023, 5230, 5232, 5234, 5236, 6390
    - manual drop (overrides.lua): 9124, 9126, 9128, 9131, 9136
    - not a candidate of the chapter: 838, 964, 3542, 3564, 3568, 3569, 3570, 5049, 5050, 5098, 5231, 5233, 5235, 5901, 5902, 5961, 7813, 7814, 7817, 7818
    - objective item source not in zone: 5149, 6022
    - prerequisite unavailable: 5152, 5153, 5154, 5210, 5241, 5781, 5845, 5846
    - repeatable: 5059
- Order: 58 shared events, 1404 of 1653 pairs in the same order (85 %), Kendall tau 0.70.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 6025 | turnin 5601 | 28 | 28 |
  | accept 6025 | turnin 5281 | 19 | 18 |
  | turnin 6025 | complete 6164 | 18 | 18 |
  | accept 6024 | accept 6164 | 11 | 9 |
  | complete 6024 | turnin 5542 | 8 | 10 |

- Class quests: none on either side.
- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 0 times and binds it 0 times (maps none).

### H_30 — Silithus (59-60)

- Races: Orc, Skyborne, Tauren, Troll, Undead. APR routes: #121 (Winterspring (1452), 58-60): 14 shared of 54. Slice: 57 of 332 steps.
- Questify -> APR: 14 of 16 general quests in the matched routes (88 %), 14 anywhere in APR (88 %).
  - Absent from APR (Questify-only): 9416, 9422 (13 200 XP)
  - In another APR route: none
- APR -> Questify (slice): 13 of 17 general quests in this chapter (76 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 1125, 1126, 5527, 6844 (21 250 XP)
    - finisher outside the chapter zones: 6844
    - not a candidate of the chapter: 5527
    - prerequisite unavailable: 1125, 1126
- Order: 36 shared events, 546 of 630 pairs in the same order (87 %), Kendall tau 0.73.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 8279 | complete 8304 | 12 | 10 |
  | complete 8318 | turnin 8304 | 12 | 10 |
  | accept 8281 | accept 8308 | 7 | 7 |
  | turnin 8278 | turnin 8308 | 6 | 6 |
  | turnin 8318 | turnin 8323 | 4 | 4 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | HUNTER | 1 | 0 | 1 | 0 | none |
  | MAGE | 1 | 0 | 1 | 0 | none |
  | WARLOCK | 1 | 0 | 1 | 0 | none |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 0 times (maps none).

## Indoor notes per zone (APR) and Questify cave entrances

APR steps of leveling routes with a note about a cave (cave, mine, tunnel, crypt...), a building (inside, inn, tower, barn...) or a floor (upstairs, downstairs, ramp, elevator...), on the maps our guides use; the notes are classified by keyword, never copied. A step can count in several categories. "Our quests": quest IDs of those steps that a Questify chapter of the faction also does: there an entrance or a floor hint may be missing on our side. Cave entrances: entries of `Questify/Data/Caves.lua` on that map.

### Alliance

| Map | Cave steps | Building steps | Floor steps | Our quests: cave | Our quests: building | Our quests: floor | Questify cave entrances |
|---|---|---|---|---|---|---|---|
| Alterac Mountains (1416) | 0 | 2 | 0 | none | none | none | 0 |
| Arathi Highlands (1417) | 6 | 3 | 5 | 691 | 665, 684 | 662 | 0 |
| Western Plaguelands (1422) | 0 | 25 | 9 | none | 4972, 5021, 5058, 5060, 6023, 6025 | 5021, 5060, 6025 | 0 |
| Eastern Plaguelands (1423) | 1 | 3 | 0 | none | none | none | 0 |
| Hillsbrad Foothills (1424) | 3 | 4 | 1 | none | 555 | 555 | 0 |
| Dun Morogh (1426) | 20 | 2 | 9 | 218, 287, 313, 413, 414, 432, 433 | 170 | 310, 311 | 1 |
| Searing Gorge (1427) | 6 | 0 | 8 | none | none | 7722 | 0 |
| Elwynn Forest (1429) | 9 | 10 | 35 | 21, 62, 76, 91743 | 60 | 3905 | 1 |
| Duskwood (1431) | 7 | 25 | 2 | 134, 181, 323 | 66, 101, 148, 149, 154, 160, 163, 164, 165, 175, 177, 223, 251, 253 | none | 0 |
| Loch Modan (1432) | 9 | 30 | 10 | 307 | 298, 301, 302, 6387, 6392 | none | 0 |
| Redridge Mountains (1433) | 1 | 13 | 2 | none | 91 | none | 0 |
| Stranglethorn Vale (1434) | 2 | 2 | 5 | none | 202, 608 | 200, 328 | 0 |
| Westfall (1436) | 0 | 6 | 2 | none | none | none | 0 |
| Wetlands (1437) | 12 | 14 | 18 | 299, 305, 306 | 290, 292, 464, 465, 98221 | 290, 292, 464 | 0 |
| Teldrassil (1438) | 3 | 0 | 0 | 917 | none | none | 0 |
| Darkshore (1439) | 20 | 6 | 30 | 947, 994 | 982 | 947, 965, 982, 983 | 0 |
| Ashenvale (1440) | 0 | 0 | 2 | none | none | none | 0 |
| Desolace (1443) | 0 | 6 | 2 | none | 5741 | 5741 | 0 |
| Feralas (1444) | 4 | 0 | 3 | none | none | none | 0 |
| Dustwallow Marsh (1445) | 0 | 5 | 6 | none | 1204, 1206, 1286 | 1220, 1286 | 0 |
| Tanaris (1446) | 1 | 3 | 1 | 10 | none | 2873 | 0 |
| Un'Goro Crater (1449) | 2 | 0 | 0 | 3883 | none | none | 0 |
| Silithus (1451) | 0 | 2 | 0 | none | none | none | 0 |
| Winterspring (1452) | 6 | 0 | 0 | none | none | none | 0 |
| Stormwind City (1453) | 0 | 10 | 61 | none | none | none | 0 |
| Ironforge (1455) | 0 | 8 | 16 | none | 6388, 6391 | none | 0 |
| Darnassus (1457) | 0 | 1 | 1 | none | none | none | 0 |
| Zephras Isle (2521) | 26 | 106 | 92 | 92849, 94489 | 93927, 94414 | 92645, 93927, 94414 | 0 |

Other maps with indoor notes at APR (no Questify step there yet): 1.

### Horde

| Map | Cave steps | Building steps | Floor steps | Our quests: cave | Our quests: building | Our quests: floor | Questify cave entrances |
|---|---|---|---|---|---|---|---|
| Durotar (1411) | 12 | 29 | 12 | none | none | 830 | 2 |
| Mulgore (1412) | 6 | 3 | 1 | 76156 | 3376, 76156 | 76156 | 0 |
| The Barrens (1413) | 2 | 24 | 9 | none | 858, 867, 871, 872, 875, 876, 95508 | 876, 887 | 0 |
| Alterac Mountains (1416) | 14 | 3 | 6 | none | 503, 544 | 503, 506, 544 | 0 |
| Arathi Highlands (1417) | 7 | 3 | 0 | 676 | none | none | 0 |
| Tirisfal Glades (1420) | 17 | 13 | 8 | 380 | 354, 371, 375 | 375 | 1 |
| Silverpine Forest (1421) | 39 | 9 | 3 | none | 422, 425 | 422 | 0 |
| Western Plaguelands (1422) | 0 | 25 | 7 | none | 4972, 5021, 5058, 5060, 6023, 6025 | 5021, 5060 | 0 |
| Eastern Plaguelands (1423) | 3 | 7 | 1 | 6021, 6024 | 5281, 6021, 6164 | 6164 | 0 |
| Hillsbrad Foothills (1424) | 3 | 15 | 4 | 539 | 498, 527, 532 | 527, 539 | 0 |
| The Hinterlands (1425) | 1 | 0 | 0 | none | none | none | 0 |
| Searing Gorge (1427) | 14 | 5 | 6 | 7722, 7727 | none | 7727 | 0 |
| Stranglethorn Vale (1434) | 2 | 3 | 2 | none | 608 | 624 | 0 |
| Swamp of Sorrows (1435) | 1 | 0 | 0 | none | none | none | 0 |
| Ashenvale (1440) | 2 | 6 | 5 | 6482 | 1088, 6544 | 6544 | 0 |
| Thousand Needles (1441) | 5 | 4 | 3 | none | 5064 | none | 0 |
| Stonetalon Mountains (1442) | 1 | 2 | 0 | none | 6629 | none | 0 |
| Desolace (1443) | 0 | 1 | 0 | none | none | none | 0 |
| Feralas (1444) | 0 | 2 | 0 | none | 7731 | none | 0 |
| Dustwallow Marsh (1445) | 6 | 0 | 0 | none | none | none | 0 |
| Tanaris (1446) | 0 | 3 | 1 | none | none | 2873 | 0 |
| Azshara (1447) | 0 | 4 | 0 | none | none | none | 0 |
| Felwood (1448) | 3 | 0 | 0 | 5203, 5204 | none | none | 0 |
| Un'Goro Crater (1449) | 10 | 0 | 1 | none | none | none | 0 |
| Silithus (1451) | 0 | 2 | 0 | none | none | none | 0 |
| Winterspring (1452) | 7 | 0 | 0 | 5087 | none | none | 0 |
| Orgrimmar (1454) | 0 | 12 | 4 | none | none | 97246 | 0 |
| Thunder Bluff (1456) | 9 | 0 | 12 | none | none | none | 0 |
| Undercity (1458) | 16 | 0 | 70 | none | none | none | 0 |
| Zephras Isle (2521) | 5 | 21 | 24 | 94489 | 93927 | 93927 | 0 |

Other maps with indoor notes at APR (no Questify step there yet): 2.

## APR leveling routes without a Questify chapter

General leveling routes (open to at least 4 classes) that no chapter of the faction matches: ground still to cover (levels 30-60), or a zone or variant our route skips.

### Alliance (10 routes)

| APR route | Quests | Done by a Questify chapter |
|---|---|---|
| #14 (Zephras Isle (2521), 10-13) | 4 | 0 |
| #16 (Loch Modan (1432), 11-13) | 17 | 4 |
| #43 (Redridge Mountains (1433), 19-20) | 49 | 9 |
| #55 (Wetlands (1437), 23-24) | 12 | 2 |
| #80 (Swamp of Sorrows (1435), 38-39) | 18 | 4 |
| #86 (Desolace (1443), 40-41) | 16 | 2 |
| #107 (Western Plaguelands (1422), 51-52) | 35 | 6 |
| #111 (Feralas (1444), 52-53) | 12 | 5 |
| #112 (Azshara (1447), 53-53) | 13 | 0 |
| #118 (Burning Steppes (1428), 56-57) | 38 | 7 |

### Horde (3 routes)

| APR route | Quests | Done by a Questify chapter |
|---|---|---|
| #13 (Tirisfal Glades (1420), 10-12) | 11 | 5 |
| #54 (Hillsbrad Foothills (1424), 22-24) | 26 | 7 |
| #87 (Stranglethorn Vale (1434), 40-41) | 13 | 6 |
