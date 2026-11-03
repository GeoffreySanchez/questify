# H_Undead_01 — Deathknell

Generated on 2026-11-03 from QuestieDB commit `c5de61ab7c629132a772cccddf7f604ac48cecf9` by `tools/routebuilder/build.lua`. Simulated race: Undead.

| Item | Value |
|---|---|
| Level band | 1-6 |
| Simulated level | 1.00 -> 6.03 |
| Time | 48 min |
| XP gained | 7702 |
| XP/h | 9530 |
| Steps | 38 |
| Quests turned in | 14 |
| Hubs | 2 |
| Median ratio (XP/s) | 3.31 |

## Kept quests (turn-in order)

XP marked `est.` is an estimate (no QuestXP value: new Forever quest).

| # | Quest | Name | Lvl | XP | Sim lvl |
|---|---|---|---|---|---|
| 1 | 363 | Rude Awakening | 1 | 40 | 1 |
| 2 | 364 | The Mindless Ones | 2 | 170 | 2 |
| 3 | 376 | The Damned | 2 | 170 | 3 |
| 4 | 3901 | Rattling the Rattlecages | 3 | 250 | 4 |
| 5 | 6395 | Marla's Last Wish | 5 | 450 | 4 |
| 6 | 98389 | A Light in the Darkness | 4 | 355 est. | 4 |
| 7 | 380 | Night Web's Hollow | 4 | 355 | 5 |
| 8 | 381 | The Scarlet Crusade | 4 | 355 | 5 |
| 9 | 382 | The Red Messenger | 5 | 670 | 5 |
| 10 | 3902 | Scavenging Deathknell | 3 | 315 | 5 |
| 11 | 8 | A Rogue's Deal | 5 | 110 | 5 |
| 12 | 590 | A Rogue's Deal | 5 | 110 | 5 |
| 13 | 96656 | The Adventurer | 6 | 135 est. | 5 |
| 14 | 383 | Vital Intelligence | 5 | 335 | 6 |

## Dropped quests

| Quest | Name | Lvl | Reason |
|---|---|---|---|
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
| 8 | A Rogue's Deal | 5 | 535 | 425 | 163 | 10 | 3.33 | 19.62 | 0 |  |
| 363 | Rude Awakening | 1 | 106 | 66 | 63 | 63 | 2.57 | 2.77 | 0 |  |
| 364 | The Mindless Ones | 2 | 970 | 0 | 371 | 349 | 2.71 | 2.95 | 1 |  |
| 376 | The Damned | 2 | 1244 | 0 | 529 | 467 | 3.02 | 3.79 | 1 |  |
| 380 | Night Web's Hollow | 4 | 1315 | 0 | 478 | 412 | 3.20 | 4.47 | 1 |  |
| 381 | The Scarlet Crusade | 4 | 1290 | 0 | 429 | 365 | 3.65 | 6.37 | 1 |  |
| 382 | The Red Messenger | 5 | 730 | 0 | 100 | 30 | 4.72 | 40.09 | 1 |  |
| 383 | Vital Intelligence | 5 | 873 | 538 | 208 | 10 | 4.20 | 87.36 | 0 |  |
| 590 | A Rogue's Deal | 5 | 110 | 0 | 30 | 30 | 3.63 | 3.63 | 1 |  |
| 3901 | Rattling the Rattlecages | 3 | 874 | 0 | 304 | 265 | 2.87 | 3.29 | 1 |  |
| 3902 | Scavenging Deathknell | 3 | 315 | 0 | 111 | 94 | 2.82 | 3.33 | 1 |  |
| 6395 | Marla's Last Wish | 5 | 450 | 0 | 32 | 32 | 13.74 | 13.74 | 1 |  |
| 96656 | The Adventurer | 6 | 603 | 468 | 183 | 10 | 3.30 | 60.36 | 0 |  |
| 98389 | A Light in the Darkness | 4 | 355 | 0 | 106 | 93 | 3.32 | 3.81 | 1 |  |

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
| 14 | A | 380 | Night Web's Hollow | 1420 | 32.1, 66.0 | 48 |  |
| 15 | A | 3902 | Scavenging Deathknell | 1420 | 31.6, 65.6 | 27 |  |
| 16 | O | 6395 | Marla's Last Wish | 1420 | 31.2, 65.1 | 25 |  |
| 17 | O | 380 | Night Web's Hollow | 1420 | 28.4, 58.1 | 245 |  |
| 18 | O | 98389 | A Light in the Darkness | 1420 | 26.6, 59.7 | 94 |  |
| 19 | T | 6395 | Marla's Last Wish | 1420 | 30.9, 66.0 | 270 |  |
| 20 | T | 98389 | A Light in the Darkness | 1420 | 31.1, 66.4 | 15 |  |
| 21 | T | 380 | Night Web's Hollow | 1420 | 32.1, 66.0 | 48 |  |
| 22 | A | 381 | The Scarlet Crusade | 1420 | 32.1, 66.0 | 0 |  |
| 23 | O | 3902 | Scavenging Deathknell | 1420 | 33.0, 64.3 | 65 |  |
| 24 | O | 381 | The Scarlet Crusade | 1420 | 37.5, 67.5 | 223 |  |
| 25 | T | 381 | The Scarlet Crusade | 1420 | 32.1, 66.0 | 246 |  |
| 26 | A | 382 | The Red Messenger | 1420 | 32.1, 66.0 | 0 |  |
| 27 | O | 382 | The Red Messenger | 1420 | 36.6, 68.5 | 213 |  |
| 28 | T | 382 | The Red Messenger | 1420 | 32.1, 66.0 | 213 |  |
| 29 | A | 383 | Vital Intelligence | 1420 | 32.1, 66.0 | 0 |  |
| 30 | A | 96656 | The Adventurer | 1420 | 32.1, 66.0 | 0 |  |
| 31 | T | 3902 | Scavenging Deathknell | 1420 | 31.6, 65.6 | 27 |  |
| 32 | A | 8 | A Rogue's Deal | 1420 | 38.2, 56.8 | 399 |  |
| 33 | T | 8 | A Rogue's Deal | 1420 | 61.7, 52.0 | 1071 |  |
| 34 | A | 590 | A Rogue's Deal | 1420 | 38.2, 56.8 | 1071 | near #32 (went 1071 yd away) |
| 35 | O | 590 | A Rogue's Deal | 1420 | 38.2, 56.8 | 0 | near #32 (went 1071 yd away) |
| 36 | T | 590 | A Rogue's Deal | 1420 | 38.2, 56.8 | 0 |  |
| 37 | T | 96656 | The Adventurer | 1420 | 57.3, 55.5 | 861 |  |
| 38 | T | 383 | Vital Intelligence | 1420 | 60.6, 51.8 | 187 | near #33 (went 1021 yd away) |

Walking between tasks: 6556 yd (~16 min at 7 yd/s).

## Logistics

None.

## Warnings

- ordering: task T8 moved before the end of the chapter to free the quest log
