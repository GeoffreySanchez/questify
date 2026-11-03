-- tests/mock_era.lua : saveur « Classic Era » (1.15.9) du mock. Utilisation dans un test :
--   local Era = dofile(Mock.root .. "/tests/mock_era.lua")
--   Era.install()            -- après Mock.reset() (fait par le lanceur), avant Mock.loadAddon
--   local Q = Mock.loadAddon(Era.TOC, opts)
-- Retire les API modernes absentes d'Era et fournit leurs équivalents Era, sur les mêmes données
-- (Mock.quests, Mock.items, Mock.greeting...). Sources : branche classic_era de wow-ui-source
-- (1.15.9.70576) : Blizzard_APIDocumentationGenerated, QuestLogFrame.lua et QuestFrame.lua (Vanilla).

local Era = {}

Era.TOC = "Questify_Vanilla/Questify_Vanilla_Vanilla.toc"
Era.FOREVER_TOC = "Questify_Vanilla/Questify_Vanilla.toc"
Era.INTERFACE = 11509

local function sortedLogIds()
  local ids = {}
  for id in pairs(Mock.quests.log) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

local function itemInfo(item)
  local i = Mock.items[item]
  if not i and type(item) == "string" then
    local id = tonumber(item:match("item:(%d+)"))
    i = id and Mock.items[id]
  end
  return i
end

function Era.install()
  Mock.interface = Era.INTERFACE
  GetBuildInfo = function() return "1.15.9", "70576", "Oct 26 2026", Mock.interface end

  -- Journal de quêtes : pas de C_QuestLog.GetInfo / GetLogIndexForQuestID / IsComplete /
  -- GetTitleForQuestID ; GetQuestLogTitle (questID en 8e valeur, isComplete 1 / -1 / nil).
  local QL = C_QuestLog
  for _, name in ipairs({ "GetInfo", "GetNumQuestLogEntries", "GetLogIndexForQuestID", "GetQuestIDForLogIndex",
                          "IsComplete", "ReadyForTurnIn", "GetTitleForQuestID", "GetQuestTagInfo",
                          "GetSelectedQuest", "GetAllCompletedQuestIDs" }) do
    QL[name] = nil
  end
  QL.GetQuestInfo = function(id)
    local q = Mock.quests.log[id]
    return (q and q.title) or Mock.titles[id]
  end
  GetNumQuestLogEntries = function() local n = #sortedLogIds(); return n, n end
  GetQuestLogTitle = function(i)
    local id = sortedLogIds()[i]
    if not id then return nil end
    local q = Mock.quests.log[id]
    local complete = nil
    if q.failed then complete = -1 elseif q.complete then complete = 1 end
    return q.title or Mock.titles[id], q.level or 1, nil, false, false, complete, 0, id
  end
  GetQuestLogIndexByID = function(id)
    for i, qid in ipairs(sortedLogIds()) do if qid == id then return i end end
    return 0
  end

  -- Fenêtre sans dialogue : pas de GetActiveQuestID ; GetAvailableQuestInfo sans questID.
  GetActiveQuestID = nil
  GetAvailableQuestInfo = function(i)
    local q = Mock.greeting.available[i]
    if not q then return nil end
    return q.isTrivial or false, false, q.isRepeatable or false, q.isLegendary or false
  end

  -- Objets : pas de C_Item.GetItemStats ; GetItemStats et GetItemInfo globaux.
  C_Item.GetItemStats = nil
  GetItemStats = function(item)
    local i = itemInfo(item)
    if not i then return nil end
    local out = {}
    for k, v in pairs(i.stats or {}) do out[k] = v end
    return out
  end
  GetItemInfo = C_Item.GetItemInfo

  -- Pas de repère de carte ni de marqueur 3D.
  C_Map.SetUserWaypoint, C_Map.ClearUserWaypoint = nil, nil
  C_Map.CanSetUserWaypointOnMap, C_Map.HasUserWaypoint = nil, nil
  C_SuperTrack = nil
  UiMapPoint = nil

  -- Suivi de quêtes de Blizzard sur Era (Vanilla/QuestLogFrame.xml), sous la minimap.
  QuestWatchFrame = Mock.newObject("Frame", "QuestWatchFrame", UIParent)

  -- Absents d'Era (ou non garantis sur 1.15.8) : l'addon doit s'en passer.
  UnitCreatureID = nil
  issecretvalue = nil
  canaccessvalue = nil
  C_SkillInfo = nil
  C_TooltipInfo = nil
  TooltipDataProcessor = nil
  MenuUtil = nil
end

-- Vrai si les API modernes sont présentes (après Mock.reset ou la remise à zéro de Mock.reload).
local function modernApi() return C_SuperTrack ~= nil or C_QuestLog.GetInfo ~= nil end

-- Charge l'addon avec la TOC Era (installe la saveur Era si besoin).
function Era.load(opts)
  if modernApi() then Era.install() end
  return Mock.loadAddon(Era.TOC, opts)
end

-- Exécute fn avec Mock.loadAddon redirigé de la TOC Forever vers la TOC Era (tests existants
-- rejoués tels quels). Mock.reload réinstalle l'API moderne : la saveur Era est alors remise.
-- La redirection est retirée ensuite, même en cas d'échec.
function Era.withEraToc(fn, ...)
  local original = Mock.loadAddon
  Mock.loadAddon = function(toc, opts)
    if toc == Era.FOREVER_TOC or toc == "Questify_Vanilla/Questify_Vanilla_Camelot.toc" then toc = Era.TOC end
    if toc == Era.TOC and modernApi() then Era.install() end
    return original(toc, opts)
  end
  local ok, err = pcall(fn, ...)
  Mock.loadAddon = original
  if not ok then error(err, 0) end
end

return Era
