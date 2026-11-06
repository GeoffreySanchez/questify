# Questify route builder

Offline LuaJIT tool that reads World of Warcraft: Forever quest data from a local QuestieDB clone
plus the Forever DB2 tables in `data/`, simulates a character chapter by chapter, and writes the
guide files of `Questify/Guides/` with one Markdown report per chapter.

The route is 100 % our own: the tool only reads facts (quest, NPC and object IDs, spawn
coordinates, XP values). Public guides are never read by the tool.

## Commands

Run everything from the project root.

```sh
# Generate guides, reports, ClassQuestData.lua and Guides.xml
luajit tools/routebuilder/build.lua [--db PATH] [--questie PATH] [--faction Alliance|Horde|all]
       [--only <planId>] [--report DIR] [--out DIR] [--overrides FILE] [--date YYYY-MM-DD]

# Check every guide listed in Guides.xml against QuestieDB (exit code 1 on any violation)
luajit tools/validate_guides.lua [--db PATH] [--questie PATH] [--guides DIR]

# Add the `choices` and `sim` fields to already generated guides, without QuestieDB (see below)
luajit tools/routebuilder/backfill.lua [--guides DIR] [--check]

# Travel time from the end of a chapter to each of its `choices`, without QuestieDB (see below)
luajit tools/routebuilder/travel.lua <planId> [--guides DIR] [--report DIR]

# Tests of the generator
luajit tools/routebuilder/tests/run.lua [pattern]
```

| Flag | Default | Meaning |
|---|---|---|
| `--db` | `~/dev/questify/.cache/questiedb` | QuestieDB root (data files are read as text, run in a sandbox) |
| `--questie` | `~/dev/questify/.cache/questie` | Questie root, for the quest blacklist |
| `--faction` | `all` | `Alliance`, `Horde` or `all` |
| `--only` | none | Write only this chapter. Earlier chapters of its race path are still simulated, so the character state (level, done quests, known flight paths) is right. |
| `--out` | `Questify/Guides` | Guide output root: `<out>/<Alliance\|Horde\|Skyborne>/<planId>.lua`, `<out>/ClassQuestData.lua`, `<out>/Guides.xml` |
| `--report` | `docs/routes` | Markdown reports, `<report>/<planId>.md` |
| `--overrides` | `tools/routebuilder/overrides.lua` | Hand fixes (see below) |
| `--date` | today | Date written in the file headers (set it for reproducible output) |

`build.lua` prints one line per chapter, for example:

```
A_DwarfGnome_01    steps  40  quests  15  dropped   1  lvl  1.00 ->  6.01  xp/h  12569  36 min
```

A chapter whose simulated end level is below `maxLevel - 1` is flagged `[below maxLevel-1]`. Each
line ends with the quality counts `quality R<revisits> P<pickups> A<areas> T<turn-ins>` (see below).

`Guides.xml` is rewritten with every guide file present under `--out` (plan order, then unknown
files alphabetically), then `ClassQuestData.lua` last. Using `--only` therefore never drops the
other chapters from the XML.

## Files

| File | Role |
|---|---|
| `qdb.lua` | QuestieDB loader: Forever view (Era data + Forever correction layers, including the new Forever quests), table add/remove operations, Questie blacklist, XP table, drop rates, dungeon areas. Shapes follow `Q.QDB` (Task 2), spawns keyed by uiMapID. |
| `world.lua` | World geometry from `UiMapAssignment` bounds (map x grows towards world −Y, y towards world −X, checked against the Ironforge flight master), distances, taxi graph (`TaxiNodes`, `TaxiPath`) with Dijkstra flight times. |
| `xp.lua` | Classic XP rules: level table, quest XP modifier, mob XP with zero difference and gray level, estimate for quests without a known value. |
| `sim.lua` | Chapter simulation: candidates, objective sites, hubs, value / time ratios, drops, tasks, logistics (fp, sethearth, hearth, fly, level), XP simulation. |
| `order.lua` | Task ordering: nearest feasible neighbour, then or-opt, with precedence, log cap and final tasks, then the hub / area sweep. |
| `quality.lua` | Itinerary checker: avoidable revisits, missed pickups, split objective areas, missed passing turn-ins. |
| `plans.lua` | Chapter plans per faction (spec § 6), `plans.validate` (successors and `choices`). |
| `emit.lua` | Guide file writer (spec § 5.2 format, one step per line with a comment). |
| `classquests.lua` | Class quest chains (level ≤ 60) for `ClassQuestData.lua`. |
| `overrides.lua` | Hand fixes applied at build time. |
| `build.lua` | CLI. |
| `backfill.lua` | Adds `choices` / `sim` to already generated guides (no QuestieDB). |
| `travel.lua` | Travel time to each `choices` target with `sim.route`, from generated guides and reports (no QuestieDB). |
| `data/*.csv` | Forever DB2 tables, build 1.60.1.70707 (wago.tools): `UiMapAssignment`, `UiMap`, `TaxiNodes`, `TaxiPath`, `AreaTable`, `Map`. |
| `tests/` | `run.lua` runner, `test_world.lua`, `test_xp.lua`, `test_sim.lua` (on the synthetic `fixture_zone.lua`), `test_emit.lua`, `test_choices.lua` (`choices`, `sim`, validation, backfill, travel; no QuestieDB). |

## Plans (`plans.lua`)

`plans.lua` returns `{ Alliance = { ... }, Horde = { ... } }`. Each list is in route order. A plan:

```lua
{
  id = "A_DwarfGnome_01", title = "Coldridge Valley", faction = "Alliance",
  races = { "Dwarf", "Gnome" },          -- start chapters only; trunk chapters have none
  zones = { 1426 },                      -- uiMapIDs where quests start and objectives are done
  bounds = { [1426] = { 19, 57, 38, 85 } }, -- optional rectangle(s) x1, y1, x2, y2 (0-100) limiting a zone map
  endZones = { 1426 },                   -- maps where a turn-in may happen at the end of the chapter
  minLevel = 1, maxLevel = 6,
  entry = { 1426, 29.93, 71.20 },        -- first hub; start position when the character has none
  exit = { mapId, x, y },                -- optional point where the chapter should end
  next = "A_DwarfGnome_02",              -- or nextByRace = { Dwarf = "A_01", ... }
  choices = {                            -- optional: 2 to 4 successors offered at the end of the chapter
    { id = "A_DwarfGnome_02", travel = { kind = "walk", minutes = 2 } },  -- must include the default
    { id = "A_Human_02", races = { "Gnome" }, label = "...", travel = { kind = "tram" }, weight = 1 },
  },                                     -- (see "Successor choices" below)
  flightPaths = { "Ironforge, Dun Morogh" }, -- TaxiNodes names to pick up in this chapter (planned detour)
  dungeons = { "The Hall of Thanes" },   -- dungeon quests (QuestieDB dungeon names) accepted in passing, optional
  optional = { [96391] = "Hall of Thanes" }, -- forced quests marked optional + dungeon label
  force = { [id] = true }, drop = { [id] = "reason" },
  levelSlack = 1,                        -- levels of overshoot allowed above maxLevel (XP budget)
  logCap = 20,
  strictLevel = true,                    -- grinding before a level-gated task counts in the ordering
  precede = { { "A3376", "O757" } },     -- first task before the second (A/T/C<quest>, O<quest> = all
                                         -- objective sites of the quest); a missing task is a warning
  safeLevel = { [312] = 7 },             -- level from which the objectives of a quest are done (replaces
                                         -- the computed "safe" level: quest level - 1, mob level - 1)
  widen = false,                         -- never widen the band (the zone is visited again later: its
                                         -- higher quests stay for that chapter)
  arrive = { via = { 1453, 24.1, 55.4 }, steps = { { "boat", 1453, 24.1, 55.4, note = "..." } }, time = 300 },
                                         -- steps inserted when the character comes from another
                                         -- continent or more than 1500 yd away; `via` (optional):
                                         -- computed travel (flights, tram) to that point first;
                                         -- `time` covers the fixed steps only
}
```

Ids: `A_<Start>_<NN>`, `A_<NN>` (Alliance trunk), `H_<Start>_<NN>`, `H_<NN>`, `A_Skyborne_<NN>`,
`H_Skyborne_<NN>`. Skyborne guides are written to `Guides/Skyborne/`.

Simulation order: for each faction, the race path of the first start chapter (Dwarf for Alliance,
Orc for Horde) is simulated through the trunk; the other start paths are simulated from level 1 up
to the first chapter already simulated. Trunk chapters are therefore tuned for the primary race path.

The `bounds` and `entry` values of every chapter except `A_DwarfGnome_01` are first estimates from
real QuestieDB start NPCs and must be checked when the chapter is reviewed.

## Overrides (`overrides.lua`)

A pure data file, loaded in an empty environment:

```lua
return {
  force = { [questId] = true },             -- keep even if dropped for ratio, level band or level range
  drop = { [questId] = "reason" },          -- drop; the reason appears in the report
  pin = { [questId] = { mapId, x, y } },    -- force the objective site
  insertAfter = { [planId] = { { afterQuestTurnin = questId, step = { "note", "..." } } } },
                                            -- step inserted after that turn-in (0 = at the start)
}
```

`force`, `drop` and `pin` are global (any chapter); a quest is only simulated in the first chapter
where it is available. Regenerate after every change and re-run the validator.

## Algorithm

All thresholds are in `sim.CONST` (`sim.lua`).

1. **Candidates.** Quests of the faction, eligible for at least one chapter race, with
   `questLevel` in [minLevel − 3, maxLevel + 3] and `reqLevel ≤ maxLevel` (forced quests skip
   this), a starter spawn in the chapter region (or a starting item dropped by mobs there) and a
   finisher in the region or in `endZones`. Excluded: class quests (class mask of 1 or 2
   classes: they go to `ClassQuestData.lua`; wider masks such as "all but Warlock" stay in the
   route with a `class` filter), profession, spell or reputation requirements, repeatable quests
   (`specialFlags` 1), escorts among the event quests (`specialFlags` 2 without an exploration
   point; see "Lot L" below), blacklisted quests, quests already done. Dungeon quests are only accepted in passing (`optional`,
   `dungeon = name`).
2. **Objective sites.** Spawns of each objective target in the region are grouped on a 60 yd
   grid; the 3 × 3 cell window with the most spawns (drop-rate weighted for items) wins, ties go
   to the window nearest the starter. A second objective of the same quest takes the window
   nearest the first site among windows of at least half the best weight. Sites of one quest
   within 150 yd merge into one task. Counts come from the objective text ("Kill 6 Rockjaw
   Troggs and 6 ..."); without a number: 1 for a unique mob (≤ 3 spawns or elite/rare), else 8
   kills, 6 items, 5 objects.
3. **Time.** Walking 7 yd/s; 20 s per kill; `ceil(n / rate) × 20 s` for drops (rate 0.5 by
   default); 6 s per world object plus the spread of the spawn window; 10 s to talk or explore;
   5 s to accept or turn in.
4. **Hubs.** Starters and finishers within 120 yd are grouped; a hub needs at least two quests.
5. **Value.** Quest XP at the current simulated level (Classic modifier) + mob XP of the kills +
   bonus. Bonus seconds: the walk from starter to finisher for breadcrumbs and turn-ins in
   `endZones`, 300 s for a quest whose finisher or objective is within 150 yd of an unknown
   flight master; seconds are valued at the median isolated ratio of the chapter (XP/s).
6. **Ratios.** Isolated time = hub → starter → sites → finisher → hub. Marginal time = durations +
   twice the distance from each point to the nearest place the route visits anyway (hub, or site
   of a quest whose isolated ratio is at least the median, minus 1.5 × that site's spread). Chains
   are discounted: value and time of a quest include 0.7 × those of the quests it unlocks.
7. **Drops.** "far" when an objective is more than 900 yd from every hub; "low ratio" when both
   the isolated and the marginal ratio are below 0.35 × the median isolated ratio; then quests whose
   prerequisite was dropped. A prerequisite counts as available when it is done, kept in the chapter,
   or in the quest log and turned in in this chapter (a quest done in the previous chapter whose
   finisher is here: its follow-ups stay candidates). A dungeon quest only picked up in passing is
   never turned in on the route: it is not an available prerequisite ("prerequisite unavailable"). **XP budget**: quests are ranked by marginal ratio (forced first) and
   kept, with their prerequisites, until their XP reaches `maxLevel + levelSlack` (1 by default);
   the rest is dropped as "level band reached". Exclusive quests keep the better ratio.
8. **Tasks and ordering.** A (accept), O (objective site), T (turn-in), C (timed quest done in
   one go), F (planned flight path). Constraints: A < O < T; T of a prerequisite or breadcrumb
   before A of the next quest; at most 20 open quests; turn-ins outside the region come last.
   A quest is only accepted once the simulated level reaches its `reqLevel` (the ordering tracks
   the XP of each task); when nothing else is possible, a `level` step (grind near the current
   position) is inserted before the blocked accept.
   Nearest feasible neighbour by walking time (ties within 20 yd: T, then A, then O), then or-opt
   (moves of 1 to 3 consecutive tasks, at most 200 passes) while the total walking time drops.
9. **Logistics.** `fp` when a walk passes within 150 yd of an unknown faction flight master;
   `sethearth` and `hearth`: see "Hearthstone" below; `fly` when the flight
   plus the walks to and from the flight masters takes under 0.7 × the walk (both nodes known;
   flight time = straight line × 1.2 / 32 yd/s + 20 s); `level` at the end when the level is below
   `maxLevel`, pointing to the densest group of hostile mobs of suitable level within 600 yd of
   the final position (else the last kill site). A change of continent without `arrive` steps
   adds a `note` step ("Travel to ...") and 900 s, with a warning in the report.
   Timed quests ("within 15 minutes") are accepted, done and turned in in one go.
10. **XP.** The ordered tasks are walked in order: mob XP per kill, quest XP at turn-in time with
    the modifier of the current level, level-ups carried over.

## Reports (`docs/routes/<planId>.md`)

Summary (level band, simulated levels, time, XP, XP/h, steps), kept quests in turn-in order with
their simulated XP, dropped quests with the reason, a candidate table (value, bonus, isolated and
marginal time and ratio), the logistic steps and the data warnings (new Forever quests without a
finisher spawn, objectives without a position, missing flight masters).

## Guide format

One `Q:RegisterGuide({ ... })` call per file. Chapter fields: `id`, `title`, `faction`, `races`,
`minLevel`, `maxLevel`, `next`, `nextByRace`, `choices`, `sim` (see below), `steps`. One step per line:

| Steps | Form |
|---|---|
| `accept`, `complete`, `turnin` | `{ "accept", questId }` |
| `goto`, `fp`, `sethearth`, `boat` | `{ "goto", uiMapId, x, y }` (x, y in 0-100) |
| `hearth`, `fly` | `{ "hearth", uiMapId }`, `{ "fly", uiMapId, node = TaxiNodes.ID }` |
| `level` | `{ "level", n }` |
| `note` | `{ "note", "text" }` |

Optional step fields: `obj` (objective index), `note`, `at = { uiMapId, x, y }`, `xp`, `node`,
`optional`, `dungeon`, `race = { raceKey, ... }`, `class = { classFile, ... }`,
`classes = { classFile, ... }`. `Questify/Engine/Guides.lua` (`Guides:Normalize`) is the reference: a
guide with an invalid step is refused in game with one `Invalid guide <id>: step <n>: ...` line.

### Class steps (`classes`)

```lua
    { "accept", 1599, classes = { "WARLOCK" } }, -- Beginnings
    { "complete", 1599, at = { 1426, 28.6, 66.1 }, classes = { "WARLOCK" } },
    { "turnin", 1599, xp = 355, classes = { "WARLOCK" } },
```

- `classes` lists game `classFile` names: `WARRIOR`, `PALADIN`, `HUNTER`, `ROGUE`, `PRIEST`, `SHAMAN`,
  `MAGE`, `WARLOCK`, `DRUID` (upper case). Absent: every class. The list must not be empty; an unknown
  name refuses the guide in game (`step 3: accept: unknown class 'WARLOK' in classes`) and fails
  `validate_guides.lua`.
- For a character of another class the step does not exist: not listed, never current, not counted
  in the tracker progress or the chapter end, not in the journal, not counted on the route choice
  cards, not a route quest for the automatic accept and turn-in. Step keys keep the index in the file
  (`g:<guideId>:<index>`): saved step states, telemetry and its export name the same step for every
  class.
- `class` is different: the step stays listed and is skipped (reason "class") for the other classes.
  It is meant for general quests restricted to some classes ("all but Warlock"). Use `classes` for
  the class quests woven into the route.
- Weave a whole chain: `accept`, `complete` and `turnin` steps of every quest, all with the same
  `classes`. In a chapter shared by several races, add `race` when the quest is not open to all of
  them.
- A chain of `ClassQuestData.lua` whose remaining quests (not turned in yet) all have a `turnin` step
  for the character, in the current chapter (not skipped or ticked by the player) or in a following
  chapter of the route (successor chosen by the player, else the default one), is "In the route": no
  alert, no "Add to route" button, and an older manual add (`cq:` inserted steps) is removed. Only
  `turnin` steps count: a chain whose turn-in lies outside the route is still offered.
- `validate_guides.lua` checks the field (same rule as in game) and, on quest steps, that each class
  is allowed by the quest's class mask (`quest 1598 not available to class MAGE`). Each race path is
  replayed once without the class steps, then once per class named on the path with its own steps
  (the 20-quest log is counted per class); an issue seen only with the steps of some classes ends
  with `(race path: Gnome, class: WARLOCK)`.

## Review checklist (Tasks 14-16)

1. Run `build.lua` for the faction, then `validate_guides.lua` (must exit 0).
2. Read each report: dropped quests that should stay (`force`), objective sites in the wrong place
   (`pin`), missing transport steps (`plans.lua` `arrive`, or `insertAfter`).
3. Check flight paths (`flightPaths`) and the level band (`maxLevel`, `levelSlack`): a chapter that
   overshoots its band makes the next chapter drop quests as "level band reached".
4. Regenerate and run `luajit tests/run.lua` (the boot test loads every guide).
5. For a plan with `choices`, run `travel.lua <planId>` and update `travel.minutes` if it changed.

## Changes from Stream E (Tasks 14-16)

### Determinism and CLI

- The build runs in the LuaJIT interpreter by default (`jit.off()`), and `--jit` speeds it up.
  Travel costs in `order.lua` are integer centiseconds, so both modes give byte-identical output.
- `--only <planId>` on a race-specific chapter simulates only that race's path up to that chapter.

### Travel (`transport.lua`, `sim.route`)

- Walk regions: Eastern Kingdoms north and south of the mountains, Kalimdor, top of Teldrassil,
  Rut'theran. Inside a region, walking is a straight line.
- Between regions, the router uses Dijkstra over walking, known flights, links and the hearthstone.
- Links:
  - Deeprun Tram;
  - Stormwind Harbor <-> Auberdine;
  - the one-way loop Auberdine -> Menethil -> Southshore -> Auberdine;
  - Rut'theran boat and the Darnassus portals;
  - zeppelins Orgrimmar <-> Undercity;
  - Skyborne skyboats and the Dalaran portal.
- Steps written: `boat` at the dock (or `goto` for a portal), `goto` FM + `fly`, `hearth`.
- Unknown flight paths are picked up on a walk when the detour is 300 yd or less.

### Ordering (`order.lua`)

- Nearest feasible neighbour, then or-opt with segments up to 6 tasks.
- Then simulated annealing with a fixed seed (moves with no gain are refused), then or-opt again.
- Then a pass moves accepts and flight paths forward to the first visit of the same place.
- `order.build` returns `seq, issues`. In a deadlock, a final task is moved forward before the
  quest log cap is ever exceeded.

### Chapter selection (`sim.chapter`)

- Band widening: if the band's quests would need more than 25 mobs of grinding, the chapter is
  re-run with quests up to `maxLevel + 6`.
- Level-gated leaf quests: an accept blocked by level that would need more than 15 mobs of grinding
  is skipped, if it opens no other quest. The chapter is then re-run without it.
- XP budget: prerequisites are kept down to depth 200. The budget is raised while kept quests lose
  their prerequisites.
- Carried turn-ins: a quest whose finisher is in one of the next two chapters of the path is
  accepted and done now, and turned in there.
- Grind spots skip unique named mobs (quest targets) and NPCs with a subname. A final `level` step
  of 3 mobs or fewer is not written.
- Exclusions before analysis are listed in the report with a reason: class quest, blacklist,
  seasonal or event, level out of band, dungeon not in the plan.

### Shared trunk (`build.simulateFaction`, `paths.lua`)

- Race-specific chapters are simulated on their lead race.
- The trunk is simulated once, from a merged state at each chapter where paths join: lowest level,
  common flight paths, common hearth, log padding for the most loaded path. A quest of another path's
  log that the lead path does not have is turned in by the trunk for it (`"foreign"`, see "Lot L").
- A path that joins from another region is brought to the join point at the end of its own last
  chapter (`exitTo`).
- Every race path is then replayed (`paths.replay`). A step that is invalid for a race gets a
  `race` filter. `tools/validate_guides.lua` replays the same paths and fails on any invalid
  applying step.

### New plan fields

| Field | Meaning |
|---|---|
| `levelBelow` | Lowest quest level accepted: `minLevel - levelBelow` (default 3). |
| `far` | Distance in yards beyond which a quest is dropped as `far` (default 900). |
| `dungeonReqSlack` | Dungeon quests accepted up to required level `maxLevel + n`. |
| `dungeonLevelHigh` | Dungeon quests accepted up to quest level `maxLevel + n`. |
| `strictLevel` | Ordering counts the grinding before a level-gated task (see below). |
| `arrive.via` | Point reached by computed travel before the fixed `arrive` steps. |
| `precede` | Pairs `{ first, second }` of task ids (`A`, `T`, `C` + quest id, `O` + quest id = all its objective sites): extra precedence. |
| `safeLevel` | `{ [questId] = level }`: level from which the objectives of that quest are done (replaces the computed safe level). |
| `widen` | `false`: the band is never widened (chapters 30-60, whose zones are visited again later). |

### Reports

The itinerary lists every task with its walking leg in yards and "returns" (back within 150 yd of
an earlier task after going more than 600 yd away), plus the total walking time.

### ClassQuestData

- Chains follow prerequisites, next quest and breadcrumbs.
- Where the Forever data has no links:
  - a handoff (the next id, up to +3, starts at the previous quest's finisher) links the quests;
  - quests with the same title and the same race mask form one chain, ordered by level.

## Changes from the player review (2026-11-04)

### Level-gated tasks in the ordering (`strictLevel`)

When the nearest-neighbour pass reaches a dead end (every remaining task needs a higher level), the
blocked task with the lowest level is marked `needLevel`: the ordering assumes the character grinds
to its level there. Before this change, or-opt and annealing could then move that task anywhere for
free, for example from level 15 back to level 13, because only the walking time counted. The walk
then found more than `SAFE_GATE_GRIND` mobs to farm and did the objective 2 to 4 levels too low.

With `strictLevel = true` on a plan, `sim.lua` passes `grindCost(level, xp, target)` to
`order.build` (mobs of the character's level, `KILL_TIME` each, as `sim.grindTo`). The cost of a
sequence is then walking time plus the grinding of its `needLevel` tasks, so a gated task is only
moved earlier when the walk saved is worth the extra grinding. Moves of a segment that holds a
`needLevel` task are tried even when they lengthen the walk (they can save grinding). Without
`strictLevel`, the ordering is unchanged.

It is on for `A_DwarfGnome_03`, `A_NightElf_02`, `A_NightElf_03` and `H_05`. On the Dwarf path it removes most objectives done 3 to 4
levels too low in Loch Modan for a few minutes of grinding. On every chapter, it would add about 1 h
of simulated time over the Dwarf path (more walking in the trunk), and on `A_DwarfGnome_02` it adds
15 min for no safety gain. On `H_05` (QuestieDB v1.0.11) it saves 12 min. Without it, the band is
widened and the chapter ends with 44 mobs of grinding. An objective area of 567 "Dangerous!" is also
split for no reason (a `free` quality item).
On `A_NightElf_02` and `A_NightElf_03` (QuestieDB v1.0.11, 2026-11-06) it saves 23 min on the Night Elf
path: Escaping Ban'ethil (99053) went from level 9 to 10, and the ordering then did objectives before their
safe level, with 105 mobs of grinding in Teldrassil and up to 159 for a chain head in Darkshore. On every
chapter at once it was measured again on v1.0.11: +37 to +99 min per race path (rejected).

### Hub sweep, one pass per area, turn-in in passing (`order.lua` step 5)

After the optimisation passes, the ordering walks the sequence; at each task it pulls in, right after
it, every later task done at the same place, when the sequence stays feasible (precedence, log cap,
levels, and no extra grinding with `strictLevel`):

- accepts and flight paths within `SWEEP_HUB` (40 yd): everything a hub gives, including quests
  unlocked by a turn-in made there;
- turn-ins within `SWEEP_TURNIN` (60 yd): a finished quest is turned in when the route passes by;
- objectives and item-started accepts within `SWEEP_AREA` (120 yd) of an objective: one pass per area.

Inside an objective area, tasks are then ordered objects first, named or elite mobs next, regular mobs
last (`t.cat` 1, 2, 3), keeping precedence. `ROUTEBUILDER_NO_SWEEP=1` turns the sweep off (comparison).

### Locked chests (`sim.keyFor`)

QuestieDB has no lock data. A start item looted from an object named `<Name>'s Chest` (Box, Strongbox,
Footlocker, Coffer, Lockbox, Trunk, Cache, Crate, Safe) whose key `<Name>'s Key` drops from NPCs is
treated as locked: the accept waits for the objective of another quest that kills the key holder, and
its note says so. Example: 830 "The Admiral's Orders" (Benedict's Chest) after Lieutenant Benedict
(784 "Vanquish the Betrayers"), in `H_OrcTroll_02`.

### Quality checker (`quality.lua`)

Run on the walked itinerary of each chapter (simulated race). For each task, it looks for an earlier
pass within the same radius as the sweep, with the route gone more than 150 yd away in between
(220 yd for an objective area), where the task was already possible (precedence done, level reached,
log not full for an accept). It reports missed pickups, missed passing turn-ins, split areas, and
avoidable revisits (a return made only of such accepts and turn-ins). Each item carries the reason the
ordering kept it: `log cap`, `level` or `chain` (moving it breaks a constraint later in the route), or
`free` (a defect). Reports get a "Qualité" section; the build prints the counts.

### Flight node on `fly` steps

Every `fly` step has `node = <TaxiNodes.ID>` (the `nodeID` of `C_TaxiMap`) of the destination flight
master, written before `note`. Hand-written `fly` steps of a plan's `arrive` get the node whose
name matches their `note`. `tools/validate_guides.lua` fails on a `fly` step without `node`, with an
unknown node, or with a node that is not on the step's destination map.

## Hearthstone (2026-11-06)

### Use (`sim.route`)

During the walk, the router (Dijkstra) takes the hearthstone when it is bound, its 3600 s cooldown is
over, and `HEARTH_CAST + HEARTH_PENALTY` (10 + 120 s) plus the walk from the inn beats walking (or
flying) to the next task. The penalty keeps the stone for a return worth it: with straight-line
walking, a return of about 910 yd or more. `HEARTH_FAR` (declared, never read) is gone.

### Cost model (`order.hearthCost`)

Real travel cost of an ordered sequence, in centiseconds: walks, returns by the stone with the same rule
and its cooldown (the duration of the tasks counts for the cooldown), and bind detours. It also returns
the final state (position, bound inn, ready time).

### Binds (`sim.planHearth`)

After the ordering, candidate inns are the faction innkeepers within `HEARTH_INN` (200 yd) of a hub of
the chapter (one per place, not the inn already bound). A bind goes after the task of the first pass at
the inn that is nearest to the innkeeper (until the route goes more than `SETHEARTH_LEAVE`, 800 yd,
away). The plans compared are: no bind, one bind, or two (`HEARTH_BINDS`: the second at the first pass
at another inn after the first, when the hub of the chapter changes). Each plan costs
`order.hearthCost` plus the computed travel (`sim.route`) from the end of the chapter to the start of the
next one (`opts.nextEntry`, from `build.lua`), with the stone bound and ready or not: a bind also serves
the start of the next chapter. The cheapest plan wins (ties: fewer binds).

### Return bundles (`order.hearthBundles`)

Then, for each end of task, the later tasks within `HEARTH_BUNDLE` (250 yd) of the inn bound at that time
are pulled right after it (in order, precedence kept) when the sequence stays feasible (log cap, levels,
no extra grinding) and `order.hearthCost` drops: one return by the stone does them all. The bind plan is
then chosen again. `ROUTEBUILDER_NO_BUNDLE=1` turns this pass off (comparison).

The report summary has a "Hearthstone" line: binds (innkeeper, after which task), returns planned by the
model, bundles applied.

Measured on QuestieDB v1.0.11 (2026-11-06): 0 to -5 min per race path 1-30. The simulator gives little
room: walking is 30-45 % of a chapter, and the long legs (over 910 yd) that end at an inn when the stone is
ready are few (upper bound for all chapters together: about 106 min over 23 chapters if every long leg
ended at an inn). A lower penalty (90 s: the same decision as walking 1.3 times longer than the straight
line) was measured too and not kept: -1 min on the Horde paths, -13 min on the Alliance trunk paths but
only through a different trunk (Redridge then grinds 116 mobs), +12 min in Darkshore for the Night Elf.

## Successor choices and simulated metrics (`choices`, `sim`)

### Guide fields

`emit.lua` writes two fields in `Q:RegisterGuide`, after `next` / `nextByRace` and before `steps`:

```lua
  choices = {
    { id = "A_DwarfGnome_04", travel = { kind = "walk", minutes = 2 } },
    { id = "A_01", travel = { kind = "boat", minutes = 7 } },
  },
  sim = { steps = 78, endLevel = 15.55, xpPerHour = 21188, minutes = 119 },
```

- `choices` is copied from the plan, one entry per line, fields in the order `id`, `races`, `label`,
  `travel = { kind, minutes }`, `weight` (absent fields are omitted). The game offers the entries, in
  this order, at the end of the chapter. `kind` is one of `walk`, `fly`, `boat`, `zeppelin`, `tram`,
  `portal`, `hearth`.
- `sim` is written for every simulated chapter. It has the same four values as the header comment
  `-- Simulation : N étapes, niveau final X, ~Y xp/h, Z min.` (`endLevel` with 2 decimals, the
  others rounded to integers), so the game can show them.

### Default path only

`next` / `nextByRace` stay the default successor: `plans.pathFor`, the simulation (state carried from
chapter to chapter, merged trunk state, carried turn-ins, race filters) and the race-path replay of
`tools/validate_guides.lua` follow it only. **The other choices are neither simulated nor replayed
from the branch point**: each target chapter was simulated from its own default predecessors. A player
who takes an alternative may arrive at a lower level than the target was tuned for, or with other
flight paths (for example `A_DwarfGnome_03` -> `A_01` arrives at about 15.5 for a chapter of band
16-19), and a quest carried across the branch would be lost (none crosses the current branch point).

### Validation (`plans.validate`)

`build.lua` runs `plans.validate` before loading QuestieDB and stops (exit code 1, one
`plans.lua: <planId>: <message>` line per error) when:

- `next` or `nextByRace` points to an unknown chapter;
- `choices` is not a list, or has fewer than 2 or more than 4 entries;
- an entry has no `id`, an unknown `id`, the chapter's own `id`, an `id` already listed, or an `id`
  of the other faction;
- the default successor (`next`, or `nextByRace[race]` for each race of the chapter) is not an entry,
  or its entry has `races` without that race; or the plan has `choices` but no default successor;
- `travel.kind` is not one of the kinds above, `travel.minutes` is not a whole number of minutes,
  `races` names a race that does not play the chapter, `label` is not a string, `weight` is not a
  positive number.

`tools/validate_guides.lua` runs the same checks on the generated guides, and fails when a guide's
`sim` field differs from its `-- Simulation :` header.

### Travel time (`travel.lua`)

`travel.minutes` is written in `plans.lua` by hand from `luajit tools/routebuilder/travel.lua
<planId>`, which uses the generator's travel code (`sim.route`: walking inside a walk region, flights
between known flight paths, `transport.lua` links) without QuestieDB:

- start: `at` of the chapter's last guide step, else the last task of its report itinerary
  (`docs/routes/<planId>.md`);
- end: the first task of the target's report itinerary, else the target's `entry`;
- known flight paths: `fp` steps of the guides on the simulated race's path up to the chapter;
- the hearthstone is ignored (its cooldown is not known outside the simulation).

The command prints the legs, the main kind (first leg that is not a walk) and the minutes (seconds / 60,
rounded), and exits 1 when `plans.lua` has other values; `test_choices.lua` runs the same check on the
shipped guides, so regenerate, run `travel.lua` and update `plans.lua` together. The target's own
`sim.minutes` already counts its arrival from its default predecessor (`A_01` starts with the boat), so
the two values overlap and should not be added.

### Backfill (`backfill.lua`)

`build.lua` writes both fields, but a full regeneration needs QuestieDB and rewrites every guide.
`backfill.lua` adds them to the guides already generated: for each guide listed in `Guides.xml` with a
`-- Simulation :` header, it removes any `choices` block and `sim` line from the `Q:RegisterGuide`
header, then writes `emit.choicesLines(plan)` and `emit.simLine` (values read from the header comment)
right before `steps = {`, exactly where `emit.guide` puts them. A second run changes nothing, a choice
removed from `plans.lua` disappears, line endings (CRLF or LF) are kept, and a header that `emit.lua`
would not write is left alone. `--check` writes nothing and exits 1 when a guide is out of date. Run it
after changing `choices` in `plans.lua` when the guides are not regenerated.

## Routes 30-60 (2026-11-06, lot H)

### Chapters

The trunk goes on after `A_05` and `H_05` up to level 60, from the "meta paths 1-60" plan, rebuilt and
measured here (see `docs/routes/README.md` for the per-chapter table):

- Alliance: `A_05 -> A_08 -> A_07 -> A_09 -> A_10 -> A_11 -> A_12 -> A_13 -> A_15 -> A_16 -> A_17 -> A_18 ->
  A_19 -> A_20 -> A_21 -> A_22 -> A_28 -> A_24 -> A_26 -> A_27 -> A_23 -> A_29 -> A_30`. `A_06` (Hillsbrad
  leftovers), `A_14` (The Hinterlands) and `A_25` (Feralas and Azshara) are written in `plans.lua` but on no
  path: they are neither simulated nor generated.
- Horde: `H_05 -> H_06 -> ... -> H_18 -> H_21 -> H_23 -> ... -> H_30` (`H_19` and `H_22` removed; `H_20`,
  Tanaris 47-49, is written but on no path: Tanaris I, `H_16`, may widen its band and takes its quests).
- Each chapter stays on one continent. Bands are contiguous (the minimum of a chapter is the maximum of the
  previous one), `levelSlack = 0`, `levelBelow = 8` (leftover quests of a zone visited earlier), `far = 1600`
  and `widen = false` except `H_16` (a zone visited again later keeps its higher quests for that visit).
- Titles are zone names only (`Guides:TitleParts` translates the names listed in `ZONE_MAPS` of
  `Questify/Engine/Guides.lua`).

### Dungeon quests taken in passing

Dungeon quests accepted in passing (`dungeons`, `optional` steps, log value `"dungeon"`) used to stay in the
simulated log for good: at level 30, 10 of the 20 slots of the Alliance path were taken. From a chapter whose
`minLevel` is at least `DUNGEON_RELEASE_FROM` (30), each such quest whose level is at most
`minLevel - DUNGEON_RELEASE_GAP` (4) leaves the log at the start of the chapter (`sim.releaseDungeonQuests`),
with one optional `note` step per dungeon ("Not running X? Abandon ..."). The log padding of the other race
paths (`logPad`) is recomputed at the same time with the same rule (lot L: `logPadQuests`, see below). `paths.replay` (build and `tools/validate_guides.lua`)
applies the same rule to quests accepted through an `optional` step with a `dungeon` name in a dungeon area
of QuestieDB (`chapters[i].minLevel` is passed for that). Chapters below level 30 are unchanged.

### Other rules

- A quest that requires level 60 is never a candidate (no quest XP at the level cap; the walk would grind to
  60 first).
- `keep()` of the XP budget counts a prerequisite taken in passing for a dungeon (no value) as 0.

### Transport (`transport.lua`)

- Zeppelins Orgrimmar <-> Grom'gol and Undercity <-> Grom'gol (zeppelin masters of QuestieDB: 12136,
  3149, 3150, 12137), boat Booty Bay <-> Ratchet (Shipmasters 9559 and 9558). Waiting and crossing time:
  420 s, an estimate like the other links. To check in game.
- Walk regions: Blasted Lands (1419) and Searing Gorge (1427, linked to the Burning Steppes through
  Blackrock Mountain) are in the south of the Eastern Kingdoms.

### Dungeons (`build_dungeons.lua`)

Uldaman 36-47, Razorfen Downs 37-46, Maraudon 42-52, Zul'Farrak 44-54, The Temple of Atal'Hakkar 50-60,
Blackrock Depths 52-60, Dire Maul 55-60 (one key `DIREMAUL`, area 2557: east, west and north have the same
QuestieDB name), Scholomance 55-60, Stratholme 58-60. Entrances from QuestieDB. Raids and Blackrock Spire
(one area for the lower and the upper spire) stay out.

## Simulator corrections (2026-11-07, lot L)

Recommended by the two 1-60 optimisation lots. Each change was measured on the totals of the eight race paths
(QuestieDB v1.0.11, `--jit`); the numbers are in `docs/routes/README.md` ("Optimisation 1-60").

### Dungeon quests picked up in passing are not prerequisites (`sim.lua`)

A dungeon quest the route only picks up (`dungeonOnly`: `optional` step with a `dungeon` name, objectives in
the instance) is never turned in on the route. It no longer counts as an available prerequisite: its
follow-up outside the dungeon is dropped as "prerequisite unavailable" (before, the simulation counted it and
the race-path replay removed its steps, "valid for no race"). The same holds in the XP budget (a log entry
`"dungeon"` is not an acquired prerequisite). The manual drops of `plans.lua` that worked around it (722 and
727 in `A_16`, 5213 and 5861 in `A_29`, 5342 in `H_29`) are gone: identical guides.

### Event quests (`specialFlags` 2) (`sim.lua`)

Event quests without an exploration point used to be excluded ("event"); several had to be forced by hand
(Kalaran's stories 3441 / 3453, the Un'Goro pylons 4285 / 4287 / 4288 / 4321, Redemption 5742). They are now
ordinary candidates when QuestieDB places each of their objectives in the region (otherwise they are dropped
with the reason of that objective):

- a story whose objective is the giver itself, or a friendly NPC at the same place ("Listen as Kalaran
  Windblade tells his story": kill objective on a friendly NPC), is a 10 s "talk" objective, as before;
- a story without any objective that is turned in to its giver (within 150 yd: "Speak with J.D. Collie in a
  moment") gets a 10 s "talk" site at the giver (`complete` step at the giver's QuestieDB position);
- escorts stay out (`sim.isEscort`: objective text with "escort", "protect", "defend", "safely",
  "accompany", "keep ... safe", "show ... the way" or a sentence starting with "Lead"): no arrival point nor
  duration is known. Escorts with an exploration point (`triggerEnd`) stay candidates as before;
- dungeon event quests stay out (no objective site is computed inside an instance).

New quests in the routes: Gerenzo's Orders 1090 (A_02, H_02), Sathrah's Sacrifice 2520 and Druid of the Claw
2561 (A_NightElf_02), Hidden Enemies 5727 (H_OrcTroll_02), the Un'Goro pylons (H_27), Redemption 5742 and its
chain (H_29), Cache of Mau'ari 975 (A_27, H_28). The forcings of 3441 / 3453 (`A_22`, `H_24`), 4285 / 4287 /
4288 / 4321 (`A_26`) and 5742 (`A_29`) are gone (identical guides).

### Quests carried across a join of race paths (`build.mergeStates`, `"foreign"`)

The trunk is simulated once, on the lead path (Dwarf, Orc). A quest of another path's log that the lead path
does not have was never turned in by the trunk: the Undead path accepts Sample for Helbrim (1358) in Undercity
(`H_Undead_03`, turn-in carried to The Barrens) and kept it in its log up to level 60; with the log padding
reset at level 30, its log was full in `H_17` (Stinglasher 7731 and Zukk'ash Report 7732 were filtered out of
the Undead path). Now, at the join:

- such a quest enters the trunk log with the value `"foreign"`: the trunk turns it in (`H_01`, step filtered to
  `race = { "Undead" }` by the replay), with no XP for the simulated race, not marked done for it, and it opens
  no follow-up in the trunk;
- a dungeon quest of the other path keeps a slot (`logPad`) only when that path has more of them than the lead
  path has quests that it lacks; `logPadQuests` keeps both lists per path, and `sim.releaseDungeonQuests`
  recomputes the padding with the abandon rule (level <= chapter minimum - 4, from level 30) instead of
  resetting it to 0.

### Forever book quests (`xp.BOOK_FACTOR`)

The book quests of Forever (79953, 81947-81956, 84395-84402: "Collect 'Stonewrought Design' and bring it to
Owen Thadd in Undercity", librarians of Stormwind and Undercity) have no QuestXP value; the median estimate of
their level counted up to ~46 000 XP in `H_29` (seven level-60 books at 6 600). `xp.isBook` (required level 1 at
most, a single item objective, a start object named "Book" in QuestieDB) now gives them a quarter of that
estimate (975 XP at level 45, 1 650 at level 60): the Classic tier of a plain delivery (known level-45
deliveries: first quartile 970 for a standard value of 3 900). It is an estimate: to check in game.

### Forcings measured again

After these changes, the forcings of `plans.lua` were measured again one by one (all eight paths):
3161 / 3362 / 2605 in `A_20` (Alliance -16 min, -3 quests, +28 mobs), 3161 / 2605 in `H_16` (Horde -10 min,
-1 quest, +43 mobs), 7843 in `H_21` (Horde -4 min, -1 quest, +22 mobs), 4023 / 4296 / 4726 in `H_24` and
1145 / 1362 in `H_07` (identical) are removed. Kept: 3062 in `H_17` (+10 min without), the Tarren Mill hooks of
`H_06` (+53 min without).

### Studied, not kept

- `strictLevel` on every 30-60 chapter: +82 min on the Alliance paths, +88 on the Horde paths (-115 and -65
  mobs).
- Trunk simulated from another lead path: Human for the Alliance gives the same routes and totals (only the
  `A_08` notes that abandon the Dwarf / Gnome dungeon quests disappear); Undead for the Horde costs +11 to +34 min
  per Horde path (Orc +29). The trunk guides are shared by every race path, so a per-race simulation could only
  change the measure, not the routes. `grindCost` (mobs of the character's
  level, 20 s each, as `sim.grindTo`) is unchanged.

## Known limits

- Walking is a straight line in world coordinates (no pathing around mountains, no city
  interiors). Cross-zone transitions should get `arrive` steps (tram, boats, zeppelins).
- `TaxiPath` has no waypoints: flight length is the straight line × 1.2.
- Objective counts come from the English objective text; without a number the defaults above apply.
- XP of the new Forever quests is an estimate (median of known Classic quests of the same level and
  type, × 0.5 for dungeon quests, × 0.25 for the Forever book quests).
- Trunk chapters are simulated for the primary race path only.
- Only the default successor is simulated and validated; other `choices` are not replayed.
