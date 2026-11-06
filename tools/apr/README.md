# APR comparison

Offline LuaJIT tool that compares the Questify chapters (`Questify/Guides`) with the World of Warcraft:
Forever routes of Azeroth Pilot Reloaded (APR) and writes `docs/routes/APR-COMPARE.md`. Run it again after
each regeneration of the guides.

APR is free software under GPL-3.0
([github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded](https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded)),
credit to its authors. Nothing from APR is copied or redistributed: the tool reads a local clone at run
time, and the report holds only counts, map IDs and quest IDs. An APR route is named there by its rank in
APR's play order, its map and its level band, never by its name, label or notes.

## Commands

Run everything from the project root.

```sh
# Local clone of APR (outside the repository: .cache/ is ignored by git)
git clone https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded.git .cache/apr
git -C .cache/apr pull          # later updates

# Write docs/routes/APR-COMPARE.md
luajit tools/apr/compare.lua [--apr DIR] [--guides DIR] [--reports DIR] [--caves FILE] [--uimap FILE]
       [--db DIR] [--questie DIR] [--out FILE] [--date YYYY-MM-DD] [--no-xp]

# Tests (fictive routes and guides in tests/fixtures, no APR data needed)
luajit tools/apr/tests/run.lua [pattern]
```

| Flag | Default | Meaning |
|---|---|---|
| `--apr` | `.cache/apr` | APR clone. Version: the tag on `HEAD` and the commit, read from `.git` without running git. |
| `--guides` | `Questify/Guides` | Chapters listed in `Guides.xml`, plus `ClassQuestData.lua` |
| `--reports` | `docs/routes` | Chapter reports of the route builder: why it dropped a quest (`## Dropped quests`) |
| `--caves` | `Questify/Data/Caves.lua` | Cave entrances shipped with Questify, counted per map |
| `--uimap` | `tools/routebuilder/data/UiMap.csv` | Map names (optional) |
| `--db`, `--questie` | `.cache/questiedb`, `.cache/questie` | QuestieDB and Questie, read through `tools/routebuilder/qdb.lua` for quest XP |
| `--no-xp` | off | Skip QuestieDB: the verdicts then use quest counts |
| `--out` | `docs/routes/APR-COMPARE.md` | Report |
| `--date` | today | Date written in the report |

## What is compared

For each chapter, the APR routes that match it: leveling category, same faction, open to a race of the
chapter and to at least 4 classes, level band within 2 levels of the chapter's, at least 3 shared quests
and 10 % of the chapter's quests or 25 % of the route's. The matched routes are put in APR's play order
(`nextRoute` graph, level, then load order); the *slice* runs from the first to the last APR step that
names a quest of the chapter.

- Coverage: chapter quests found in the matched routes and anywhere in APR (lists of the missing IDs);
  slice quests found in the chapter, in another chapter, or in none ("APR-only", grouped by the reason
  the route builder gave in its chapter report).
- Order: first `accept`, `complete` and `turnin` of each quest, on the events present on both sides:
  share of pairs in the same order, Kendall tau, and the five most costly inverted pairs (each event
  listed once).
- Class quests: per class, quests open to at most 3 classes at APR (step conditions) against `classes`
  / `class` steps here, and those offered by `ClassQuestData.lua`. Class quests stay out of the coverage.
- Hearthstone: use and bind steps per class in the slice, against `hearth` and `sethearth` steps.
- Indoor notes per zone: APR steps whose note key names a cave, a building or a floor (keyword
  classification, the notes are not copied), with the quest IDs of our guides on those steps and the
  number of cave entrances in `Caves.lua`.
- APR leveling routes that no chapter matches (levels 30-60, skipped zones).
- Summary: a side is clearly ahead on a chapter when the quests only it does on that slice are worth at
  least 15 % of the chapter's quest XP more than the other side's (at least 5 such quests). XP comes from
  the QuestieDB Forever view of the route builder, for a player in the chapter's band; without QuestieDB,
  quest counts are used. Travel and kill time are not compared.

## Sandbox

`apr.lua` reads each route file listed in `Routes/RouteList_Camelot.xml` (the Forever client list) as
text, refuses bytecode, and runs it with `setfenv` in a strict environment that holds only stubs
(`LibStub`, `APR` enums, a fake coordinate converter, `RouteQuestStepList`) and copies of `string` (without
`dump`) and `math`: no `io`, `os`, `require`, `load*`, `pcall`, `debug` or `getfenv`, and any unknown global
raises an error. The code runs interpreted (`jit.off`) under an instruction limit.

Conditions are read statically: faction, race, class and hardcore are known; level, quest, item and
other in-game conditions are unknown and never exclude a step.

## Known limits

- APR's slice ends at the last shared quest: APR quests after it, in a route no later chapter matches,
  count in no slice (see the table of routes without a chapter).
- A quest at the boundary of two chapters can count in both slices; the summary line per faction counts
  it once.
- Quest XP is not route XP: it ignores travel, kill time and grinding, and the player level is a guess
  (the chapter band, nearest to the quest level).
- A note key that does not name its place (for example a note about an NPC) is not counted as indoor.
