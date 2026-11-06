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
| `classquests.lua` | Class quest chains (level ≤ 30) for `ClassQuestData.lua`. |
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
   (`specialFlags` 1), event quests (`specialFlags` 2 without an exploration point), blacklisted
   quests, quests already done. Dungeon quests are only accepted in passing (`optional`,
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
   prerequisite was dropped. **XP budget**: quests are ranked by marginal ratio (forced first) and
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
   `sethearth` at the inn (≤ 200 yd) of the busiest hub when the route returns there after
   leaving it by more than 800 yd; `hearth` when the next task is within 120 yd of the
   hearthstone, more than 1200 yd away and the 3600 s cooldown is over; `fly` when the flight
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
  common flight paths, common hearth, log padding for the most loaded path.
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

It is on for `A_DwarfGnome_03` and `H_05`. On the Dwarf path it removes most objectives done 3 to 4
levels too low in Loch Modan for a few minutes of grinding. On every chapter, it would add about 1 h
of simulated time over the Dwarf path (more walking in the trunk), and on `A_DwarfGnome_02` it adds
15 min for no safety gain. On `H_05` (QuestieDB v1.0.11) it saves 12 min. Without it, the band is
widened and the chapter ends with 44 mobs of grinding. An objective area of 567 "Dangerous!" is also
split for no reason (a `free` quality item).

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

## Known limits

- Walking is a straight line in world coordinates (no pathing around mountains, no city
  interiors). Cross-zone transitions should get `arrive` steps (tram, boats, zeppelins).
- `TaxiPath` has no waypoints: flight length is the straight line × 1.2.
- Objective counts come from the English objective text; without a number the defaults above apply.
- XP of the new Forever quests is an estimate (median of known Classic quests of the same level and
  type, × 0.5 for dungeon quests).
- Trunk chapters are simulated for the primary race path only.
- Only the default successor is simulated and validated; other `choices` are not replayed.
