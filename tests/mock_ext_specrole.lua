-- tests/mock_ext_specrole.lua
-- Compléments du mock pour les spécialisations (Automation/SpecRole.lua) et le menu de Blizzard_Menu
-- (UI/MinimapButton.lua). Utilisation dans un test :
--   local Ext = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")
--   Ext.install()               -- après Mock.reset() (fait par le lanceur), avant Mock.loadAddon
--   Ext.installMenu()           -- MenuUtil factice (facultatif)
-- État lu à chaque appel (un test peut le changer à tout moment) :
--   Mock.spec.index         index de spécialisation (nil, 0, 1-3, 5 = spécialisation de départ)
--   Mock.spec.specs         [classFile] = { { id, name, icon, role, stat }, ... }
--   Mock.spec.initialized   C_SpecializationInfo.IsInitialized()
--   Mock.spec.selection     C_SpecializationInfo.IsSpecSelectionEnabled(classID)
--   Mock.spec.fail          GetSpecializationInfo lève une erreur
--   Mock.cursor = { x, y }  GetCursorPosition
-- Menu : Mock.lastMenu = { owner, elements = { { kind, text, isSelected, setSelected, data } } }.
-- Ext.reinstall() après Mock.reload (qui recrée l'API).

local Ext = {}

local CLASS_IDS = { WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, SHAMAN = 7, MAGE = 8, WARLOCK = 9,
  DRUID = 11 }
Ext.CLASS_IDS = CLASS_IDS

-- Spécialisations de la branche Mainline (identifiants, rôle, statistique principale LE_UNIT_STAT_*).
local SPECS = {
  SHAMAN = {
    { id = 262, name = "Elemental", icon = 136048, role = "DAMAGER", stat = 4 },
    { id = 263, name = "Enhancement", icon = 237581, role = "DAMAGER", stat = 2 },
    { id = 264, name = "Restoration", icon = 136052, role = "HEALER", stat = 4 },
  },
  HUNTER = {
    { id = 253, name = "Beast Mastery", icon = 461112, role = "DAMAGER", stat = 2 },
    { id = 254, name = "Marksmanship", icon = 236179, role = "DAMAGER", stat = 2 },
    { id = 255, name = "Survival", icon = 461113, role = "DAMAGER", stat = 2 },
  },
  WARRIOR = {
    { id = 71, name = "Arms", icon = 132355, role = "DAMAGER", stat = 1 },
    { id = 72, name = "Fury", icon = 132347, role = "DAMAGER", stat = 1 },
    { id = 73, name = "Protection", icon = 132341, role = "TANK", stat = 1 },
  },
  MAGE = {
    { id = 62, name = "Arcane", icon = 135932, role = "DAMAGER", stat = 4 },
    { id = 63, name = "Fire", icon = 135810, role = "DAMAGER", stat = 4 },
    { id = 64, name = "Frost", icon = 135846, role = "DAMAGER", stat = 4 },
  },
}
Ext.SPECS = SPECS

local function classFile() return Mock.player.classFile end

function Ext.reinstall()
  local S = Mock.spec
  UnitSex = function() return 2 end
  LE_UNIT_STAT_INTELLECT = 4
  GetCursorPosition = function()
    local c = Mock.cursor
    if c then return c.x, c.y end
    return 0, 0
  end
  C_SpecializationInfo = {
    GetSpecialization = function() return S.index end,
    GetNumSpecializationsForClassID = function(classID)
      for cf, id in pairs(CLASS_IDS) do
        if id == classID then return #(S.specs[cf] or {}) end
      end
      return 0
    end,
    IsSpecSelectionEnabled = function() return S.selection ~= false end,
    IsInitialized = function() return S.initialized ~= false end,
    GetSpecializationInfo = function(index)
      if S.fail then error("GetSpecializationInfo failed") end
      local list = S.specs[classFile()] or {}
      local sp = list[index]
      if index == 5 then
        -- spécialisation de départ (avant le niveau 10)
        return 1444, "Initial", "", 0, "DAMAGER", 2
      end
      if not sp then return 0 end
      return sp.id, sp.name, "", sp.icon, sp.role, sp.stat, 0, "", 0, true
    end,
  }
end

function Ext.install()
  local specs = {}
  for cf, list in pairs(SPECS) do specs[cf] = list end
  Mock.spec = { index = nil, specs = specs, initialized = true, selection = true, fail = false }
  Mock.cursor = nil
  Ext.reinstall()
end

-- Description de menu factice : chaque Create* garde l'élément dans Mock.lastMenu.elements.
local function newRoot(elements)
  local root = {}
  local function add(kind, text, isSelected, setSelected, data)
    local e = { kind = kind, text = text, isSelected = isSelected, setSelected = setSelected, data = data }
    elements[#elements + 1] = e
    return e
  end
  function root:CreateTitle(text) return add("title", text) end
  function root:CreateDivider() return add("divider") end
  function root:CreateButton(text, callback, data) return add("button", text, nil, callback, data) end
  function root:CreateRadio(text, isSelected, setSelected, data) return add("radio", text, isSelected, setSelected, data) end
  function root:CreateCheckbox(text, isSelected, setSelected, data)
    return add("checkbox", text, isSelected, setSelected, data)
  end
  return root
end

function Ext.installMenu()
  MenuUtil = {
    CreateContextMenu = function(owner, generator, ...)
      local elements = {}
      Mock.lastMenu = { owner = owner, elements = elements }
      Mock.record("MenuUtil.CreateContextMenu", owner)
      generator(owner, newRoot(elements), ...)
      return {}
    end,
  }
end

-- Éléments du dernier menu, d'un type donné (et, si donné, de données data).
function Ext.menuElements(kind, data)
  local out = {}
  for _, e in ipairs(Mock.lastMenu and Mock.lastMenu.elements or {}) do
    if e.kind == kind and (data == nil or e.data == data) then out[#out + 1] = e end
  end
  return out
end

return Ext
