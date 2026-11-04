local addonName, Q = ...

-- Import et export des builds de talents (spec 2.7, 3, 7.9).
--   * Format d'échange « QFYB1: » + Base64( Serialize{ v = 1, builds = { { class, specID, name, source, order } } } ),
--     par Q.Profiles (sérialiseur déterministe, lecture stricte, jamais de loadstring).
--   * Lien du calculateur Icy Veins : chaque caractère de l'ordre devient un spellID par Q.TalentIndexData ;
--     le suffixe « ~<version> » du lien doit être Q.TalentIndexVersion (un lien sans suffixe est accepté).
--   * Decode ne touche à rien : il rend la liste de builds ou nil et la raison. L'enregistrement
--     (Builds:Save) reste à l'appelant, donc rien n'est écrit en cas d'erreur.
local Codec = {}
Q.BuildCodec = Codec

local PREFIX = "QFYB1:"
local VERSION = 1
local MAX_POINTS = 51
local MAX_SOURCE = 40
local ICY_SOURCE = "Icy Veins (lien)"
Codec.PREFIX = PREFIX

local function profiles() return Q.Profiles end

local function isInteger(v)
  return type(v) == "number" and v == math.floor(v) and v > 0 and v < 2 ^ 31
end

-- Nom présenté : sans caractère de contrôle ni « | », coupé à la longueur permise, puis Profiles:CleanName.
-- Un nom inutilisable (vide, réservé) devient le nom par défaut : un nom ne fait jamais refuser un build.
local function cleanName(name)
  if type(name) ~= "string" then name = "" end
  name = name:gsub("[%c|]", "")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  local max = profiles().MAX_NAME
  if #name > max then
    name = name:sub(1, max)
    -- ne pas couper au milieu d'un caractère UTF-8 : retirer l'octet de tête resté seul ou ses suites orphelines
    local i = #name
    while i > 0 and name:byte(i) >= 0x80 and name:byte(i) < 0xC0 do i = i - 1 end
    if i > 0 and name:byte(i) >= 0xC0 then
      local lead = name:byte(i)
      local need = lead >= 0xF0 and 4 or lead >= 0xE0 and 3 or 2
      if #name - i + 1 < need then name = name:sub(1, i - 1) end
    end
    name = name:gsub("%s+$", "")
  end
  local clean = profiles():CleanName(name)
  return clean or Q.L.BUILD_NEW_NAME
end

local function entryOf(build, class)
  local name = Q.Builds:Name(build)
  local e = { class = build.class or class, name = name, order = {} }
  if isInteger(build.specID) then e.specID = build.specID end
  if type(build.source) == "string" and build.source ~= "" then e.source = build.source end
  for i, id in ipairs(build.order or {}) do e.order[i] = id end
  return e
end

local function encode(builds)
  local class = Q.Player and Q.Player.classFile
  local list = {}
  for i, b in ipairs(builds) do list[i] = entryOf(b, class) end
  local p = profiles()
  return PREFIX .. p.Base64Encode(p.Serialize({ v = VERSION, builds = list }))
end

function Codec:Encode(build)
  return encode({ build })
end

function Codec:EncodeAll(builds)
  return encode(builds or {})
end

local function now() return type(time) == "function" and time() or 0 end

-- Entrée décodée -> build prêt pour Builds:Save, ou nil et la raison.
local function checkEntry(e, class)
  if type(e) ~= "table" then return nil, "format" end
  if e.class ~= class then return nil, e.class == nil and "format" or "class" end
  if e.specID ~= nil and type(e.specID) ~= "number" then return nil, "format" end
  if type(e.order) ~= "table" then return nil, "format" end
  if e.source ~= nil and type(e.source) ~= "string" then return nil, "format" end
  local order, n = {}, 0
  for k, id in pairs(e.order) do
    if not (isInteger(k) and isInteger(id)) then return nil, "format" end
    n = n + 1
  end
  if n ~= #e.order then return nil, "format" end
  if n > MAX_POINTS then return nil, "toolong" end
  for i = 1, n do order[i] = e.order[i] end
  local source = e.source and e.source:gsub("[%c|]", ""):sub(1, MAX_SOURCE) or nil
  if source == "" then source = nil end
  return { class = class, specID = e.specID, name = cleanName(e.name), source = source, date = now(),
    official = false, order = order }
end

local CLASS_SLUG = function(slug) return (slug:gsub("%-", ""):upper()) end

-- Lien du calculateur Icy Veins -> { build } | nil, "icyveins" (ou "toolong", ou "icyversion" : lien d'une
-- autre version du calculateur, dont les index peuvent désigner d'autres talents).
local function decodeIcy(text, class)
  local rest = text:gsub("^[hH][tT][tT][pP][sS]?://", ""):gsub("^[wW][wW][wW]%.", "")
  local slug, order = rest:match("^[iI][cC][yY]%-[vV][eE][iI][nN][sS]%.[cC][oO][mM]/wow%-forever/([%w%-]+)%-talent%-calculator#tc%-([^~%s]*)")
  if not slug then return nil, "icyveins" end
  if CLASS_SLUG(slug) ~= class then return nil, "icyveins" end
  local version = rest:match("#tc%-[^~%s]*~(%S*)")
  if version ~= nil and version ~= Q.TalentIndexVersion then return nil, "icyversion" end
  local index = type(Q.TalentIndexData) == "table" and Q.TalentIndexData[class]
  if type(index) ~= "table" or order == "" then return nil, "icyveins" end
  local ids = {}
  for i = 1, #order do
    local id = index[order:sub(i, i)]
    if not isInteger(id) then return nil, "icyveins" end
    ids[i] = id
  end
  if #ids > MAX_POINTS then return nil, "toolong" end
  local stamp = type(date) == "function" and date("%Y-%m-%d") or "?"
  return { { class = class, name = cleanName(string.format(Q.L.BUILD_IMPORT_ICY_NAME, stamp)),
    source = ICY_SOURCE, date = now(), official = false, order = ids } }
end

-- Decode(texte, classe) -> { build, … } | nil, raison.
-- Raisons : "prefix" (ni QFYB1: ni lien Icy Veins), "format", "class", "toolong", "size", "icyveins",
-- "icyversion".
function Codec:Decode(text, class)
  if type(text) ~= "string" then return nil, "prefix" end
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if #text > profiles().MAX_IMPORT then return nil, "size" end
  if text:sub(1, #PREFIX) ~= PREFIX then
    if text:lower():find("icy%-veins%.com") then
      return decodeIcy(text, class)
    end
    return nil, "prefix"
  end
  local raw = profiles().Base64Decode(text:sub(#PREFIX + 1))
  if not raw then return nil, "format" end
  local ok, data = pcall(profiles().Deserialize, raw)
  if not ok or type(data) ~= "table" or data.v ~= VERSION or type(data.builds) ~= "table" then
    return nil, "format"
  end
  local count = 0
  for _ in pairs(data.builds) do count = count + 1 end
  if count == 0 or count ~= #data.builds then return nil, "format" end
  local out = {}
  for i, e in ipairs(data.builds) do
    local build, reason = checkEntry(e, class)
    if not build then return nil, reason end
    out[i] = build
  end
  return out
end
