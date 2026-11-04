local addonName, Q = ...

local floor = math.floor

local Util = {}
Q.Util = Util

-- Teste un bit sans opérateur binaire : les masques de races dépassent 32 bits
-- (Skyborne = 2^32 et 2^33), bit.band ne fonctionne pas dessus.
function Util.HasBit(mask, bitValue)
  if type(mask) ~= "number" or type(bitValue) ~= "number" or bitValue <= 0 then return false end
  return floor(mask / bitValue) % 2 == 1
end

-- Vrai si le masque n'impose rien (nil ou 0) ou contient le bit.
-- Un bit inconnu (nil) est considéré comme autorisé.
function Util.MaskAllows(mask, bitValue)
  if mask == nil or mask == 0 then return true end
  if bitValue == nil then return true end
  return Util.HasBit(mask, bitValue)
end

-- Valeurs secrètes (Midnight) : toute valeur secrète doit être ignorée.
-- Sur ces clients, du code non sécurisé peut déclencher une erreur rien qu'en comparant une
-- valeur secrète : on interroge donc issecretvalue AVANT toute comparaison, type() ou test
-- sur v. Seul le résultat de l'API est comparé ensuite.
function Util.IsSecret(v)
  local check = issecretvalue
  if type(check) ~= "function" then return false end   -- client sans valeurs secrètes
  local ok, res = pcall(check, v)
  if ok then return res == true end
  -- l'API a échoué : la valeur est considérée secrète, sauf nil (test brut protégé)
  local okNil, isNil = pcall(rawequal, v, nil)
  if okNil and isNil then return false end
  return true
end

function Util.Round(v, n)
  local m = 10 ^ (n or 0)
  return floor(v * m + 0.5) / m
end

-- Distance lisible : "85 yd", puis "1.2 km" au-delà de 1000.
function Util.FormatDistance(yards)
  if type(yards) ~= "number" then return "" end
  if yards < 1000 then
    return string.format("%d yd", Util.Round(yards))
  end
  return string.format("%.1f km", yards / 1000)
end

local function copyValue(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = copyValue(x) end
  return out
end
Util.DeepCopy = copyValue

-- Complète dst avec les valeurs absentes de defaults (récursif, sans écraser false).
function Util.CopyDefaults(dst, defaults)
  if type(dst) ~= "table" then dst = {} end
  if type(defaults) ~= "table" then return dst end
  for k, v in pairs(defaults) do
    if dst[k] == nil then
      dst[k] = copyValue(v)
    elseif type(v) == "table" and type(dst[k]) == "table" then
      Util.CopyDefaults(dst[k], v)
    end
  end
  return dst
end

function Util.Contains(list, value)
  if type(list) ~= "table" then return false end
  for _, v in pairs(list) do if v == value then return true end end
  return false
end

-- Retire les codes de couleur WoW d'un texte.
function Util.StripColors(s)
  if type(s) ~= "string" then return s end
  return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end
