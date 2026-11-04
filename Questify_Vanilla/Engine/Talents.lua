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
-- Talent à (arbre, palier, colonne) : -> index, nom, icône, rang, rang max ; nil si absent.
function Talents:Find(tab, tier, column)
  local n = call(GetNumTalents, tab) or 0
  for i = 1, n do
    local name, icon, ti, col, rank, maxRank = call(GetTalentInfo, tab, i)
    if ti == tier and col == column then return i, name, icon, rank or 0, maxRank or 0 end
  end
  return nil
end

-- Relevé des arbres pour QuestifyVanillaDB.talentDump : -> nombre de talents relevés.
function Talents:Dump()
  QuestifyVanillaDB = QuestifyVanillaDB or {}
  local db = QuestifyVanillaDB
  db.talentDump = db.talentDump or {}
  local list, count = { locale = GetLocale and GetLocale() or "?", tabs = {} }, 0
  for tab = 1, (call(GetNumTalentTabs) or 0) do
    local a, b = call(GetTalentTabInfo, tab)
    list.tabs[tab] = type(a) == "number" and b or a
    for i = 1, (call(GetNumTalents, tab) or 0) do
      local name, icon, tier, col, _, maxRank = call(GetTalentInfo, tab, i)
      list[#list + 1] = { tab = tab, index = i, name = name, icon = icon, tier = tier, column = col, maxRank = maxRank }
      count = count + 1
    end
  end
  db.talentDump[Q.Player.classFile or "?"] = list
  return count
end

-- Points déjà placés dans tous les arbres.
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

-- Points à dépenser : API du client, sinon niveau - 9 - points placés.
function Talents:Unspent()
  if playerLevel() < FIRST_LEVEL then return 0 end
  local v = call(UnitCharacterPoints, "player")
  if type(v) == "number" and not Q.Util.IsSecret(v) then return math.max(0, v) end
  v = call(GetUnspentTalentPoints)
  if type(v) == "number" and not Q.Util.IsSecret(v) then return math.max(0, v) end
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
for _, event in ipairs({ "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "SPELLS_CHANGED" }) do
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
