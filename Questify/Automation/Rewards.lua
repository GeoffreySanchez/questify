local addonName, Q = ...

-- Choix de la récompense (spec § 5.6) : parmi les objets utilisables par la classe, la plus
-- forte amélioration par rapport à l'équipé ; sinon l'objet qui se revend le plus cher.
local Rewards = {}
Q.Rewards = Rewards

local EPSILON = 1e-6
local LATE_ARMOR_LEVEL = 40   -- plaque (guerrier, paladin) et mailles (chasseur, chaman)

local function set(...)
  local s = {}
  for i = 1, select("#", ...) do s[(select(i, ...))] = true end
  return s
end

---------------------------------------------------------------------------
-- Utilisabilité : sous-classes d'armure (classID 4) et d'arme (classID 2) par classe
---------------------------------------------------------------------------
-- armor : toujours ; late : à partir du niveau 40 ; weapon : armes.
-- La sous-classe d'armure 0 (cous, anneaux, bijoux, objets de main gauche) est toujours utilisable.
local USABLE = {
  WARRIOR = { armor = set(1, 2, 3, 6), late = set(4), weapon = set(0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18) },
  PALADIN = { armor = set(1, 2, 3, 6), late = set(4), weapon = set(0, 1, 4, 5, 6, 7, 8) },
  HUNTER = { armor = set(1, 2), late = set(3), weapon = set(0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18) },
  ROGUE = { armor = set(1, 2), late = set(), weapon = set(2, 3, 4, 7, 13, 15, 16, 18) },
  PRIEST = { armor = set(1), late = set(), weapon = set(4, 10, 15, 19) },
  SHAMAN = { armor = set(1, 2, 6), late = set(3), weapon = set(0, 1, 4, 5, 10, 13, 15) },
  MAGE = { armor = set(1), late = set(), weapon = set(7, 10, 15, 19) },
  WARLOCK = { armor = set(1), late = set(), weapon = set(7, 10, 15, 19) },
  DRUID = { armor = set(1, 2), late = set(), weapon = set(4, 5, 10, 13, 15) },
}

---------------------------------------------------------------------------
-- Poids des statistiques par classe
---------------------------------------------------------------------------
local STAT_KEYS = {
  STR = "ITEM_MOD_STRENGTH_SHORT",
  AGI = "ITEM_MOD_AGILITY_SHORT",
  STA = "ITEM_MOD_STAMINA_SHORT",
  INT = "ITEM_MOD_INTELLECT_SHORT",
  SPI = "ITEM_MOD_SPIRIT_SHORT",
  ARMOR = "RESISTANCE0_NAME",
  DPS = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT",
  -- Puissance des sorts : clés possibles selon le client (à confirmer sur la branche forever de
  -- Gethe/wow-ui-source) ; une clé absente de l'objet ne compte pas.
  SP = "ITEM_MOD_SPELL_POWER_SHORT",
  SPELLDMG = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
  -- Soins : le nom de clé varie selon les clients, on prend la première présente.
  HEAL = { "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "ITEM_MOD_HEALING_DONE_SHORT" },
}

local WEIGHTS = {
  WARRIOR = { STR = 1, AGI = 0.6, STA = 0.5, ARMOR = 0.02, DPS = 3 },
  PALADIN = { STR = 1, STA = 0.6, INT = 0.4, AGI = 0.3, SPI = 0.2, ARMOR = 0.02, DPS = 2.5 },
  HUNTER = { AGI = 1, STA = 0.5, INT = 0.3, STR = 0.1, ARMOR = 0.01, DPS = 2 },
  ROGUE = { AGI = 1, STR = 0.5, STA = 0.4, ARMOR = 0.01, DPS = 3 },
  PRIEST = { INT = 1, SPI = 0.8, STA = 0.5, ARMOR = 0.005, DPS = 0.5 },
  SHAMAN = { STR = 0.8, INT = 0.8, STA = 0.5, AGI = 0.4, SPI = 0.3, ARMOR = 0.015, DPS = 2.5 },
  MAGE = { INT = 1, SPI = 0.6, STA = 0.5, DPS = 0.5 },
  WARLOCK = { INT = 1, STA = 0.8, SPI = 0.6, DPS = 0.5 },
  DRUID = { INT = 0.8, STR = 0.6, AGI = 0.6, SPI = 0.5, STA = 0.5, ARMOR = 0.01, DPS = 1 },
}

---------------------------------------------------------------------------
-- Profils de rôle (dans le profil d'options actif, un par classe : Q.Profiles:RewardRole ;
-- "auto" = table de classe ci-dessus)
---------------------------------------------------------------------------
-- DPS_RANGED / DPS_MELEE : poids du DPS d'arme à distance (emplacement 18) / de mêlée, si présents ;
-- sinon DPS s'applique aux deux.
local ROLE_WEIGHTS = {
  caster = { INT = 1, SPI = 0.6, STA = 0.5, SP = 1.2, SPELLDMG = 1.2, HEAL = 0.2, STR = 0.05, AGI = 0.05,
    ARMOR = 0.005, DPS = 0.2 },
  healer = { INT = 1, SPI = 0.8, STA = 0.4, SP = 1.1, HEAL = 1.1, SPELLDMG = 0.3, STR = 0.05, AGI = 0.05,
    ARMOR = 0.005, DPS = 0.1 },
  ranged = { AGI = 1, STA = 0.5, INT = 0.3, STR = 0.1, ARMOR = 0.01, DPS_RANGED = 3, DPS_MELEE = 0.5 },
}
local TANK_WEIGHTS = {
  WARRIOR = { STA = 1, STR = 0.6, AGI = 0.4, ARMOR = 0.05, DPS = 1 },
  PALADIN = { STA = 1, STR = 0.6, AGI = 0.3, INT = 0.2, ARMOR = 0.05, DPS = 1 },
  DRUID = { STA = 1, AGI = 0.7, STR = 0.3, ARMOR = 0.05, DPS = 1 },
}
-- Mêlée : la table de la classe, sauf le druide (la sienne penche vers l'intelligence).
local MELEE_OVERRIDE = {
  DRUID = { STR = 1, AGI = 0.9, STA = 0.5, ARMOR = 0.01, DPS = 1.5 },
}

-- Profils proposés par classe ("auto" est toujours disponible en plus).
local CLASS_ROLES = {
  SHAMAN = { "caster", "melee", "healer" },
  DRUID = { "caster", "melee", "tank", "healer" },
  PALADIN = { "melee", "tank", "healer" },
  PRIEST = { "caster", "healer" },
  WARRIOR = { "melee", "tank" },
  HUNTER = { "ranged", "melee" },
  ROGUE = { "melee" },
  MAGE = { "caster" },
  WARLOCK = { "caster" },
}
Rewards.CLASS_ROLES = CLASS_ROLES

-- Roles(classFile) -> { "auto", ... } : les profils de la classe, "auto" en tête.
function Rewards:Roles(classFile)
  local out = { "auto" }
  for _, r in ipairs(CLASS_ROLES[classFile] or {}) do out[#out + 1] = r end
  return out
end

-- Le sélecteur ne vaut que s'il y a un vrai choix (pas pour les classes à un seul profil).
function Rewards:HasChoice(classFile)
  return #(CLASS_ROLES[classFile] or {}) > 1
end

local function validRole(classFile, role)
  if role == "auto" then return true end
  for _, r in ipairs(CLASS_ROLES[classFile] or {}) do
    if r == role then return true end
  end
  return false
end

-- Role(classFile) -> profil choisi pour cette classe dans le profil d'options actif, "auto" s'il
-- manque ou ne convient pas à la classe.
function Rewards:Role(classFile)
  classFile = classFile or (Q.Player and Q.Player.classFile)
  local P = Q.Profiles
  local role = P and P.RewardRole and P:RewardRole(classFile)
  if type(role) == "string" and validRole(classFile, role) then return role end
  return "auto"
end

-- SetRole(role) : enregistre le profil de la classe du joueur dans le profil d'options actif
-- (ignoré s'il ne convient pas à la classe).
function Rewards:SetRole(role)
  local classFile = Q.Player and Q.Player.classFile
  local P = Q.Profiles
  if not (classFile and validRole(classFile, role) and P and P:SetRewardRole(classFile, role)) then return false end
  Q:Fire("SETTINGS_CHANGED", "rewardRole", role)
  return true
end

-- NextRole(current) -> profil suivant de la classe (boucle).
function Rewards:NextRole(current, classFile)
  classFile = classFile or (Q.Player and Q.Player.classFile)
  local roles = self:Roles(classFile)
  for i, r in ipairs(roles) do
    if r == current then return roles[i % #roles + 1] end
  end
  return roles[1]
end

-- RoleLabel(role, classFile) -> nom localisé : la spécialisation si connue, sinon le rôle.
function Rewards:RoleLabel(role, classFile)
  local L = Q.L
  classFile = classFile or (Q.Player and Q.Player.classFile)
  if role == "auto" then return L.REWARD_ROLE_AUTO end
  local up = tostring(role):upper()
  local specKey = "REWARD_SPEC_" .. tostring(classFile) .. "_" .. up
  -- Q.L renvoie la clé pour un texte absent : on ne la prend que si elle a une vraie valeur
  local spec = rawget(L, specKey)
  if spec == nil and L[specKey] ~= specKey then spec = L[specKey] end
  return spec or L["REWARD_ROLE_" .. up]
end

-- Weights(classFile, role) -> table de poids : "auto" = table de classe ; sinon le profil.
function Rewards:Weights(classFile, role)
  local base = WEIGHTS[classFile]
  if role == nil then role = self:Role(classFile) end
  if role == "auto" or not validRole(classFile, role) then return base end
  if role == "melee" then return MELEE_OVERRIDE[classFile] or base end
  if role == "tank" then return TANK_WEIGHTS[classFile] or base end
  return ROLE_WEIGHTS[role] or base
end

---------------------------------------------------------------------------
-- Emplacements d'équipement
---------------------------------------------------------------------------
local SLOTS = {
  INVTYPE_HEAD = { 1 },
  INVTYPE_NECK = { 2 },
  INVTYPE_SHOULDER = { 3 },
  INVTYPE_CHEST = { 5 },
  INVTYPE_ROBE = { 5 },
  INVTYPE_WAIST = { 6 },
  INVTYPE_LEGS = { 7 },
  INVTYPE_FEET = { 8 },
  INVTYPE_WRIST = { 9 },
  INVTYPE_HAND = { 10 },
  INVTYPE_CLOAK = { 15 },
  INVTYPE_2HWEAPON = { 16 },
  INVTYPE_WEAPONMAINHAND = { 16 },
  INVTYPE_WEAPONOFFHAND = { 17 },
  INVTYPE_SHIELD = { 17 },
  INVTYPE_HOLDABLE = { 17 },
  INVTYPE_RANGED = { 18 },
  INVTYPE_RANGEDRIGHT = { 18 },
  INVTYPE_THROWN = { 18 },
  -- deux emplacements : on compare au moins bon des deux
  INVTYPE_FINGER = { 11, 12 },
  INVTYPE_TRINKET = { 13, 14 },
  INVTYPE_WEAPON = { 16, 17 },
}

-- SlotsFor(equipLoc) -> liste d'emplacements, ou nil pour un objet non équipable.
function Rewards:SlotsFor(equipLoc)
  local slots = SLOTS[equipLoc]
  if not slots then return nil end
  local copy = {}
  for i, s in ipairs(slots) do copy[i] = s end
  return copy
end

-- Classes qui portent une arme à une main en main gauche (pas le chaman : il lui faut un talent).
local DUAL_WIELD = set("WARRIOR", "ROGUE", "HUNTER")

---------------------------------------------------------------------------
-- Lecture des objets
---------------------------------------------------------------------------
-- -> équipement, classe, sous-classe, niveau requis, prix de revente, stats, chargé ?
-- Si l'objet n'est pas encore en cache, les infos instantanées (type, classe) restent lisibles.
local function readItem(link)
  local out = { stats = {}, sellPrice = 0, minLevel = 0, loaded = false }
  if type(link) ~= "string" then return out end
  local name, _, _, _, minLevel, _, _, _, equipLoc, _, sellPrice, classID, subclassID = Q.API.GetItemInfo(link)
  if name then
    out.loaded = true
    out.name = name
    out.minLevel, out.equipLoc, out.sellPrice = minLevel or 0, equipLoc, sellPrice or 0
    out.classID, out.subclassID = classID, subclassID
  else
    local _, _, _, loc, _, cid, sid = Q.API.GetItemInfoInstant(link)
    out.equipLoc, out.classID, out.subclassID = loc, cid, sid
  end
  if Q.API.HasItemStats() then
    out.stats = Q.API.GetItemStats(link) or {}
  else
    -- sans les statistiques on ne sait pas évaluer l'objet : il compte comme non chargé
    out.loaded = false
  end
  return out
end

-- CollectChoices() -> { { index, link, equipLoc, classID, subclassID, minLevel, sellPrice, stats, loaded } }
-- Lit les choix de la fenêtre de récompense en cours.
function Rewards:CollectChoices()
  local list = {}
  local n = GetNumQuestChoices and GetNumQuestChoices() or 0
  for i = 1, n do
    local link = GetQuestItemLink("choice", i)
    local item = readItem(link)
    list[#list + 1] = {
      index = i, link = link, name = item.name, equipLoc = item.equipLoc, classID = item.classID,
      subclassID = item.subclassID, minLevel = item.minLevel, sellPrice = item.sellPrice, stats = item.stats,
      loaded = item.loaded,
    }
  end
  return list
end

-- Vrai quand toutes les infos des choix sont en cache.
function Rewards:AllLoaded(choices)
  for _, c in ipairs(choices or {}) do
    if c.loaded == false then return false end
  end
  return true
end

-- Demande au client de charger les objets absents du cache.
function Rewards:RequestLoad(choices)
  if not (C_Item and C_Item.RequestLoadItemDataByID) then return end
  for _, c in ipairs(choices or {}) do
    local id = c.loaded == false and type(c.link) == "string" and tonumber(c.link:match("item:(%d+)"))
    if id then C_Item.RequestLoadItemDataByID(id) end
  end
end

---------------------------------------------------------------------------
-- Score
---------------------------------------------------------------------------
-- Score(stats, classFile, ranged, role) : somme des poids du profil (par défaut celui du personnage)
-- appliqués aux stats de l'objet. ranged : l'objet va dans l'emplacement à distance (DPS d'arme).
function Rewards:Score(stats, classFile, ranged, role)
  local weights = self:Weights(classFile, role)
  if not weights or type(stats) ~= "table" then return 0 end
  local total = 0
  for short, weight in pairs(weights) do
    local key = STAT_KEYS[short]
    if short == "DPS_RANGED" or short == "DPS_MELEE" then
      if (short == "DPS_RANGED") == (ranged and true or false) then key = STAT_KEYS.DPS else key = nil end
    end
    local v
    if type(key) == "table" then
      for _, k in ipairs(key) do
        v = tonumber(stats[k])
        if v then break end
      end
    else
      v = key and tonumber(stats[key])
    end
    if v then total = total + v * weight end
  end
  return total
end

-- EquippedScore(slot, player) : score de l'objet porté dans l'emplacement, 0 s'il est vide.
function Rewards:EquippedScore(slot, player)
  player = player or Q.Player
  local link = GetInventoryItemLink("player", slot)
  if not link then return 0 end
  return self:Score(readItem(link).stats, player and player.classFile, slot == 18)
end

-- ComparisonSlots(equipLoc, player) -> emplacements auxquels comparer une récompense.
-- Bagues et bijoux : les deux emplacements (on compare au moins bon). Arme à une main : la main
-- gauche (17) ne compte que si la classe peut manier deux armes et y porte une vraie arme ;
-- sinon une main gauche vide ou un bouclier fausserait la comparaison.
function Rewards:ComparisonSlots(equipLoc, player)
  local slots = self:SlotsFor(equipLoc)
  if equipLoc ~= "INVTYPE_WEAPON" or not slots then return slots end
  player = player or Q.Player
  if player and DUAL_WIELD[player.classFile] then
    local link = GetInventoryItemLink("player", 17)
    if link and readItem(link).classID == 2 then return { 16, 17 } end
  end
  return { 16 }
end

-- Usable(choice, player) : l'objet est un équipement que la classe peut porter au niveau actuel.
function Rewards:Usable(choice, player)
  player = player or Q.Player
  local def = player and USABLE[player.classFile]
  if not def or type(choice) ~= "table" then return false end
  if (choice.minLevel or 0) > (player.level or 1) then return false end
  if choice.classID == 4 then
    local sub = choice.subclassID
    if sub == 0 or def.armor[sub] then return true end
    return def.late[sub] == true and (player.level or 1) >= LATE_ARMOR_LEVEL
  elseif choice.classID == 2 then
    return def.weapon[choice.subclassID] == true
  end
  return false
end

-- ReadItem(link) -> { name, equipLoc, classID, subclassID, minLevel, sellPrice, stats, loaded }
Rewards.ReadItem = function(_, link) return readItem(link) end

-- UpgradeGain(item, player, equipped) -> gain de score par rapport à l'objet porté (le moins bon des
-- emplacements comparés), ou nil si l'objet n'est pas portable par la classe à ce niveau.
-- equipped(slot) facultatif : score porté (cache de l'appelant).
function Rewards:UpgradeGain(item, player, equipped)
  player = player or Q.Player or {}
  local slots = self:Usable(item, player) and self:ComparisonSlots(item.equipLoc, player)
  if not slots then return nil end
  local base = math.huge
  for _, s in ipairs(slots) do
    base = math.min(base, equipped and equipped(s) or self:EquippedScore(s, player))
  end
  return self:Score(item.stats, player.classFile, item.equipLoc and SLOTS[item.equipLoc] and SLOTS[item.equipLoc][1] == 18) - base
end
Rewards.EPSILON = EPSILON

---------------------------------------------------------------------------
-- Choix
---------------------------------------------------------------------------
-- Pick(choices, player) -> index, reasonKey, detail
--   "upgrade" : meilleure amélioration ; detail = gain de score
--   "vendor"  : rien n'améliore ; le plus cher à la revente ; detail = prix en cuivre
-- player = { classFile, level }. Renvoie nil sans choix.
function Rewards:Pick(choices, player)
  if type(choices) ~= "table" or #choices == 0 then return nil end
  player = player or Q.Player or {}
  local equippedCache = {}
  local function equipped(slot)
    local v = equippedCache[slot]
    if v == nil then v = self:EquippedScore(slot, player); equippedCache[slot] = v end
    return v
  end

  local best, bestGain, bestPos
  for pos, c in ipairs(choices) do
    local gain = self:UpgradeGain(c, player, equipped)
    if gain then
      if gain > EPSILON then
        if not best or gain > bestGain + EPSILON
          or (math.abs(gain - bestGain) <= EPSILON and (c.sellPrice or 0) > (best.sellPrice or 0)) then
          best, bestGain, bestPos = c, gain, pos
        end
      end
    end
  end
  if best then return best.index or bestPos, "upgrade", bestGain end

  local top, topPos
  for pos, c in ipairs(choices) do
    if not top or (c.sellPrice or 0) > (top.sellPrice or 0) then top, topPos = c, pos end
  end
  return top.index or topPos, "vendor", top.sellPrice or 0
end

---------------------------------------------------------------------------
-- Message dans le chat
---------------------------------------------------------------------------
-- FormatMoney(copper) -> "1g 20s 5c"
function Rewards.FormatMoney(copper)
  copper = math.floor(tonumber(copper) or 0)
  local L = Q.L
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  local parts = {}
  if g > 0 then parts[#parts + 1] = g .. L.COIN_GOLD end
  if s > 0 then parts[#parts + 1] = s .. L.COIN_SILVER end
  if c > 0 or #parts == 0 then parts[#parts + 1] = c .. L.COIN_COPPER end
  return table.concat(parts, " ")
end

-- Describe(reasonKey, link, detail) -> texte « quoi et pourquoi ».
function Rewards:Describe(reasonKey, link, detail)
  local L = Q.L
  local shown = link or "?"
  if reasonKey == "upgrade" then return string.format(L.REWARD_UPGRADE, shown) end
  return string.format(L.REWARD_VENDOR, shown, self.FormatMoney(detail))
end
