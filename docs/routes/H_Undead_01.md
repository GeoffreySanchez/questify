# H_Undead_01 — Deathknell

Generated on 2026-11-07 from QuestieDB commit `80866960788084ae1592abf66a08f0d306458a95` by `tools/routebuilder/build.lua`. Simulated race: Undead.

| Item | Value |
|---|---|
| Level band | 1-6 |
| Simulated level | 1.00 -> 6.02 |
| Time | 45 min |
| XP gained | 7662 |
| XP/h | 10280 |
| Steps | 35 |
| Quests turned in | 13 |
| Hubs | 1 |
| Median ratio (XP/s) | 3.20 |
| Grinding (level steps) | ~1 mobs |
| Hearthstone | no new bind; 0 return(s) planned, 0 bundle(s) |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 363 | Rude Awakening | 1 | 40 | 1 |
| 2 | 364 | The Mindless Ones | 2 | 170 | 2 |
| 3 | 376 | The Damned | 2 | 170 | 3 |
| 4 | 3901 | Rattling the Rattlecages | 3 | 250 | 4 |
| 5 | 6395 | Marla's Last Wish | 5 | 450 | 4 |
| 6 | 3902 | Scavenging Deathknell | 3 | 315 | 4 |
| 7 | 98389 | A Light in the Darkness | 4 | 355 est. | 5 |
| 8 | 380 | Night Web's Hollow | 4 | 355 | 5 |
| 9 | 381 | The Scarlet Crusade | 4 | 355 | 5 |
| 10 | 382 | The Red Messenger | 5 | 670 | 5 |
| 11 | 96656 | The Adventurer | 6 | 135 est. | 5 |
| 12 | 383 | Vital Intelligence | 5 | 335 | 5 |
| 13 | 8 | A Rogue's Deal | 5 | 110 | 5 |

## Dropped quests

| Quest | Name | Lvl | Reason |
|---|---|---|---|
| 590 | A Rogue's Deal | 5 | Opened by the turn-in of 8 in Brill: 1,071 yd back to Calvin Montague, then back to Brill, for 110 XP |
| 1470 | Piercing the Veil | 3 | class quest (ClassQuestData.lua) |
| 3095 | Simple Scroll | 1 | class quest (ClassQuestData.lua) |
| 3096 | Encrypted Scroll | 1 | class quest (ClassQuestData.lua) |
| 3097 | Hallowed Scroll | 1 | class quest (ClassQuestData.lua) |
| 3098 | Glyphic Scroll | 1 | class quest (ClassQuestData.lua) |
| 3099 | Tainted Scroll | 1 | class quest (ClassQuestData.lua) |
| 5651 | In Favor of Darkness | 4 | class quest (ClassQuestData.lua) |
| 90902 | Rediscovering the Light | 2 | class quest (ClassQuestData.lua) |
| 91208 | Coming to Terms | 4 | class quest (ClassQuestData.lua) |
| 91209 | Continue Your Training | 4 | class quest (ClassQuestData.lua) |
| 98601 | A Difficult Path | 1 | class quest (ClassQuestData.lua) |

## Candidate ratios

Value = quest XP at the simulated level + mob XP + strategic bonus. Ratio = chain value / isolated time;
marginal ratio uses the detour from places the route visits anyway. A quest is dropped when both ratios are
below 0.35 × the median ratio, or when an objective is more than 900 yd from every hub.

| Quest | Name | Lvl | Value | Bonus | Isolated s | Marginal s | Ratio | Marginal ratio | Sites | Dropped |
|---|---|---|---|---|---|---|---|---|---|---|
| 8 | A Rogue's Deal | 5 | 530 | 420 | 222 | 65 | 2.39 | 8.13 | 0 |  |
| 363 | Rude Awakening | 1 | 105 | 65 | 63 | 63 | 2.57 | 2.77 | 0 |  |
| 364 | The Mindless Ones | 2 | 970 | 0 | 371 | 349 | 2.71 | 2.95 | 1 |  |
| 376 | The Damned | 2 | 1244 | 0 | 529 | 467 | 3.03 | 3.94 | 1 |  |
| 380 | Night Web's Hollow | 4 | 1315 | 0 | 478 | 410 | 3.20 | 4.48 | 1 |  |
| 381 | The Scarlet Crusade | 4 | 1290 | 0 | 429 | 365 | 3.64 | 6.36 | 1 |  |
| 382 | The Red Messenger | 5 | 730 | 0 | 100 | 30 | 4.69 | 39.89 | 1 |  |
| 383 | Vital Intelligence | 5 | 866 | 531 | 208 | 10 | 4.16 | 86.69 | 0 |  |
| 3901 | Rattling the Rattlecages | 3 | 874 | 0 | 304 | 265 | 2.87 | 3.29 | 1 |  |
| 3902 | Scavenging Deathknell | 3 | 315 | 0 | 111 | 94 | 2.82 | 3.33 | 1 |  |
| 6395 | Marla's Last Wish | 5 | 450 | 0 | 32 | 32 | 13.74 | 13.74 | 1 |  |
| 96656 | The Adventurer | 6 | 597 | 462 | 183 | 10 | 3.27 | 59.78 | 0 |  |
| 98389 | A Light in the Darkness | 4 | 355 | 0 | 105 | 33 | 3.35 | 10.59 | 1 |  |

## Itinerary

One line per task (A accept, O objective, T turn-in, C timed quest, F flight path). Leg = straight-line
yards from the previous task (blank after a flight, boat or zone change). Returns: the task is within
150 yd of an earlier task after the route went more than 600 yd away from it.

| # | Task | Quest | Name | Map | x, y | Leg yd | Return |
|---|---|---|---|---|---|---|---|
| 1 | A | 363 | Rude Awakening | 1420 | 30.2, 71.7 | 166 |  |
| 2 | T | 363 | Rude Awakening | 1420 | 30.8, 66.2 | 166 |  |
| 3 | A | 364 | The Mindless Ones | 1420 | 30.8, 66.2 | 0 |  |
| 4 | O | 364 | The Mindless Ones | 1420 | 32.1, 63.4 | 101 |  |
| 5 | A | 376 | The Damned | 1420 | 30.9, 66.0 | 97 |  |
| 6 | T | 364 | The Mindless Ones | 1420 | 30.8, 66.2 | 4 |  |
| 7 | A | 3901 | Rattling the Rattlecages | 1420 | 30.8, 66.2 | 0 |  |
| 8 | O | 376 | The Damned | 1420 | 35.7, 58.3 | 323 |  |
| 9 | O | 3901 | Rattling the Rattlecages | 1420 | 33.2, 62.0 | 160 |  |
| 10 | T | 376 | The Damned | 1420 | 30.9, 66.0 | 160 |  |
| 11 | A | 6395 | Marla's Last Wish | 1420 | 30.9, 66.0 | 0 |  |
| 12 | T | 3901 | Rattling the Rattlecages | 1420 | 30.8, 66.2 | 4 |  |
| 13 | A | 98389 | A Light in the Darkness | 1420 | 31.1, 66.4 | 13 |  |
| 14 | A | 3902 | Scavenging Deathknell | 1420 | 31.6, 65.6 | 33 |  |
| 15 | A | 380 | Night Web's Hollow | 1420 | 32.1, 66.0 | 27 |  |
| 16 | O | 6395 | Marla's Last Wish | 1420 | 31.2, 65.1 | 52 |  |
| 17 | T | 6395 | Marla's Last Wish | 1420 | 30.9, 66.0 | 32 |  |
| 18 | O | 3902 | Scavenging Deathknell | 1420 | 33.0, 64.3 | 111 |  |
| 19 | T | 3902 | Scavenging Deathknell | 1420 | 31.6, 65.6 | 75 |  |
| 20 | O | 98389 | A Light in the Darkness | 1420 | 26.8, 59.6 | 281 |  |
| 21 | O | 380 | Night Web's Hollow | 1420 | 28.4, 58.1 | 85 |  |
| 22 | T | 98389 | A Light in the Darkness | 1420 | 31.1, 66.4 | 278 |  |
| 23 | T | 380 | Night Web's Hollow | 1420 | 32.1, 66.0 | 48 |  |
| 24 | A | 381 | The Scarlet Crusade | 1420 | 32.1, 66.0 | 0 |  |
| 25 | O | 381 | The Scarlet Crusade | 1420 | 37.5, 67.5 | 246 |  |
| 26 | T | 381 | The Scarlet Crusade | 1420 | 32.1, 66.0 | 246 |  |
| 27 | A | 382 | The Red Messenger | 1420 | 32.1, 66.0 | 0 |  |
| 28 | O | 382 | The Red Messenger | 1420 | 36.6, 68.5 | 213 |  |
| 29 | T | 382 | The Red Messenger | 1420 | 32.1, 66.0 | 213 |  |
| 30 | A | 383 | Vital Intelligence | 1420 | 32.1, 66.0 | 0 |  |
| 31 | A | 96656 | The Adventurer | 1420 | 32.1, 66.0 | 0 |  |
| 32 | A | 8 | A Rogue's Deal | 1420 | 38.2, 56.8 | 390 |  |
| 33 | T | 96656 | The Adventurer | 1420 | 57.3, 55.5 | 861 |  |
| 34 | T | 383 | Vital Intelligence | 1420 | 60.6, 51.8 | 187 |  |
| 35 | T | 8 | A Rogue's Deal | 1420 | 61.7, 52.0 | 51 |  |

Walking between tasks: 4639 yd (~11 min at 7 yd/s).

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
