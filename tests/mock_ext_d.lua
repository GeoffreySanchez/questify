-- tests/mock_ext_d.lua
-- Compléments du mock pour les tests du flux D (interface). Utilisation dans un test :
--   local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")
--   Ext.install()                       -- après Mock.reset() (fait par le lanceur), avant Mock.loadAddon
--   local cq = Ext.fakeClassQuests(Q, rows)   -- après le chargement
-- Les modules du flux C (ClassQuests, Nav, Telemetry) sont remplacés méthode par méthode :
-- si le vrai module existe déjà, seules les méthodes utiles aux tests sont surchargées.

local Ext = {}

-- Infobulle enregistrée : Mock.tooltip = { owner, lines = { "texte", ... }, items = { itemId, ... } }
function Ext.install()
  Mock.combatCalls = {}
  Mock.tooltip = { owner = nil, lines = {}, items = {}, shown = false }
  local tip = GameTooltip
  rawset(tip, "SetOwner", function(_, owner) Mock.tooltip.owner = owner end)
  rawset(tip, "ClearLines", function() Mock.tooltip.lines = {} end)
  rawset(tip, "SetText", function(_, text) Mock.tooltip.lines = { tostring(text) } end)
  rawset(tip, "AddLine", function(_, text) local l = Mock.tooltip.lines; l[#l + 1] = tostring(text) end)
  rawset(tip, "AddDoubleLine", function(_, a, b)
    local l = Mock.tooltip.lines
    l[#l + 1] = tostring(a) .. " " .. tostring(b)
  end)
  rawset(tip, "SetItemByID", function(_, id)
    local items = Mock.tooltip.items
    items[#items + 1] = id
    Mock.record("GameTooltip:SetItemByID", id)
  end)
  rawset(tip, "Show", function() Mock.tooltip.shown = true end)
  rawset(tip, "Hide", function() Mock.tooltip.shown = false end)
end

-- Espion de combat : enregistre dans Mock.combatCalls ("<nom>:<méthode>") chaque appel qui
-- déplace, redimensionne, affiche, cache ou modifie les attributs des cadres donnés pendant que
-- Mock.player.combat est vrai. Les cadres sécurisés (et leur parent) ne doivent en recevoir aucun.
local SPIED = { "SetPoint", "ClearAllPoints", "SetAllPoints", "Show", "Hide", "SetShown", "SetSize",
  "SetWidth", "SetHeight", "SetScale", "SetAttribute", "SetParent" }
function Ext.spyCombat(frames)
  Mock.combatCalls = Mock.combatCalls or {}
  for _, f in ipairs(frames) do
    for _, name in ipairs(SPIED) do
      local orig = f[name]
      rawset(f, name, function(self, ...)
        if Mock.player.combat then
          local list = Mock.combatCalls
          list[#list + 1] = tostring(rawget(self, "_name") or rawget(self, "_type")) .. ":" .. name
        end
        return orig(self, ...)
      end)
    end
  end
  return Mock.combatCalls
end

-- Vrai si une ligne de l'infobulle contient le texte (codes de couleur ignorés).
function Ext.tooltipHas(text)
  for _, line in ipairs(Mock.tooltip and Mock.tooltip.lines or {}) do
    local plain = line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    if line:find(text, 1, true) or plain:find(text, 1, true) then return true end
  end
  return false
end

-- Chaîne de classe de la fixture (démoniste : 1598 puis 1599).
function Ext.warlockChain()
  return {
    key = "WARLOCK_1598",
    title = "The Stolen Tome",
    faction = "Alliance",
    level = 4,
    quests = { 1598, 1599 },
    rewards = { [1598] = { items = { 6900, 6901 }, xp = 250 }, [1599] = { items = { 6902 }, xp = 300 } },
  }
end

-- Remplace Q.ClassQuests par un faux qui enregistre ses appels dans Mock.calls
-- ("ClassQuests:Add", "ClassQuests:Ignore", "ClassQuests:Unignore", "ClassQuests:MarkSeen").
-- rows = { { chain = ..., state = "available" }, ... }
-- Alerts() renvoie des lignes { chain, state } comme le vrai module du flux C ; avec
-- bareChains = true, il renvoie les chaînes seules (forme décrite dans l'interface du contrôleur).
function Ext.fakeClassQuests(Q, rows, bareChains)
  local cq = Q.ClassQuests or {}
  Q.ClassQuests = cq
  local seen = {}
  local function find(key)
    for _, r in ipairs(rows) do if r.chain.key == key then return r end end
  end
  cq.List = function() return rows end
  cq.Alerts = function()
    local out = {}
    for _, r in ipairs(rows) do
      if r.state == "available" and not seen[r.chain.key] then out[#out + 1] = bareChains and r.chain or r end
    end
    return out
  end
  cq.MarkSeen = function(_, key)
    seen[key] = true
    Mock.record("ClassQuests:MarkSeen", key)
  end
  cq.Add = function(_, key)
    Mock.record("ClassQuests:Add", key)
    local r = find(key)
    if r then r.state = "added" end
    Q:Fire("CLASSQUESTS_CHANGED")
  end
  cq.Ignore = function(_, key)
    Mock.record("ClassQuests:Ignore", key)
    local r = find(key)
    if r then r.state = "ignored" end
    Q:Fire("CLASSQUESTS_CHANGED")
  end
  cq.Unignore = function(_, key)
    Mock.record("ClassQuests:Unignore", key)
    local r = find(key)
    if r then r.state = "available" end
    Q:Fire("CLASSQUESTS_CHANGED")
  end
  return cq
end

-- Faux Q.Nav:Detect (le reste du vrai module, s'il existe, est conservé).
function Ext.fakeNavDetect(Q, detected)
  Q.Nav = Q.Nav or {}
  Q.Nav.Detect = function()
    local out = { native = true }
    for k, v in pairs(detected) do out[k] = v end
    return out
  end
end

-- Faux Q.Telemetry:Export.
function Ext.fakeTelemetry(Q, text)
  Q.Telemetry = Q.Telemetry or {}
  Q.Telemetry.Export = function() return text end
end

return Ext
