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
-- Profils de rôle (réglage propre au personnage, Q.char.rewardRole, hors profils d'options : jamais
-- partagé, exporté ni changé par un changement de profil ; absent = "auto", table de classe ci-dessus)
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

-- Role(classFile) -> profil choisi pour ce personnage, "auto" s'il manque ou ne convient pas à la classe.
function Rewards:Role(classFile)
  classFile = classFile or (Q.Player and Q.Player.classFile)
  local role = Q.char and Q.char.rewardRole
  if type(role) == "string" and validRole(classFile, role) then return role end
  return "auto"
end

-- SetRole(role) : enregistre le profil du personnage dans Q.char (ignoré s'il ne convient pas à la
-- classe).
function Rewards:SetRole(role)
  local classFile = Q.Player and Q.Player.classFile
  if not (Q.char and validRole(classFile, role)) then return false end
  Q.char.rewardRole = role
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

-- Objets de la main droite seule ou des deux mains au choix (armes à une main), et objets de la
-- main gauche seule (une arme à une main « INVTYPE_WEAPON » n'en fait pas partie).
local MAIN_HAND = set("INVTYPE_WEAPON", "INVTYPE_WEAPONMAINHAND")
local OFF_HAND = set("INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_WEAPONOFFHAND")

-- Repli quand le jeu ne dit pas si la compétence est apprise (CanDualWield absent) : niveau
-- d'apprentissage habituel de la classe. Le chaman (talent) n'en fait pas partie.
local DUAL_WIELD_LEVEL = { ROGUE = 10, WARRIOR = 20, HUNTER = 20 }

-- Arme en main gauche : classe à deux armes, et compétence apprise (CanDualWield quand le jeu le
-- fournit, sinon le repli par niveau ci-dessus).
local function dualWields(player)
  if not (player and DUAL_WIELD[player.classFile]) then return false end
  if type(CanDualWield) == "function" then return CanDualWield() and true or false end
  return (player.level or 1) >= (DUAL_WIELD_LEVEL[player.classFile] or math.huge)
end

---------------------------------------------------------------------------
-- Lecture des objets
---------------------------------------------------------------------------
-- -> lien, équipement, classe, sous-classe, niveau requis, prix de revente, lien d'objet (bindType),
-- stats, chargé ? Si l'objet n'est pas encore en cache, les infos instantanées (type, classe)
-- restent lisibles.
local function readItem(link)
  local out = { stats = {}, sellPrice = 0, minLevel = 0, loaded = false }
  if type(link) ~= "string" then return out end
  out.link = link
  local name, _, _, _, minLevel, _, _, _, equipLoc, _, sellPrice, classID, subclassID, bindType =
    Q.API.GetItemInfo(link)
  if name then
    out.loaded = true
    out.name = name
    out.minLevel, out.equipLoc, out.sellPrice = minLevel or 0, equipLoc, sellPrice or 0
    out.classID, out.subclassID, out.bindType = classID, subclassID, bindType
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

local BAGS = { 0, 1, 2, 3, 4 }

local function numSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) or 0 end
  if GetContainerNumSlots then return GetContainerNumSlots(bag) or 0 end
  return 0
end

local function slotLink(bag, slot)
  if C_Container and C_Container.GetContainerItemLink then return C_Container.GetContainerItemLink(bag, slot) end
  if GetContainerItemLink then return GetContainerItemLink(bag, slot) end
  return nil
end

-- BagItems() -> équipements des sacs, lus comme ReadItem (avec leur lien) : candidats pour l'autre
-- moitié d'une paire main droite + main gauche. Les objets pas encore en cache sont laissés de côté.
function Rewards:BagItems()
  local list = {}
  for _, bag in ipairs(BAGS) do
    for slot = 1, numSlots(bag) do
      local link = slotLink(bag, slot)
      if not Q.Util.IsSecret(link) and type(link) == "string" then
        local it = readItem(link)
        if it.loaded and it.equipLoc and it.equipLoc ~= "" then list[#list + 1] = it end
      end
    end
  end
  return list
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

-- inventoryItem(slot) -> objet porté dans l'emplacement (lu comme ReadItem), nil s'il est vide.
local function inventoryItem(slot)
  local link = GetInventoryItemLink("player", slot)
  if not link then return nil end
  return readItem(link)
end

-- slotReader(equipped) -> fonction(slot) -> objet porté ou nil. Quand l'appelant fournit
-- equipped(slot) (comparaison simulée, cache), c'est la seule lecture de ce qui est porté : jamais
-- l'inventaire réel à côté. equipped(slot) renvoie l'objet lu (table de ReadItem) ou nil ;
-- l'ancienne forme qui renvoie un score reste acceptée (objet de nature inconnue).
local function slotReader(equipped)
  if not equipped then return inventoryItem end
  return function(slot)
    local v = equipped(slot)
    if type(v) == "number" then return { score = v, stats = {} } end
    if type(v) == "table" then return v end
    return nil
  end
end

-- ComparisonSlots(equipLoc, player, slotItem) -> emplacements auxquels comparer une récompense.
-- Bagues et bijoux : les deux emplacements (on compare au moins bon). Arme à une main : la main
-- gauche (17) ne compte que si la classe peut manier deux armes et y porte une vraie arme ;
-- sinon une main gauche vide ou un bouclier fausserait la comparaison.
-- slotItem(slot) facultatif : lecteur de l'objet porté (par défaut l'inventaire du joueur).
function Rewards:ComparisonSlots(equipLoc, player, slotItem)
  local slots = self:SlotsFor(equipLoc)
  if equipLoc ~= "INVTYPE_WEAPON" or not slots then return slots end
  player = player or Q.Player
  if player and DUAL_WIELD[player.classFile] then
    local off = (slotItem or inventoryItem)(17)
    if off and off.classID == 2 then return { 16, 17 } end
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

-- ReadItem(link) -> { link, name, equipLoc, classID, subclassID, bindType, minLevel, sellPrice, stats, loaded }
Rewards.ReadItem = function(_, link) return readItem(link) end

---------------------------------------------------------------------------
-- Paire main droite + main gauche
---------------------------------------------------------------------------
-- L'objet peut-il aller en main droite (arme à une main) / en main gauche ?
local function fitsMain(self, it, player)
  return MAIN_HAND[it.equipLoc] == true and self:Usable(it, player)
end
local function fitsOff(self, it, player)
  local loc = it.equipLoc
  if loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONOFFHAND" then
    return dualWields(player) and self:Usable(it, player)
  end
  return OFF_HAND[loc] == true and self:Usable(it, player)
end

-- others(bags, item) : la réserve sans l'objet évalué (un seul exemplaire retiré, par son lien :
-- l'objet qu'on évalue est souvent lui-même dans les sacs).
local function others(bags, item)
  local out, skipped = {}, false
  for _, it in ipairs(bags or {}) do
    if not skipped and item.link ~= nil and it.link == item.link then
      skipped = true
    else
      out[#out + 1] = it
    end
  end
  return out
end

-- bestPoolPair(player, pool) -> valeur de la meilleure paire (ou moitié seule) déjà dans la réserve.
local function bestPoolPair(self, player, pool)
  local classFile = player.classFile
  local best = 0
  for i, m in ipairs(pool) do
    local v = self:Score(m.stats, classFile)
    if fitsMain(self, m, player) then
      if v > best then best = v end
      for j, o in ipairs(pool) do
        if j ~= i and fitsOff(self, o, player) then
          local pair = v + self:Score(o.stats, classFile)
          if pair > best then best = pair end
        end
      end
    elseif fitsOff(self, m, player) and v > best then
      best = v
    end
  end
  return best
end

-- bestPair(item, player, pool) -> valeur de la meilleure paire qui contient l'objet, main droite,
-- main gauche. L'autre moitié vient de la réserve, ou la main reste vide.
local function bestPair(self, item, player, pool)
  local classFile = player.classFile
  local bestValue, bestMain, bestOff
  local function try(main, off)
    local v = (main and self:Score(main.stats, classFile) or 0) + (off and self:Score(off.stats, classFile) or 0)
    if not bestValue or v > bestValue + EPSILON then bestValue, bestMain, bestOff = v, main, off end
  end
  if fitsMain(self, item, player) then
    try(item, nil)
    for _, o in ipairs(pool) do
      if fitsOff(self, o, player) then try(item, o) end
    end
  end
  if fitsOff(self, item, player) then
    try(nil, item)
    for _, m in ipairs(pool) do
      if fitsMain(self, m, player) then try(m, item) end
    end
  end
  return bestValue, bestMain, bestOff
end

-- UpgradeGain(item, player, equipped, bags) -> gain de score par rapport à l'objet porté (le moins
-- bon des emplacements comparés), ou nil si l'objet n'est pas portable par la classe à ce niveau.
--   equipped(slot) facultatif : objet porté (voir slotReader) ; remplace la lecture de l'inventaire.
--   bags facultatif : équipements des sacs (liste de ReadItem), par défaut lus dans les sacs.
-- Arme à deux mains portée : une arme à une main ou un objet de main gauche ne vaut que dans une
-- paire (meilleure autre moitié des sacs, ou main vide) qui bat à la fois l'arme à deux mains et la
-- meilleure paire déjà dans les sacs sans lui ; le second résultat est alors cette paire
-- { main = objet, off = objet } quand l'autre moitié vient des sacs.
function Rewards:UpgradeGain(item, player, equipped, bags)
  player = player or Q.Player or {}
  local slotItem = slotReader(equipped)
  local slots = self:Usable(item, player) and self:ComparisonSlots(item.equipLoc, player, slotItem)
  if not slots then return nil end
  local function score(s)
    local it = slotItem(s)
    if not it then return 0 end
    return it.score or self:Score(it.stats, player.classFile, s == 18)
  end
  local loc = item.equipLoc
  local own = self:Score(item.stats, player.classFile, SLOTS[loc] ~= nil and SLOTS[loc][1] == 18)
  if loc == "INVTYPE_2HWEAPON" then
    -- une arme à deux mains libère aussi la main gauche : elle doit battre les deux mains réunies
    return own - (score(16) + score(17))
  end
  local main = slotItem(16)
  if main and main.equipLoc == "INVTYPE_2HWEAPON" and (MAIN_HAND[loc] or OFF_HAND[loc]) then
    -- arme à deux mains portée : l'équiper ou équiper une main gauche la retire ; la paire formée
    -- avec la meilleure autre moitié des sacs (ou une main vide) doit battre l'arme à deux mains,
    -- et aussi la meilleure paire que les sacs forment déjà sans l'objet
    local pool = others(bags or self:BagItems(), item)
    local value, m, o = bestPair(self, item, player, pool)
    if not value then return nil end
    local gain = value - math.max(score(16) + score(17), bestPoolPair(self, player, pool))
    if (m and m ~= item) or (o and o ~= item) then return gain, { main = m, off = o } end
    return gain
  end
  local base = math.huge
  for _, s in ipairs(slots) do base = math.min(base, score(s)) end
  return own - base
end
Rewards.EPSILON = EPSILON

-- FitsMain(item, player) / FitsOff(item, player) : l'objet, portable par la classe, peut aller en
-- main droite (arme à une main) / en main gauche (bouclier, objet de main gauche, ou arme pour une
-- classe qui porte deux armes).
function Rewards:FitsMain(item, player) return fitsMain(self, item, player or Q.Player or {}) == true end
function Rewards:FitsOff(item, player) return fitsOff(self, item, player or Q.Player or {}) == true end

-- EquippedItem(slot, equipped) -> objet porté dans l'emplacement (lu comme ReadItem), ou nil.
function Rewards:EquippedItem(slot, equipped) return slotReader(equipped)(slot) end

-- FillsEmptySlot(item, player, equipped) : l'objet, portable par la classe, irait dans un
-- emplacement vide. Main gauche : seulement à côté d'une main droite qui la laisse libre (pas
-- d'arme à deux mains), et pour une arme, seulement si la classe porte deux armes.
function Rewards:FillsEmptySlot(item, player, equipped)
  player = player or Q.Player or {}
  if not self:Usable(item, player) then return false end
  local slotItem = slotReader(equipped)
  local loc = item.equipLoc
  local main = slotItem(16)
  if (loc == "INVTYPE_2HWEAPON" or MAIN_HAND[loc]) and main == nil then return true end
  if fitsOff(self, item, player) then
    return slotItem(17) == nil and not (main and main.equipLoc == "INVTYPE_2HWEAPON")
  end
  if loc == "INVTYPE_2HWEAPON" or MAIN_HAND[loc] or OFF_HAND[loc] then return false end
  for _, s in ipairs(self:SlotsFor(loc) or {}) do
    if slotItem(s) == nil then return true end
  end
  return false
end

---------------------------------------------------------------------------
-- Objets recommandés (annonce d'amélioration, récompense choisie pour une paire)
---------------------------------------------------------------------------
local RECOMMENDED_TIME = 600   -- secondes pendant lesquelles un objet recommandé n'est pas vendu
local recommended = {}         -- { [ID d'objet] = GetTime() }

-- ID d'objet d'un lien (ou d'une chaîne « item:123 »), d'un ID, ou d'un nom connu du client ; sinon nil.
-- Le lien d'une récompense de quête et celui du même objet dans le sac peuvent différer (champs de
-- niveau, de bonus…) : les objets recommandés sont donc retenus par ID.
local function itemIdOf(item)
  if type(item) == "number" then return item end
  if type(item) ~= "string" then return nil end
  local id = tonumber(item:match("item:(%d+)"))
  if id then return id end
  local ok, instant = pcall(Q.API.GetItemInfoInstant, item)
  return ok and type(instant) == "number" and instant or nil
end

-- Recommend(link, ...) : retient les objets qu'on vient de recommander d'équiper.
function Rewards:Recommend(...)
  local now = GetTime and GetTime() or 0
  for i = 1, select("#", ...) do
    local id = itemIdOf(select(i, ...))
    if id then recommended[id] = now end
  end
end

-- Recommended(link) : objet recommandé il y a peu (seul ou moitié d'une paire), par ID d'objet.
function Rewards:Recommended(link)
  local id = itemIdOf(link)
  local at = id and recommended[id]
  if not at then return false end
  local now = GetTime and GetTime() or 0
  return now - at <= RECOMMENDED_TIME
end

---------------------------------------------------------------------------
-- Choix
---------------------------------------------------------------------------
-- Pick(choices, player, equipped, bags) -> index, reasonKey, detail
--   "upgrade" : meilleure amélioration ; detail = gain de score
--   "vendor"  : rien n'améliore ; le plus cher à la revente ; detail = prix en cuivre
-- player = { classFile, level }. equipped, bags : comme UpgradeGain (par défaut l'inventaire et les
-- sacs du joueur, lus une fois). Renvoie nil sans choix.
function Rewards:Pick(choices, player, equipped, bags)
  if type(choices) ~= "table" or #choices == 0 then return nil end
  player = player or Q.Player or {}
  local read = slotReader(equipped)
  local equippedCache = {}
  local function cached(slot)
    local v = equippedCache[slot]
    if v == nil then v = read(slot) or false; equippedCache[slot] = v end
    return v or nil
  end
  -- les sacs ne servent qu'avec une arme à deux mains portée (paire main droite + main gauche)
  if not bags then
    local main = cached(16)
    bags = (main and main.equipLoc == "INVTYPE_2HWEAPON") and self:BagItems() or {}
  end

  local best, bestGain, bestPos, bestPair
  for pos, c in ipairs(choices) do
    local gain, pair = self:UpgradeGain(c, player, cached, bags)
    if gain then
      if gain > EPSILON then
        if not best or gain > bestGain + EPSILON
          or (math.abs(gain - bestGain) <= EPSILON and (c.sellPrice or 0) > (best.sellPrice or 0)) then
          best, bestGain, bestPos, bestPair = c, gain, pos, pair
        end
      end
    end
  end
  if best then
    -- récompense choisie (et l'autre moitié de sa paire) : la vente automatique ne la prend pas
    self:Recommend(best.link, bestPair and bestPair.main.link, bestPair and bestPair.off.link)
    return best.index or bestPos, "upgrade", bestGain
  end

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
