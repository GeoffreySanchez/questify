# Questify vs APR Forever: comparison

Generated on 2026-11-06 by `luajit tools/apr/compare.lua`. APR (Azeroth Pilot Reloaded, free software under GPL-3.0) v7.5.5, commit `c5960471d63f836c57c6973148eacdc8f748b6f9`, read at run time from a local clone (`.cache/apr`, outside the repository) through a sandbox: nothing from APR is copied here. This page holds only counts, map IDs and quest IDs; an APR route is named by its rank in APR's play order (`nextRoute` graph), its map and its level band.

Questify: 29 chapters from `Questify/Guides/Guides.xml` (QuestieDB commit `80866960788084ae1592abf66a08f0d306458a95`). APR: 96 route files of the Forever client list, 127 routes. XP: QuestieDB Forever view of the route builder (quest XP for a player in the chapter's band, nearest to the quest level).

## Summary

A side is **clearly ahead** on a chapter when, on the same slice of the route, the quests that only it does (that the other addon does nowhere for the faction) are worth at least 15 % of the chapter's quest XP more than the other side's, with at least 5 such quests. "APR-only": general quests (not class quests) that APR does in the slice and no Questify chapter of the faction does, except those of a level more than 2 above the chapter's band. "Questify-only": general quests of the chapter that no APR route of the faction does. Only quest XP is compared: travel time, kill time and grinding are not.

- APR clearly ahead: A_Skyborne_01 (APR-only 25 quests / 12 315 XP, Questify-only 6 / 4 070 XP, chapter 46 335 XP); A_01 (APR-only 11 quests / 12 860 XP, Questify-only 4 / 3 795 XP, chapter 45 590 XP); A_02 (APR-only 13 quests / 15 120 XP, Questify-only 6 / 5 815 XP, chapter 33 640 XP); A_03 (APR-only 14 quests / 20 150 XP, Questify-only 3 / 6 000 XP, chapter 76 400 XP); A_04 (APR-only 28 quests / 45 375 XP, Questify-only 16 / 25 630 XP, chapter 51 575 XP); H_OrcTroll_01 (APR-only 5 quests / 2 610 XP, Questify-only 1 / 170 XP, chapter 5 165 XP); H_Tauren_01 (APR-only 5 quests / 2 140 XP, Questify-only 0 / 0 XP, chapter 6 665 XP); H_01 (APR-only 19 quests / 14 380 XP, Questify-only 1 / 1 950 XP, chapter 47 810 XP); H_04 (APR-only 12 quests / 20 650 XP, Questify-only 4 / 6 200 XP, chapter 61 160 XP)
- Questify clearly ahead: A_DwarfGnome_03 (APR-only 7 quests / 5 060 XP, Questify-only 11 / 12 125 XP, chapter 22 465 XP); A_DwarfGnome_04 (APR-only 5 quests / 4 780 XP, Questify-only 9 / 8 080 XP, chapter 15 195 XP); A_Human_03 (APR-only 10 quests / 7 650 XP, Questify-only 11 / 11 080 XP, chapter 21 740 XP); H_Undead_03 (APR-only 2 quests / 200 XP, Questify-only 10 / 8 170 XP, chapter 27 275 XP)
- Close: A_DwarfGnome_01 (APR-only 1 quest / 630 XP, Questify-only 0 / 0 XP, chapter 4 255 XP); A_DwarfGnome_02 (APR-only 8 quests / 5 510 XP, Questify-only 6 / 3 805 XP, chapter 22 825 XP); A_Human_01 (APR-only 4 quests / 2 160 XP, Questify-only 0 / 0 XP, chapter 4 270 XP); A_Human_02 (APR-only 11 quests / 6 455 XP, Questify-only 6 / 4 115 XP, chapter 23 490 XP); A_NightElf_01 (APR-only 1 quest / 630 XP, Questify-only 0 / 0 XP, chapter 4 110 XP); A_NightElf_02 (APR-only 9 quests / 6 710 XP, Questify-only 10 / 6 355 XP, chapter 26 350 XP); A_NightElf_03 (APR-only 16 quests / 15 270 XP, Questify-only 6 / 6 545 XP, chapter 58 570 XP); A_05 (APR-only 2 quests / 5 700 XP, Questify-only 2 / 2 200 XP, chapter 11 560 XP); H_OrcTroll_02 (APR-only 6 quests / 3 065 XP, Questify-only 2 / 1 540 XP, chapter 25 275 XP); H_Tauren_02 (APR-only 7 quests / 3 835 XP, Questify-only 2 / 1 120 XP, chapter 22 075 XP); H_Undead_01 (APR-only 2 quests / 1 080 XP, Questify-only 0 / 0 XP, chapter 3 710 XP); H_Undead_02 (APR-only 6 quests / 3 590 XP, Questify-only 7 / 4 970 XP, chapter 26 760 XP); H_Skyborne_01 (APR-only 27 quests / 13 185 XP, Questify-only 18 / 12 950 XP, chapter 47 225 XP); H_02 (APR-only 12 quests / 11 670 XP, Questify-only 7 / 8 235 XP, chapter 47 625 XP); H_03 (APR-only 15 quests / 16 055 XP, Questify-only 7 / 12 250 XP, chapter 64 315 XP); H_05 (APR-only 6 quests / 15 000 XP, Questify-only 10 / 13 855 XP, chapter 33 805 XP)

Alliance: 125 distinct APR-only quests over all slices. Why our route builder left them out (its chapter report, `docs/routes/<chapter>.md`): not a candidate of the chapter 44; level band reached 21; requires a profession 15; prerequisite unavailable 13; finisher outside the chapter zones 9; objective item source not in zone 7; quest level below the band 6; manual drop (overrides.lua) 3; exclusive with another quest 2; event 1; exploration point not in zone 1; low ratio 1; objective object not in zone 1; repeatable 1.

Horde: 87 distinct APR-only quests over all slices. Why our route builder left them out (its chapter report, `docs/routes/<chapter>.md`): not a candidate of the chapter 33; level band reached 19; requires a profession 11; finisher outside the chapter zones 7; objective item source not in zone 5; prerequisite dropped 3; event 2; low ratio 2; prerequisite unavailable 2; exclusive with another quest 1; exploration point not in zone 1; far 1.

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
| A_03 | 22-26 | #57 | 56 | 42 (75 %) | 53 (95 %) | 42 / 57 (74 %) | 14 | 3 | 81 % | 0.63 | 0-3 / 0 | 2-3 / 3 | 1-2 / 1 |
| A_04 | 26-29 | #52, #61 | 32 | 15 (47 %) | 16 (50 %) | 14 / 42 (33 %) | 28 | 16 | 72 % | 0.43 | 0-1 / 0 | 3 / 0 | 1 / 0 |
| A_05 | 29-30 | #68 | 8 | 6 (75 %) | 6 (75 %) | 6 / 8 (75 %) | 2 | 2 | 88 % | 0.75 | 0 / 0 | 0 / 0 | 1 / 0 |
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
| H_05 | 28-30 | #65 | 20 | 6 (30 %) | 10 (50 %) | 6 / 12 (50 %) | 6 | 10 | 82 % | 0.64 | 0-2 / 0 | 0 / 1 | 0 / 1 |

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
  - In another Questify chapter: 103
  - In no Questify chapter (APR-only): 34, 67, 68, 69, 70, 72, 74, 90, 94, 104, 126, 173, 1076, 1078 (20 150 XP)
  - Left out, quest level above 28 (band + 2): 269, 335
    - finisher outside the chapter zones: 67, 69
    - manual drop (overrides.lua): 34, 173
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
- Questify -> APR: 6 of 20 general quests in the matched routes (30 %), 10 anywhere in APR (50 %).
  - Absent from APR (Questify-only): 541, 547, 550, 78143, 78145, 78149, 79097, 96986, 98094, 98095 (13 855 XP)
  - In another APR route: 501, 502, 527, 528
- APR -> Questify (slice): 6 of 12 general quests in this chapter (50 %).
  - In another Questify chapter: none
  - In no Questify chapter (APR-only): 546, 556, 567, 676, 677, 7321 (15 000 XP)
  - Left out, quest level above 32 (band + 2): 533, 544, 642, 655, 671, 672, 674, 675, 1136, 1164
    - finisher outside the chapter zones: 676
    - level band reached: 546, 567
    - not a candidate of the chapter: 677
    - objective item source not in zone: 556
    - requires a profession: 7321
- Order: 15 shared events, 86 of 105 pairs in the same order (82 %), Kendall tau 0.64.
  Most costly inversions (each event once; gap = distance in ranks among the shared events):

  | Questify does first | then | Questify gap | APR does them the other way, gap |
  |---|---|---|---|
  | complete 539 | complete 552 | 6 | 5 |
  | accept 539 | accept 552 | 4 | 4 |
  | complete 509 | turnin 552 | 5 | 3 |

- Class quests:

  | Class | APR (slice) | Questify class steps | APR's done by this chapter | APR's offered by `ClassQuestData.lua` | APR's in neither |
  |---|---|---|---|---|---|
  | WARRIOR | 2 | 0 | 0 | 1 | 1712 |

- Hearthstone: APR uses it 0 times (WARRIOR 0, PALADIN 0, HUNTER 0, ROGUE 0, PRIEST 0, SHAMAN 0, MAGE 0, WARLOCK 0, DRUID 0; 0 "if ready" steps open to all) and binds it 0 times (maps none); Questify uses it 1 times and binds it 1 times (maps Hillsbrad Foothills (1424)).

## Indoor notes per zone (APR) and Questify cave entrances

APR steps of leveling routes with a note about a cave (cave, mine, tunnel, crypt...), a building (inside, inn, tower, barn...) or a floor (upstairs, downstairs, ramp, elevator...), on the maps our guides use; the notes are classified by keyword, never copied. A step can count in several categories. "Our quests": quest IDs of those steps that a Questify chapter of the faction also does: there an entrance or a floor hint may be missing on our side. Cave entrances: entries of `Questify/Data/Caves.lua` on that map.

### Alliance

| Map | Cave steps | Building steps | Floor steps | Our quests: cave | Our quests: building | Our quests: floor | Questify cave entrances |
|---|---|---|---|---|---|---|---|
| Alterac Mountains (1416) | 0 | 2 | 0 | none | none | none | 0 |
| Hillsbrad Foothills (1424) | 3 | 4 | 1 | none | 555 | 555 | 0 |
| Dun Morogh (1426) | 20 | 2 | 9 | 218, 287, 313, 413, 414, 432, 433 | 170 | 310, 311 | 1 |
| Elwynn Forest (1429) | 9 | 10 | 35 | 21, 62, 76, 91743 | 60 | 3905 | 1 |
| Duskwood (1431) | 7 | 25 | 2 | 134, 181, 323 | 66, 101, 148, 149, 154, 160, 163, 164, 165, 175, 177, 251, 253 | none | 0 |
| Loch Modan (1432) | 9 | 30 | 10 | 307 | 298, 301, 302, 6387, 6392 | none | 0 |
| Redridge Mountains (1433) | 1 | 13 | 2 | none | 91 | none | 0 |
| Westfall (1436) | 0 | 6 | 2 | none | none | none | 0 |
| Wetlands (1437) | 12 | 14 | 18 | 299, 305, 306 | 290, 292, 464, 465, 98221 | 290, 292, 464 | 0 |
| Teldrassil (1438) | 3 | 0 | 0 | 917 | none | none | 0 |
| Darkshore (1439) | 20 | 6 | 30 | 947, 994 | 982 | 947, 965, 982, 983 | 0 |
| Ashenvale (1440) | 0 | 0 | 2 | none | none | none | 0 |
| Stormwind City (1453) | 0 | 10 | 61 | none | none | none | 0 |
| Ironforge (1455) | 0 | 8 | 16 | none | 6388, 6391 | none | 0 |
| Darnassus (1457) | 0 | 1 | 1 | none | none | none | 0 |
| Zephras Isle (2521) | 26 | 106 | 92 | 92849, 94489 | 93927, 94414 | 92645, 93927, 94414 | 0 |

Other maps with indoor notes at APR (no Questify step there yet): 13.

### Horde

| Map | Cave steps | Building steps | Floor steps | Our quests: cave | Our quests: building | Our quests: floor | Questify cave entrances |
|---|---|---|---|---|---|---|---|
| Durotar (1411) | 12 | 29 | 12 | none | none | 830 | 2 |
| Mulgore (1412) | 6 | 3 | 1 | 76156 | 3376, 76156 | 76156 | 0 |
| The Barrens (1413) | 2 | 24 | 9 | none | 858, 867, 871, 872, 875, 876, 95508 | 876, 887 | 0 |
| Tirisfal Glades (1420) | 17 | 13 | 8 | 380 | 354, 371, 375 | 375 | 1 |
| Silverpine Forest (1421) | 39 | 9 | 3 | none | 422, 425 | 422 | 0 |
| Hillsbrad Foothills (1424) | 3 | 15 | 4 | 539 | 527, 532 | 527, 539 | 0 |
| Ashenvale (1440) | 2 | 6 | 5 | 6482 | 1088, 6544 | 6544 | 0 |
| Thousand Needles (1441) | 5 | 4 | 3 | none | 5064 | none | 0 |
| Stonetalon Mountains (1442) | 1 | 2 | 0 | none | 6629 | none | 0 |
| Orgrimmar (1454) | 0 | 12 | 4 | none | none | 97246 | 0 |
| Thunder Bluff (1456) | 9 | 0 | 12 | none | none | none | 0 |
| Undercity (1458) | 16 | 0 | 70 | none | none | none | 0 |
| Zephras Isle (2521) | 5 | 21 | 24 | 94489 | 93927 | 93927 | 0 |

Other maps with indoor notes at APR (no Questify step there yet): 19.

## APR leveling routes without a Questify chapter

General leveling routes (open to at least 4 classes) that no chapter of the faction matches: ground still to cover (levels 30-60), or a zone or variant our route skips.

### Alliance (31 routes)

| APR route | Quests | Done by a Questify chapter |
|---|---|---|
| #14 (Zephras Isle (2521), 10-13) | 4 | 0 |
| #16 (Loch Modan (1432), 11-13) | 17 | 4 |
| #43 (Redridge Mountains (1433), 19-20) | 49 | 9 |
| #55 (Wetlands (1437), 23-24) | 12 | 2 |
| #63 (Ashenvale (1440), 29-30) | 26 | 3 |
| #64 (Duskwood (1431), 29-32) | 66 | 15 |
| #69 (Thousand Needles (1441), 33-34) | 41 | 0 |
| #72 (Stranglethorn Vale (1434), 34-35) | 46 | 0 |
| #74 (Desolace (1443), 35-37) | 30 | 0 |
| #77 (Stranglethorn Vale (1434), 36-38) | 26 | 0 |
| #80 (Swamp of Sorrows (1435), 38-39) | 18 | 0 |
| #83 (Arathi Highlands (1417), 39-40) | 49 | 0 |
| #85 (Wetlands (1437), 40-40) | 22 | 0 |
| #86 (Desolace (1443), 40-41) | 16 | 0 |
| #88 (Badlands (1418), 41-41) | 30 | 0 |
| #89 (Stranglethorn Vale (1434), 41-43) | 48 | 0 |
| #93 (Tanaris (1446), 43-44) | 24 | 0 |
| #96 (Feralas (1444), 44-48) | 32 | 0 |
| #101 (Tanaris (1446), 48-50) | 54 | 0 |
| #104 (Stranglethorn Vale (1434), 50-50) | 15 | 0 |
| #105 (Searing Gorge (1427), 50-51) | 26 | 0 |
| #106 (Blasted Lands (1419), 51-51) | 10 | 0 |
| #107 (Western Plaguelands (1422), 51-52) | 35 | 0 |
| #109 (Felwood (1448), 52-52) | 29 | 0 |
| #111 (Feralas (1444), 52-53) | 12 | 0 |
| #112 (Azshara (1447), 53-53) | 13 | 0 |
| #113 (Un'Goro Crater (1449), 53-54) | 44 | 0 |
| #115 (Felwood (1448), 54-56) | 47 | 0 |
| #118 (Burning Steppes (1428), 56-57) | 38 | 0 |
| #120 (Eastern Plaguelands (1423), 57-59) | 66 | 0 |
| #122 (Winterspring (1452), 59-60) | 57 | 0 |

### Horde (26 routes)

| APR route | Quests | Done by a Questify chapter |
|---|---|---|
| #13 (Tirisfal Glades (1420), 10-12) | 11 | 5 |
| #54 (Hillsbrad Foothills (1424), 22-24) | 26 | 6 |
| #70 (Thousand Needles (1441), 33-34) | 28 | 1 |
| #73 (Desolace (1443), 34-35) | 27 | 1 |
| #76 (Stranglethorn Vale (1434), 35-37) | 35 | 0 |
| #79 (Dustwallow Marsh (1445), 37-38) | 18 | 0 |
| #81 (Arathi Highlands (1417), 38-39) | 35 | 0 |
| #82 (Badlands (1418), 39-40) | 20 | 0 |
| #87 (Stranglethorn Vale (1434), 40-41) | 13 | 0 |
| #90 (Swamp of Sorrows (1435), 41-400) | 22 | 0 |
| #91 (Desolace (1443), 41-41) | 8 | 0 |
| #92 (Tanaris (1446), 41-43) | 25 | 0 |
| #95 (Feralas (1444), 43-44) | 26 | 0 |
| #97 (Stranglethorn Vale (1434), 44-45) | 29 | 0 |
| #98 (Swamp of Sorrows (1435), 45-46) | 16 | 0 |
| #99 (Tanaris (1446), 46-48) | 37 | 0 |
| #100 (The Hinterlands (1425), 48-49) | 33 | 0 |
| #102 (Feralas (1444), 49-50) | 26 | 0 |
| #103 (Blasted Lands (1419), 50-51) | 20 | 0 |
| #108 (Searing Gorge (1427), 51-52) | 22 | 0 |
| #110 (Azshara (1447), 52-53) | 26 | 0 |
| #114 (Felwood (1448), 53-54) | 22 | 0 |
| #116 (Un'Goro Crater (1449), 54-55) | 36 | 0 |
| #117 (Felwood (1448), 55-56) | 45 | 0 |
| #119 (Western Plaguelands (1422), 56-58) | 74 | 0 |
| #121 (Winterspring (1452), 58-60) | 54 | 0 |
