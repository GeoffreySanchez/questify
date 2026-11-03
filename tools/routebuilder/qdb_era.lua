-- tools/routebuilder/qdb_era.lua : vue Classic Era de QuestieDB pour le générateur (hors jeu).
--
-- qdb.lua (flux E, lecture seule ici) ne charge que la vue Forever : chemins data/Forever,
-- support/Forever et couches de corrections Forever. Plutôt que de recopier son chargeur, on
-- redirige pendant l'appel chaque fichier lu par qdb.runFile vers son équivalent Era :
--   data/Forever/forever<X>DB.lua            -> data/Classic/classic<X>DB.lua
--   src/corrections/Forever/legacy/classic*  -> src/corrections/Era/classic*
--   src/corrections/Forever/legacy/itemStart -> src/corrections/Shared/itemStartFixes.lua
--   src/corrections/Forever/(generated|traces|forever*Fixes) -> module vide (rien de propre à Forever)
--   support/Forever/<fichier>                -> support/<fichier>
-- Les fichiers QuestieDB restent exécutés dans le bac à sable de qdb.lua (setfenv, environnement strict).
--
-- qdbEra.load{ db = <racine QuestieDB>, faction = "Alliance"|"Horde", questie = <racine Questie>|nil } -> D

local qdb = require("qdb")

local M = {}

-- Chargeur Forever d'origine, capturé avant toute redirection éventuelle de qdb.load par l'appelant.
local foreverLoad = qdb.load

-- Couches propres à Forever : fichier -> module QuestieDB à déclarer vide.
local FOREVER_ONLY = {
  ["Forever/generated/foreverBaseNpc.lua"] = "ForeverBaseNpc",
  ["Forever/generated/foreverBaseObject.lua"] = "ForeverBaseObject",
  ["Forever/generated/foreverBaseQuest.lua"] = "ForeverBaseQuest",
  ["Forever/generated/foreverBaseItem.lua"] = "ForeverBaseItem",
  ["Forever/traces/foreverQuestTraces.lua"] = "ForeverQuestTraces",
  ["Forever/traces/foreverNpcTraces.lua"] = "ForeverNpcTraces",
  ["Forever/traces/foreverItemTraces.lua"] = "ForeverItemTraces",
  ["Forever/traces/foreverObjectTraces.lua"] = "ForeverObjectTraces",
  ["Forever/foreverQuestFixes.lua"] = "ForeverQuestFixes",
  ["Forever/foreverNPCFixes.lua"] = "ForeverNpcFixes",
  ["Forever/foreverItemFixes.lua"] = "ForeverItemFixes",
  ["Forever/foreverObjectFixes.lua"] = "ForeverObjectFixes",
}

-- Chemin relatif Forever -> chemin relatif Era (nil = inchangé).
function M.mapPath(rel)
  local entity = rel:match("^data/Forever/forever(%a+DB)%.lua$")
  if entity then return "data/Classic/classic" .. entity .. ".lua" end
  local legacy = rel:match("^src/corrections/Forever/legacy/(classic%a+%.lua)$")
  if legacy then return "src/corrections/Era/" .. legacy end
  if rel == "src/corrections/Forever/legacy/itemStartFixes.lua" then return "src/corrections/Shared/itemStartFixes.lua" end
  local support = rel:match("^support/Forever/(.+)$")
  if support then return "support/" .. support end
  return nil
end

local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

function M.load(opts)
  opts = opts or {}
  local root = opts.db or qdb.DEFAULT_DB
  local prefix = root .. "/"
  local original = qdb.runFile
  local redirected = {}
  qdb.runFile = function(path, env, ...)
    if path:sub(1, #prefix) == prefix then
      local rel = path:sub(#prefix + 1)
      local corr = rel:match("^src/corrections/(.+)$")
      local module = corr and FOREVER_ONLY[corr]
      if module then
        -- couche Forever : module déclaré sans aucune correction
        local m = env.QuestieLoader:CreateModule(module)
        m.Load = function() return {} end
        m.LoadDynamic = function() return {} end
        redirected[#redirected + 1] = rel .. " -> (empty)"
        return
      end
      local era = M.mapPath(rel)
      if era then
        assert(exists(prefix .. era), "Era file missing: " .. prefix .. era)
        redirected[#redirected + 1] = rel .. " -> " .. era
        return original(prefix .. era, env, ...)
      end
    end
    return original(path, env, ...)
  end
  local ok, D = pcall(foreverLoad, opts)
  qdb.runFile = original
  if not ok then error(D, 0) end
  D.flavor = "Era"
  D.redirected = redirected
  return D
end

return M
