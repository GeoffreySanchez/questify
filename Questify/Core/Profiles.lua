local addonName, Q = ...

-- Profils d'options (QuestifyDB.profiles[nom]) : chaque profil garde toutes les valeurs de
-- Q.Settings (dont la position, la taille, la largeur, le thème et l'opacité du suivi) et le
-- profil de butin de chaque classe :
--   QuestifyDB.profiles[nom] = { settings = { ... arbre de Q.Settings ... }, rewardRole = { [classe] = rôle } }
--   QuestifyDB.profileKeys["Nom - Royaume"] = nom du profil de ce personnage
--   QuestifyDB.profileMode = "account" | "character" : choix appliqué aux personnages vus pour la
--   première fois (« Par compte » : le profil partagé « Default » ; « Par personnage » : un
--   profil à son nom, copié du profil partagé).
-- L'état de progression du personnage (chapitre, étapes cochées ou passées, quêtes de classe,
-- mesures…) reste dans QuestifyCharDB, hors des profils.
-- Migration (premier chargement) : QuestifyDB.settings devient le profil « Default », puis le
-- profil de butin de chaque personnage (Q.char.rewardRole) passe dans le profil actif, pour sa classe.
-- Changer de profil (ou le copier, le réinitialiser, l'importer) réapplique tout à chaud : un
-- SETTINGS_CHANGED par réglage dont la valeur change (et "rewardRole"), puis PROFILE_CHANGED(nom).
-- Partage : « QFY1: » + base64 d'une table sérialisée de façon déterministe (sérialiseur et
-- base64 en Lua pur). L'import n'utilise jamais loadstring : lecture stricte du format, chaque
-- valeur contrôlée par le schéma (Core/OptionsSchema.lua), clés inconnues ignorées, nombres
-- ramenés entre min et max, choix vérifiés, longueur limitée, et jamais d'erreur Lua.
local Profiles = {}
Q.Profiles = Profiles

local DEFAULT = "Default"
local PREFIX = "QFY1:"
local FORMAT_VERSION = 1
local MAX_IMPORT = 20000          -- caractères acceptés à l'import
local MAX_NAME = 32               -- longueur d'un nom de profil
local MAX_DEPTH = 8               -- tables imbriquées acceptées à la lecture
local MAX_ITEMS = 4000            -- valeurs lues au plus
Profiles.DEFAULT, Profiles.PREFIX, Profiles.MAX_IMPORT, Profiles.MAX_NAME = DEFAULT, PREFIX, MAX_IMPORT, MAX_NAME

local active = DEFAULT            -- nom du profil actif

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function deepcopy(v, depth)
  if type(v) ~= "table" then return v end
  depth = depth or 0
  if depth > 20 then return nil end
  local out = {}
  for k, val in pairs(v) do out[k] = deepcopy(val, depth + 1) end
  return out
end
Profiles.DeepCopy = deepcopy

local function deepEqual(a, b)
  if a == b then return true end
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end

local function split(path)
  local parts = {}
  for p in tostring(path):gmatch("[^%.]+") do parts[#parts + 1] = p end
  return parts
end

local function walk(t, path)
  for _, p in ipairs(split(path)) do
    if type(t) ~= "table" then return nil end
    t = t[p]
  end
  return t
end

local function setPath(t, path, value)
  local parts = split(path)
  for i = 1, #parts - 1 do
    local p = parts[i]
    if type(t[p]) ~= "table" then t[p] = {} end
    t = t[p]
  end
  t[parts[#parts]] = value
end

local function db() return Q.db end

local function playerClass()
  local P = Q.Player
  if P and type(P.classFile) == "string" then return P.classFile end
  if UnitClass then
    local ok, _, cf = pcall(UnitClass, "player")
    if ok and type(cf) == "string" and not (Q.Util and Q.Util.IsSecret(cf)) then return cf end
  end
  return nil
end

-- Profil bien formé : { settings = {}, rewardRole = {} }.
local function normalizeProfile(p)
  if type(p) ~= "table" then p = {} end
  if type(p.settings) ~= "table" then p.settings = {} end
  if type(p.rewardRole) ~= "table" then p.rewardRole = {} end
  return p
end

---------------------------------------------------------------------------
-- Personnage
---------------------------------------------------------------------------
-- CharKey() -> « Nom - Royaume », ou nil tant que le nom n'est pas connu.
function Profiles:CharKey()
  local name = UnitName and UnitName("player")
  local realm = GetRealmName and GetRealmName()
  if type(name) ~= "string" or name == "" or (Q.Util and Q.Util.IsSecret(name)) then return nil end
  if name == UNKNOWNOBJECT then return nil end   -- nom pas encore connu (« Inconnu »)
  if type(realm) ~= "string" or realm == "" then realm = "?" end
  return name .. " - " .. realm
end

---------------------------------------------------------------------------
-- Mise en place et migration (ADDON_LOADED, avant l'INIT des modules)
---------------------------------------------------------------------------
-- Profil de butin du personnage (ancien réglage Q.char.rewardRole) : passé dans le profil actif
-- pour sa classe, sauf si ce profil en a déjà un. Rien à faire tant que la classe est inconnue.
local function migrateCharRole()
  local c, d = Q.char, db()
  if type(c) ~= "table" or not d or c.rewardRole == nil then return end
  local cf = playerClass()
  if not cf then return end
  local p = normalizeProfile(d.profiles[active])
  d.profiles[active] = p
  if type(c.rewardRole) == "string" and p.rewardRole[cf] == nil then p.rewardRole[cf] = c.rewardRole end
  c.rewardRole = nil
end

-- Profil du personnage d'après profileKeys ; personnage vu pour la première fois : selon
-- profileMode (« character » : un profil à son nom, copié de « Default »).
local function resolveCharacter()
  local d = db()
  local key = Profiles:CharKey()
  if not key then return DEFAULT end
  local name = d.profileKeys[key]
  if type(name) == "string" and d.profiles[name] then return name end
  if d.profileMode == "character" then
    name = key
    if not d.profiles[name] then d.profiles[name] = deepcopy(d.profiles[DEFAULT]) end
  else
    name = DEFAULT
  end
  d.profileKeys[key] = name
  return name
end

-- Setup() : appelé par Core/Init.lua à ADDON_LOADED, une fois Q.db et Q.char posés.
function Profiles:Setup()
  local d = db()
  if type(d) ~= "table" then return end
  if type(d.profiles) ~= "table" then
    -- première fois : les anciens réglages du compte deviennent le profil « Default »
    d.profiles = {}
    d.profiles[DEFAULT] = { settings = type(d.settings) == "table" and deepcopy(d.settings) or {}, rewardRole = {} }
    d.settings = nil
  end
  for name, p in pairs(d.profiles) do
    if type(name) ~= "string" then d.profiles[name] = nil else d.profiles[name] = normalizeProfile(p) end
  end
  if not d.profiles[DEFAULT] then d.profiles[DEFAULT] = normalizeProfile({}) end
  if type(d.profileKeys) ~= "table" then d.profileKeys = {} end
  if d.profileMode ~= "character" then d.profileMode = "account" end
  active = resolveCharacter()
  self.keyKnown = self:CharKey() ~= nil
  migrateCharRole()
end

-- À la connexion : nom du personnage enfin connu, ou classe connue pour la migration.
Q:On("LOGIN", function()
  if not db() or not db().profiles then return end
  if not Profiles.keyKnown and Profiles:CharKey() then
    Profiles.keyKnown = true
    local name = resolveCharacter()
    if name ~= active then Profiles:SetActive(name) end
  end
  migrateCharRole()
end)

---------------------------------------------------------------------------
-- Accès
---------------------------------------------------------------------------
function Profiles:Active() return active end

-- Data(nom) -> table du profil (actif par défaut), ou nil.
function Profiles:Data(name)
  local d = db()
  if not (d and type(d.profiles) == "table") then return nil end
  local p = d.profiles[name or active]
  if p then return normalizeProfile(p) end
  return nil
end

-- Store() -> arbre des réglages du profil actif (lu et écrit par Q.Settings), ou nil avant l'INIT.
-- Appelé à chaque Q.Settings:Get : accès direct, sans copie.
function Profiles:Store()
  local d = Q.db
  local p = d and type(d.profiles) == "table" and d.profiles[active]
  if type(p) ~= "table" then return nil end
  local st = p.settings
  if type(st) ~= "table" then
    st = {}
    p.settings = st
  end
  return st
end

function Profiles:Exists(name)
  return type(name) == "string" and self:Data(name) ~= nil
end

-- List() -> noms des profils : « Default » d'abord, les autres par ordre alphabétique.
function Profiles:List()
  local d = db()
  local out = {}
  if not (d and type(d.profiles) == "table") then return { DEFAULT } end
  for name in pairs(d.profiles) do
    if name ~= DEFAULT then out[#out + 1] = name end
  end
  table.sort(out, function(a, b) return a:lower() < b:lower() end)
  table.insert(out, 1, DEFAULT)
  return out
end

-- Nom affiché : « Default » est traduit (« Par défaut »).
function Profiles:DisplayName(name)
  if name == DEFAULT then return Q.L.PROFILE_DEFAULT_NAME end
  return tostring(name)
end

-- Mode() -> "account" (profil partagé « Default »), "character" (profil au nom du personnage)
-- ou "custom" (un autre profil choisi à la main).
function Profiles:Mode()
  if active == DEFAULT then return "account" end
  if active == self:CharKey() then return "character" end
  return "custom"
end

-- Profil de butin d'une classe dans le profil actif (nil : aucun choix).
function Profiles:RewardRole(classFile)
  local p = self:Data()
  if not (p and classFile) then return nil end
  local role = p.rewardRole[classFile]
  if type(role) == "string" then return role end
  return nil
end

function Profiles:SetRewardRole(classFile, role)
  local p = self:Data()
  if not (p and type(classFile) == "string" and type(role) == "string") then return false end
  p.rewardRole[classFile] = role
  return true
end

---------------------------------------------------------------------------
-- Réapplication à chaud
---------------------------------------------------------------------------
-- Chemins comparés : toutes les valeurs par défaut et tous les chemins du schéma.
local function knownPaths()
  local seen, out = {}, {}
  local function addPath(p) if not seen[p] then seen[p] = true; out[#out + 1] = p end end
  local function leaves(t, prefix, depth)
    if type(t) ~= "table" or depth > 6 then return end
    for k, v in pairs(t) do
      if type(k) == "string" then
        local path = prefix and (prefix .. "." .. k) or k
        if type(v) == "table" then leaves(v, path, depth + 1) else addPath(path) end
      end
    end
  end
  leaves(Q.Settings and Q.Settings.defaults, nil, 1)
  local S = Q.OptionsSchema
  if S then for path in pairs(S:Paths()) do addPath(path) end end
  table.sort(out)
  return out
end
Profiles.KnownPaths = knownPaths

local function snapshot()
  local snap = { values = {} }
  for _, path in ipairs(knownPaths()) do snap.values[path] = deepcopy(Q.Settings:Get(path)) end
  snap.role = Q.Rewards and Q.Rewards:Role() or nil
  return snap
end

-- Exécute fn (qui change le profil actif ou son contenu), puis prévient les modules de chaque
-- valeur qui a changé (SETTINGS_CHANGED, dans l'ordre alphabétique des chemins).
local function withChanges(fn)
  local before = snapshot()
  fn()
  Profiles.applying = true
  local ok, err = pcall(function()
    for _, path in ipairs(knownPaths()) do
      local now = Q.Settings:Get(path)
      if not deepEqual(before.values[path], now) then Q:Fire("SETTINGS_CHANGED", path, now) end
    end
    local role = Q.Rewards and Q.Rewards:Role() or nil
    if role ~= before.role then Q:Fire("SETTINGS_CHANGED", "rewardRole", role) end
  end)
  Profiles.applying = false
  if not ok then Q:ReportError(err) end
  Q:Fire("PROFILE_CHANGED", active)
end

---------------------------------------------------------------------------
-- Gestion
---------------------------------------------------------------------------
-- Nom de profil valide : 1 à 32 caractères, sans caractère de contrôle ni « | ».
function Profiles:CleanName(name)
  if type(name) ~= "string" then return nil, Q.L.PROFILE_ERR_NAME end
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" or #name > MAX_NAME or name:find("[%c|]") then return nil, Q.L.PROFILE_ERR_NAME end
  -- « Par défaut » est le nom affiché du profil « Default »
  if name ~= DEFAULT and name:lower() == tostring(Q.L.PROFILE_DEFAULT_NAME):lower() then
    return nil, Q.L.PROFILE_ERR_EXISTS
  end
  return name
end

-- SetActive(nom) -> ok, erreur : ce personnage utilise ce profil (réappliqué à chaud).
function Profiles:SetActive(name)
  local d = db()
  if not d then return false end
  if not self:Exists(name) then return false, Q.L.PROFILE_ERR_UNKNOWN end
  if name == active then return true end
  withChanges(function()
    active = name
    local key = self:CharKey()
    if key then d.profileKeys[key] = name end
  end)
  return true
end

-- SetMode("account" | "character") : profil partagé, ou profil au nom du personnage (créé
-- d'après le profil actif). Retenu pour les personnages vus pour la première fois.
function Profiles:SetMode(mode)
  local d = db()
  if not d then return false end
  if mode == "account" then
    d.profileMode = "account"
    return self:SetActive(DEFAULT)
  elseif mode == "character" then
    local key = self:CharKey()
    if not key then return false, Q.L.PROFILE_ERR_UNKNOWN end
    d.profileMode = "character"
    if not d.profiles[key] then d.profiles[key] = deepcopy(self:Data()) end
    return self:SetActive(key)
  end
  return false
end

-- Create(nom, source) -> nom, erreur : nouveau profil vide (valeurs par défaut) ou copie de source.
function Profiles:Create(name, source)
  local d = db()
  if not d then return nil end
  local clean, err = self:CleanName(name)
  if not clean then return nil, err end
  if d.profiles[clean] then return nil, Q.L.PROFILE_ERR_EXISTS end
  if source ~= nil and not self:Exists(source) then return nil, Q.L.PROFILE_ERR_UNKNOWN end
  d.profiles[clean] = source and deepcopy(self:Data(source)) or normalizeProfile({})
  Q:Fire("PROFILE_CHANGED", active)
  return clean
end

-- CopyFrom(source) -> ok, erreur : le profil actif prend toutes les valeurs de source.
function Profiles:CopyFrom(source)
  local d = db()
  if not d then return false end
  if not self:Exists(source) then return false, Q.L.PROFILE_ERR_UNKNOWN end
  if source == active then return false, Q.L.PROFILE_ERR_SAME end
  withChanges(function() d.profiles[active] = deepcopy(self:Data(source)) end)
  return true
end

-- Delete(nom) -> ok, erreur : jamais le profil actif ni « Default ». Les personnages qui
-- l'utilisaient retrouvent leur profil par défaut à leur prochaine connexion.
function Profiles:Delete(name)
  local d = db()
  if not d then return false end
  if not self:Exists(name) then return false, Q.L.PROFILE_ERR_UNKNOWN end
  if name == active then return false, Q.L.PROFILE_ERR_ACTIVE end
  if name == DEFAULT then return false, Q.L.PROFILE_ERR_DEFAULT end
  d.profiles[name] = nil
  for key, p in pairs(d.profileKeys) do
    if p == name then d.profileKeys[key] = nil end
  end
  Q:Fire("PROFILE_CHANGED", active)
  return true
end

-- Deletable() -> profils qu'on peut supprimer (ni l'actif ni « Default »).
function Profiles:Deletable()
  local out = {}
  for _, name in ipairs(self:List()) do
    if name ~= active and name ~= DEFAULT then out[#out + 1] = name end
  end
  return out
end

-- Others() -> profils autres que l'actif (copie).
function Profiles:Others()
  local out = {}
  for _, name in ipairs(self:List()) do
    if name ~= active then out[#out + 1] = name end
  end
  return out
end

-- Reset() : le profil actif revient aux valeurs par défaut (position du suivi comprise).
function Profiles:Reset()
  local d = db()
  if not d then return false end
  withChanges(function() d.profiles[active] = normalizeProfile({}) end)
  return true
end

---------------------------------------------------------------------------
-- Base64 (Lua pur, sans bibliothèque bit)
---------------------------------------------------------------------------
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64_INDEX = {}
for i = 1, 64 do B64_INDEX[B64:byte(i)] = i - 1 end
local floor = math.floor

function Profiles.Base64Encode(s)
  local out = {}
  for i = 1, #s, 3 do
    local a, b, c = s:byte(i, i + 2)
    local n = a * 65536 + (b or 0) * 256 + (c or 0)
    local c1, c2 = floor(n / 262144) % 64, floor(n / 4096) % 64
    local c3, c4 = floor(n / 64) % 64, n % 64
    out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
      .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
  end
  return table.concat(out)
end

-- Base64Decode(texte) -> chaîne, ou nil si un caractère ou la longueur ne convient pas.
function Profiles.Base64Decode(s)
  if type(s) ~= "string" or #s % 4 ~= 0 then return nil end
  local out = {}
  for i = 1, #s, 4 do
    local q1, q2, q3, q4 = s:byte(i, i + 3)
    local v1, v2 = B64_INDEX[q1], B64_INDEX[q2]
    if not (v1 and v2) then return nil end
    local pad3, pad4 = q3 == 61, q4 == 61   -- « = »
    local last = i + 3 == #s
    if (pad3 or pad4) and not last then return nil end
    if pad3 and not pad4 then return nil end
    local v3 = pad3 and 0 or B64_INDEX[q3]
    local v4 = pad4 and 0 or B64_INDEX[q4]
    if not (v3 and v4) then return nil end
    local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
    local a, b, c = floor(n / 65536) % 256, floor(n / 256) % 256, n % 256
    if pad3 then
      out[#out + 1] = string.char(a)
    elseif pad4 then
      out[#out + 1] = string.char(a, b)
    else
      out[#out + 1] = string.char(a, b, c)
    end
  end
  return table.concat(out)
end

---------------------------------------------------------------------------
-- Sérialisation déterministe
---------------------------------------------------------------------------
-- Format : T / F (booléens), N<nombre>; , S<longueur>:<octets> , { clé valeur ... }.
-- Clés : nombres (d'abord, croissants) puis chaînes (ordre des octets). nil et les autres types
-- (fonctions…) sont refusés.
local function numberText(v)
  if v ~= v or v == math.huge or v == -math.huge then error("number not finite") end
  if v % 1 == 0 and math.abs(v) < 2 ^ 53 then return string.format("%d", v) end
  local s = string.format("%.14g", v)
  if tonumber(s) ~= v then s = string.format("%.17g", v) end
  return s
end

local function keyLess(a, b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then return ta == "number" end
  return a < b
end

local function serialize(v, out, depth)
  local t = type(v)
  if t == "boolean" then
    out[#out + 1] = v and "T" or "F"
  elseif t == "number" then
    out[#out + 1] = "N" .. numberText(v) .. ";"
  elseif t == "string" then
    out[#out + 1] = "S" .. #v .. ":" .. v
  elseif t == "table" then
    if depth >= MAX_DEPTH then error("table too deep") end
    local keys = {}
    for k in pairs(v) do
      local kt = type(k)
      if kt ~= "string" and kt ~= "number" then error("bad key type") end
      keys[#keys + 1] = k
    end
    table.sort(keys, keyLess)
    out[#out + 1] = "{"
    for _, k in ipairs(keys) do
      serialize(k, out, depth + 1)
      serialize(v[k], out, depth + 1)
    end
    out[#out + 1] = "}"
  else
    error("bad value type")
  end
end

function Profiles.Serialize(v)
  local out = {}
  serialize(v, out, 0)
  return table.concat(out)
end

-- Lecture stricte (jamais loadstring) : -> valeur, ou nil et la raison.
function Profiles.Deserialize(s)
  if type(s) ~= "string" then return nil, "not a string" end
  local pos, count = 1, 0
  local len = #s
  local parse
  local function fail(msg) error({ msg = msg }, 0) end
  local function parseNumber()
    local stop = s:find(";", pos, true)
    if not stop or stop - pos > 32 or stop == pos then fail("bad number") end
    local text = s:sub(pos, stop - 1)
    if not text:match("^%-?[%d%.]+[eE]?[%+%-]?%d*$") then fail("bad number") end
    local n = tonumber(text)
    if not n or n ~= n or n == math.huge or n == -math.huge then fail("bad number") end
    pos = stop + 1
    return n
  end
  local function parseString()
    local colon = s:find(":", pos, true)
    if not colon or colon - pos > 6 or colon == pos then fail("bad string") end
    local digits = s:sub(pos, colon - 1)
    if not digits:match("^%d+$") then fail("bad string") end
    local n = tonumber(digits)
    if colon + n > len then fail("bad string") end
    local str = s:sub(colon + 1, colon + n)
    pos = colon + n + 1
    return str
  end
  parse = function(depth)
    count = count + 1
    if count > MAX_ITEMS then fail("too many values") end
    if pos > len then fail("unexpected end") end
    local tag = s:sub(pos, pos)
    pos = pos + 1
    if tag == "T" then return true end
    if tag == "F" then return false end
    if tag == "N" then return parseNumber() end
    if tag == "S" then return parseString() end
    if tag == "{" then
      if depth >= MAX_DEPTH then fail("too deep") end
      local t = {}
      while true do
        if pos > len then fail("unexpected end") end
        if s:sub(pos, pos) == "}" then
          pos = pos + 1
          return t
        end
        local ktag = s:sub(pos, pos)
        if ktag ~= "S" and ktag ~= "N" then fail("bad key") end
        local k = parse(depth + 1)
        local v = parse(depth + 1)
        if t[k] ~= nil then fail("duplicate key") end
        t[k] = v
      end
    end
    fail("bad tag")
  end
  local ok, res = pcall(parse, 0)
  if not ok then
    return nil, type(res) == "table" and res.msg or "corrupt"
  end
  if pos ~= len + 1 then return nil, "trailing data" end
  return res
end

---------------------------------------------------------------------------
-- Export et import
---------------------------------------------------------------------------
-- Payload(nom) -> table exportée : version, toutes les valeurs du schéma (position comprise si
-- elle est enregistrée) et les profils de butin.
function Profiles:Payload(name)
  local p = self:Data(name)
  if not p then return nil end
  local S = Q.OptionsSchema
  local settings = {}
  for path in pairs(S and S:Paths() or {}) do
    local v = walk(p.settings, path)
    if v == nil then v = walk(Q.Settings.defaults, path) end
    if v ~= nil then setPath(settings, path, deepcopy(v)) end
  end
  local roles = {}
  for cf, role in pairs(p.rewardRole) do
    if type(cf) == "string" and type(role) == "string" then roles[cf] = role end
  end
  return { v = FORMAT_VERSION, settings = settings, rewardRole = roles }
end

-- Export(nom) -> chaîne « QFY1:… » du profil (actif par défaut).
function Profiles:Export(name)
  local payload = self:Payload(name)
  if not payload then return "" end
  local ok, s = pcall(Profiles.Serialize, payload)
  if not ok then
    Q:ReportError(s)
    return ""
  end
  return PREFIX .. Profiles.Base64Encode(s)
end

-- Nombre de valeurs (feuilles) d'un arbre, pour compter ce qui est ignoré.
local function countLeaves(t, depth)
  if type(t) ~= "table" then return 1 end
  if (depth or 0) > MAX_DEPTH then return 0 end
  local n = 0
  for _, v in pairs(t) do n = n + countLeaves(v, (depth or 0) + 1) end
  return n
end

-- Profil de butin importé : classe connue et rôle de cette classe (ou "auto").
local function validRole(cf, role)
  local roles = Q.Rewards and Q.Rewards.CLASS_ROLES
  if type(cf) ~= "string" or type(role) ~= "string" or not (roles and roles[cf]) then return false end
  if role == "auto" then return true end
  for _, r in ipairs(roles[cf]) do if r == role then return true end end
  return false
end

-- Decode(texte) -> profil propre { settings, rewardRole }, nombre de valeurs gardées, nombre de
-- valeurs ignorées ; ou nil et un message clair (jamais d'erreur Lua).
function Profiles:Decode(text)
  local L = Q.L
  if type(text) ~= "string" then return nil, L.PROFILE_ERR_EMPTY end
  if #text > MAX_IMPORT then return nil, string.format(L.PROFILE_ERR_TOO_LONG, MAX_IMPORT) end
  text = text:gsub("%s+", "")
  if text == "" then return nil, L.PROFILE_ERR_EMPTY end
  if text:sub(1, #PREFIX) ~= PREFIX then return nil, L.PROFILE_ERR_PREFIX end
  local raw = Profiles.Base64Decode(text:sub(#PREFIX + 1))
  if not raw then return nil, L.PROFILE_ERR_CORRUPT end
  local data = Profiles.Deserialize(raw)
  if type(data) ~= "table" then return nil, L.PROFILE_ERR_CORRUPT end
  if data.v ~= FORMAT_VERSION then return nil, L.PROFILE_ERR_VERSION end
  local S = Q.OptionsSchema
  local clean = { settings = {}, rewardRole = {} }
  local kept, dropped = 0, 0
  local settings = type(data.settings) == "table" and data.settings or {}
  local consumed = 0
  for path, e in pairs(S and S:Paths() or {}) do
    local v = walk(settings, path)
    if v ~= nil then
      consumed = consumed + countLeaves(v)
      local ok, value = S:Validate(e, v)
      if ok then
        setPath(clean.settings, path, value)
        kept = kept + 1
      else
        dropped = dropped + 1
      end
    end
  end
  dropped = dropped + math.max(0, countLeaves(settings) - consumed)
  if type(data.rewardRole) == "table" then
    for cf, role in pairs(data.rewardRole) do
      if validRole(cf, role) then
        clean.rewardRole[cf] = role
        kept = kept + 1
      else
        dropped = dropped + 1
      end
    end
  end
  for k in pairs(data) do
    if k ~= "v" and k ~= "settings" and k ~= "rewardRole" then dropped = dropped + 1 end
  end
  if kept == 0 then return nil, L.PROFILE_ERR_NOTHING end
  return clean, kept, dropped
end

-- Import(texte, cible) -> ok, message : les valeurs importées remplacent celles du profil cible
-- (nouveau nom : profil créé ; vide : profil actif), qui devient le profil actif.
function Profiles:Import(text, target)
  local d = db()
  if not d then return false, Q.L.PROFILE_ERR_UNKNOWN end
  local clean, kept, dropped = self:Decode(text)
  if not clean then return false, kept end
  local name = active
  if type(target) == "string" and target:match("%S") then
    local cleanName, err = self:CleanName(target)
    if not cleanName then return false, err end
    name = cleanName
  end
  if name == active then
    withChanges(function() d.profiles[active] = clean end)
  else
    d.profiles[name] = clean
    if not self:SetActive(name) then return false, Q.L.PROFILE_ERR_UNKNOWN end
  end
  return true, string.format(Q.L.PROFILE_IMPORTED, self:DisplayName(name), kept, dropped)
end
