-- tests/mock_ext_comfort.lua
-- Compléments du mock pour les tests du confort de jeu (vols, pierre de foyer, danger, sacs, XP/h).
-- Utilisation dans un test :
--   local Ext = dofile(Mock.root .. "/tests/mock_ext_comfort.lua")
--   Ext.install()      -- après Mock.reset() (fait par le lanceur), avant Mock.loadAddon
-- L'état est dans Mock.comfort ; chaque API lit cet état à l'appel, un test peut donc le changer
-- à tout moment, ou retirer une fonction (globale = nil) pour simuler une API absente.

local Ext = {}

function Ext.install()
  local S = {
    -- vols : nœuds de C_TaxiMap.GetAllTaxiNodes(taxiMapId) ; legacy = { { name, type } }
    taxiMapId = 1415,
    nodes = {},
    legacy = nil,
    mapNodes = {},          -- [uiMapID] = nœuds de C_TaxiMap.GetTaxiNodesForMap
    -- pierre de foyer
    cooldown = { start = 0, duration = 0, enable = 1 },
    itemCount = { [6948] = 1 },
    -- XP
    xp = 0, xpMax = 1000, afk = false, dead = false,
    -- sacs et équipement
    freeSlots = { [0] = 10, [1] = 0, [2] = 0, [3] = 0, [4] = 0 },
    bagFamily = {},
    durability = {},        -- [slot] = { cur, max }
    resting = false,
  }
  Mock.comfort = S

  -- Vols
  GetTaxiMapID = function() return S.taxiMapId end
  C_TaxiMap = C_TaxiMap or {}
  C_TaxiMap.GetAllTaxiNodes = function(mapId)
    Mock.record("C_TaxiMap.GetAllTaxiNodes", mapId)
    if mapId ~= S.taxiMapId then return {} end
    local out = {}
    for i, n in ipairs(S.nodes) do
      out[i] = {
        nodeID = n.nodeID or (100 + i), name = n.name, state = n.state or 1, slotIndex = n.slotIndex or i,
        position = CreateVector2D(n.x or 0, n.y or 0), isMapLayerTransition = n.layer == true,
        textureKit = "", useSpecialIcon = false,
      }
    end
    return out
  end
  C_TaxiMap.GetTaxiNodesForMap = function(mapId)
    local out = {}
    for i, n in ipairs(S.mapNodes[mapId] or {}) do
      out[i] = { nodeID = n.nodeID or (200 + i), name = n.name, position = CreateVector2D(n.x or 0, n.y or 0),
        faction = n.faction or 0, isUndiscovered = n.undiscovered == true, atlasName = "", textureKit = "" }
    end
    return out
  end
  NumTaxiNodes = function() return S.legacy and #S.legacy or 0 end
  TaxiNodeName = function(i) local n = S.legacy and S.legacy[i]; return n and n.name end
  TaxiNodeGetType = function(i) local n = S.legacy and S.legacy[i]; return n and n.type or "NONE" end
  TakeTaxiNode = function(i) Mock.record("TakeTaxiNode", i) end

  -- Pierre de foyer
  C_Container = C_Container or {}
  C_Container.GetItemCooldown = function(id)
    if id ~= 6948 then return 0, 0, 1 end
    local c = S.cooldown
    return c.start, c.duration, c.enable
  end
  C_Item.GetItemCount = function(id) return S.itemCount[id] or 0 end

  -- XP
  UnitXP = function(unit) if unit == "player" then return S.xp end return 0 end
  UnitXPMax = function(unit) if unit == "player" then return S.xpMax end return 0 end
  UnitIsAFK = function(unit) return unit == "player" and S.afk end
  UnitIsDeadOrGhost = function(unit)
    if unit == "player" then return S.dead end
    local u = Mock.units[unit]
    return u and u.dead or false
  end

  -- Danger
  UnitClassification = function(unit)
    local u = Mock.units[unit]
    return u and (u.classification or "normal")
  end
  UnitPlayerControlled = function(unit)
    local u = Mock.units[unit]
    return u and u.playerControlled == true or false
  end

  -- Sacs et équipement
  C_Container.GetContainerNumFreeSlots = function(bag)
    return S.freeSlots[bag] or 0, S.bagFamily[bag] or 0
  end
  GetInventoryItemDurability = function(slot)
    local d = S.durability[slot]
    if not d then return nil end
    return d[1], d[2]
  end
  IsResting = function() return S.resting end
end

-- Place un monstre sur une barre de nom et déclenche NAME_PLATE_UNIT_ADDED.
function Ext.addPlate(unit, def)
  Mock.units[unit] = def
  Mock.nameplates[unit] = Mock.newObject("Frame", nil, nil)
  rawset(Mock.nameplates[unit], "namePlateUnitToken", unit)
  Mock.fire("NAME_PLATE_UNIT_ADDED", unit)
end

function Ext.removePlate(unit)
  Mock.units[unit] = nil
  Mock.nameplates[unit] = nil
  Mock.fire("NAME_PLATE_UNIT_REMOVED", unit)
end

return Ext
