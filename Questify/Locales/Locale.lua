local addonName, Q = ...

-- Table des textes. Une clé absente renvoie la clé elle-même, pour ne jamais afficher nil.
Q.L = setmetatable({}, {
  __index = function(_, key) return key end,
})

-- Enregistre les textes d'un module : { enUS = {...}, frFR = {...} }.
-- L'anglais est toujours appliqué, puis la langue du client par-dessus.
-- Chaque flux appelle cette fonction dans son propre fichier de textes.
function Q:RegisterStrings(tables)
  if type(tables) ~= "table" then return end
  local L = self.L
  if type(tables.enUS) == "table" then
    for k, v in pairs(tables.enUS) do rawset(L, k, v) end
  end
  local locale = (GetLocale and GetLocale()) or "enUS"
  if locale == "enGB" then locale = "enUS" end
  if locale ~= "enUS" and type(tables[locale]) == "table" then
    for k, v in pairs(tables[locale]) do rawset(L, k, v) end
  end
end
