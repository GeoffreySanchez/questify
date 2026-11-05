local addonName, Q = ...

-- Mise en forme des étapes : titre court (points de navigation) et texte coloré (suivi).
-- Couleurs : quêtes |cffffd100, PNJ |cff00ff96, monstres |cffff6060, objets du monde |cff66bbff.
local Format = {}
Q.Format = Format

local NOTE_COLOR = "|cff999999"
local DONE_COLOR = "|cff808080"
local TODO_COLOR = "|cffffffff"

local ICONS = {
  accept = "Interface\\GossipFrame\\AvailableQuestIcon",
  turnin = "Interface\\GossipFrame\\ActiveQuestIcon",
  complete = "Interface\\Icons\\INV_Sword_04",
  ["goto"] = "Interface\\Icons\\Ability_Rogue_Sprint",
  boat = "Interface\\Icons\\Ability_Rogue_Sprint",
  fp = "Interface\\Minimap\\Tracking\\FlightMaster",
  fly = "Interface\\Minimap\\Tracking\\FlightMaster",
  sethearth = "Interface\\Icons\\INV_Misc_Rune_01",
  hearth = "Interface\\Icons\\INV_Misc_Rune_01",
  level = "Interface\\Icons\\INV_Sword_04",
  note = "Interface\\Icons\\INV_Misc_Note_01",
  train = "Interface\\Icons\\INV_Misc_Book_11",
  trainprof = "Interface\\Icons\\INV_Misc_Book_08",
}
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function fmt(template, ...)
  local ok, s = pcall(string.format, template, ...)
  if ok then return s end
  return tostring(template)
end

local function stepOf(entry)
  if type(entry) ~= "table" then return nil end
  if type(entry.step) == "table" then return entry.step end
  if type(entry.action) == "string" then return entry end
  return nil
end

-- Nom du donneur (ou du destinataire) : celui vers lequel la navigation pointe, sinon le premier.
-- -> nom, "npc"|"object"|"item"|nil
local function giverName(entry, step, list)
  if not list then return nil end
  if Q.Targets and type(entry.step) == "table" then
    local target = Q.Targets:ForEntry(entry)
    if target and target.id then
      if target.kind == "npc" then return Q.QDB:NpcName(target.id), "npc" end
      if target.kind == "object" then return Q.QDB:ObjectName(target.id), "object" end
    end
  end
  if list.npcs and list.npcs[1] then return Q.QDB:NpcName(list.npcs[1]), "npc" end
  if list.objects and list.objects[1] then return Q.QDB:ObjectName(list.objects[1]), "object" end
  if list.items and list.items[1] then return Q.QDB:ItemName(list.items[1]), "item" end
  return nil
end

-- Lignes d'objectifs : celles du journal si la quête y est, sinon les cibles QuestieDB.
-- -> { { text, index } } ; index = n° de l'objectif du journal, sinon ordre QuestieDB (comme
-- objIndex dans Q.Targets).
local function objectiveList(step)
  local L = Q.L
  local id = step.questId
  local lines = {}
  if Q.Progress and Q.Progress:InLog(id) then
    local objs = C_QuestLog.GetQuestObjectives(id) or {}
    for i, o in ipairs(objs) do
      if (not step.obj or step.obj == i) and type(o.text) == "string" and o.text ~= "" then
        lines[#lines + 1] = { text = (o.finished and DONE_COLOR or TODO_COLOR) .. o.text .. "|r", index = i }
      end
    end
  end
  if #lines == 0 then
    local q = Q.QDB:Quest(id)
    if q then
      for ordinal, o in ipairs(q.objectives.ordered) do
        if not step.obj or step.obj == ordinal then
          if o.kind == "creature" then
            lines[#lines + 1] = { text = fmt(L.OBJ_KILL, Q.QDB:NpcName(o.ids[1])), index = ordinal }
          elseif o.kind == "killCredit" then
            lines[#lines + 1] = { text = fmt(L.OBJ_KILL, o.text or Q.QDB:NpcName(o.base or o.ids[1])), index = ordinal }
          elseif o.kind == "object" then
            lines[#lines + 1] = { text = fmt(L.OBJ_USE, Q.QDB:ObjectName(o.ids[1])), index = ordinal }
          elseif o.kind == "item" then
            local item = Q.QDB:Item(o.ids[1])
            if item and #item.npcDrops == 0 and item.objectDrops[1] then
              -- objet ramassé sur un objet du monde (coffre, plante) : « Utiliser : <objet> »
              lines[#lines + 1] = { text = fmt(L.OBJ_USE, Q.QDB:ObjectName(item.objectDrops[1])), index = ordinal }
            else
              lines[#lines + 1] = { text = fmt(L.OBJ_LOOT, Q.QDB:ItemName(o.ids[1])), index = ordinal }
            end
          end
        end
      end
    end
  end
  return lines
end

local OBJ_INDENT = "  "

-- Nom du métier suivi du rang entre parenthèses quand il dépasse Apprenti.
local function withRank(name, rank)
  if type(rank) == "number" and rank > 1 then
    return name .. " (" .. (Q.L["PROF_RANK_" .. rank] or rank) .. ")"
  end
  return name
end

local function mainText(entry, step)
  local L = Q.L
  local a = step.action
  if a == "accept" or a == "turnin" then
    local q = Q.QDB:Quest(step.questId)
    local name = Q.QDB:QuestName(step.questId)
    local who, kind = giverName(entry, step, q and (a == "accept" and q.starters or q.finishers))
    if a == "accept" then
      if kind == "npc" then return fmt(L.STEP_ACCEPT, name, who) end
      if kind == "object" then return fmt(L.STEP_ACCEPT_OBJECT, name, who) end
      if kind == "item" then return fmt(L.STEP_ACCEPT_ITEM, name, who) end
      return fmt(L.STEP_ACCEPT_ANY, name)
    end
    if kind == "npc" then return fmt(L.STEP_TURNIN, name, who) end
    if kind == "object" then return fmt(L.STEP_TURNIN_OBJECT, name, who) end
    return fmt(L.STEP_TURNIN_ANY, name)
  elseif a == "complete" then
    return fmt(L.STEP_COMPLETE, Q.QDB:QuestName(step.questId)), objectiveList(step)
  elseif a == "goto" then
    return L.STEP_GOTO
  elseif a == "fp" then
    return L.STEP_FP
  elseif a == "sethearth" then
    return L.STEP_SETHEARTH
  elseif a == "hearth" then
    return L.STEP_HEARTH
  elseif a == "fly" then
    return fmt(L.STEP_FLY, Q.Maps:MapName(step.mapId))
  elseif a == "boat" then
    return L.STEP_BOAT
  elseif a == "level" then
    return fmt(L.STEP_LEVEL, step.level or 0)
  elseif a == "note" then
    return step.text or ""
  elseif a == "train" then
    local who = giverName(entry, step, { npcs = Q.Trainer and Q.Trainer:TrainerIds() or {} })
    if who then return fmt(L.STEP_TRAIN, who) end
    return L.STEP_TRAIN_ANY
  elseif a == "trainprof" then
    local P = Q.Professions
    local prof = P and P:Name(step.prof) or tostring(step.prof)
    prof = withRank(prof, step.rank)
    local who = giverName(entry, step, { npcs = P and P:TrainerIds(step.prof) or {} })
    if who then return fmt(L.STEP_TRAINPROF, prof, who) end
    return fmt(L.STEP_TRAINPROF_ANY, prof)
  end
  return tostring(a)
end

-- Q.Format:StepParts(entry) -> { head = texte, objectives = { { text, index } }, tail = { lignes } }
-- Les lignes d'objectifs sont sans retrait ; le suivi les met en page et place sous chacune les
-- monstres à tuer.
function Format:StepParts(entry)
  local parts = { head = "", objectives = {}, tail = {} }
  local step = stepOf(entry)
  if not step then return parts end
  if type(entry.step) ~= "table" then entry = { step = step } end
  local ok, head, objectives = pcall(mainText, entry, step)
  if not ok then
    Q:ReportError(head)
    head, objectives = tostring(step.action), nil
  end
  parts.head = head
  parts.objectives = type(objectives) == "table" and objectives or {}
  if step.dungeon then
    parts.tail[#parts.tail + 1] = NOTE_COLOR .. fmt(Q.L.DUNGEON_TAG, step.dungeon) .. "|r"
  end
  if step.note then
    parts.tail[#parts.tail + 1] = NOTE_COLOR .. step.note .. "|r"
  end
  return parts
end

-- Ligne d'objectif telle qu'affichée sous le titre de l'étape (avec son retrait).
function Format:ObjectiveLine(text)
  return OBJ_INDENT .. tostring(text or "")
end

-- Q.Format:StepText(entry) -> texte coloré pour le suivi (accepte aussi une étape seule).
function Format:StepText(entry)
  local parts = self:StepParts(entry)
  local lines = { parts.head }
  for _, o in ipairs(parts.objectives) do lines[#lines + 1] = self:ObjectiveLine(o.text) end
  for _, line in ipairs(parts.tail) do lines[#lines + 1] = line end
  return table.concat(lines, "\n")
end

local function titleText(step)
  local L = Q.L
  local a = step.action
  if a == "accept" then return fmt(L.TITLE_ACCEPT, Q.QDB:QuestName(step.questId)) end
  if a == "turnin" then return fmt(L.TITLE_TURNIN, Q.QDB:QuestName(step.questId)) end
  if a == "complete" then return fmt(L.TITLE_COMPLETE, Q.QDB:QuestName(step.questId)) end
  if (a == "goto" or a == "boat") and step.note then return step.note end
  if a == "goto" then return L.STEP_GOTO end
  if a == "boat" then return L.STEP_BOAT end
  if a == "fp" then return L.STEP_FP end
  if a == "sethearth" then return L.STEP_SETHEARTH end
  if a == "hearth" then return L.STEP_HEARTH end
  if a == "fly" then return fmt(L.STEP_FLY, Q.Maps:MapName(step.mapId)) end
  if a == "level" then return fmt(L.STEP_LEVEL, step.level or 0) end
  if a == "note" then return step.text or "" end
  if a == "train" then return L.TITLE_TRAIN end
  if a == "trainprof" then
    local name = Q.Professions and Q.Professions:Name(step.prof) or tostring(step.prof)
    name = withRank(name, step.rank)
    return fmt(L.TITLE_TRAINPROF, name)
  end
  return tostring(a)
end

-- Q.Format:StepTitle(entry) -> titre court sans couleur (points de navigation).
function Format:StepTitle(entry)
  local step = stepOf(entry)
  if not step then return "" end
  local ok, text = pcall(titleText, step)
  if not ok then
    Q:ReportError(text)
    text = tostring(step.action)
  end
  return Q.Util.StripColors(text)
end

-- Q.Format:ActionIcon(action) -> texture du jeu.
function Format:ActionIcon(action)
  return ICONS[action] or UNKNOWN_ICON
end

-- Q.Format:Reason(reason) -> texte lisible pour la raison renvoyée par Progress:State.
function Format:Reason(reason)
  if type(reason) ~= "string" or reason == "" then return "" end
  local level = reason:match("^level (%d+)$")
  if level then return fmt(Q.L.REASON_LEVEL, tonumber(level)) end
  local key = "REASON_" .. reason:upper()
  local text = rawget(Q.L, key)
  return text or reason
end
