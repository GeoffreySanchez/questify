-- tests/mock_ext_playerspells.lua
-- Fenêtre des talents du jeu (Blizzard_PlayerSpells, variante Camelot de Forever) pour les tests de
-- UI/TalentFrameHook.lua. Utilisation dans un test :
--   local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")          -- infobulle enregistrée
--   local PS = dofile(Mock.root .. "/tests/mock_ext_playerspells.lua")
--   Ext.install(); local w = PS.install(opts)    -- après Mock.reset(), avant ou après Mock.loadAddon
-- opts :
--   nodes = { nodeID, … }    nœuds posés à chaque affichage de TalentsFrame (comme refreshOnShow du jeu)
--   noTalentsFrame = true    PlayerSpellsFrame sans affichage des talents
--   noButtonApi = true       TalentsFrame sans GetTalentButtonByNodeID
--   missingTemplates = { [nom] = true }   C_XMLUtil.GetTemplateInfo(nom) renvoie nil (modèle absent du client)
--   noInspectApi = true      TalentsFrame sans IsInspecting ni IsActiveTabSelected
-- w.inspecting = true : TalentsFrame:IsInspecting() vrai ; w.otherSpecTab = true : IsActiveTabSelected() faux.
-- w = { host = PlayerSpellsFrame, talents = TalentsFrame, buttons = { [nodeID] = bouton actif } }.
--   PS.open(w) / PS.close(w)      le jeu montre / cache la fenêtre puis l'affichage des talents
--   PS.layout(w, nodes)           le jeu relâche tous les boutons (pool) puis en pose un par nœud. Relâchés du
--                                 dernier nœud au premier, repris du dernier relâché au premier : avec deux
--                                 nœuds, chaque nouvelle pose échange leurs boutons (déterministe).
--   PS.enter(button)              survol par le joueur : scripts OnEnter du bouton (celui du jeu, puis les crochets)
-- Le jeu fait lui-même Show, Hide et SetScript sur ses cadres : ces appels-là ne sont pas notés. Tout autre
-- appel (donc ceux de l'addon) à une méthode qui modifie un cadre de Blizzard est noté
-- "Blizzard:<méthode>" (Mock.callsTo) ; AddNamedTab et AddTab sur les TabSystem sont notés "AddNamedTab" et
-- "AddTab" ; HookScript est noté "Blizzard:HookScript" (autorisé). Un clic sur un talent appelle le script
-- OnClick du jeu, noté "Blizzard:TalentClick".

local PS = {}
local unpack = unpack or table.unpack

local SPIED = { "SetScript", "Show", "Hide", "SetShown", "SetPoint", "ClearAllPoints", "SetAllPoints", "SetParent",
  "SetSize", "SetWidth", "SetHeight", "SetScale", "SetAlpha", "SetFrameLevel", "SetFrameStrata", "EnableMouse",
  "SetAttribute", "RegisterForClicks" }

-- Profondeur d'exécution « par le jeu » : les appels faits par le jeu ne sont pas notés.
local gameDepth = 0

local function asGame(fn, ...)
  gameDepth = gameDepth + 1
  local res = { pcall(fn, ...) }
  gameDepth = gameDepth - 1
  if not res[1] then error(res[2], 0) end
  return unpack(res, 2)
end

-- Script du jeu : son corps s'exécute « par le jeu ».
local function gameScript(fn)
  return function(...) return asGame(fn, ...) end
end

-- Espion : chaque méthode modifiante d'un cadre de Blizzard est notée si l'appel ne vient pas du jeu.
-- Les scripts déclenchés par l'appel (OnShow…) s'exécutent hors du mode « jeu » : un crochet de l'addon
-- appelé ainsi est noté s'il touche un cadre de Blizzard.
local function spy(obj, label)
  rawset(obj, "_blizzard", label)
  for _, m in ipairs(SPIED) do
    local orig = obj[m]
    rawset(obj, m, function(self, ...)
      if gameDepth == 0 then Mock.record("Blizzard:" .. m, label, ...) end
      local saved = gameDepth
      gameDepth = 0
      local res = { pcall(orig, self, ...) }
      gameDepth = saved
      if not res[1] then error(res[2], 0) end
      return unpack(res, 2)
    end)
  end
  local hook = obj.HookScript
  rawset(obj, "HookScript", function(self, name, fn)
    Mock.record("Blizzard:HookScript", label, name, self)
    return hook(self, name, fn)
  end)
  return obj
end
PS.spy = spy

local function setGameScript(obj, name, fn)
  rawget(obj, "_scripts")[name] = gameScript(fn)
end

local function newTabSystem(parent, label)
  local ts = Mock.newObject("Frame", nil, parent)
  rawset(ts, "_shown", false)
  rawset(ts, "AddNamedTab", function(...) Mock.record("AddNamedTab", label, ...) end)
  rawset(ts, "AddTab", function(...) Mock.record("AddTab", label, ...) end)
  return spy(ts, label)
end

-- Bouton de talent du jeu : nœud courant, infobulle et clic du jeu.
local function newButton(w)
  local b = Mock.newObject("Button", nil, w.talents.ButtonsParent)
  rawset(b, "GetNodeID", function(self) return rawget(self, "nodeID") end)
  setGameScript(b, "OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("talent " .. tostring(rawget(self, "nodeID")))
    GameTooltip:Show()
  end)
  setGameScript(b, "OnClick", function(self) Mock.record("Blizzard:TalentClick", rawget(self, "nodeID")) end)
  w.created[#w.created + 1] = b
  return spy(b, "TalentButton")
end

function PS.layout(w, nodes)
  asGame(function()
    local tf = w.talents
    for i = #w.order, 1, -1 do
      local b = w.buttons[w.order[i]]
      b:Hide()
      w.free[#w.free + 1] = b
    end
    w.buttons, w.order = {}, {}
    tf.nodeIDToButton = {}
    for _, nodeID in ipairs(nodes or {}) do
      local b = table.remove(w.free) or newButton(w)
      rawset(b, "nodeID", nodeID)
      b:Show()
      w.buttons[nodeID] = b
      w.order[#w.order + 1] = nodeID
      tf.nodeIDToButton[nodeID] = b
    end
  end)
end

function PS.install(opts)
  opts = opts or {}
  Mock.missingTemplates = opts.missingTemplates or {}
  C_XMLUtil = {
    GetTemplateInfo = function(name)
      if Mock.missingTemplates[name] then return nil end
      return { type = "Button", width = 0, height = 0 }
    end,
  }
  rawset(GameTooltip, "GetOwner", function() return Mock.tooltip and Mock.tooltip.owner end)

  local w = { buttons = {}, order = {}, free = {}, created = {}, nodes = opts.nodes or {} }
  local host = Mock.newObject("Frame", "PlayerSpellsFrame", UIParent)
  rawset(host, "_shown", false)
  host.TabSystem = newTabSystem(host, "PlayerSpellsFrame.TabSystem")
  w.host = spy(host, "PlayerSpellsFrame")
  if not opts.noTalentsFrame then
    local tf = Mock.newObject("Frame", nil, host)
    rawset(tf, "_shown", false)
    tf.TabSystem = newTabSystem(tf, "TalentsFrame.TabSystem")
    tf.ButtonsParent = spy(Mock.newObject("Frame", nil, tf), "TalentsFrame.ButtonsParent")
    tf.nodeIDToButton = {}
    if not opts.noButtonApi then
      rawset(tf, "GetTalentButtonByNodeID", function(self, nodeID) return self.nodeIDToButton[nodeID] end)
    end
    if not opts.noInspectApi then
      rawset(tf, "IsInspecting", function() return w.inspecting == true end)
      rawset(tf, "IsActiveTabSelected", function() return w.otherSpecTab ~= true end)
    end
    -- Comme le jeu (refreshOnShow) : chaque affichage relâche et repose les boutons.
    setGameScript(tf, "OnShow", function() PS.layout(w, w.nodes) end)
    setGameScript(tf, "OnHide", function() end)
    host.TalentsFrame = tf
    w.talents = spy(tf, "TalentsFrame")
  else
    rawset(host, "TalentsFrame", nil)
  end
  return w
end

function PS.open(w)
  asGame(function()
    w.host:Show()
    if w.talents then w.talents:Show() end
  end)
end

function PS.close(w)
  asGame(function()
    if w.talents then w.talents:Hide() end
    w.host:Hide()
  end)
end

function PS.enter(button)
  local fn = rawget(button, "_scripts").OnEnter
  if fn then fn(button) end
end

-- Cadres créés par l'addon (CreateFrame) dont le parent direct est l'un des cadres donnés.
function PS.childrenCreatedIn(parents)
  local set, out = {}, {}
  for _, p in ipairs(parents) do set[p] = true end
  for _, f in ipairs(Mock.frames) do
    if set[rawget(f, "_parent")] then out[#out + 1] = f end
  end
  return out
end

return PS
