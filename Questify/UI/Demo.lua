local addonName, Q = ...

-- Commande cachée /qf demo : montre les vraies fenêtres et alertes de l'addon avec des données
-- d'exemple, pour prendre des captures en jeu. Absente de /qf help, des options et du menu de la
-- minicarte ; /qf demo seul liste les scènes dans la discussion.
--   /qf demo <scène>   une scène : classquest, classlate, dungeon, upgrade, pair, route, supplies, cave,
--                      profession
--   /qf demo all       enchaîne les scènes ; /qf demo next passe à la suivante
--   /qf demo off       ferme tout et rétablit l'état d'avant (repère, lignes du suivi, alertes)
-- Aucun effet de bord : rien n'est écrit dans Q.char ni dans Q.db, aucune quête n'est ajoutée, ignorée
-- ou choisie, aucun objet n'est équipé. Les fenêtres reçoivent un drapeau « demo » (sur la chaîne, le
-- donjon, l'annonce ou les cartes) : leurs boutons se contentent alors de fermer la fenêtre. Les alertes
-- du suivi et les lignes d'avant-poste viennent de fonctions du jeu remplacées le temps de la scène et
-- rendues par « off » ; le repère de la grotte passe par Q.Nav:SetTarget, puis l'ancien repère revient.
-- Hors combat seulement : en combat un message le dit et rien ne s'ouvre ; un début de combat range tout.
-- Données : les vraies (chaînes de la classe du joueur, donjon de sa faction, guides livrés, grottes) ;
-- exemples fixes : la suite de Loch Modan est calculée pour un Nain de l'Alliance (quelle que soit la
-- position réelle), les objets viennent de Demo.ITEMS (le premier connu du client est pris).
-- Une donnée ou une API absente : la scène le dit dans la discussion et ne lève jamais d'erreur.
Q.UI = Q.UI or {}
local Demo = {}
Q.UI.Demo = Demo

local L = Q.L

-- Ordre de /qf demo all.
Demo.SCENES = { "classquest", "classlate", "dungeon", "upgrade", "pair", "route", "supplies", "cave", "profession" }

-- Objets d'exemple (ID de WoW Classic) : par liste, le premier que le client connaît est pris.
-- upgrade : annonce simple ; main + off : une arme à une main et un bouclier (annonce de paire).
Demo.ITEMS = {
  upgrade = { 2129, 2362 },
  main = { 36, 37 },
  off = { 2362, 2129 },
}

local ROUTE_FROM = "A_DwarfGnome_03"            -- Loch Modan : Marche de l'Ouest ou Sombrivage
local ROUTE_RACE, ROUTE_FACTION = "Dwarf", "Alliance"
local DUNGEONS = { Alliance = "DM", Horde = "RFC" }
local CAVE_KEY = "dunmorogh_grizzled_den"
local ITEM_TRIES, ITEM_DELAY = 6, 0.5          -- attente du chargement d'un objet : 3 s au plus
local SUPPLY_COLOR = "|cffffd040"
local CENTER_COLOR = { r = 1, g = 0.82, b = 0.25 }
local WHY_DATA, WHY_API, WHY_ITEM = "UI_DEMO_WHY_DATA", "UI_DEMO_WHY_API", "UI_DEMO_WHY_ITEM"

local token = 0            -- change à chaque scène et à chaque « off » : les attentes en cours s'annulent
local patches = {}         -- fonctions remplacées : { table, clé, original }
local extraLines = {}      -- lignes ajoutées au suivi (zone des avertissements)
local savedNav             -- { target = ... } : repère d'avant la scène
local seq                  -- { i = scène courante de /qf demo all }

local function inCombat() return InCombatLockdown and InCombatLockdown() end

local function say(fmt, ...) Q:Print(fmt, ...) end

local function copy(t)
  local out = {}
  for k, v in pairs(t) do out[k] = v end
  return out
end

local function refreshTracker()
  local T = Q.UI and Q.UI.Tracker
  if T and T.Refresh then T:Refresh() end
end

---------------------------------------------------------------------------
-- Fonctions remplacées le temps d'une scène
---------------------------------------------------------------------------
local function patch(tbl, key, make)
  patches[#patches + 1] = { tbl, key, tbl[key] }
  tbl[key] = make(tbl[key])
end

local function unpatch()
  for i = #patches, 1, -1 do
    local p = patches[i]
    p[1][p[2]] = p[3]
    patches[i] = nil
  end
end

-- Lignes ajoutées après celles d'Engine/Supplies.lua (zone des avertissements du suivi).
local function showExtraLines(lines)
  local S = Q.Supplies
  if not (S and type(S.Lines) == "function") then return false end
  extraLines = lines
  local patched = false
  for _, p in ipairs(patches) do
    if p[1] == S and p[2] == "Lines" then patched = true end
  end
  if not patched then
    patch(S, "Lines", function(orig)
      return function(self, ...)
        local out = orig(self, ...)
        out = type(out) == "table" and out or {}
        for _, line in ipairs(extraLines) do out[#out + 1] = line end
        return out
      end
    end)
  end
  return true
end

---------------------------------------------------------------------------
-- Données d'exemple
---------------------------------------------------------------------------
-- Chaînes de la classe du joueur (faction et race convenables).
local function classChains()
  local P = Q.Player or {}
  local byClass = type(Q.ClassQuestData) == "table" and Q.ClassQuestData[P.classFile]
  local out = {}
  if type(byClass) ~= "table" then return out end
  for _, chain in ipairs(byClass) do
    if type(chain) == "table" and type(chain.key) == "string" and type(chain.quests) == "table"
      and #chain.quests > 0 and (chain.faction == nil or chain.faction == P.faction)
      and Q.Util.MaskAllows(chain.races, P.raceBit) then
      out[#out + 1] = chain
    end
  end
  return out
end

-- Copie de la chaîne marquée « demo » : la première disponible (en retard d'abord si late), sinon la
-- première de la classe. nil sans donnée.
local function pickChain(late)
  local mine = classChains()
  if #mine == 0 then return nil end
  local state = {}
  local cq = Q.ClassQuests
  if cq and cq.List then
    local ok, rows = pcall(cq.List, cq)
    if ok and type(rows) == "table" then
      for _, row in ipairs(rows) do
        if type(row) == "table" and type(row.chain) == "table" then state[row.chain.key] = row.state end
      end
    end
  end
  local chosen
  if late and cq and cq.IsLate then
    for _, chain in ipairs(mine) do
      if state[chain.key] == "available" and cq.IsLate(chain, "available") then chosen = chain; break end
    end
  end
  if not chosen then
    for _, chain in ipairs(mine) do
      if state[chain.key] == "available" then chosen = chain; break end
    end
  end
  local demo = copy(chosen or mine[1])
  demo.demo = true
  return demo
end

local function pickDungeon()
  local P = Q.Player or {}
  local key = DUNGEONS[P.faction] or DUNGEONS.Alliance
  for _, d in ipairs(type(Q.DungeonData) == "table" and Q.DungeonData or {}) do
    if type(d) == "table" and d.key == key then
      local demo = copy(d)
      demo.demo = true
      return demo
    end
  end
  return nil
end

-- Premier objet connu du client parmi des ID : -> id, nom, lien.
local function knownItem(ids)
  for _, id in ipairs(ids) do
    local name, link = Q.API.GetItemInfo(id)
    if type(name) == "string" and name ~= "" and type(link) == "string" and link ~= "" then
      return id, name, link
    end
  end
  return nil
end

-- Attend que chaque liste d'ID donne un objet connu, puis done({ { id, name, link }, ... }). Les
-- données sont demandées au client à chaque essai ; sans réponse, un message le dit.
local function whenItems(mine, scene, lists, done, tries)
  if mine ~= token then return end
  local items = {}
  for i, ids in ipairs(lists) do
    local id, name, link = knownItem(ids)
    if not id then break end
    items[i] = { id = id, name = name, link = link }
  end
  if #items == #lists then return done(items) end
  if tries >= ITEM_TRIES then
    say(L.UI_DEMO_MISSING, scene, L[WHY_ITEM])
    return
  end
  if C_Item and C_Item.RequestLoadItemDataByID then
    for _, ids in ipairs(lists) do
      for _, id in ipairs(ids) do pcall(C_Item.RequestLoadItemDataByID, id) end
    end
  end
  Q:After(ITEM_DELAY, function() whenItems(mine, scene, lists, done, tries + 1) end)
end

---------------------------------------------------------------------------
-- Scènes : chacune renvoie true, ou false et la clé du texte qui dit pourquoi.
---------------------------------------------------------------------------
local SCENE = {}

-- Alerte du suivi : une seule ligne d'exemple à la place des vraies alertes ; late = en retard.
local function classAlert(chain, late)
  local cq = Q.ClassQuests
  if not (cq and cq.Alerts) then return end
  patch(cq, "Alerts", function()
    return function() return { { chain = chain, state = "available" } } end
  end)
  patch(cq, "IsLate", function(orig)
    return function(c, state)
      if late and type(c) == "table" and c.demo then return state == "available" end
      return orig(c, state)
    end
  end)
end

function SCENE.classquest()
  local P = Q.UI.ClassQuestPopup
  local chain = pickChain(false)
  if not (P and chain) then return false, WHY_DATA end
  classAlert(chain, false)
  refreshTracker()
  P:Show(chain, 1, 1)
  return true
end

function SCENE.classlate()
  local chain = pickChain(true)
  if not (Q.UI.ClassQuestPopup and chain) then return false, WHY_DATA end
  classAlert(chain, true)
  refreshTracker()
  return true
end

function SCENE.dungeon()
  local P, D = Q.UI.DungeonPopup, Q.Dungeons
  local d = pickDungeon()
  if not (P and D and D.Alerts and d) then return false, WHY_DATA end
  patch(D, "Alerts", function()
    return function() return { { dungeon = d, state = "available" } } end
  end)
  refreshTracker()
  P:Show(d, 1, 1)
  return true
end

-- Annonce d'équipement : l'objet est demandé au client, puis la vraie annonce s'affiche, sans minuterie.
local function announce(scene, lists, make)
  local P = Q.UI.UpgradePopup
  if not (P and P.ShowEntry and Q.API and Q.API.GetItemInfo) then return false, WHY_API end
  whenItems(token, scene, lists, function(items)
    if inCombat() then
      say(L.UI_DEMO_COMBAT)
      return
    end
    -- une vraie annonce à l'écran repart en tête de file : « off » la rend
    if P.current and not P.current.demo then table.insert(P.queue, 1, P.current) end
    P:ShowEntry(make(items))
    P.serial = (P.serial or 0) + 1   -- l'annonce reste affichée jusqu'à « off » ou au clic
  end, 0)
  return true
end

function SCENE.upgrade()
  return announce("upgrade", { Demo.ITEMS.upgrade }, function(items)
    return { link = items[1].link, name = items[1].name, gain = 0, demo = true }
  end)
end

function SCENE.pair()
  return announce("pair", { Demo.ITEMS.main, Demo.ITEMS.off }, function(items)
    return { link = items[1].link, name = items[1].name, gain = 0, demo = true,
      pair = { main = items[1].link, off = items[2].link } }
  end)
end

-- Fenêtre de choix de suite : cartes de Q.RouteChoice:Rank pour les suites de la fin de Loch Modan,
-- comme Popup:Open les montre (sans passer par Q.Progress, qui dépend de la position réelle).
function SCENE.route()
  local P = Q.UI.RouteChoicePopup
  local guide = Q.Guides and Q.Guides:Get(ROUTE_FROM)
  if not (P and guide and Q.RouteChoice) then return false, WHY_DATA end
  local options = Q.Guides:Choices(guide, ROUTE_RACE, ROUTE_FACTION)
  if #options < 2 then return false, WHY_DATA end
  local cards = Q.RouteChoice:Rank(options)
  cards.demo = true
  P.resume = nil
  P.fromId, P.manual, P.cards = ROUTE_FROM, true, cards
  local f = P:Create()
  P:Fill(ROUTE_FROM, cards)
  f:Show()
  if P.fadeIn then P.fadeIn:Play() end
  P:SetKeyboard(true)
  return true
end

-- Message bien visible au milieu de l'écran (même chemin qu'Engine/Supplies.lua).
local function centerMessage(text)
  if RaidWarningFrame then
    if type(RaidWarningUtil) == "table" and type(RaidWarningUtil.AddMessage) == "function" then
      if pcall(RaidWarningUtil.AddMessage, text, CENTER_COLOR) then return end
    elseif type(RaidNotice_AddMessage) == "function" then
      if pcall(RaidNotice_AddMessage, RaidWarningFrame, text, CENTER_COLOR) then return end
    end
  end
  local frame = UIErrorsFrame
  if type(frame) == "table" and type(frame.AddMessage) == "function" then
    pcall(frame.AddMessage, frame, text, CENTER_COLOR.r, CENTER_COLOR.g, CENTER_COLOR.b)
  end
end

-- Alerte d'avant-poste : « 4 places libres sur 64, pas de boisson » (lignes du suivi, discussion et
-- message au centre, comme Engine/Supplies.lua).
function SCENE.supplies()
  local C = Q.Comfort
  if not C then return false, WHY_API end
  local slots = C.Format(L.COMFORT_SLOTS_FREE, 4, 64)
  local lines = {
    SUPPLY_COLOR .. C.Format(L.COMFORT_BAGS_FULL, slots) .. "|r",
    SUPPLY_COLOR .. L.COMFORT_NO_DRINK .. "|r",
  }
  if not showExtraLines(lines) then return false, WHY_API end
  local msg = C.Format(L.COMFORT_SUPPLY_ALERT, slots .. L.COMFORT_LIST_SEP .. L.COMFORT_PART_DRINK)
  say("%s", msg)
  centerMessage(msg)
  refreshTracker()
  return true
end

-- Repère « Entrée de la grotte — The Grizzled Den » à l'entrée réelle, par la navigation normale
-- (affichage WaypointUI, TomTom ou natif selon les réglages).
function SCENE.cave()
  local N = Q.Nav
  if not (N and N.SetTarget and N.Status) then return false, WHY_API end
  local cave
  for _, c in ipairs(type(Q.CaveData) == "table" and Q.CaveData or {}) do
    if type(c) == "table" and type(c.entrance) == "table" and type(c.mapId) == "number" then
      cave = cave or c
      if c.key == CAVE_KEY then cave = c; break end
    end
  end
  if not cave then return false, WHY_DATA end
  local name = tostring(cave.name or cave.key):gsub("%s*%b()%s*$", "")
  savedNav = savedNav or { target = N:Status().target }
  N:SetTarget(cave.mapId, cave.entrance[1], cave.entrance[2], L.NAV_CAVE_ENTER .. " — " .. name)
  return true
end

-- Étape « Métier : Herboristerie (Compagnon) » : titre dans la discussion, texte dans la zone des
-- avertissements du suivi ; rien n'est inséré dans la route.
function SCENE.profession()
  local F = Q.Format
  if not (F and Q.Professions) then return false, WHY_DATA end
  local step = { action = "trainprof", prof = "HERBALISM", rank = 2 }
  say("%s", F:StepTitle(step))
  if not showExtraLines({ F:StepText(step) }) then return false, WHY_API end
  refreshTracker()
  return true
end

---------------------------------------------------------------------------
-- Ouverture, fermeture
---------------------------------------------------------------------------
-- Ferme toutes les scènes et rétablit l'état d'avant.
function Demo:Reset()
  token = token + 1
  local cq, dg, up, rp = Q.UI.ClassQuestPopup, Q.UI.DungeonPopup, Q.UI.UpgradePopup, Q.UI.RouteChoicePopup
  if cq and cq.demo then cq.demo = nil; cq:Hide() end
  if dg and dg.demo then dg.demo = nil; dg:Hide() end
  if up then
    for i = #up.queue, 1, -1 do
      if up.queue[i].demo then table.remove(up.queue, i) end
    end
    if up.current and up.current.demo then up:Next() end
  end
  if rp and rp.cards and rp.cards.demo then
    rp.resume = nil
    rp:Close()
    rp.cards = nil
  end
  unpatch()
  extraLines = {}
  if savedNav then
    local prev = savedNav.target
    savedNav = nil
    if prev then Q.Nav:SetTarget(prev.mapId, prev.x, prev.y, prev.title) else Q.Nav:Clear() end
  end
  refreshTracker()
end

local function runScene(name)
  Demo:Reset()
  local ok, res, why = pcall(SCENE[name])
  if ok and res then return true end
  Demo:Reset()
  say(L.UI_DEMO_MISSING, name, ok and L[why] or tostring(res))
  return false
end

local function printList()
  say("%s", L.UI_DEMO_HEADER)
  for _, name in ipairs(Demo.SCENES) do say("%s", "  /qf demo " .. name .. " - " .. L["UI_DEMO_SCENE_" .. name]) end
  say("%s", L.UI_DEMO_FOOTER)
end

function Demo:Run(name)
  if not SCENE[name] then
    say(L.UI_DEMO_UNKNOWN, name)
    printList()
    return false
  end
  if inCombat() then
    say(L.UI_DEMO_COMBAT)
    return false
  end
  seq = nil
  return runScene(name)
end

function Demo:Next()
  if not seq then
    say(L.UI_DEMO_NO_SEQUENCE)
    return false
  end
  if seq.i >= #self.SCENES then
    say(L.UI_DEMO_LAST)
    return false
  end
  if inCombat() then
    say(L.UI_DEMO_COMBAT)
    return false
  end
  seq.i = seq.i + 1
  local name = self.SCENES[seq.i]
  say(L.UI_DEMO_STEP, name, seq.i, #self.SCENES)
  return runScene(name)
end

function Demo:Off()
  seq = nil
  self:Reset()
  say(L.UI_DEMO_OFF)
end

-- /qf demo [scène | all | next | off]
function Demo:Handle(arg)
  arg = arg or ""
  if arg == "" then return printList() end
  if arg == "off" then return self:Off() end
  if arg == "next" then return self:Next() end
  if arg == "all" then
    if inCombat() then
      say(L.UI_DEMO_COMBAT)
      return false
    end
    seq = { i = 0 }
    return self:Next()
  end
  return self:Run(arg)
end

-- Début de combat : tout se range, sans message.
Q:RegisterEvent("PLAYER_REGEN_DISABLED", function()
  seq = nil
  Demo:Reset()
end)
