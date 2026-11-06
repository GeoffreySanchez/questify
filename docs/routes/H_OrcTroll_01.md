# H_OrcTroll_01 — Valley of Trials

Generated on 2026-11-07 from QuestieDB commit `80866960788084ae1592abf66a08f0d306458a95` by `tools/routebuilder/build.lua`. Simulated race: Orc.

| Item | Value |
|---|---|
| Level band | 1-6 |
| Simulated level | 1.00 -> 6.08 |
| Time | 38 min |
| XP gained | 7893 |
| XP/h | 12347 |
| Steps | 40 |
| Quests turned in | 15 |
| Hubs | 2 |
| Median ratio (XP/s) | 2.79 |
| Hearthstone | no new bind; 0 return(s) planned, 0 bundle(s) |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 4641 | Your Place In The World | 1 | 40 | 1 |
| 2 | 788 | Cutting Teeth | 2 | 170 | 2 |
| 3 | 789 | Sting of the Scorpid | 3 | 250 | 3 |
| 4 | 5441 | Lazy Peons | 4 | 445 | 4 |
| 5 | 792 | Vile Familiars | 4 | 445 | 4 |
| 6 | 97279 | Wayward Weapons | 2 | 170 est. | 4 |
| 7 | 790 | Sarkoth | 5 | 450 | 4 |
| 8 | 4402 | Galgar's Cactus Apple Surprise | 3 | 380 | 4 |
| 9 | 804 | Sarkoth | 5 | 110 | 4 |
| 10 | 794 | Burning Blade Medallion | 5 | 670 | 5 |
| 11 | 6394 | Thazz'ril's Pick | 4 | 445 | 5 |
| 12 | 96652 | The Adventurer | 6 | 135 est. | 5 |
| 13 | 96876 | Ukor's Lost Pack | 8 | 530 est. | 5 |
| 14 | 99123 | Lost in the Shadows | 8 | 700 est. | 6 |
| 15 | 805 | Report to Sen'jin Village | 5 | 225 | 6 |

## Dropped quests

| Quest | Name | Lvl | Reason |
|---|---|---|---|
| 1463 | Earth Sapta | 4 | class quest (ClassQuestData.lua) |
| 1464 | Fire Sapta | 13 | class quest (ClassQuestData.lua) |
| 1485 | Vile Familiars | 4 | class quest (ClassQuestData.lua) |
| 1499 | Vile Familiars | 4 | class quest (ClassQuestData.lua) |
| 1516 | Call of Earth | 4 | class quest (ClassQuestData.lua) |
| 1517 | Call of Earth | 4 | class quest (ClassQuestData.lua) |
| 1518 | Call of Earth | 4 | class quest (ClassQuestData.lua) |
| 1521 | Call of Earth | 4 | class quest (ClassQuestData.lua) |
| 1525 | Call of Fire | 12 | class quest (ClassQuestData.lua) |
| 1526 | Call of Fire | 13 | class quest (ClassQuestData.lua) |
| 1527 | Call of Fire | 13 | class quest (ClassQuestData.lua) |
| 2383 | Simple Parchment | 1 | class quest (ClassQuestData.lua) |
| 3065 | Simple Tablet | 1 | class quest (ClassQuestData.lua) |
| 3082 | Etched Tablet | 1 | class quest (ClassQuestData.lua) |
| 3083 | Encrypted Tablet | 1 | class quest (ClassQuestData.lua) |
| 3084 | Rune-Inscribed Tablet | 1 | class quest (ClassQuestData.lua) |
| 3085 | Hallowed Tablet | 1 | class quest (ClassQuestData.lua) |
| 3086 | Glyphic Tablet | 1 | class quest (ClassQuestData.lua) |
| 3087 | Etched Parchment | 1 | class quest (ClassQuestData.lua) |
| 3088 | Encrypted Parchment | 1 | class quest (ClassQuestData.lua) |
| 3089 | Rune-Inscribed Parchment | 1 | class quest (ClassQuestData.lua) |
| 3090 | Tainted Parchment | 1 | class quest (ClassQuestData.lua) |
| 5649 | In Favor of Spirituality | 4 | class quest (ClassQuestData.lua) |
| 98575 | Tainted Tablet | 1 | class quest (ClassQuestData.lua) |
| 98576 | Glyphic Parchment | 1 | class quest (ClassQuestData.lua) |

## Candidate ratios

Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;
marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are
below 0.35 × the median ratio, or when an objective is more than 900 yd from every hub.

| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |
|---|---|---|---|---|---|---|---|---|---|---|
| 788 | Cutting Teeth | 2 | 670 | 0 | 283 | 253 | 2.34 | 2.70 | 1 |  |
| 789 | Sting of the Scorpid | 3 | 1185 | 0 | 425 | 374 | 2.79 | 3.16 | 1 |  |
| 790 | Sarkoth | 5 | 507 | 0 | 72 | 51 | 5.53 | 8.72 | 1 |  |
| 792 | Vile Familiars | 4 | 1105 | 0 | 395 | 303 | 3.12 | 5.72 | 1 |  |
| 794 | Burning Blade Medallion | 5 | 730 | 0 | 199 | 57 | 3.59 | 16.92 | 1 |  |
| 804 | Sarkoth | 5 | 110 | 0 | 46 | 21 | 2.35 | 5.09 | 0 |  |
| 805 | Report to Sen'jin Village | 5 | 467 | 242 | 116 | 16 | 4.03 | 28.48 | 0 |  |
| 4402 | Galgar's Cactus Apple Surprise | 3 | 380 | 0 | 247 | 198 | 1.54 | 1.91 | 1 |  |
| 4641 | Your Place In The World | 1 | 62 | 22 | 28 | 28 | 2.33 | 2.67 | 0 |  |
| 5441 | Lazy Peons | 4 | 445 | 0 | 155 | 90 | 2.60 | 5.42 | 1 |  |
| 6394 | Thazz'ril's Pick | 4 | 445 | 0 | 193 | 70 | 2.30 | 6.29 | 1 |  |
| 96652 | The Adventurer | 6 | 442 | 307 | 143 | 16 | 3.09 | 27.26 | 0 |  |
| 96876 | Ukor's Lost Pack | 8 | 1020 | 155 | 263 | 181 | 3.87 | 5.64 | 0 |  |
| 97279 | Wayward Weapons | 2 | 170 | 0 | 191 | 129 | 0.89 | 1.31 | 1 |  |
| 99123 | Lost in the Shadows | 8 | 879 | 179 | 158 | 158 | 5.55 | 5.55 | 1 |  |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | A | 4641 | Your Place In The World | 1411 | 43.3, 68.5 | 63 |  |
| 2 | T | 4641 | Your Place In The World | 1411 | 42.1, 68.3 | 65 |  |
| 3 | A | 788 | Cutting Teeth | 1411 | 42.1, 68.3 | 0 |  |
| 4 | A | 97279 | Wayward Weapons | 1411 | 42.1, 68.3 | 0 |  |
| 5 | O | 97279 | Wayward Weapons | 1411 | 44.3, 64.2 | 186 |  |
| 6 | O | 788 | Cutting Teeth | 1411 | 43.4, 62.5 | 76 |  |
| 7 | T | 788 | Cutting Teeth | 1411 | 42.1, 68.3 | 217 |  |
| 8 | A | 789 | Sting of the Scorpid | 1411 | 42.1, 68.3 | 0 |  |
| 9 | A | 790 | Sarkoth | 1411 | 40.6, 62.6 | 216 |  |
| 10 | O | 789 | Sting of the Scorpid | 1411 | 40.6, 62.4 | 5 |  |
| 11 | A | 4402 | Galgar's Cactus Apple Surprise | 1411 | 42.7, 67.2 | 203 |  |
| 12 | T | 789 | Sting of the Scorpid | 1411 | 42.1, 68.3 | 52 |  |
| 13 | A | 792 | Vile Familiars | 1411 | 42.9, 69.2 | 50 |  |
| 14 | A | 5441 | Lazy Peons | 1411 | 44.6, 68.7 | 95 |  |
| 15 | O | 4402 | Galgar's Cactus Apple Surprise | 1411 | 45.3, 62.5 | 221 |  |
| 16 | O | 792 | Vile Familiars | 1411 | 44.7, 55.7 | 241 |  |
| 17 | O | 5441 | Lazy Peons | 1411 | 41.7, 58.9 | 197 |  |
| 18 | T | 5441 | Lazy Peons | 1411 | 44.6, 68.7 | 378 |  |
| 19 | A | 6394 | Thazz'ril's Pick | 1411 | 44.6, 68.7 | 0 |  |
| 20 | T | 792 | Vile Familiars | 1411 | 42.9, 69.2 | 95 |  |
| 21 | A | 794 | Burning Blade Medallion | 1411 | 42.9, 69.2 | 0 |  |
| 22 | T | 97279 | Wayward Weapons | 1411 | 40.5, 68.0 | 132 |  |
| 23 | O | 790 | Sarkoth | 1411 | 40.5, 66.8 | 41 |  |
| 24 | T | 790 | Sarkoth | 1411 | 40.6, 62.6 | 149 |  |
| 25 | A | 804 | Sarkoth | 1411 | 40.6, 62.6 | 0 |  |
| 26 | O | 6394 | Thazz'ril's Pick | 1411 | 43.7, 53.8 | 351 |  |
| 27 | O | 794 | Burning Blade Medallion | 1411 | 42.7, 53.0 | 61 |  |
| 28 | T | 4402 | Galgar's Cactus Apple Surprise | 1411 | 42.7, 67.2 | 503 |  |
| 29 | T | 804 | Sarkoth | 1411 | 42.1, 68.3 | 52 |  |
| 30 | T | 794 | Burning Blade Medallion | 1411 | 42.9, 69.2 | 50 |  |
| 31 | A | 805 | Report to Sen'jin Village | 1411 | 42.9, 69.2 | 0 |  |
| 32 | A | 96652 | The Adventurer | 1411 | 42.8, 69.1 | 3 |  |
| 33 | T | 6394 | Thazz'ril's Pick | 1411 | 44.6, 68.7 | 98 |  |
| 34 | A | 99123 | Lost in the Shadows | 1411 | 46.3, 78.6 | 363 |  |
| 35 | O | 99123 | Lost in the Shadows | 1411 | 51.4, 79.3 | 271 |  |
| 36 | A | 96876 | Ukor's Lost Pack | 1411 | 51.2, 55.3 | 847 |  |
| 37 | T | 96652 | The Adventurer | 1411 | 52.0, 47.3 | 285 |  |
| 38 | T | 96876 | Ukor's Lost Pack | 1411 | 52.1, 68.3 | 741 |  |
| 39 | T | 99123 | Lost in the Shadows | 1411 | 55.9, 74.4 | 296 |  |
| 40 | T | 805 | Report to Sen'jin Village | 1411 | 56.0, 74.7 | 11 |  |

Walking between tasks: 6630 yd (~16 min at 7 yd/s).

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
