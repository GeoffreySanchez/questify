local addonName, Q = ...

-- Talents : points à dépenser et talents à prendre d'après le build suivi (Engine/Builds.lua).
-- Dès le niveau 10 (un point par niveau), le suivi affiche une alerte tant qu'un point reste à
-- dépenser, avec le prochain talent du build ; un personnage sans build choisi suit le build fourni
-- préféré de sa spécialisation (Builds:AutoPick). Les talents sont désignés par leur spellID : le nom
-- vient du jeu, donc de la langue du client. L'alerte est recalculée à chaque TALENTS_CHANGED (I7).
local Talents = {}
Q.Talents = Talents

local FIRST_LEVEL = 10

local function setting(path) return Q.Settings:Get(path) end
local function playerLevel() return Q.Player.level or 1 end

local function call(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b, c, d, e, f = pcall(fn, ...)
  if not ok then return nil end
  return a, b, c, d, e, f
end

---------------------------------------------------------------------------
-- Arbres de talents du client
---------------------------------------------------------------------------
-- Forever (famille Mainline 12.x) expose les talents par C_ClassTalents et C_Traits (voir
-- Blizzard_PlayerSpells/Camelot/ClassTalents) : un arbre de classe dont les trois « arbres »
-- classiques sont des groupes de nœuds. GetNumTalentTabs, GetTalentInfo et UnitCharacterPoints
-- n'y existent pas.

local function plain(v)
  if Q.Util.IsSecret(v) then return nil end
  local k = type(v)
  if k == "number" or k == "string" or k == "boolean" then return v end
  return nil
end

local function plainList(list)
  local out = {}
  if type(list) ~= "table" or Q.Util.IsSecret(list) then return out end
  for _, v in ipairs(list) do
    local p = plain(v)
    if p ~= nil then out[#out + 1] = p end
  end
  return out
end

-- Configuration de talents active et ses arbres : -> configID, { treeID, ... } ; nil si l'API
-- manque ou ne répond pas encore.
local function activeTrees()
  if type(C_ClassTalents) ~= "table" or type(C_Traits) ~= "table" then return nil end
  local configID = plain(call(C_ClassTalents.GetActiveConfigID))
  if type(configID) ~= "number" then return nil end
  local info = call(C_Traits.GetConfigInfo, configID)
  if type(info) ~= "table" or Q.Util.IsSecret(info) then return nil end
  local trees = plainList(info.treeIDs)
  if #trees == 0 then return nil end
  return configID, trees
end

-- Monnaies d'un arbre (C_Traits.GetTreeCurrencyInfo) : { { traitCurrencyID, quantity, maxQuantity,
-- spent, spentInTree } }.
local function treeCurrencies(configID, treeID)
  local list = call(C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
  local out = {}
  if type(list) ~= "table" or Q.Util.IsSecret(list) then return out end
  for _, c in ipairs(list) do
    if type(c) == "table" and not Q.Util.IsSecret(c) then
      out[#out + 1] = { traitCurrencyID = plain(c.traitCurrencyID), quantity = plain(c.quantity),
        maxQuantity = plain(c.maxQuantity), spent = plain(c.spent), spentInTree = plain(c.spentInTree) }
    end
  end
  return out
end

-- Points à dépenser selon la monnaie des arbres de la configuration active (Forever) ; nil si
-- l'API manque ou ne donne aucune quantité lisible. Une monnaie présente dans plusieurs arbres
-- n'est comptée qu'une fois.
function Talents:TreeCurrencyUnspent()
  if type(C_Traits) ~= "table" or type(C_Traits.GetTreeCurrencyInfo) ~= "function" then return nil end
  local configID, trees = activeTrees()
  if not configID then return nil end
  local byCurrency, extra, any = {}, 0, false
  for _, treeID in ipairs(trees) do
    for _, c in ipairs(treeCurrencies(configID, treeID)) do
      local q = c.quantity
      if type(q) == "number" then
        any = true
        if c.traitCurrencyID then
          byCurrency[c.traitCurrencyID] = math.max(byCurrency[c.traitCurrencyID] or 0, q)
        else
          extra = extra + q
        end
      end
    end
  end
  if not any then return nil end
  local total = extra
  for _, q in pairs(byCurrency) do total = total + q end
  return math.max(0, total)
end

-- Relevé des arbres Forever pour QuestifyDB.talentDump[<jeu>][<classe>] :
--   { locale, interface, configID, trees = { { treeID, currencies, groups } },
--     nodes = { { treeID, nodeID, posX, posY, maxRanks, currentRank, type, isVisible, groupIDs,
--                 entries = { { entryID, definitionID, spellID, name, maxRanks } } } } }
-- -> nombre de nœuds relevés ; 0 avec un message clair si l'API manque ou ne répond pas.
local DUMP_API = {
  { "C_ClassTalents", "GetActiveConfigID" }, { "C_Traits", "GetConfigInfo" }, { "C_Traits", "GetTreeNodes" },
  { "C_Traits", "GetNodeInfo" }, { "C_Traits", "GetEntryInfo" }, { "C_Traits", "GetDefinitionInfo" },
  { "C_Traits", "GetTreeCurrencyInfo" },
}

local function hasDumpApi()
  for _, a in ipairs(DUMP_API) do
    local ns = _G[a[1]]
    if type(ns) ~= "table" or type(ns[a[2]]) ~= "function" then return false end
  end
  return true
end

local function spellName(spellID)
  if type(spellID) ~= "number" then return nil end
  if type(C_Spell) == "table" then return plain(call(C_Spell.GetSpellName, spellID)) end
  return nil
end

local function gameKey()
  if Q.IsForever() then return "forever" end
  local interface = GetBuildInfo and select(4, GetBuildInfo())
  return "interface-" .. tostring(tonumber(interface) or "?")
end

local function dumpNode(configID, treeID, nodeID)
  local info = call(C_Traits.GetNodeInfo, configID, nodeID)
  if type(info) ~= "table" or Q.Util.IsSecret(info) then return nil end
  local node = { treeID = treeID, nodeID = nodeID, posX = plain(info.posX), posY = plain(info.posY),
    maxRanks = plain(info.maxRanks), currentRank = plain(info.currentRank), type = plain(info.type),
    isVisible = plain(info.isVisible), groupIDs = plainList(info.groupIDs), entries = {} }
  for _, entryID in ipairs(plainList(info.entryIDs)) do
    local e = { entryID = entryID }
    local entry = call(C_Traits.GetEntryInfo, configID, entryID)
    if type(entry) == "table" and not Q.Util.IsSecret(entry) then
      e.definitionID = plain(entry.definitionID)
      e.maxRanks = plain(entry.maxRanks)
      if type(e.definitionID) == "number" then
        local def = call(C_Traits.GetDefinitionInfo, e.definitionID)
        if type(def) == "table" and not Q.Util.IsSecret(def) then
          e.spellID = plain(def.spellID)
          e.name = plain(def.overrideName) or spellName(e.spellID)
        end
      end
    end
    node.entries[#node.entries + 1] = e
  end
  return node
end

function Talents:Dump()
  local L = Q.L
  if not hasDumpApi() then
    Q:Print(L.TALENT_DUMP_NO_API)
    return 0
  end
  local configID, trees = activeTrees()
  if not configID then
    Q:Print(L.TALENT_DUMP_NO_CONFIG)
    return 0
  end
  local version = GetBuildInfo and select(4, GetBuildInfo())
  local out = { locale = GetLocale and GetLocale() or "?", interface = tonumber(version), configID = configID,
    trees = {}, nodes = {} }
  for _, treeID in ipairs(trees) do
    local tree = { treeID = treeID, currencies = treeCurrencies(configID, treeID), groups = {} }
    -- groupes du tree (les trois arbres classiques de Forever) : nom affiché et ordre
    local groups = type(C_Traits.GetGroupDisplayInfoByTreeID) == "function"
      and call(C_Traits.GetGroupDisplayInfoByTreeID, treeID)
    if type(groups) == "table" and not Q.Util.IsSecret(groups) then
      for _, g in ipairs(groups) do
        if type(g) == "table" and not Q.Util.IsSecret(g) then
          tree.groups[#tree.groups + 1] = { groupID = plain(g.groupID), displayName = plain(g.displayName),
            orderIndex = plain(g.orderIndex), icon = plain(g.icon) }
        end
      end
    end
    out.trees[#out.trees + 1] = tree
    for _, nodeID in ipairs(plainList(call(C_Traits.GetTreeNodes, treeID))) do
      local node = dumpNode(configID, treeID, nodeID)
      if node then out.nodes[#out.nodes + 1] = node end
    end
  end
  if #out.nodes == 0 then
    Q:Print(L.TALENT_DUMP_EMPTY)
    return 0
  end
  QuestifyDB = QuestifyDB or {}
  local db = QuestifyDB
  db.talentDump = type(db.talentDump) == "table" and db.talentDump or {}
  local game = gameKey()
  db.talentDump[game] = type(db.talentDump[game]) == "table" and db.talentDump[game] or {}
  db.talentDump[game][Q.Player.classFile or "?"] = out
  return #out.nodes
end

-- Points à dépenser : la monnaie des arbres (C_Traits, Forever ; points en attente déjà comptés comme
-- dépensés), sinon l'ancienne API du client ; 0 (rappel muet) si rien ne répond. Ne lit jamais l'arbre (M1).
function Talents:Unspent()
  if playerLevel() < FIRST_LEVEL then return 0 end
  local v = self:TreeCurrencyUnspent()
  if type(v) == "number" then return v end
  v = call(UnitCharacterPoints, "player")
  if type(v) == "number" and not Q.Util.IsSecret(v) then return math.max(0, v) end
  v = call(GetUnspentTalentPoints)
  if type(v) == "number" and not Q.Util.IsSecret(v) then return math.max(0, v) end
  return 0
end

-- État vu par la dernière alerte, pour décider de TALENTS_DUE.
local lastDue, lastUnspent = 0, 0

-- État des talents pour n points à dépenser : build suivi pour le groupe actif (choisi, sinon le fourni
-- préféré de la spécialisation, Builds:AutoPick), validé contre l'arbre (Builds:Obsolete, en cache) ; un build
-- obsolète ne donne aucun point dû (anti-objectif 4 : jamais suivi sans le dire) ; sinon points dus
-- (Builds:Due) et écart au build.
local function stateOf(tree, n)
  local B = Q.Builds
  local build = B and (B:AutoPick(B:ActiveGroup(), tree) or B:Active()) or nil
  local due, deviates, obsolete = {}, false, nil
  if build and tree then
    obsolete = B:Obsolete(build, tree)
    if not obsolete then
      due = B:Due(build, tree)
      deviates = B:Deviates(build, tree)
    end
  end
  return { unspent = n, due = due, build = build, tree = tree, deviates = deviates, obsolete = obsolete }
end

-- State() -> { unspent, due, build, tree, deviates, obsolete }, même avec 0 point à dépenser, ou nil sans
-- arbre lisible. obsolete : raison de Builds:Validate quand le build suivi ne convient plus à l'arbre (due
-- est alors vide). Indépendant du réglage talentAlert (la popup et la ligne du suivi seulement) : le halo,
-- l'infobulle et la bande de la fenêtre des talents (UI/TalentFrameHook.lua) le lisent. Ne déclenche rien.
function Talents:State()
  local tree = Q.TalentTree and Q.TalentTree:Read() or nil
  if not tree then return nil end
  local n = playerLevel() >= FIRST_LEVEL and tonumber(tree.unspent) or 0
  return stateOf(tree, math.max(0, n or 0))
end

-- Alert() -> le même état quand un point est à dépenser et que talentAlert est actif, sinon nil.
--   due : points à prendre maintenant, dans l'ordre du build (Builds:Due) ; vide sans build, sans arbre ou
--   avec un build obsolète ;
--   build : build suivi pour le groupe actif (choisi, sinon le fourni préféré de la spécialisation), ou nil ;
--   deviates : le joueur s'est écarté du build ; obsolete : raison, build obsolète.
-- Le nombre de points vient de Unspent() (monnaie) ; l'arbre n'est lu que s'il y a un point à dépenser
-- (M1), et sans arbre lisible tree = nil. Le build n'est choisi (AutoPick) que s'il y a un point à dépenser.
-- Déclenche TALENTS_DUE quand due passe de vide à non vide, ou quand unspent augmente.
function Talents:Alert()
  if setting("talentAlert") == false then return nil end
  local n = self:Unspent()
  if n <= 0 then
    lastDue, lastUnspent = 0, 0
    return nil
  end
  local tree = Q.TalentTree and Q.TalentTree:Read() or nil
  local alert = stateOf(tree, n)
  local fire = (#alert.due > 0 and lastDue == 0) or n > lastUnspent
  lastDue, lastUnspent = #alert.due, n
  if fire then Q:Fire("TALENTS_DUE", alert) end
  return alert
end

-- Texte du conseil : « <talent> (<groupe>, rang r/max) » pour une entrée de `due`.
function Talents:Advice(entry, tree)
  if type(entry) ~= "table" then return nil end
  tree = tree or (Q.TalentTree and Q.TalentTree:Read())
  local node = entry.node
  local group = node and tree and tree.groups and tree.groups[node.group]
  return string.format(Q.L.TALENT_ADVICE, spellName(entry.spellID) or "?", group and group.name or "?",
    entry.rank or 1, node and node.maxRanks or 1)
end

-- Touche des talents (raccourci TOGGLETALENTS du jeu), « N » si aucune n'est lisible.
function Talents:TalentKey()
  local key = type(GetBindingKey) == "function" and plain(call(GetBindingKey, "TOGGLETALENTS")) or nil
  if type(key) ~= "string" or key == "" then return "N" end
  local text = type(GetBindingText) == "function" and plain(call(GetBindingText, key)) or nil
  if type(text) == "string" and text ~= "" then return text end
  return key
end

local function isShown(frame, method)
  local fn = type(frame) == "table" and frame[method]
  if type(fn) ~= "function" then return nil end
  local ok, v = pcall(fn, frame)
  if not ok then return nil end
  return plain(v) == true
end

-- Ouvre l'affichage des talents du jeu, hors combat, sans jamais charger d'addon de Blizzard (I10) :
-- PlayerSpellsUtil.ToggleClassTalentFrame charge Blizzard_PlayerSpells quand PlayerSpellsFrame n'existe pas
-- (PlayerSpellsFrame_LoadUI -> LoadAddOnWithErrorHandling, branche forever de wow-ui-source), ce qui
-- rattache la fenêtre à l'addon (sorts du grimoire bloqués ensuite). Elle n'est donc appelée que sur une
-- fenêtre déjà chargée par le jeu et cachée (c'est une bascule : montrée, elle la refermerait). Fenêtre
-- absente ou montrée sur le grimoire : message « Ouvre tes talents avec <touche> » (quiet : pas de message).
-- -> vrai si l'affichage des talents est ouvert (ou l'était déjà).
function Talents:OpenFrame(quiet)
  if InCombatLockdown and InCombatLockdown() then return false end
  local frame = PlayerSpellsFrame
  if type(PlayerSpellsUtil) == "table" and type(PlayerSpellsUtil.ToggleClassTalentFrame) == "function"
      and type(frame) == "table" then
    local shown = isShown(frame, "IsShown")
    if shown == false then
      pcall(PlayerSpellsUtil.ToggleClassTalentFrame)
      return true
    end
    if shown and isShown(frame.TalentsFrame, "IsVisible") then return true end
  elseif type(PlayerTalentFrame) == "table" and type(ToggleTalentFrame) == "function" then
    -- ancienne fenêtre (hors Forever), même règle : seulement déjà chargée et cachée
    local shown = isShown(PlayerTalentFrame, "IsShown")
    if shown == false then
      pcall(ToggleTalentFrame)
      return true
    end
    if shown then return true end
  end
  if not quiet then Q:Print(Q.L.TALENT_OPEN_KEY, self:TalentKey()) end
  return false
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
local function announce(level)
  if setting("talentAlert") == false or (level or 0) < FIRST_LEVEL then return end
  local L = Q.L
  if level == FIRST_LEVEL then Q:Print(L.TALENT_FIRST) end
  local alert = Talents:Alert()
  local entry = alert and alert.due[1]
  if entry then
    Q:Print(L.TALENT_LEVEL_ADVICE, Talents:Advice(entry, alert.tree))
  elseif level > FIRST_LEVEL then
    Q:Print(L.TALENT_LEVEL)
  end
end
Talents.Announce = function(_, level) announce(level) end

Q:RegisterEvent("PLAYER_LEVEL_UP", function(_, level)
  -- Q.Player est mis à jour par Progress sur le même évènement : on lit le niveau reçu
  Q:After(0.5, function() Q.SafeCall(announce, tonumber(level)) Q:Fire("TALENTS_CHANGED") end)
end)
-- TRAIT_* : points dépensés ou gagnés dans les arbres C_Traits (Forever).
for _, event in ipairs({ "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "SPELLS_CHANGED",
    "TRAIT_TREE_CURRENCY_INFO_UPDATED", "TRAIT_CONFIG_UPDATED" }) do
  Q:RegisterEvent(event, function() Q:Fire("TALENTS_CHANGED") end)
end
Q:On("SETTINGS_CHANGED", function(path)
  if path == "talentAlert" then Q:Fire("TALENTS_CHANGED") end
end)

-- I7 : l'alerte (et donc TALENTS_DUE, qui ouvre la popup) ne dépend pas du dessin du suivi, qui sort tôt
-- sans QuestieDB ou sans guide : Talents la calcule lui-même à chaque TALENTS_CHANGED, au plus une fois par
-- ALERT_GAP secondes (un appel tout de suite, puis un seul en fin de fenêtre). Le suivi continue de l'appeler
-- pour son affichage : l'émission de TALENTS_DUE reste idempotente.
local ALERT_GAP = 0.5
local alertAt, alertQueued = nil, false

local function now() return type(GetTime) == "function" and tonumber(GetTime()) or 0 end

local function selfAlert()
  local t = now()
  if alertAt and t - alertAt < ALERT_GAP then
    if not alertQueued then
      alertQueued = true
      Q:After(ALERT_GAP - (t - alertAt), function()
        alertQueued = false
        alertAt = now()
        Talents:Alert()
      end)
    end
    return
  end
  alertAt = t
  Talents:Alert()
end
Q:On("TALENTS_CHANGED", selfAlert)
