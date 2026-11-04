# Questify Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship by 2026-11-04 evening a free WoW Forever leveling-guide addon (`Questify`) with generated, optimized 1-30 routes for every race (Alliance first, then Horde, then Skyborne).

**Architecture:** The in-game addon reads quest/NPC/object data at runtime from the QuestieDB addon, a declared dependency. It ships only route step lists that our offline LuaJIT generator writes from a local QuestieDB clone and the Forever DB2 tables. Modules share one namespace table `Q` and talk through `Q:On`/`Q:Fire` messages. Every WoW API call is guarded, so a missing API never breaks the UI.

**Tech Stack:**
- Lua 5.1 (WoW client and LuaJIT 2.1 at `/opt/homebrew/bin/luajit`, used for tests and tools);
- WoW Forever API (Mainline 12.1.5 family, Interface 16001);
- QuestieDB public API contract 4;
- no third-party Lua libraries.

**Spec:** `docs/superpowers/specs/2026-11-03-questify-design.md`. Read it first; this plan does not repeat its rationale.

## Global Constraints

### Project and addon layout
- Project root: `/Users/geoffrey/dev/questify`. Never read from or write to `/Users/geoffrey/dev/quick_path`.
- Addon folder: `Questify/`.
- TOC files: `Questify.toc` and `Questify_Camelot.toc`, with identical content.
- TOC header:
  - `## Interface: 16001`
  - `## Dependencies: QuestieDB`
  - `## OptionalDeps: QuestieDB, TomTom, WaypointUI, ShortestPathForever`
  - `## SavedVariables: QuestifyDB`
  - `## SavedVariablesPerCharacter: QuestifyCharDB`
  - `## AddonCompartmentFunc: Questify_OnAddonCompartmentClick`
  - `## X-License: GPL-3.0-or-later`
- Every addon file starts with `local addonName, Q = ...`. The only global is `Questify = Q`, set in `Core/Init.lua`.
- Slash commands: `/questify` and `/qf`.

### Lua and WoW API rules
- Lua 5.1 only: no `goto`, no `//`, no bitwise operators.
- Race masks exceed 32 bits. Test bits with `Q.Util.HasBit(mask, bit)`, which computes `math.floor(mask / bit) % 2 == 1`. Never use `bit.band` on them.
- Absent APIs: `GetQuestsCompleted`, `GetQuestLogTitle`, global `GetItemInfo`.
- Use instead: `C_QuestLog.*`, `C_Item.GetItemInfo`, `C_Item.GetItemStats`.
- Protected functions: never call `SetRaidTarget` or `TargetUnit`.
  - Targeting goes only through `SecureActionButtonTemplate` with `type="macro"` and `macrotext="/cleartarget\n/targetexact <name>\n/tm !8"`.
  - Change attributes only when `not InCombatLockdown()`.
- Secret values: every `UnitGUID` / `UnitName` / `UnitCreatureID` result goes through `Q.Util.IsSecret(v)`, and secret values are ignored.
- Event handlers and timers must not break the UI:
  - wrap them in `Q.SafeCall`;
  - print each distinct error once with prefix `Questify:`.
- Coordinates:
  - Guides, the QuestieDB facade and the `Q.Nav` interface all use 0-100 map percentages with uiMapIDs.
  - Providers convert to their own scale: TomTom and ShortestPath use 0-1, WaypointUI uses 0-100, `UiMapPoint` uses 0-1.

### Text, data and dependencies
- UI text comes from `Q.L` (`Locales/enUS.lua` defaults, `Locales/frFR.lua` overrides). Code comments are in French.
- No QuestieDB data is copied into the addon. Guides may contain only:
  - quest, NPC and object IDs;
  - coordinates the generator chose (`at = {...}`, `goto`/`fp`/`sethearth`/`boat` points);
  - `xp` estimates.

  `Guides/ClassQuestData.lua` may contain only quest IDs, chain order, levels and reward item IDs.
- Commits: the user has not asked for commits. Do not run `git commit`. The "Checkpoint" steps below only run the tests.

## Review Focus

1. **QuestieDB missing, or contract below 4.**
   - Expected: one chat line explaining what to install, the tracker shows the same message, no Lua error.
   - Test: `test_boot.lua: boots_without_questiedb` in Task 1.
2. **A quest in the guide that QuestieDB does not know, or that has no starter or finisher spawn.**
   - Expected: the step is shown with the quest ID as its name and no waypoint. It never blocks: `StepState` returns `"active"` and the player can skip it.
   - Test: `test_progress.lua: unknown_quest_is_active_not_error` in Task 3.
3. **Combat.**
   - Expected: no secure-attribute change, a nav retry after `PLAYER_REGEN_ENABLED`, and secret unit values ignored.
   - Tests: `test_mobpanel.lua: no_attribute_change_in_combat` (Task 8), `test_nav.lua: shortestpath_retries_after_combat` (Task 5), `test_nameplates.lua: secret_guid_ignored` (Task 8).
4. **Character not at the chapter start.** Examples: a level-12 character with half the quests done, or a quest abandoned mid-route.
   - Expected: completed quests count as done, abandoned quests make their `complete`/`turnin` steps `"skipped"`, and the chapter auto-selection picks the right level band.
   - Tests: `test_progress.lua: abandoned_quest_skips_followups`, `test_guides.lua: picks_chapter_by_level` (Tasks 2-3).
5. **Shift held, or automation disabled.**
   - Expected: no automatic accept, turn-in or reward choice. With several reward choices and auto-reward off, the addon never calls `GetQuestReward`.
   - Test: `test_autoquest.lua: respects_shift_and_settings` (Task 6).

---

## Workstreams and order

| Stream | Tasks | Can start |
|---|---|---|
| A, Foundation | 1, 2, 3, 4 | now |
| B, Route builder | 10, 11, 12, 13 | now (needs only the step format from Task 2's Interfaces) |
| C, Navigation and automation | 5, 6, 7 | after Task 1 (harness), against the Interfaces of Tasks 2-4 |
| D, UI | 8, 9 | after Task 1, against the Interfaces of Tasks 2-4 and 7 |
| E, Content | 14, 15, 16 | after Tasks 13 and 3 |
| F, Release | 17 | last |

Inside a stream, run tasks in order. Streams that run in parallel must not edit the same files. The ownership in each task's **Files** block is exclusive. The TOC file list is owned by Task 1. A later task that adds a file appends one line to both TOC files and touches nothing else in them.

---

### Task 1: Scaffold, WoW mock, test runner, core

**Files:**
- Create:
  - `Questify/Questify.toc` and `Questify/Questify_Camelot.toc`;
  - `Questify/Locales/enUS.lua` and `Questify/Locales/frFR.lua`;
  - `Questify/Core/Init.lua`, `Core/Util.lua`, `Core/Settings.lua`;
  - `Questify/Data/Constants.lua`;
  - `Questify/Guides/Guides.xml` (empty `<Ui>` for now);
  - `tests/run.lua`, `tests/wow_mock.lua`, `tests/fixtures/qdb_fixture.lua`;
  - `tests/test_boot.lua`, `tests/test_util.lua`;
  - `tools/check_syntax.sh`;
  - `LICENSE` (GPL-3.0 text) and `README.md` (French and English: install, dependencies, commands).

**Interfaces:**
- Produces:
  - **Messages and events:**
    - `Q:On(msg, fn)` and `Q:Fire(msg, ...)` for internal messages. The messages are `"INIT"`, `"LOGIN"`, `"STEP_CHANGED"(entry)`, `"PROGRESS_UPDATED"`, `"GUIDE_CHANGED"(guide)`, `"SETTINGS_CHANGED"(path, value)`, `"CLASSQUESTS_CHANGED"`, `"COMBAT_ENDED"`.
    - `Q:RegisterEvent(event, fn)` and `Q:UnregisterEvent(event, fn)`: one hidden frame dispatches to several handlers. Each call is `fn(event, ...)` inside `Q.SafeCall`.
    - `Q.SafeCall(fn, ...) -> ok, ...`
  - **Logging and detection:**
    - `Q:Print(fmt, ...)` prints with the prefix `|cff33ccffQuestify|r:`.
    - `Q:Debug(...)` prints only when `QuestifyDB.debug`.
    - `Q.IsForever() -> boolean`, true when the interface is between 16000 and 16999.
  - **Saved state** (after `"INIT"`):
    - `Q.db = QuestifyDB`, holding `settings` and `debug`;
    - `Q.char = QuestifyCharDB`, holding `guideId`, `manual = {[stepKey]=true}`, `skipped = {[stepKey]=true}`, `inserted = { {tag=string, steps={...}} }`, `classQuests = {added={}, ignored={}, seen={}}`, `telemetry = {}` and `wizardDone`.
    - `"LOGIN"` fires on `PLAYER_LOGIN`, after `"INIT"`.
  - **`Q.Util`:**
    - `HasBit(mask, bitValue) -> boolean`;
    - `MaskAllows(mask, bitValue) -> boolean`, true when mask is nil or 0 or has the bit;
    - `IsSecret(v) -> boolean`;
    - `Round(v, n)`;
    - `FormatDistance(yards) -> string` (`"85 yd"`, `"1.2 km"` above 1000);
    - `CopyDefaults(dst, defaults)`.
  - **`Q.Settings`:**
    - `Get(path) -> any` and `Set(path, value)`, where `path` is dotted (`"nav.display"`);
    - `Set` fires `"SETTINGS_CHANGED"`.
    - Defaults: `{ autoQuest = true, autoReward = true, dungeonQuests = true, nav = { routing = false, display = "native" }, tracker = { locked = false, scale = 1, nextSteps = 3, showMobs = true }, nameplates = true, telemetry = true }`.
  - **`Data/Constants.lua`:**
    - `Q.RACE_BY_ID = { [1]={key="Human",bit=1}, [2]={key="Orc",bit=2}, [3]={key="Dwarf",bit=4}, [4]={key="NightElf",bit=8}, [5]={key="Undead",bit=16}, [6]={key="Tauren",bit=32}, [7]={key="Gnome",bit=64}, [8]={key="Troll",bit=128}, [95]={key="Skyborne",bit=4294967296}, [96]={key="Skyborne",bit=8589934592} }`;
    - `Q.CLASS_BITS = { WARRIOR=1, PALADIN=2, HUNTER=4, ROGUE=8, PRIEST=16, SHAMAN=64, MAGE=128, WARLOCK=256, DRUID=1024 }`.
  - `Q.L` is a locale table. A missing key returns the key itself (`__index`).
  - **`tests/wow_mock.lua`, a `Mock` table:**
    - `Mock.reset()`;
    - `Mock.loadAddon("Questify/Questify.toc", opts) -> Q`: parses the TOC and runs `Locales\*.lua`, `*.lua` and `Guides\Guides.xml` `<Script file>` entries in order, with varargs `("Questify", ns)`, then fires `ADDON_LOADED` and `PLAYER_LOGIN`. It takes two options:
      - `opts.extraFiles = {paths}`: files run after the TOC files and before `ADDON_LOADED`, with the same varargs;
      - `opts.beforeLogin = fn(Q)`: called just before `PLAYER_LOGIN`;
    - `Mock.fire(event, ...)` and `Mock.advance(seconds)`, which drives `C_Timer.After` and `C_Timer.NewTicker`;
    - `Mock.player = {raceId=3, classFile="WARRIOR", level=1, faction="Alliance", map=1426, x=29.9, y=71.2, combat=false, shift=false}`;
    - `Mock.quests = {log={[id]={complete=false, objectives={{text=, finished=}}}}, completed={[id]=true}}`;
    - `Mock.calls`, a list of `{name, args}` recorded for `AcceptQuest`, `CompleteQuest`, `GetQuestReward`, `C_GossipInfo.SelectAvailableQuest`, `C_GossipInfo.SelectActiveQuest`, `C_Map.SetUserWaypoint`, `TomTom:AddWaypoint`, and so on;
    - `Mock.addons = {QuestieDB=true, TomTom=false, WaypointUI=false, ShortestPathForever=false}`.
    - `CreateFrame` returns permissive mock frames: unknown methods are no-ops returning nil, `SetScript`/`GetScript`/`SetAttribute`/`GetAttribute` are stored, and `RegisterEvent` is recorded.
    - QuestieDB globals (`LibQuestieDB`, `QuestDB`, `NpcDB`, `ObjectDB`, `ItemDB`) are backed by `tests/fixtures/qdb_fixture.lua`. Their behaviour follows the semantics in QuestieDB's `docs/api.md`: numeric getters return 0, table getters return copies, and `RequireContract(n)` returns `true` when `n <= 4`.
    - Fixture content:
      - quests 179, 170, 233, 3361;
      - one class quest chain (1599, 1598 Warlock);
      - one Dwarf+Gnome-only quest;
      - one quest with `preQuestSingle={179}`;
      - their NPCs and objects with spawns on area 1 (Dun Morogh, uiMap 1426);
      - item 750 with `npcDrops={705}`.
    - Use real names and coordinates: Sten Stoutarm 658 at 29.93,71.20; Balir Frosthammer 713 at 29.71,71.25; Talin Keeneye 714 at 22.60,71.43; Ragged Young Wolf 705.
  - **`tests/run.lua`:**
    - `luajit tests/run.lua [pattern]` runs every `tests/test_*.lua`. Each file returns `{ [name] = function(t) end }`.
    - `t.eq(actual, expected, msg)`, `t.ok(v, msg)`, `t.fails(fn, msg)`.
    - `Mock.reset()` runs before each test.
    - It prints `PASS name` / `FAIL name: msg` and exits 1 on any failure.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/test_boot.lua
return {
  loads_and_fires_login = function(t)
    local loginSeen = false
    local Q = Mock.loadAddon("Questify/Questify.toc", { beforeLogin = function(Q) Q:On("LOGIN", function() loginSeen = true end) end })
    t.ok(Questify == Q, "global set")
    t.ok(loginSeen, "LOGIN fired")
    t.eq(Q.Settings:Get("nav.display"), "native")
    t.ok(Q.IsForever())
  end,
  boots_without_questiedb = function(t)
    Mock.addons.QuestieDB = false            -- the mock then defines no QuestieDB globals
    local Q = Mock.loadAddon("Questify/Questify.toc")
    t.ok(Mock.printed("QuestieDB"), "explains missing dependency")
    t.eq(#Mock.errors, 0, "no Lua error")
  end,
}
-- tests/test_util.lua
return {
  hasbit_above_32_bits = function(t)
    local Q = Mock.loadAddon("Questify/Questify.toc")
    t.ok(Q.Util.HasBit(4294967373, 4))             -- Alliance mask includes Dwarf
    t.ok(Q.Util.HasBit(4294967373, 4294967296))    -- and Skyborne Alliance
    t.ok(not Q.Util.HasBit(4294967373, 2))         -- not Orc
    t.ok(Q.Util.MaskAllows(0, 2) and Q.Util.MaskAllows(nil, 2))
  end,
  settings_set_fires = function(t)
    local Q = Mock.loadAddon("Questify/Questify.toc")
    local got; Q:On("SETTINGS_CHANGED", function(p, v) got = p .. "=" .. tostring(v) end)
    Q.Settings:Set("autoQuest", false)
    t.eq(got, "autoQuest=false"); t.eq(Q.Settings:Get("autoQuest"), false)
  end,
  safecall_reports_once = function(t)
    local Q = Mock.loadAddon("Questify/Questify.toc")
    Q.SafeCall(function() error("boom") end); Q.SafeCall(function() error("boom") end)
    t.eq(Mock.countPrinted("boom"), 1)
  end,
}
```

`Mock.printed(substr) -> boolean`, `Mock.countPrinted(substr) -> number`, and `Mock.errors` (uncaught errors during load or events) are part of the mock.

- [ ] **Step 2: Run the tests to verify they fail.** Run `cd /Users/geoffrey/dev/questify && luajit tests/run.lua`. Expected: FAIL, because the TOC is not found.
- [ ] **Step 3: Implement the files listed above.** TOC file order: Locales, Core, Data, Engine, Nav, Automation, UI, `Guides\Guides.xml`. List only files that exist so far; later tasks append theirs. The QuestieDB-missing message is localized key `L.NEED_QUESTIEDB`, in French "QuestieDB est requis : installe-le depuis CurseForge.".
- [ ] **Step 4: Run the tests to verify they pass.** Run `luajit tests/run.lua`. Expected: all PASS.
- [ ] **Step 5: Write `tools/check_syntax.sh`.** It runs `luajit -bl` on every `.lua` under `Questify/`, `tools/` and `tests/` and exits non-zero on any error. Run it. Expected: no output, exit code 0.

---

### Task 2: QuestieDB facade, maps, guide registry

**Files:**
- Create:
  - `Questify/Data/QDB.lua`, `Questify/Data/Maps.lua`;
  - `Questify/Engine/Guides.lua`;
  - `tests/test_qdb.lua`, `tests/test_guides.lua`;
  - `tests/fixtures/guide_fixture.lua`, with two Alliance chapters: Dwarf/Gnome 1-6 and Dwarf/Gnome 6-11 with `next`.

**Interfaces:**
- Consumes: Task 1 (`Q.Util`, `Q:On`, `Mock`).
- Produces:
  - **Availability and quest data (`Q.QDB`):**
    - `Q.QDB:IsAvailable() -> boolean`;
    - `Q.QDB:Quest(id) -> table|nil` (cached), with fields:
      - `{ id, name, level, reqLevel, races, classes }`;
      - `starters = {npcs={}, objects={}, items={}}`, `finishers = {npcs={}, objects={}}`;
      - `objectives = { creatures = {npcId,...}, killCredit = { {npcIds={...}, base=npcId} }, objects = {objId,...}, items = {itemId,...} }`;
      - `preSingle = {}`, `preGroup = {}`, `exclusiveTo = {}`;
      - `next` (number|nil), `breadcrumbFor` (number|nil), `specialFlags` (number), `requiredSkill` (number|nil).

      Read through `QuestDB.GetAll`. Numeric 0 becomes nil.
  - **NPC, object and item data:**
    - `Q.QDB:Npc(id) -> {id, name, minLevel, maxLevel, spawns = {[uiMapId] = {{x,y},...}}}|nil`;
    - `Q.QDB:Object(id) -> {id, name, spawns = {[uiMapId] = {...}}}|nil`;
    - `Q.QDB:Item(id) -> {id, name, npcDrops={}, objectDrops={}}|nil`.
  - **Names:**
    - `Q.QDB:QuestName(id) -> string`, tried in order: QuestieDB name, `C_QuestLog.GetTitleForQuestID`, then `"#"..id`;
    - `Q.QDB:NpcName(id) -> string`.
  - **Eligibility:**
    - `Q.QDB:IsEligible(id, raceBit, classBit) -> boolean`, using `MaskAllows` on races and classes;
    - `Q.QDB:PrereqsMet(id, isDone) -> boolean`, where `isDone(questId) -> boolean`:
      - `preSingle`: any one done;
      - `preGroup`: all done;
      - `exclusiveTo`: none done.
  - **Maps (`Q.Maps`):**
    - `Q.Maps:AreaToUiMap(areaId) -> uiMapId|nil`. It uses `LibQuestieDB.Support.Get("ZoneDB")`:
      - `private.areaIdToUiMapIdOverride` first, then `private.areaIdToUiMapId`, then `private.subZoneToParentZone` recursively;
      - the strings are parsed with `loadstring` in an empty environment and cached;
      - see `docs/api.md` § Support data in the QuestieDB clone at `/private/tmp/claude-501/-Users-geoffrey-dev-questify/83261d45-3f77-4785-8c8b-3764c772a863/scratchpad/questiedb`.
    - `Q.Maps:PlayerPos() -> uiMapId, x, y` (0-100), or nil in an instance;
    - `Q.Maps:Distance(m1, x1, y1, m2, x2, y2) -> yards|nil`, via `C_Map.GetWorldPosFromMapPos`, nil across continents;
    - `Q.Maps:Nearest(spawnsByMap, fromMap, fromX, fromY) -> mapId, x, y, yards`. When no spawn shares the player's continent, it returns the first spawn with yards nil.
  - **Guides:**
    - `Q:RegisterGuide(def)` stores and validates a guide; an invalid guide prints one error and is ignored;
    - `Q.Guides:Get(id)`, `Q.Guides:All() -> list` sorted by id;
    - `Q.Guides:Normalize(rawStep) -> step`. The table form is `{ action, questId, obj, mapId, x, y, level, text, note, race, class, optional, dungeon, at = {mapId, x, y}, xp }`:
      - `{ "accept", 179 }` gives `action="accept", questId=179`;
      - `{ "goto", 1426, 22.6, 71.4 }` gives `mapId, x, y`;
      - `{ "level", 6 }` gives `level`;
      - `{ "note", "txt" }` gives `text`;
      - `{ "hearth", 1426 }` and `{ "fly", 1453 }` give `mapId`.
    - `Q.Guides:ForPlayer(faction, raceKey, level) -> guide|nil`:
      - candidates match the faction, and either have no `races` or list `raceKey`;
      - prefer a candidate with `minLevel <= level < maxLevel`, race-specific first, then the lowest id;
      - otherwise take the candidate with the highest `minLevel <= level`.
    - `Q.Guides:Next(guide, raceKey) -> guide|nil`, using `nextByRace[raceKey]`, then `next`.
  - Valid actions: `accept`, `complete`, `turnin`, `goto`, `fp`, `sethearth`, `hearth`, `fly`, `boat`, `level`, `note`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/test_qdb.lua (assertions)
quest_shape:        local q = Q.QDB:Quest(179); t.eq(q.name, "Dwarven Outfitters"); t.eq(q.starters.npcs[1], 658); t.eq(q.objectives.items[1], 750)
npc_spawns_uimap:   local n = Q.QDB:Npc(658); t.ok(n.spawns[1426] and math.abs(n.spawns[1426][1][1] - 29.93) < 0.01)
eligibility:        t.ok(Q.QDB:IsEligible(179, 4, 1)); t.ok(not Q.QDB:IsEligible(<dwarfGnomeOnlyId>, 1, 1))
prereqs:            t.ok(not Q.QDB:PrereqsMet(<needs179>, function() return false end)); t.ok(Q.QDB:PrereqsMet(<needs179>, function(id) return id == 179 end))
unknown_quest_nil:  t.eq(Q.QDB:Quest(999999), nil); t.eq(Q.QDB:QuestName(999999), "#999999")
-- tests/test_guides.lua
normalize_forms:    t.eq(Q.Guides:Normalize({"goto",1426,22.6,71.4}).mapId, 1426); t.eq(Q.Guides:Normalize({"complete",170,obj=2}).obj, 2)
invalid_guide_ignored: Q:RegisterGuide({ id = "X", steps = { {"dance", 1} } }); t.eq(Q.Guides:Get("X"), nil); t.ok(Mock.printed("X"))
picks_chapter_by_level: t.eq(Q.Guides:ForPlayer("Alliance","Dwarf",1).id, "A_DwarfGnome_01"); t.eq(Q.Guides:ForPlayer("Alliance","Dwarf",7).id, "A_DwarfGnome_02"); t.eq(Q.Guides:ForPlayer("Alliance","Human",7), nil)
next_chapter:       t.eq(Q.Guides:Next(Q.Guides:Get("A_DwarfGnome_01"), "Dwarf").id, "A_DwarfGnome_02")
```

Write these as functions in the Task 1 file format. Load the guide fixture with `Mock.loadAddon(toc, {extraFiles = {"tests/fixtures/guide_fixture.lua"}})`.

- [ ] **Step 2: Run to verify they fail.** Run `luajit tests/run.lua qdb` and `luajit tests/run.lua guides`. Expected: FAIL.
- [ ] **Step 3: Implement `Data/QDB.lua`, `Data/Maps.lua` and `Engine/Guides.lua`.** Append them to both TOCs, in the Data and Engine sections.
- [ ] **Step 4: Run all tests.** Run `luajit tests/run.lua`. Expected: all PASS.

---

### Task 3: Progress engine

**Files:**
- Create: `Questify/Engine/Progress.lua`, `tests/test_progress.lua`.

**Interfaces:**
- Consumes: Task 2 (`Q.QDB`, `Q.Guides`, `Q.Maps`).
- Produces:
  - **Player context:** `Q.Player = { faction, raceKey, raceBit, classFile, classBit, level }`, refreshed on `"LOGIN"` and `PLAYER_LEVEL_UP`.
  - **Quest state:**
    - `Q.Progress:IsTurnedIn(id)` (`C_QuestLog.IsQuestFlaggedCompleted` plus a session cache filled on `QUEST_TURNED_IN`);
    - `:InLog(id)`;
    - `:IsComplete(id)` (`C_QuestLog.IsComplete`);
    - `:ObjectiveDone(id, i)` (`C_QuestLog.GetQuestObjectives(id)[i].finished`).
  - **Guide selection:**
    - `Q.Progress:SetGuide(id)` stores `Q.char.guideId` and fires `"GUIDE_CHANGED"`;
    - `Q.Progress:Guide() -> guide|nil`. On `"LOGIN"` with no saved guide, it auto-selects with `Q.Guides:ForPlayer`.
  - **Step list:** `Q.Progress:Entries() -> list of entry`. Inserted steps come first (`Q.char.inserted`, in order), then the guide's steps.
    - `entry = { key = string, step = step, index = number, source = "guide"|"inserted", tag = string|nil }`;
    - guide keys are `"g:<guideId>:<i>"`, inserted keys are `"i:<tag>:<j>"`.
  - **Step state:** `Q.Progress:State(entry) -> state, reason`, where state is `"done"`, `"skipped"`, `"active"` or `"blocked"`. Rules from spec § 5.3:
    - manual `Q.char.manual[key]` gives `"done"`;
    - `Q.char.skipped[key]` gives `"skipped"`;
    - a `race`/`class` filter mismatch gives `"skipped"`;
    - `optional` with `dungeonQuests=false` gives `"skipped"`;
    - `accept`:
      - done if in the log or turned in;
      - skipped if not eligible, or if `PrereqsMet` is false and every prerequisite is itself skipped or impossible for this character;
      - blocked with reason `"level N"` if `reqLevel > level`;
    - `complete`:
      - done if turned in;
      - with `obj`, done if that objective is done;
      - without `obj`, done if complete;
      - skipped if neither in the log nor turned in;
    - `turnin`: done if turned in, skipped if neither in the log nor turned in;
    - `goto` / `boat`: done within 15 yd, or in `Q.char.manual`;
    - `fp`: done on `TAXIMAP_OPENED` within 30 yd of the point;
    - `sethearth`: done on `HEARTHSTONE_BOUND` within 40 yd of the point;
    - `hearth` / `fly`: done when `C_Map.GetBestMapForUnit("player")` equals `mapId` after the step became active;
    - `level`: done when `level >= step.level`;
    - `note`: manual only;
    - a quest unknown to QuestieDB is `"active"`.
  - **Navigation through the list:**
    - `Q.Progress:Current() -> entry|nil`: the first entry that is neither done nor skipped (blocked counts as current);
    - `:Skip(key)`, `:MarkDone(key)`, `:Back()` (unskips and unmarks the entry before the current one);
    - `:InsertSteps(tag, steps)` and `:RemoveInserted(tag)`.
  - **Events:**
    - recompute on `QUEST_ACCEPTED`, `QUEST_TURNED_IN`, `QUEST_REMOVED`, `QUEST_LOG_UPDATE` (throttled to 0.2 s), `PLAYER_LEVEL_UP`, `HEARTHSTONE_BOUND`, `TAXIMAP_OPENED`, `ZONE_CHANGED_NEW_AREA`, plus a 1 s ticker while the current step is `goto`/`boat`;
    - fire `"PROGRESS_UPDATED"` on each recompute, and `"STEP_CHANGED"(entry)` when `Current().key` changes;
    - when every guide entry is done or skipped, `SetGuide(Q.Guides:Next(...).id)` if it exists, otherwise print `L.ROUTE_END`.
  - **State memory:**
    - steps that became `"done"` through game state are not stored;
    - `"skipped"` and `"done"` set by the player are stored in `Q.char`;
    - `turnin` done-ness is permanent through `IsTurnedIn`.

- [ ] **Step 1: Write the failing tests.** Use the guide fixture from Task 2 and drive the mock state with `Mock.quests` + `Mock.fire`.

```lua
accept_then_complete_then_turnin: current is accept 179 → Mock.quests.log[179]={complete=false}; Mock.fire("QUEST_ACCEPTED",179) → current advances past accept 179; set complete=true + fire QUEST_LOG_UPDATE + Mock.advance(0.3) → complete step done; Mock.quests.completed[179]=true; log[179]=nil; fire QUEST_TURNED_IN → turnin done
abandoned_quest_skips_followups: accept 179 done, then log[179]=nil + fire QUEST_REMOVED → State(complete 179) == "skipped", State(turnin 179) == "skipped"
class_filter_skipped:  step {"accept",1599,class={"WARLOCK"}} with Mock.player.classFile="WARRIOR" → "skipped"
level_blocked_is_current: step accept of a quest with reqLevel 4 at level 1 → State == "blocked", reason "level 4", and Current() is that entry
unknown_quest_is_active_not_error: step {"accept",999999} → State == "active", #Mock.errors == 0
inserted_first:        Q.Progress:InsertSteps("cq:1599", {{"accept",1599}}) → Current().key == "i:cq:1599:1"
step_changed_fires_once_per_change: count STEP_CHANGED messages across one accept → exactly 1
manual_skip_and_back:  Skip(current.key) advances; Back() returns to it
chapter_rollover:      mark every entry of A_DwarfGnome_01 done → Guide().id == "A_DwarfGnome_02"
```

- [ ] **Step 2: Run to verify they fail.** Run `luajit tests/run.lua progress`.
- [ ] **Step 3: Implement `Engine/Progress.lua`** and append it to both TOCs.
- [ ] **Step 4: Run all tests.** Expected: all PASS.

---

### Task 4: Targets (where to go, which mobs)

**Files:**
- Create: `Questify/Engine/Targets.lua`, `tests/test_targets.lua`.

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces:
  - `Q.Targets:ForEntry(entry) -> target|nil`, with `target = { mapId, x, y, title, kind = "npc"|"object"|"area"|"point", id = number|nil }` in 0-100. The source depends on the step:
    - `accept`: the nearest starter NPC or object spawn;
    - `turnin`: the nearest finisher;
    - `complete`: `step.at` if present, otherwise the nearest spawn among the step's objective targets (creatures, killCredit npcIds, objects, and the `npcDrops`/`objectDrops` of the objective items); with `obj`, only the targets matched to that objective;
    - other actions: their own point (`hearth`/`fly` have no point and return nil);
    - `title` is localized from step text (Task 7's `Q.Format:StepTitle(entry)` once it exists; until then the quest or NPC name).
  - `Q.Targets:ObjectiveMobs() -> list` of `{ npcId, name, minLevel, maxLevel, questId, objIndex|nil, done = boolean, viaItem = itemId|nil }`:
    - covers every in-log quest referenced by a `complete` entry that is not done within the next 15 non-done entries;
    - deduplicated by `npcId`, ordered by entry order.
  - `Q.Targets:ObjectiveNpcSet() -> {[npcId] = true}`, made from the not-done rows of `ObjectiveMobs`.
  - `Q.Targets:MatchObjective(questId, name) -> index|nil`: the client objective whose `text` contains `name`, compared lowercase and as a plain search.

- [ ] **Step 1: Write the failing tests.**
  - `accept_targets_starter_npc`: the target of `accept 179` has `kind == "npc"`, `id == 658`, and x ≈ 29.93.
  - `complete_uses_item_drop_mobs`: for `complete 179` with item 750, `ObjectiveMobs()` contains npcId 705 with `viaItem == 750`.
  - `complete_prefers_at`: with `at = {1426, 26.1, 74.3}`, the target x is 26.1.
  - `done_objective_excluded`: when 170's objective 1 is finished in the mock, its creature is not in `ObjectiveNpcSet()`.
  - `no_spawns_returns_nil`: an unknown quest gives nil and no error.
- [ ] **Step 2: Run to verify they fail.** Run `luajit tests/run.lua targets`.
- [ ] **Step 3: Implement `Engine/Targets.lua`** and append it to both TOCs.
- [ ] **Step 4: Run all tests.** Expected: all PASS.

---

### Task 5: Navigation providers

**Files:**
- Create: `Questify/Nav/Navigation.lua`, `tests/test_nav.lua`.

**Interfaces:**
- Consumes: `Q.Targets:ForEntry` (Task 4), `Q.Settings`, and the messages `STEP_CHANGED` and `PROGRESS_UPDATED`.
- Produces:
  - **API:**
    - `Q.Nav:SetTarget(mapId, x, y, title)` (0-100) and `Q.Nav:Clear()`;
    - `Q.Nav:Detect() -> {shortestpath = bool, waypointui = bool, tomtom = bool, native = true}`;
    - `Q.Nav:Active() -> routingName|nil, displayName`.
  - **Detection by globals:**
    - ShortestPath: `ShortestPathForever and ShortestPathForever.API`;
    - WaypointUI: `WaypointUIAPI and WaypointUIAPI.Navigation`;
    - TomTom: `TomTom and TomTom.AddWaypoint`.
  - **Behaviour:**
    - `nav.routing == true` and ShortestPath present: call `ShortestPathForever.API.Navigate("Questify", mapId, x/100, y/100, title, "quest")` and nothing else. If it returns false (combat), keep the target and retry once on `PLAYER_REGEN_ENABLED`.
    - Otherwise use the display set in `nav.display`, falling back to `native` if that one is missing:
      - `"waypointui"`: `WaypointUIAPI.Navigation.NewUserNavigation({ name = title, mapID = mapId, x = x, y = y })`;
      - `"tomtom"`: remove the previous uid, then `TomTom:AddWaypoint(mapId, x/100, y/100, { title = title, crazy = true, persistent = false, minimap = true, world = true })`;
      - `"native"`: if `C_Map.CanSetUserWaypointOnMap(mapId)`, then `C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapId, x/100, y/100))` and `C_SuperTrack.SetSuperTrackedUserWaypoint(true)`.
    - Skip the update when map, title, and x/y rounded to 0.1 are unchanged.
    - `Clear()` clears the provider in use: `ShortestPathForever.API.Cancel("Questify")`, `WaypointUIAPI.Navigation.ClearUserNavigation()`, `TomTom:RemoveWaypoint(uid)`, or `C_Map.ClearUserWaypoint()`.
    - Update on `STEP_CHANGED`, and every 5 s while the current step is `complete` without `at`.
    - Clear when the current entry is nil.
    - Changing `nav.*` settings clears the old provider and re-applies the target.
- Coordinate checks against provider docs: TomTom (ID 18808), WaypointUI (`x`,`y` 0-100), ShortestPath API doc at `https://github.com/cjber/shortest-path-forever/blob/main/docs/api.md`.

- [ ] **Step 1: Write the failing tests.**
  - `native_by_default`: `STEP_CHANGED` leads to a `C_Map.SetUserWaypoint` call with x = 0.2993 within ±0.001.
  - `tomtom_replaces_previous`: with display `"tomtom"`, two step changes give 2 `AddWaypoint` calls and 1 `RemoveWaypoint` call.
  - `waypointui_uses_0_100`: the call receives `x == 29.93`.
  - `missing_provider_falls_back_native`: display `"tomtom"` without TomTom still calls `SetUserWaypoint`.
  - `shortestpath_retries_after_combat`: with routing on, the mocked `Navigate` returns false; after `Mock.fire("PLAYER_REGEN_ENABLED")`, it has been called twice.
  - `dedupe_same_target`: the same target twice gives one provider call.
- [ ] **Step 2: Run to verify they fail.** Run `luajit tests/run.lua nav`.
- [ ] **Step 3: Implement `Nav/Navigation.lua`** and append it to both TOCs.
- [ ] **Step 4: Run all tests.** Expected: all PASS.

---

### Task 6: Quest automation and reward choice

**Files:**
- Create: `Questify/Automation/AutoQuest.lua`, `Questify/Automation/Rewards.lua`, `tests/test_autoquest.lua`, `tests/test_rewards.lua`.

**Interfaces:**
- Consumes: `Q.Guides:All()`, `Q.Progress:Entries()`, `Q.Settings`, `Q.Player`.
- Produces:
  - **`Q.AutoQuest:IsRouteQuest(id) -> boolean`**: true if any `accept`/`turnin` step of a guide for the player's faction, or any inserted step, references `id`. The set is rebuilt on `GUIDE_CHANGED`, `CLASSQUESTS_CHANGED` and `"LOGIN"`.
  - **Handlers.** Nothing runs when `autoQuest` is false or `IsShiftKeyDown()` is true.
    - `QUEST_DETAIL`: `AcceptQuest()` if `IsRouteQuest(GetQuestID())`.
    - `GOSSIP_SHOW`:
      - first, for each `C_GossipInfo.GetActiveQuests()` entry with `isComplete` and a route quest, `SelectActiveQuest(questID)`;
      - otherwise, for each `GetAvailableQuests()` entry with a route quest, `SelectAvailableQuest(questID)`;
      - one selection per event.
    - `QUEST_GREETING`: the same logic with `GetNumActiveQuests`/`GetActiveQuestID(i)`/`SelectActiveQuest(i)` and `GetNumAvailableQuests`/`GetAvailableQuestInfo(i)`/`SelectAvailableQuest(i)`, guarded when absent.
    - `QUEST_PROGRESS`: `CompleteQuest()` if `IsQuestCompletable()` and the quest is a route quest.
    - `QUEST_COMPLETE` with `n = GetNumQuestChoices()`:
      - `n <= 1`: `GetQuestReward(n)`;
      - `n > 1` and `autoReward`: `GetQuestReward(Q.Rewards:Pick(Q.Rewards:CollectChoices(), Q.Player))` and print the reason;
      - `n > 1` without `autoReward`: do nothing.
  - **`Q.Rewards:CollectChoices() -> list`** of `{ index, link, equipLoc, classID, subclassID, minLevel, sellPrice, stats }`, built from `GetQuestItemLink("choice", i)`, `C_Item.GetItemInfo(link)` and `C_Item.GetItemStats(link)`.
  - **`Q.Rewards:Pick(choices, player) -> index, reasonKey, detail`**:
    - a pure function;
    - `player = {classFile, level}`;
    - equipped items come from `Q.Rewards:EquippedScore(slot, player)`, which reads `GetInventoryItemLink("player", slot)` and returns 0 when empty;
    - `reasonKey` is `"upgrade"` or `"vendor"`.
  - **`Q.Rewards:Usable(choice, player) -> boolean`**, using this table (classID 4 = armor, 2 = weapon):

    | Class | Armor subclasses | Weapon subclasses |
    |---|---|---|
    | WARRIOR | 1, 2, 3, 6; 4 from level 40 | 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18 |
    | PALADIN | 1, 2, 3, 6; 4 from level 40 | 0, 1, 4, 5, 6, 7, 8 |
    | HUNTER | 1, 2; 3 from level 40 | 0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18 |
    | ROGUE | 1, 2 | 2, 3, 4, 7, 13, 15, 16, 18 |
    | PRIEST | 1 | 4, 10, 15, 19 |
    | SHAMAN | 1, 2, 6; 3 from level 40 | 0, 1, 4, 5, 10, 13, 15 |
    | MAGE | 1 | 7, 10, 15, 19 |
    | WARLOCK | 1 | 7, 10, 15, 19 |
    | DRUID | 1, 2 | 4, 5, 10, 13, 15 |

    - Armor subclass 0 (misc: necks, rings, trinkets, cloaks) is always usable.
    - `minLevel <= level` is required.
  - **Stat weights** (keys from `C_Item.GetItemStats`):
    - `STR = ITEM_MOD_STRENGTH_SHORT`, `AGI = ITEM_MOD_AGILITY_SHORT`, `STA = ITEM_MOD_STAMINA_SHORT`, `INT = ITEM_MOD_INTELLECT_SHORT`, `SPI = ITEM_MOD_SPIRIT_SHORT`, `ARMOR = RESISTANCE0_NAME`, `DPS = ITEM_MOD_DAMAGE_PER_SECOND_SHORT`.
    - WARRIOR: STR 1, AGI .6, STA .5, ARMOR .02, DPS 3
    - PALADIN: STR 1, STA .6, INT .4, AGI .3, SPI .2, ARMOR .02, DPS 2.5
    - HUNTER: AGI 1, STA .5, INT .3, STR .1, ARMOR .01, DPS 2
    - ROGUE: AGI 1, STR .5, STA .4, ARMOR .01, DPS 3
    - PRIEST: INT 1, SPI .8, STA .5, ARMOR .005, DPS .5
    - SHAMAN: STR .8, INT .8, STA .5, AGI .4, SPI .3, ARMOR .015, DPS 2.5
    - MAGE: INT 1, SPI .6, STA .5, DPS .5
    - WARLOCK: INT 1, STA .8, SPI .6, DPS .5
    - DRUID: INT .8, STR .6, AGI .6, SPI .5, STA .5, ARMOR .01, DPS 1
  - **Slot map:**
    - single slots: HEAD 1, NECK 2, SHOULDER 3, CHEST/ROBE 5, WAIST 6, LEGS 7, FEET 8, WRIST 9, HAND 10, CLOAK 15, 2HWEAPON 16, WEAPONMAINHAND 16, WEAPONOFFHAND/SHIELD/HOLDABLE 17, RANGED/RANGEDRIGHT/THROWN 18;
    - two slots: FINGER 11/12, TRINKET 13/14, WEAPON 16/17. Compare against the lower-scoring of the two.

- [ ] **Step 1: Write the failing tests.**
  - `accepts_route_quest` (`QUEST_DETAIL` with `GetQuestID` = 179 gives one `AcceptQuest` call).
  - `ignores_non_route_quest`.
  - `respects_shift_and_settings`:
    - shift held: no call;
    - `autoQuest=false`: no call;
    - `autoReward=false` with 3 choices: no `GetQuestReward` call.
  - `gossip_turnin_before_accept`.
  - `pick_upgrade` (Warrior, level 10, choices = cloth INT robe or mail STR chest, empty chest slot: the mail chest wins with `reasonKey == "upgrade"`).
  - `pick_vendor_when_nothing_usable` (Mage, choices = two plate items with sellPrice 120 and 300: index 2 wins with `"vendor"`).
  - `rings_compare_lower_slot`.
  - `plate_unusable_before_40` (Warrior level 39 rejects plate; level 40 accepts it).
- [ ] **Step 2: Run to verify they fail.** Run `luajit tests/run.lua autoquest` and `luajit tests/run.lua rewards`.
- [ ] **Step 3: Implement both files** and append them to both TOCs.
- [ ] **Step 4: Run all tests.** Expected: all PASS.

---

### Task 7: Class quests, telemetry, text formatting

**Files:**
- Create:
  - `Questify/Engine/ClassQuests.lua`, `Questify/Engine/Telemetry.lua`, `Questify/Engine/Format.lua`;
  - `Questify/Guides/ClassQuestData.lua` (a placeholder with the shape below and one Warlock chain; Task 13 regenerates it);
  - `tests/test_classquests.lua`, `tests/test_format.lua`.

**Interfaces:**
- Consumes: Tasks 2 and 3.
- Produces:
  - **Data file:** `Q.ClassQuestData = { [classFile] = { chain, ... } }`, where `chain = { key = "WARLOCK_1598", title = "The Stolen Tome", faction = "Alliance"|"Horde"|nil, races = mask|nil, level = number, quests = {1598, ...}, rewards = { [questId] = { items = {itemId,...}, xp = number|nil } } }`.
  - **`Q.ClassQuests:List() -> list`** of `{ chain, state }`, where state is one of `"available"`, `"upcoming"`, `"added"`, `"ignored"`, `"inprogress"` or `"done"`. A chain is listed only when its faction and races match the player. States:
    - `"done"`: last quest turned in;
    - `"inprogress"`: a chain quest is in the log;
    - `"added"`: in `Q.char.classQuests.added`;
    - `"ignored"`: in `.ignored`;
    - `"available"`: `level <= Q.Player.level` and the first undone quest's `PrereqsMet` is true;
    - `"upcoming"`: otherwise.
  - **`Q.ClassQuests:Alerts() -> list`**: chains with state `"available"` that are not in `.seen`. `:MarkSeen(key)`.
  - **`Q.ClassQuests:Add(key)`**:
    - calls `Q.Progress:InsertSteps("cq:"..key, steps)`, where steps are, for each quest not yet turned in, `{"accept",q}, {"complete",q}, {"turnin",q}`;
    - records the chain in `.added`, removes it from `.ignored`, and fires `"CLASSQUESTS_CHANGED"`.
  - **`Q.ClassQuests:Ignore(key)`**: removes the inserted steps and records the chain in `.ignored`. `:Unignore(key)` reverses it.
  - **Inserted chains finish themselves:** when every inserted step of `"cq:"..key` is done, call `RemoveInserted` and fire `"CLASSQUESTS_CHANGED"`.
  - **`Q.Telemetry`:**
    - on `STEP_CHANGED`, it stores the seconds since the previous change into `Q.char.telemetry[guideId][index]`, only if the setting `telemetry` is on and the slot is empty;
    - `:Export() -> string` is one line `QV1;<guideId>:<idx>=<sec>,...;...`.
  - **`Q.Format`:**
    - `Q.Format:StepTitle(entry) -> string` is short, for waypoint titles;
    - `Q.Format:StepText(entry) -> string` is colored, for the tracker. Quest names are `|cffffd100`, NPCs `|cff00ff96`, mobs `|cffff6060`, objects `|cff66bbff`. Templates come from `Q.L`. French examples:
      - `accept`: "Prendre |cffffd100%s|r auprès de |cff00ff96%s|r";
      - `turnin`: "Rendre |cffffd100%s|r à |cff00ff96%s|r";
      - `complete`: "Faire : |cffffd100%s|r" plus objective lines from the client log;
      - `goto`: "Aller au point indiqué";
      - `fp`: "Prendre le point de vol";
      - `sethearth`: "Lier la pierre de foyer ici";
      - `hearth`: "Utiliser la pierre de foyer";
      - `fly`: "Prendre un vol vers %s";
      - `boat`: "Prendre le bateau";
      - `level`: "Tuer des monstres jusqu'au niveau %d";
      - `note`: the text itself.

      `step.note`, when present, is appended on its own line in grey.
    - `Q.Format:ActionIcon(action) -> texturePath`, using built-in textures only: `Interface\GossipFrame\AvailableQuestIcon`, `ActiveQuestIcon`, `Interface\Minimap\Tracking\FlightMaster`, `Interface\Icons\INV_Misc_Rune_01`, `Interface\Icons\Ability_Rogue_Sprint`.
  - Also define `Questify_OnAddonCompartmentClick` here as a stub that calls `Q.UI.Journal:Toggle()` if it exists.

- [ ] **Step 1: Write the failing tests.**
  - `warlock_chain_listed_for_warlock_only`.
  - `available_raises_alert_once` (after `MarkSeen`, `Alerts()` is empty).
  - `add_inserts_steps_before_route` (`Q.Progress:Current().key` starts with `"i:cq:"`).
  - `ignore_removes_steps`.
  - `unignore_lists_again`.
  - `chain_done_removes_insert`.
  - `format_accept_fr` (with `GetLocale()` returning `"frFR"`, `StepText` of `accept 179` contains "Dwarven Outfitters" and "Sten Stoutarm").
  - `telemetry_export_format` (matches `^QV1;`).
- [ ] **Step 2: Run to verify they fail.** Run `luajit tests/run.lua classquests` and `luajit tests/run.lua format`.
- [ ] **Step 3: Implement the files** and append them to both TOCs. `ClassQuestData.lua` goes in `Guides/Guides.xml`, after the guide files.
- [ ] **Step 4: Run all tests.** Expected: all PASS.

---

### Task 8: Tracker, mob panel, nameplates

**Files:**
- Create: `Questify/UI/Tracker.lua`, `Questify/UI/MobPanel.lua`, `Questify/UI/Nameplates.lua`, `tests/test_tracker.lua`, `tests/test_mobpanel.lua`, `tests/test_nameplates.lua`.

**Interfaces:**
- Consumes: `Q.Progress`, `Q.Targets`, `Q.Format`, `Q.ClassQuests:Alerts()`, `Q.Maps`, `Q.Settings`.
- Produces:
  - **`Q.UI.Tracker`:**
    - `Q.UI.Tracker:Refresh()` and `Q.UI.Tracker.frame`. Name the frame `QuestifyTracker`.
    - The default anchor is `TOPRIGHT` of `MinimapCluster`, `BOTTOMRIGHT`, offset (0, -10). The frame is movable when unlocked, and its position is saved in `settings.tracker.point`.
    - Header: chapter title, `minLevel-maxLevel`, progress `done/total` as a StatusBar.
    - Current entry: action icon, `Format:StepText`, and distance from `Q.Maps:Distance` to `Targets:ForEntry`, updated every 0.5 s.
    - Then the next `settings.tracker.nextSteps` non-done entries, in small grey text.
    - Class-quest alert button (pulsing glow) when `Q.ClassQuests:Alerts()` is non-empty. Clicking it calls `Q.UI.ClassQuestPopup:Show(chain)` (Task 9).
    - Mouse: right-click on the current line calls `Progress:Skip`, shift+right-click calls `Progress:Back`, left-click on a `note` or `goto` line calls `Progress:MarkDone`.
    - Missing QuestieDB: the frame shows `L.NEED_QUESTIEDB` only.
    - Refresh on `PROGRESS_UPDATED`, `STEP_CHANGED`, `GUIDE_CHANGED`, `CLASSQUESTS_CHANGED`, `SETTINGS_CHANGED`.
  - **`Q.UI.MobPanel`:**
    - `Q.UI.MobPanel:Refresh()` builds up to 6 rows, anchored below the tracker, from `Q.Targets:ObjectiveMobs()` (not-done rows first).
    - Each row is a `Button` with `SecureActionButtonTemplate`. Attributes: `type="macro"`, `macrotext="/cleartarget\n/targetexact "..name.."\n/tm !8"`. The row shows the name, level range and the objective text. Register clicks with `RegisterForClicks("AnyUp", "AnyDown")`.
    - Hovering shows a shared 160x160 `PlayerModel` called `QuestifyMobModel`, beside the row, with `SetCreature(npcId)`.
    - `QuestifyMobModel` shows an icon fallback when `GetModelFileID()` is nil after 0.3 s.
    - **In combat** (`InCombatLockdown()`), `Refresh` only sets `pending = true` and changes no attribute. It applies on `PLAYER_REGEN_ENABLED`.
  - **`Q.UI.Nameplates`:**
    - On `NAME_PLATE_UNIT_ADDED(unit)`, read the npcID with `UnitCreatureID(unit)` if it exists, otherwise from field 6 of `strsplit("-", UnitGUID(unit))`. Ignore it when `IsSecret`.
    - If the npcID is in `Q.Targets:ObjectiveNpcSet()` and setting `nameplates` is on, attach a 24 px icon (`Interface\GossipFrame\AvailableQuestIcon` or a skull-like built-in) above the plate. The icon bounces with an `AnimationGroup` `Translation` of 0 to 6 px, looped with `BOUNCE`.
    - Remove the icon on `NAME_PLATE_UNIT_REMOVED`.
    - Re-scan visible plates (`C_NamePlate.GetNamePlates()`) on `PROGRESS_UPDATED`.

- [ ] **Step 1: Write the failing tests** (smoke and state tests against the permissive mock).
  - `tracker_shows_current_step` (the tracker's current FontString text contains "Dwarven Outfitters").
  - `tracker_missing_questiedb_message`.
  - `mobpanel_sets_macro` (row 1 has `macrotext` containing `/targetexact Ragged Young Wolf` and `/tm !8`).
  - `no_attribute_change_in_combat` (with `Mock.player.combat=true`, `Refresh` after the objectives change leaves row attributes unchanged; after `Mock.fire("PLAYER_REGEN_ENABLED")` they update).
  - `secret_guid_ignored` (`UnitCreatureID` returns a mock secret value, `issecretvalue` returns true for it: no icon and no error).
  - `nameplate_icon_for_objective_mob`.
- [ ] **Step 2: Run to verify they fail.** Run `luajit tests/run.lua tracker`, `luajit tests/run.lua mobpanel` and `luajit tests/run.lua nameplates`.
- [ ] **Step 3: Implement the three files** and append them to both TOCs.
- [ ] **Step 4: Run all tests.** Expected: all PASS.

---

### Task 9: Journal, class-quest popup, wizard, slash commands

**Files:**
- Create: `Questify/UI/Journal.lua`, `Questify/UI/ClassQuestPopup.lua`, `Questify/UI/Wizard.lua`, `Questify/UI/Slash.lua`, `tests/test_journal.lua`, `tests/test_wizard.lua`.

**Interfaces:**
- Consumes: everything above.
- Produces:
  - **`Q.UI.Journal`:**
    - `Q.UI.Journal:Toggle()` and `:ShowTab(name)`, with `name` one of `"route"`, `"class"`, `"options"`. The frame is called `QuestifyJournal`, uses `ButtonFrameTemplate` (fallback `BasicFrameTemplateWithInset`), measures 520x560, is movable and is added to `UISpecialFrames`.
    - **Route tab:**
      - left: a scrollable chapter list from `Q.Guides:All()`, filtered to the player's faction; clicking one calls `Progress:SetGuide`;
      - right: a scrollable step list of `Progress:Entries()` with state icons (done = check, skipped = grey, current = arrow, blocked = lock and reason);
      - clicking a step makes it current: earlier undone entries are skipped and later ones are unskipped.
    - **Class tab:** one row per `Q.ClassQuests:List()` item (title, level, state), with buttons "Ajouter"/"Ignorer"/"Réactiver" depending on state. Hovering shows the chain's quest names and reward item tooltips (`GameTooltip:SetItemByID`).
    - **Options tab:** checkboxes for `autoQuest`, `autoReward`, `dungeonQuests`, `nameplates`, `tracker.locked`, `telemetry`, and `tracker.showMobs`, plus buttons:
      - "Assistant de navigation" calls `Q.UI.Wizard:Show()`;
      - "Réinitialiser la progression du chapitre" clears `manual`/`skipped` keys of the current guide;
      - "Exporter les mesures" shows `Telemetry:Export()` in a selectable EditBox.
  - **`Q.UI.ClassQuestPopup:Show(chain)`:** a small frame with the title, level, first quest's objectives (from `QuestDB`), rewards as item buttons with tooltips, the starter NPC name and zone, and two buttons. "Ajouter à la route" calls `ClassQuests:Add`, "Ignorer" calls `ClassQuests:Ignore`. Both call `MarkSeen` and hide the popup.
  - **`Q.UI.Wizard:Show()`:**
    - step 1 lists the detected providers (`Q.Nav:Detect()`), with one sentence each from `Q.L`;
    - step 2 is a routing checkbox (enabled only if ShortestPath is detected);
    - step 3 is a display radio with `"waypointui"`, `"tomtom"` and `"native"` (missing ones disabled);
    - step 4 holds the two automation checkboxes;
    - "Terminer" saves everything through `Q.Settings:Set` and sets `Q.char.wizardDone = true`.
    - It shows automatically once, 3 s after `"LOGIN"`, when `wizardDone` is not set.
  - **`/questify` and `/qf`:**
    - no argument: toggle the journal;
    - `skip`, `back`, `options`, `wizard`;
    - `export`: telemetry;
    - `debug`: toggle `QuestifyDB.debug`;
    - `reset`: confirm through `StaticPopup`, then wipe `Q.char`.

- [ ] **Step 1: Write the failing tests.**
  - `slash_toggles_journal`.
  - `class_tab_add_button_calls_add`.
  - `wizard_shows_once_and_saves` (after `Mock.advance(3)` the wizard is shown; choosing `"tomtom"` while TomTom is present and clicking finish gives `Settings:Get("nav.display") == "tomtom"` and `wizardDone == true`; a reload does not show it again).
  - `wizard_disables_missing_providers`.
- [ ] **Step 2: Run to verify they fail.** Run `luajit tests/run.lua journal` and `luajit tests/run.lua wizard`.
- [ ] **Step 3: Implement the four files** and append them to both TOCs.
- [ ] **Step 4: Run all tests and the syntax check.** Run `luajit tests/run.lua && tools/check_syntax.sh`. Expected: all PASS, exit code 0.

---

### Task 10: Route builder data loader and world geometry

**Files:**
- Create:
  - `tools/routebuilder/qdb.lua`: module form of `/private/tmp/claude-501/-Users-geoffrey-dev-questify/83261d45-3f77-4785-8c8b-3764c772a863/scratchpad/tools/questie_extract.lua`. Copy its sandboxed loading (text only, `setfenv` strict environment, batched data strings), its correction layers and its blacklist. Drop its CLI.
  - `tools/routebuilder/world.lua`;
  - `tools/routebuilder/data/` with `UiMapAssignment.csv`, `UiMap.csv`, `TaxiNodes.csv`, `TaxiPath.csv` and `AreaTable.csv`, copied from `/private/tmp/claude-501/-Users-geoffrey-dev-questify/83261d45-3f77-4785-8c8b-3764c772a863/scratchpad/dl_wago/` (Forever build 1.60.1.70707 from wago.tools);
  - `tools/routebuilder/tests/test_world.lua` and `tools/routebuilder/tests/run.lua`, a copy of the `tests/run.lua` runner without the WoW mock.

**Interfaces:**
- Produces:
  - **`qdb.load{ db = <QuestieDB root>, faction = "Alliance"|"Horde", questie = <Questie root>|nil } -> D`**:
    - `D.quests[id]`, `D.npcs[id]`, `D.objects[id]` and `D.items[id]` use the field names of Task 2's `Q.QDB` shapes, with spawns keyed by uiMapId;
    - `D.xp[questId] = {level, xp}` from `support/Forever/QuestXP/xpDB-classic.lua`;
    - `D.drops[itemId][npcId] = rate` (0-1) from item `npcDrops` and Forever DropTables when present;
    - `D.npcFlags[npcId]`, `D.flightMasters = {npcId,...}`, `D.innkeepers = {npcId,...}`, using the flag values from `LibQuestieDB.Enum.npcFlags` / `src/corrections/enum`.
  - **`world.load(dataDir) -> W`**:
    - `W.toWorld(uiMapId, x, y) -> continent, wx, wy` (yards), from `UiMapAssignment` `Region` bounds with `OrderIndex 0` and `UiMin=0`/`UiMax=1`. In WoW, a map's x grows towards world −Y and its y towards world −X; check this against the test below.
    - `W.dist(m1, x1, y1, m2, x2, y2) -> yards|math.huge`;
    - `W.taxi`: nodes `{id, name, continent, wx, wy, faction}` and edges from `TaxiPath`, with flight time = path length / 32 yd/s plus 20 s;
    - `W.flightTime(nodeA, nodeB) -> seconds|nil` (Dijkstra);
    - `W.nearestTaxi(continent, wx, wy) -> node, yards`.
- Default paths: `--db /private/tmp/claude-501/-Users-geoffrey-dev-questify/83261d45-3f77-4785-8c8b-3764c772a863/scratchpad/questiedb` and `--questie /private/tmp/claude-501/-Users-geoffrey-dev-questify/83261d45-3f77-4785-8c8b-3764c772a863/scratchpad/questie`. Both are overridable by CLI flags (Task 13).

- [ ] **Step 1: Write the failing tests.**
  - `ironforge_taxi_matches_map`: the `TaxiNodes` row "Ironforge, Dun Morogh" (world -4821.78, -1155.44) converted to uiMap 1426 coordinates and back lands within 5 yd.
  - `distance_coldridge`: `W.dist(1426, 29.93, 71.20, 1426, 22.60, 71.43)` is between 250 and 450 yd (Sten Stoutarm to Talin Keeneye).
  - `loader_quest_179`: `D.quests[179].name == "Dwarven Outfitters"` and `D.xp[179][2] == 80`.
  - `loader_has_forever_quest`: `D.quests[97277]` exists and is named "Grund and Gozwin".
  - `loader_sandbox`: a data file trying `os.exit` raises inside the sandbox and never exits the process.
- [ ] **Step 2: Run to verify they fail.** Run `cd /Users/geoffrey/dev/questify && luajit tools/routebuilder/tests/run.lua`.
- [ ] **Step 3: Implement `qdb.lua` and `world.lua`.**
- [ ] **Step 4: Run the tests to verify they pass.**

---

### Task 11: XP model

**Files:**
- Create: `tools/routebuilder/xp.lua`, `tools/routebuilder/tests/test_xp.lua`.

**Interfaces:**
- Produces:
  - `xp.LEVEL_XP[level]` (XP to reach `level + 1`), from the Classic table: 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300, 23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400, 50800, 54500, 58600, 62800, 67100 for levels 1-35.
  - `xp.questXP(D, quest, playerLevel) -> number`:
    - base = `D.xp[id][2]`, or the estimate when it is absent;
    - modifier by `d = playerLevel - questLevel`: `d <= 5` gives 1.0, 6 gives 0.8, 7 gives 0.6, 8 gives 0.4, 9 gives 0.2, `>= 10` gives 0.1;
    - the result is rounded down to a multiple of 5.
  - `xp.estimateBase(D, questLevel, flags) -> number`:
    - the median of the known `D.xp` values at that `questLevel`, across all quests;
    - dungeon quests (`zoneOrSort` is a dungeon area, or a `dungeon` flag from the zone plan) are × 0.5, per Forever's −50 % change;
    - level-1 quests with no known value get 80.
  - `xp.mobXP(playerLevel, mobLevel) -> number`:
    - base `playerLevel * 5 + 45`;
    - mob above the player: × (1 + 0.05 × diff);
    - mob below the player: × (1 − diff / ZD), with ZD = 5 (levels 1-7), 6 (8-9), 7 (10-11), 8 (12-15), 9 (16-19), 10 (20-29), 11 (30-39), floored at 0 and gray at 0;
    - rounded down.
  - `xp.addXP(state, amount)`: updates `state.level` and `state.xp`, carrying over level-ups.

- [ ] **Step 1: Write the failing tests.**
  - `mob_same_level` (`mobXP(10, 10) == 95`).
  - `mob_above` (`mobXP(10, 12) == 104`).
  - `mob_below_gray` (`mobXP(20, 10) == 0`).
  - `quest_modifier` (with a known 1000 XP quest of level 10, the result is 1000 at player 15, 800 at 16 and 100 at 25).
  - `estimate_dungeon_half`.
  - `addxp_levels_up` (level 1, 0 XP plus 1000 XP gives level 3 with 100 XP).
- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement `xp.lua`.**
- [ ] **Step 4: Run the tests to verify they pass.**

---

### Task 12: Simulator and route ordering

**Files:**
- Create: `tools/routebuilder/sim.lua`, `tools/routebuilder/order.lua`, `tools/routebuilder/tests/test_sim.lua`, `tools/routebuilder/tests/fixture_zone.lua`.

`fixture_zone.lua` is a synthetic zone: 6 quests around 2 hubs, a two-quest chain, one breadcrumb, and one far-away low-XP quest.

**Interfaces:**
- Consumes: `D` (Task 10), `W` (Task 10), `xp` (Task 11).
- Produces:
  - **`sim.chapter(D, W, plan, state) -> steps, report`**:
    - `plan = { id, title, faction, races = {...}|nil, zones = {uiMapId,...}, minLevel, maxLevel, endZones = {uiMapId,...}|nil, entry = {mapId, x, y}|nil, dungeons = {name,...}|nil }`;
    - `state = { level, xp, pos = {mapId, x, y}, done = {[q]=true}, log = {[q]=true}, knownTaxi = {[nodeId]=true}, hearth = {mapId, x, y}|nil, hearthReadyAt = seconds, time = seconds, raceBits = mask, classBit = nil }`;
    - `steps` use Task 2's raw guide format;
    - `report = { xpPerHour, quests = {...}, dropped = { {id, reason} }, warnings = {...}, endLevel }`.
    - `state` is updated in place, so the next chapter continues from it.
  - **Candidates:** quests for the faction, eligible for at least one of `plan.races` (or any race of the faction). The quest must have:
    - `questLevel` in [minLevel − 3, maxLevel + 3] and `reqLevel <= maxLevel`;
    - a starter spawn in `plan.zones`, or an item start dropping from mobs there;
    - a finisher in `plan.zones` or in `endZones`.

    Exclude a quest when it:
    - has `classes ~= 0` (class quests are handled separately);
    - has `requiredSkill`;
    - has `specialFlags` repeatable (1) or event (2);
    - is blacklisted;
    - is in `state.done`.
  - **Time costs:**
    - travel at 7 yd/s, using `W.dist`;
    - objective time:
      - kill: 8 kills × 20 s;
      - item from mobs: ceil(6 / rate) × 20 s, rate defaulting to 0.5;
      - object: 5 × 6 s, plus the spread of the chosen spawn cluster at 7 yd/s;
    - accept or turn-in: 5 s.
  - **Objective site:** for each objective target, cluster its spawns on a 60 yd grid in the plan zones. Take the cluster with the most spawns; on ties, the one nearest the quest starter. The site is that cluster's centroid; with several objectives, take the one nearest each target's site.
  - **Selection:**
    - value = `xp.questXP` at the current simulated level + `xp.mobXP` × kills + bonus;
    - bonus: a breadcrumb or quest whose finisher is in `endZones`, or a quest leading within 150 yd of an unknown faction flight master, gets the seconds it saves, valued at the chapter's running XP/s;
    - a chain head gets 0.7 × the summed value of its chain;
    - ratio = value / isolated time, where isolated time = round trip from the nearest hub (starter position) + objectives;
    - drop a quest when its ratio is below 0.35 × the median ratio of the candidates, with reason `"low ratio"`;
    - also drop it when its objective site is more than 900 yd from every hub, with reason `"far"`.
  - **Ordering** (`order.lua`):
    - `order.build(tasks, start, distFn) -> orderedTasks`;
    - tasks are `{ kind = "A"|"O"|"T", q, pos, dur, after = {taskIds} }`. Constraints: A before O before T for the same quest; T(pre) before A(next) for chains (`preSingle`/`preGroup`); the log holds at most 20 accepted, unfinished quests;
    - order by nearest feasible neighbour by travel time, tie-breaking T before A before O when within 20 yd;
    - then or-opt: move single tasks to any feasible position while total time decreases, at most 200 passes.
  - **Logistic steps inserted by `sim`:**
    - `fp`: when the route passes within 150 yd of an unknown faction flight master (TaxiNodes nearest the NPC spawn);
    - `sethearth`: at the hub with the most A/T tasks, if the route returns there later after leaving it by more than 800 yd;
    - `hearth`: when the next task is within 120 yd of the hearth, more than 1200 yd away, and `time >= hearthReadyAt` (cooldown 3600 s);
    - `fly`: when `W.flightTime` + walking to and from the taxi nodes is under 0.7 × the walking time and both nodes are known;
    - `level`: when the simulated level after the chapter is below `maxLevel`, append `{ "level", maxLevel }` with a note giving the number of mobs to kill at the last objective site.
  - **XP simulation:** walk the ordered tasks, apply XP, and recompute the quest modifier at turn-in time.

- [ ] **Step 1: Write the failing tests** on the fixture.
  - `respects_precedence` (every quest's A index < O index < T index; for the chain, T1 < A2).
  - `drops_far_low_xp` (the far quest is in `report.dropped` with reason `"far"` or `"low ratio"`).
  - `keeps_breadcrumb` (the breadcrumb is kept despite its low XP).
  - `log_cap` (with a cap of 3 in the fixture options, at most 3 quests are open at any point).
  - `hub_batching` (the first three tasks are the A tasks of hub 1).
  - `inserts_fp`.
  - `deterministic` (two runs give identical step lists).
- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement `sim.lua` and `order.lua`.**
- [ ] **Step 4: Run the tests to verify they pass.**

---

### Task 13: Emitter, zone plans, CLI, guide validator, class-quest data

**Files:**
- Create:
  - `tools/routebuilder/emit.lua`, `tools/routebuilder/plans.lua`, `tools/routebuilder/build.lua`, `tools/routebuilder/classquests.lua`;
  - `tools/validate_guides.lua`;
  - `tools/routebuilder/tests/test_emit.lua`.

**Interfaces:**
- Produces:
  - **`luajit tools/routebuilder/build.lua [--db PATH] [--questie PATH] [--faction Alliance|Horde|all] [--only <planId>] [--report docs/routes]`**:
    - writes `Questify/Guides/<Faction>/<planId>.lua`;
    - rewrites `Questify/Guides/Guides.xml` with every guide file, then `ClassQuestData.lua` last;
    - writes `docs/routes/<planId>.md` reports with XP/h, kept and dropped quests and warnings;
    - prints one summary line per chapter.
  - **`emit.guide(plan, steps, report) -> string`**: one step per line, followed by a comment `-- <quest name> (lvl <questLevel>, ~<xp> xp, sim lvl <n>)`. The header comment says it was generated, from which QuestieDB commit, and on which date.
  - **`plans.lua`** returns ordered plan lists `{ Alliance = { ... }, Horde = { ... } }`, keyed as in spec § 6.
    - Ids follow `A_<Start>_<NN>`, `A_<NN>` (shared trunk), `H_<Start>_<NN>`, `H_<NN>`, `A_Skyborne_<NN>` and `H_Skyborne_<NN>`.
    - Every start chapter lists its `races`; trunk chapters have none.
    - The last start chapter's `nextByRace` points into the trunk.
    - Each chapter's `entry` is its first hub.
    - Zones use uiMapIDs: Dun Morogh 1426, Elwynn 1429, Teldrassil 1438, Darkshore 1439, Loch Modan 1432, Westfall 1436, Redridge 1433, Duskwood 1431, Wetlands 1437, Ashenvale 1440, Stonetalon 1442, Hillsbrad 1424, Durotar 1411, Mulgore 1412, Tirisfal 1420, Silverpine 1421, Barrens 1413, Thousand Needles 1441, Zephras Isle 2521.
  - **`classquests.lua`**: for each class, the chains of quests with `classes` including that class and `questLevel <= 30`, from QuestieDB.
    - A chain follows `preSingle`/`next`. Its `faction`/`races` come from `requiredRaces`.
    - Rewards are the items whose `questRewards` contain the quest id, plus `xp` from `D.xp`.
    - The output is written to `Questify/Guides/ClassQuestData.lua` in Task 7's shape.
  - **`luajit tools/validate_guides.lua [--db PATH]`**: loads every guide file with a stub `Q:RegisterGuide` and checks each step:
    - its action is valid;
    - its quest id exists in D;
    - the quest is eligible for at least one race of the chapter (or the faction);
    - `at`/point coordinates are within 0-100 on a known uiMap;
    - every `complete`/`turnin` follows an `accept` of the same quest earlier in the same chapter or a previous one, unless the quest is item-started;
    - no `accept` comes after its `turnin`.

    Every violation prints `<file>:<line> <message>`, and the exit code is 1 if there is any.

- [ ] **Step 1: Write the failing tests.**
  - `emit_round_trip` (the emitted string loads with a stub `Q:RegisterGuide` and gives the same steps).
  - `validator_flags_turnin_without_accept` (on a temp guide, the exit code is 1 and the message contains "turnin without accept").
  - `classquests_warlock_alliance` (the generated data for WARLOCK holds a chain containing 1598).
- [ ] **Step 2: Run to verify they fail.**
- [ ] **Step 3: Implement the files.** Then run `luajit tools/routebuilder/build.lua --faction Alliance --only A_DwarfGnome_01` and `luajit tools/validate_guides.lua`. Expected: one guide file is written, and the validator exits 0.
- [ ] **Step 4: Run all tests.** Run `luajit tools/routebuilder/tests/run.lua && luajit tests/run.lua`. Expected: all PASS.

---

### Task 14: Alliance routes 1-30 (Dwarf/Gnome first)

**Files:**
- Create or modify:
  - `tools/routebuilder/plans.lua` (Alliance entries);
  - generated `Questify/Guides/Alliance/*.lua`, `Questify/Guides/ClassQuestData.lua`, `docs/routes/A_*.md`;
  - `tools/routebuilder/overrides.lua`, which holds hand fixes applied after generation:
    - `force = { [questId] = true }`;
    - `drop = { [questId] = "reason" }`;
    - `pin = { [questId] = {mapId, x, y} }` for objective sites;
    - `insertAfter = { [planId] = { {afterQuestTurnin = id, step = {...}} } }`.

  `build.lua` reads `overrides.lua`.

- [ ] **Step 1: Generate the Alliance chapters.** Order: Dwarf/Gnome (`A_DwarfGnome_01`… through the trunk to level 30), then Human, then Night Elf. Run `luajit tools/routebuilder/build.lua --faction Alliance` and `luajit tools/validate_guides.lua`. Expected: the validator exits 0, and every chapter's simulated `endLevel` is at least its `maxLevel − 1`.
- [ ] **Step 2: Review each chapter report** (`docs/routes/A_*.md`) against these checks, and fix with `overrides.lua`, then regenerate:
  - no back-and-forth longer than 600 yd that a reorder would remove;
  - the 6-slot bag quest 97277 is kept;
  - Dwarf Shaman totem quests are not in the route (they belong to class quests);
  - Hall of Thanes pre-quests 96391-96393 are kept as `optional` with `dungeon = "Hall of Thanes"`;
  - flight paths are picked up in Kharanos, Ironforge, Thelsamar, Stormwind, Sentinel Hill, Menethil, Auberdine, Lakeshire, Darkshire, Astranaar and Southshore, each when first passed;
  - the Menethil–Auberdine boat (and Forever's Stormwind–Auberdine boat if it is faster) is used for Darkshore;
  - the zone order follows spec § 6 unless a report shows a better rate, in which case note it in the report.

  Use public guides only to check facts (quest exists, NPC location), never to copy order or text.
- [ ] **Step 3: Load check.** Run `luajit tests/run.lua` (the boot test loads `Guides.xml` with every guide). Expected: all PASS, no `RegisterGuide` errors printed.

---

### Task 15: Horde routes 1-30

Same as Task 14, for the Horde plans:
- starts:
  - Orc/Troll: Valley of Trials, then Durotar;
  - Tauren: Camp Narache, then Mulgore;
  - Undead: Deathknell, Tirisfal, then Silverpine 12-14;
- then the Barrens trunk to 30, per spec § 6.

Flight paths to collect when first passed: Orgrimmar, Crossroads, Thunder Bluff, Undercity, the Sepulcher, Camp Taurajo, Ratchet, Splintertree, Tarren Mill, Freewind Post and Sun Rock. Use the zeppelins Orgrimmar–Undercity. Use the Ruins of Lordaeron quests as `optional`.

- [ ] **Step 1: Generate the Horde chapters.** Run `luajit tools/routebuilder/build.lua --faction Horde`, then `luajit tools/validate_guides.lua`. Expected: exit 0.
- [ ] **Step 2: Review the reports and fix with overrides** (same checks as Task 14, with Horde hubs).
- [ ] **Step 3: Load check.** Run `luajit tests/run.lua`. Expected: all PASS.

---

### Task 16: Skyborne routes

Plans `A_Skyborne_01..` and `H_Skyborne_01..`:
- Zephras Isle (uiMap 2521, 1-13), with races `{"Skyborne"}`;
- then the boat (Valanaar–Zephras route) into each faction trunk at the chapter matching level 13.

- [ ] **Step 1: Generate and validate.** Run `luajit tools/routebuilder/build.lua --faction all`, then `luajit tools/validate_guides.lua`. Expected: exit 0.
- [ ] **Step 2: Review and fix.**
- [ ] **Step 3: Load check.** Run `luajit tests/run.lua`. Expected: all PASS.

---

### Task 17: Packaging and release check

**Files:**
- Create: `.pkgmeta`, `tools/package.sh`, `CHANGELOG.md`.

**Content:**
- `.pkgmeta`:
  - `package-as: Questify`;
  - `required-dependencies: [questiedb]` (confirm the slug on CurseForge before publishing; leave a `# TODO confirm slug` comment if unconfirmed);
  - `optional-dependencies: [shortest-path-forever, waypointui, tomtom]`;
  - `ignore: [docs, tools, tests, .pkgmeta, CHANGELOG.md]`.
- `tools/package.sh`:
  1. run `tools/check_syntax.sh`, `luajit tests/run.lua` and `luajit tools/validate_guides.lua`;
  2. zip `Questify/` to `dist/Questify-<version from TOC>.zip`, with the `Questify` folder at the zip root.
- `CHANGELOG.md`: 0.1.0 with the feature list and the known limits from spec § 8.

- [ ] **Step 1: Run the release check.** Run `tools/package.sh`. Expected: all checks pass and the zip exists.
- [ ] **Step 2: Inspect the zip.** Run `unzip -l dist/Questify-0.1.0.zip | head`. Expected: the paths start with `Questify/`, and there is no `tests/` or `tools/`.
- [ ] **Step 3: Install note.** Add to `README.md` the manual install steps:
  1. unzip into `World of Warcraft\_forever_\Interface\AddOns\`;
  2. install QuestieDB from CurseForge;
  3. optionally install ShortestPath Forever, WaypointUI and TomTom.

  Also add the first-launch checklist to verify in game:
  - `/tm` works solo;
  - the native marker shows;
  - auto-accept works;
  - no errors in combat.
