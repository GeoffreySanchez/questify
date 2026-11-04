-- tests/mock_ext_mappins.lua
-- Compléments du mock pour les tests des repères de carte (UI/MapPins.lua).
-- Les vraies bibliothèques (Libs\ : LibStub, CallbackHandler, HereBeDragons) sont chargées par le
-- TOC comme en jeu ; tests/wow_mock.lua leur fournit la carte du monde et la minicarte.
-- Utilisation dans un test :
--   local Ext = dofile(Mock.root .. "/tests/mock_ext_mappins.lua")
--   Mock.loadAddon(toc, { beforeLogin = Ext.spy })   -- espionne avant le premier dessin
-- Chaque appel à HereBeDragons-Pins est noté dans Mock.calls ("HBDPins:AddWorldMapIconMap",
-- "HBDPins:AddMinimapIconMap", "HBDPins:RemoveAllWorldMapIcons", "HBDPins:RemoveAllMinimapIcons"),
-- sans le self, puis transmis à la bibliothèque.

local Ext = {}

local SPIED = { "AddWorldMapIconMap", "AddMinimapIconMap", "RemoveAllWorldMapIcons", "RemoveAllMinimapIcons" }

function Ext.pins()
  return LibStub and LibStub("HereBeDragons-Pins-2.0", true)
end

function Ext.spy()
  local lib = Ext.pins()
  if not lib or lib._mockSpied then return lib end
  lib._mockSpied = true
  for _, name in ipairs(SPIED) do
    local orig = lib[name]
    lib[name] = function(self, ...)
      Mock.record("HBDPins:" .. name, ...)
      return orig(self, ...)
    end
  end
  return lib
end

-- Nombre de repères de la bibliothèque enregistrés pour une clé (carte du monde, minicarte).
function Ext.registered(ref)
  local lib = Ext.pins()
  local w, m = 0, 0
  for _ in pairs(lib.worldmapPinRegistry[ref] or {}) do w = w + 1 end
  for _ in pairs(lib.minimapPinRegistry[ref] or {}) do m = m + 1 end
  return w, m
end

-- Lignes ajoutées à GameTooltip (texte brut), remises à zéro à chaque SetOwner.
function Ext.captureTooltip()
  local lines = {}
  rawset(GameTooltip, "SetOwner", function() for i = #lines, 1, -1 do lines[i] = nil end end)
  rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = tostring(text) end)
  return lines
end

return Ext
