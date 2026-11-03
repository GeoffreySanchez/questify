# Questify Vanilla route builder

Offline LuaJIT tool that reads World of Warcraft: Forever quest data from a local QuestieDB clone
plus the Forever DB2 tables in `data/`, simulates a character chapter by chapter, and writes the
guide files of `Questify_Vanilla/Guides/` with one Markdown report per chapter.

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

# Tests of the generator
luajit tools/routebuilder/tests/run.lua [pattern]
```

| Flag | Default | Meaning |
|---|---|---|
| `--db` | `~/dev/questify/.cache/questiedb` | QuestieDB root (data files are read as text, run in a sandbox) |
| `--questie` | `~/dev/questify/.cache/questie` | Questie root, for the quest blacklist |
| `--faction` | `all` | `Alliance`, `Horde` or `all` |
| `--only` | none | Write only this chapter. Earlier chapters of its race path are still simulated, so the character state (level, done quests, known flight paths) is right. |
| `--out` | `Questify_Vanilla/Guides` | Guide output root: `<out>/<Alliance\|Horde\|Skyborne>/<planId>.lua`, `<out>/ClassQuestData.lua`, `<out>/Guides.xml` |
| `--report` | `docs/routes` | Markdown reports, `<report>/<planId>.md` |
| `--overrides` | `tools/routebuilder/overrides.lua` | Hand fixes (see below) |
| `--date` | today | Date written in the file headers (set it for reproducible output) |

`build.lua` prints one line per chapter, for example:

```
A_DwarfGnome_01    steps  40  quests  15  dropped   1  lvl  1.00 ->  6.01  xp/h  12569  36 min
```

A chapter whose simulated end level is below `maxLevel - 1` is flagged `[below maxLevel-1]`.

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
| `order.lua` | Task ordering: nearest feasible neighbour, then or-opt, with precedence, log cap and final tasks. |
| `plans.lua` | Chapter plans per faction (spec § 6). |
| `emit.lua` | Guide file writer (spec § 5.2 format, one step per line with a comment). |
| `classquests.lua` | Class quest chains (level ≤ 30) for `ClassQuestData.lua`. |
| `overrides.lua` | Hand fixes applied at build time. |
| `build.lua` | CLI. |
| `data/*.csv` | Forever DB2 tables, build 1.60.1.70707 (wago.tools): `UiMapAssignment`, `UiMap`, `TaxiNodes`, `TaxiPath`, `AreaTable`, `Map`. |
| `tests/` | `run.lua` runner, `test_world.lua`, `test_xp.lua`, `test_sim.lua` (on the synthetic `fixture_zone.lua`), `test_emit.lua`. |

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
  flightPaths = { "Ironforge, Dun Morogh" }, -- TaxiNodes names to pick up in this chapter (planned detour)
  dungeons = { "The Hall of Thanes" },   -- dungeon quests (QuestieDB dungeon names) accepted in passing, optional
  optional = { [96391] = "Hall of Thanes" }, -- forced quests marked optional + dungeon label
  force = { [id] = true }, drop = { [id] = "reason" },
  levelSlack = 1,                        -- levels of overshoot allowed above maxLevel (XP budget)
  logCap = 20,
  arrive = { steps = { { "boat", 1437, 4.6, 57.1, note = "..." } }, time = 300 },
                                         -- steps inserted when the character comes from another
                                         -- continent or more than 1500 yd away
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

## Review checklist (Tasks 14-16)

1. Run `build.lua` for the faction, then `validate_guides.lua` (must exit 0).
2. Read each report: dropped quests that should stay (`force`), objective sites in the wrong place
   (`pin`), missing transport steps (`plans.lua` `arrive`, or `insertAfter`).
3. Check flight paths (`flightPaths`) and the level band (`maxLevel`, `levelSlack`): a chapter that
   overshoots its band makes the next chapter drop quests as "level band reached".
4. Regenerate and run `luajit tests/run.lua` (the boot test loads every guide).

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

### Reports

The itinerary lists every task with its walking leg in yards and "returns" (back within 150 yd of
an earlier task after going more than 600 yd away), plus the total walking time.

### ClassQuestData

- Chains follow prerequisites, next quest and breadcrumbs.
- Where the Forever data has no links:
  - a handoff (the next id, up to +3, starts at the previous quest's finisher) links the quests;
  - quests with the same title and the same race mask form one chain, ordered by level.

## Known limits

- Walking is a straight line in world coordinates (no pathing around mountains, no city
  interiors). Cross-zone transitions should get `arrive` steps (tram, boats, zeppelins).
- `TaxiPath` has no waypoints: flight length is the straight line × 1.2.
- Objective counts come from the English objective text; without a number the defaults above apply.
- XP of the new Forever quests is an estimate (median of known Classic quests of the same level and
  type, × 0.5 for dungeon quests).
- Trunk chapters are simulated for the primary race path only.
