-- tests/mock_ext_wizard.lua
-- Compléments du mock pour l'assistant de premier démarrage. Utilisation dans un test :
--   local W = dofile(Mock.root .. "/tests/mock_ext_wizard.lua")
--   W.install({ WaypointUI = "disabled" })   -- après Mock.reset() (fait par le lanceur)
--   local Q = Mock.loadAddon(...)
--   local Q2 = W.reload()                    -- /reload simulé, compléments réinstallés
-- États d'un addon (Mock.addonState[dossier]) :
--   "loaded"    installé, activé et chargé ;
--   "enabled"   installé et activé, pas encore chargé (chargé au prochain W.reload) ;
--   "disabled"  installé, désactivé pour ce personnage ;
--   "outdated"  installé, activé, pas chargé car périmé (raison INTERFACE_VERSION) ;
--   nil         absent, sauf Mock.addons[dossier] == true qui vaut "loaded".
-- Appels enregistrés dans Mock.calls : "C_AddOns.EnableAddOn" (dossier, personnage), "ReloadUI".

local W = {}

local function state(name)
  local s = Mock.addonState and Mock.addonState[name]
  if s then return s end
  if Mock.addons[name] == true then return "loaded" end
  return nil
end
W.state = state

-- Complète C_AddOns et ajoute ReloadUI. Mock.reload recrée l'API : W.reload les réinstalle.
function W.patch()
  local api = C_AddOns
  local isLoaded = api.IsAddOnLoaded
  api.DoesAddOnExist = function(name) return state(name) ~= nil end
  api.GetAddOnInfo = function(name)
    local s = state(name)
    if not s then return name, nil, nil, false, "MISSING", "INSECURE", false end
    local reason = (s == "disabled" and "DISABLED") or (s == "outdated" and "INTERFACE_VERSION") or nil
    return name, name, "", s ~= "disabled" and s ~= "outdated", reason, "INSECURE", false
  end
  api.GetAddOnEnableState = function(name, character)
    local s = state(name)
    if s == nil or s == "disabled" then return 0 end
    return 2
  end
  api.EnableAddOn = function(name, character)
    Mock.record("C_AddOns.EnableAddOn", name, character)
    if state(name) == "disabled" then Mock.addonState[name] = "enabled" end
  end
  api.IsAddOnLoaded = function(name)
    local s = Mock.addonState and Mock.addonState[name]
    if s == "loaded" then return true, true end
    if s then return false, false end
    return isLoaded(name)
  end
  ReloadUI = function() Mock.record("ReloadUI") end
end

function W.install(states)
  Mock.addonState = {}
  for k, v in pairs(states or {}) do Mock.addonState[k] = v end
  W.patch()
end

-- /reload simulé : un addon activé ("enabled") est chargé, comme dans le jeu ; un addon chargé
-- de navigation fournit son API (Mock.addons). SavedVariables conservées (Mock.reload).
function W.reload(opts)
  for name, s in pairs(Mock.addonState or {}) do
    if s == "enabled" or s == "loaded" then
      Mock.addonState[name] = "loaded"
      Mock.addons[name] = true
    end
  end
  local Q = Mock.reload(opts)
  W.patch()
  return Q
end

return W
