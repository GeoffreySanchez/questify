local addonName, Q = ...

-- Talents : points à dépenser et talent conseillé par le preset de build choisi.
-- Dès le niveau 10 (un point par niveau), le suivi affiche une alerte tant qu'un point reste à
-- dépenser ; au niveau 10, un message présente les talents, puis à chaque niveau un message dit quel
-- talent prendre. Le joueur choisit au niveau 10 un preset (montée en niveau, donjon…) parmi ceux de
-- sa classe (Data/TalentBuilds.lua) : une liste ordonnée de talents désignés par leur arbre, leur
-- palier et leur colonne, pour ne pas dépendre de la langue du client (le nom vient du jeu).
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
-- n'y existent pas ; les fonctions qui les lisent (Find, Spent) restent pour les presets et
-- renvoient « rien » sans elles.

-- Talent à (arbre, palier, colonne) : -> index, nom, icône, rang, rang max ; nil si absent.
function Talents:Find(tab, tier, column)
  local n = call(GetNumTalents, tab) or 0
  for i = 1, n do
    local name, icon, ti, col, rank, maxRank = call(GetTalentInfo, tab, i)
    if ti == tier and col == column then return i, name, icon, rank or 0, maxRank or 0 end
  end
  return nil
end

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

-- Points déjà placés dans tous les arbres (API Classic des presets, absente de Forever).
function Talents:Spent()
  local total = 0
  for tab = 1, (call(GetNumTalentTabs) or 0) do
    for i = 1, (call(GetNumTalents, tab) or 0) do
      local _, _, _, _, rank = call(GetTalentInfo, tab, i)
      total = total + (tonumber(rank) or 0)
    end
  end
  return total
end

-- Points à dépenser : ancienne API du client, sinon la monnaie des arbres (C_Traits, Forever),
-- sinon niveau - 9 - points placés (arbres Classic) ; 0 (rappel muet) si rien ne répond.
function Talents:Unspent()
  if playerLevel() < FIRST_LEVEL then return 0 end
  local v = call(UnitCharacterPoints, "player")
  if type(v) == "number" and not Q.Util.IsSecret(v) then return math.max(0, v) end
  v = call(GetUnspentTalentPoints)
  if type(v) == "number" and not Q.Util.IsSecret(v) then return math.max(0, v) end
  v = self:TreeCurrencyUnspent()
  if v then return v end
  if (call(GetNumTalentTabs) or 0) == 0 then return 0 end
  return math.max(0, playerLevel() - (FIRST_LEVEL - 1) - self:Spent())
end

---------------------------------------------------------------------------
-- Presets
---------------------------------------------------------------------------
-- Presets de la classe du personnage (Data/TalentBuilds.lua).
function Talents:Presets()
  local data = Q.TalentBuildData
  local list = type(data) == "table" and Q.Player.classFile and data[Q.Player.classFile]
  if type(list) ~= "table" then return {} end
  local out = {}
  for _, p in ipairs(list) do out[#out + 1] = p end
  return out
end

function Talents:PresetTitle(preset)
  if type(preset) ~= "table" then return "" end
  local t = preset.title
  if type(t) == "table" then return t[GetLocale and GetLocale() or "enUS"] or t.enUS or preset.key end
  return tostring(t or preset.key)
end

function Talents:Chosen()
  local key = Q.char and Q.char.talentPreset
  if not key then return nil end
  for _, p in ipairs(self:Presets()) do
    if p.key == key then return p end
  end
  return nil
end

function Talents:HasAnswered()
  return Q.char ~= nil and Q.char.talentPreset ~= nil
end

-- key = clé d'un preset, ou false pour « aucun ».
function Talents:Choose(key)
  if not Q.char then return end
  Q.char.talentPreset = key or false
  Q:Fire("TALENTS_CHANGED")
end

-- Prochain talent du preset : le premier rang de la liste pas encore pris.
-- -> { name, icon, tab, tabName, rank, maxRank, index } ou nil (preset fini, absent, ou arbre inconnu).
function Talents:Next()
  local preset = self:Chosen()
  if not preset or type(preset.order) ~= "table" then return nil end
  local need = {}
  for _, pos in ipairs(preset.order) do
    local tab, tier, col = pos[1], pos[2], pos[3]
    local k = tab .. ":" .. tier .. ":" .. col
    need[k] = (need[k] or 0) + 1
    local index, name, icon, rank, maxRank = self:Find(tab, tier, col)
    if not index then return nil end   -- arbre différent de celui du preset : on ne conseille rien
    -- vérifications : rang max, et nom anglais quand le client est en anglais
    if pos[4] and pos[4] ~= maxRank then return nil end
    if pos[5] and GetLocale and GetLocale() == "enUS" and pos[5] ~= name then return nil end
    if rank < need[k] and rank < maxRank then
      local tabName = call(GetTalentTabInfo, tab)
      if type(tabName) == "number" then tabName = select(2, call(GetTalentTabInfo, tab)) end
      return { name = name, icon = icon, tab = tab, tabName = tabName, rank = rank, maxRank = maxRank, index = index }
    end
  end
  return nil
end

-- Alert() -> { unspent, next } quand un point est à dépenser, sinon nil.
function Talents:Alert()
  if setting("talentAlert") == false then return nil end
  local n = self:Unspent()
  if n <= 0 then return nil end
  return { unspent = n, next = self:Next() }
end

-- Texte du conseil : « <talent> (<arbre>, rang r/max) ».
function Talents:Advice(nxt)
  if not nxt then return nil end
  return string.format(Q.L.TALENT_ADVICE, nxt.name or "?", nxt.tabName or "?", (nxt.rank or 0) + 1, nxt.maxRank or 1)
end

-- Ouvre la fenêtre des talents du jeu (hors combat).
function Talents:OpenFrame()
  if InCombatLockdown and InCombatLockdown() then return false end
  if type(TalentFrame_LoadUI) == "function" then pcall(TalentFrame_LoadUI) end
  if type(ToggleTalentFrame) == "function" then
    pcall(ToggleTalentFrame)
    return true
  end
  return false
end

---------------------------------------------------------------------------
-- Évènements
---------------------------------------------------------------------------
local function announce(level)
  if setting("talentAlert") == false or (level or 0) < FIRST_LEVEL then return end
  local L = Q.L
  if level == FIRST_LEVEL then Q:Print(L.TALENT_FIRST) end
  local nxt = Talents:Next()
  if nxt then
    Q:Print(L.TALENT_LEVEL_ADVICE, Talents:Advice(nxt))
  elseif level > FIRST_LEVEL then
    Q:Print(L.TALENT_LEVEL)
  end
  if not Talents:HasAnswered() and #Talents:Presets() > 0 then Q:Fire("TALENTS_ASK") end
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
Q:On("LOGIN", function()
  -- personnage déjà au niveau 10 ou plus sans preset : on pose la question une fois
  if playerLevel() >= FIRST_LEVEL and not Talents:HasAnswered() and #Talents:Presets() > 0 then
    Q:After(6, function() Q:Fire("TALENTS_ASK") end)
  end
end)
Q:On("SETTINGS_CHANGED", function(path)
  if path == "talentAlert" then Q:Fire("TALENTS_CHANGED") end
end)
