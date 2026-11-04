-- tools/talentbuilds/keys.lua : clé d'un build fourni par une source autre qu'Icy Veins.
--   <SOURCE>_<CLASSE>_<SPÉ>[_<SORTE>] ; la sorte n'est ajoutée que hors leveling (clés leveling inchangées).
return function(source, class, specKey, kind)
  local src = tostring(source):lower():gsub("[^%w]", ""):upper()
  local spec = specKey:upper():gsub("%-", "_")
  return src .. "_" .. class .. "_" .. spec .. (kind ~= "leveling" and ("_" .. kind:upper()) or "")
end
