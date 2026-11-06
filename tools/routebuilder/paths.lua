-- tools/routebuilder/paths.lua : rejeu des étapes d'une suite de chapitres pour une race donnée.
--
-- Partagé par build.lua (filtres de race des chapitres communs) et tools/validate_guides.lua
-- (contrôles par parcours de race).
--
-- paths.replay(D, W, faction, race, chapters, onIssue)
--   chapters = { { id = planId, steps = {...}, races = {...}|nil }, ... } dans l'ordre du parcours ;
--   onIssue(chapterIndex, stepIndex, message) est appelé pour chaque étape invalide sur ce parcours.
--   Les étapes dont le filtre `race` exclut la race sont ignorées ; une étape invalide n'est pas
--   appliquée (la quête n'entre pas dans le journal, etc.), ce qui propage l'erreur aux suites.
--
-- Règles :
--   accept   : quête éligible pour la race ; pas déjà dans le journal ni rendue ; tous les preGroup
--              rendus ; un des preSingle rendu ; aucune quête exclusive rendue ou dans le journal ;
--              journal de LOG_CAP quêtes au plus.
--   complete : quête dans le journal (pas après son rendu).
--   turnin   : quête dans le journal (pas deux fois).
--   obj      : index présent dans la liste des objectifs de la quête.
--   fly      : nœud de destination (`node`, à défaut nom dans note) découvert par une étape fp antérieure
--              du parcours.
--   hearth   : pierre liée par une étape sethearth antérieure, sur la même carte.
--   donjon   : une quête de donjon prise au passage (accept `optional` + `dungeon`, zone de donjon de
--              QuestieDB) quitte le journal en tête d'un chapitre de niveau minimal >= DUNGEON_RELEASE_FROM
--              quand son niveau est <= minLevel - DUNGEON_RELEASE_GAP (abandon, même règle que
--              sim.releaseDungeonQuests ; chapters[i].minLevel requis).

local qdb = require("qdb")

local paths = {}
paths.LOG_CAP = 20
paths.DUNGEON_RELEASE_FROM = 30
paths.DUNGEON_RELEASE_GAP = 4

local function raceBit(race, faction)
  if race == "Skyborne" then return faction == "Horde" and qdb.RACE_BITS.SkyborneH or qdb.RACE_BITS.SkyborneA end
  return qdb.RACE_BITS[race]
end
paths.raceBit = raceBit

local function hasRace(list, race)
  for _, r in ipairs(list) do if r == race then return true end end
  return false
end
paths.hasRace = hasRace

-- Nœud de vol (id) d'une étape fp : nœud de la faction le plus proche (100 yd au plus).
local function fpNode(W, faction, m, x, y)
  local c, wx, wy = W.toWorld(m, x, y)
  if not c then return nil end
  local node, d = W.nearestTaxi(c, wx, wy, faction)
  if node and d <= 100 then return node.id end
  return nil
end

local function nodeByName(W, name)
  for _, id in ipairs(qdb.sortedKeys(W.taxi.nodes)) do
    if W.taxi.nodes[id].name == name then return id end
  end
  return nil
end

function paths.replay(D, W, faction, race, chapters, onIssue)
  local log, nlog, done = {}, 0, {}
  local known, hearthMap = {}, nil
  local bit = raceBit(race, faction)
  local inDungeon = {} -- quêtes de donjon prises au passage, dans le journal
  for ci, ch in ipairs(chapters) do
    local minLevel = ch.minLevel or 0
    if minLevel >= paths.DUNGEON_RELEASE_FROM then
      for _, qid in ipairs(qdb.sortedKeys(inDungeon)) do
        local q = D.quests[qid]
        if log[qid] and q and (q.level or 0) <= minLevel - paths.DUNGEON_RELEASE_GAP then
          log[qid] = nil; nlog = nlog - 1; inDungeon[qid] = nil
        end
      end
    end
    for si, s in ipairs(ch.steps or {}) do
      local applies = not s.race or hasRace(s.race, race)
      local act, qid = s[1], s[2]
      if applies then
        local function bad(msg) onIssue(ci, si, msg) end
        if act == "accept" or act == "complete" or act == "turnin" then
          local q = D.quests[qid]
          if not q then bad(("unknown quest %s"):format(tostring(qid)))
          else
            if s.obj then
              local ok = false
              for _, o in ipairs(q.objectives.list) do if o.index == s.obj then ok = true end end
              if not ok then bad(("obj=%s is not an objective of quest %d (%d objectives)"):format(tostring(s.obj), qid, #q.objectives.list)) end
            end
            if act == "accept" then
              local why
              if (q.races or 0) ~= 0 and bit and not qdb.hasBit(q.races, bit) then why = "quest not available to the race"
              elseif done[qid] then why = "accept after turnin"
              elseif log[qid] then why = "accept while already in the quest log" end
              if not why then
                for _, p in ipairs(q.preGroup) do if not done[p] then why = ("prerequisite %d not turned in"):format(p) end end
              end
              if not why and #q.preSingle > 0 then
                local any = false
                for _, p in ipairs(q.preSingle) do if done[p] then any = true end end
                if not any then why = ("no prerequisite (%s) turned in"):format(table.concat(q.preSingle, ",")) end
              end
              if not why then
                for _, x in ipairs(q.exclusiveTo) do if done[x] or log[x] then why = ("exclusive with quest %d"):format(x) end end
              end
              if not why and nlog + 1 > paths.LOG_CAP then why = ("quest log full (%d quests)"):format(nlog) end
              if why then bad(("accept %d: %s"):format(qid, why))
              else
                log[qid] = true; nlog = nlog + 1
                local z = q.zoneOrSort or 0
                if s.optional and s.dungeon and z > 0 and D.dungeonAreas and D.dungeonAreas[z] then inDungeon[qid] = true end
              end
            elseif act == "complete" then
              if done[qid] then bad(("complete %d after its turnin"):format(qid))
              elseif not log[qid] then bad(("complete %d without accept"):format(qid)) end
            else
              if done[qid] then bad(("turnin %d twice"):format(qid))
              elseif not log[qid] then bad(("turnin %d without accept"):format(qid))
              else log[qid] = nil; nlog = nlog - 1; done[qid] = true; inDungeon[qid] = nil end
            end
          end
        elseif act == "fp" then
          local n = fpNode(W, faction, s[2], s[3], s[4])
          if n then known[n] = true end
        elseif act == "fly" then
          local n = s.node or (s.note and nodeByName(W, s.note))
          if n and not known[n] then
            onIssue(ci, si, ("fly to %s: flight path not discovered on this path"):format(s.note or tostring(n)))
          end
        elseif act == "sethearth" then
          hearthMap = s[2]
        elseif act == "hearth" then
          if not hearthMap then onIssue(ci, si, "hearth before any sethearth on this path")
          elseif hearthMap ~= s[2] then onIssue(ci, si, ("hearth to map %s but the stone is bound on map %s"):format(tostring(s[2]), tostring(hearthMap))) end
        end
      end
    end
  end
  return { log = log, done = done, known = known }
end

return paths
