-- Tests des icônes au-dessus des barres de nom (Q.UI.Nameplates).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

local function load(opts)
  Ext.install()
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end   -- routes générées : contenu changeant
  return Mock.loadAddon(TOC, opts)
end

local function acceptWolves()
  Mock.quests.log[179] = { objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
  Mock.fire("QUEST_ACCEPTED", 179)
end

local function addPlate(unit, npcId, guid)
  Mock.units[unit] = { npcId = npcId, guid = guid, name = "Ragged Young Wolf", level = 1, hostile = true }
  local plate = CreateFrame("Frame", nil, WorldFrame)
  Mock.nameplates[unit] = plate
  Mock.fire("NAME_PLATE_UNIT_ADDED", unit)
  return plate
end

return {
  nameplate_icon_for_objective_mob = function(t)
    local Q = load()
    acceptWolves()
    local plate = addPlate("nameplate1", 705, "Creature-0-1-0-1-705-00004A1B2C")
    local N = Q.UI.Nameplates
    local icon = N.icons.nameplate1
    t.ok(icon, "icon attached")
    t.ok(icon:IsShown())
    t.ok(icon:GetParent() == plate, "parented to the plate")
    t.eq({ icon:GetSize() }, { 24, 24 })
    local p, rel, rp = icon:GetPoint(1)
    t.eq(p, "BOTTOM"); t.ok(rel == plate); t.eq(rp, "TOP")
    t.eq(icon.texture:GetTexture(), "Interface\\GossipFrame\\AvailableQuestIcon")
    t.ok(icon.bounce:IsPlaying(), "bouncing")
    t.eq(icon.bounce:GetLooping(), "BOUNCE")
    local x, y = icon.translation:GetOffset()
    t.eq(x, 0); t.eq(y, 6)
    Mock.fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
    t.eq(N.icons.nameplate1, nil, "removed")
    t.ok(not icon:IsShown(), "hidden")
    t.eq(#Mock.errors, 0)
  end,

  secret_guid_ignored = function(t)
    local Q = load()
    acceptWolves()
    addPlate("nameplate2", Mock.secret(705), Mock.secret("Creature-0-1-0-1-705-00004A1B2C"))
    t.eq(Q.UI.Nameplates.icons.nameplate2, nil, "no icon")
    -- UnitCreatureID absent ou vide, GUID secret : ignoré aussi
    addPlate("nameplate3", nil, Mock.secret("Creature-0-1-0-1-705-00004A1B2C"))
    t.eq(Q.UI.Nameplates.icons.nameplate3, nil)
    t.eq(#Mock.errors, 0, "no error")
  end,

  guid_field_6_when_no_creature_id = function(t)
    local Q = load()
    acceptWolves()
    UnitCreatureID = nil
    addPlate("nameplate4", nil, "Creature-0-1-0-1-705-00004A1B2C")
    t.ok(Q.UI.Nameplates.icons.nameplate4, "npcId read from the GUID")
    addPlate("nameplate5", nil, "Creature-0-1-0-1-707-00004A1B2D")
    t.eq(Q.UI.Nameplates.icons.nameplate5, nil, "not an objective mob")
    addPlate("nameplate6", nil, "Player-1-00000002")
    t.eq(Q.UI.Nameplates.icons.nameplate6, nil, "players ignored")
    t.eq(#Mock.errors, 0)
  end,

  setting_off_and_rescan = function(t)
    local Q = load()
    addPlate("nameplate1", 705, "Creature-0-1-0-1-705-00004A1B2C")
    local N = Q.UI.Nameplates
    t.eq(N.icons.nameplate1, nil, "quest not taken yet")
    acceptWolves()                                  -- PROGRESS_UPDATED : nouvelle lecture des barres
    t.ok(N.icons.nameplate1, "icon after rescan")
    Q.Settings:Set("nameplates", false)
    t.eq(N.icons.nameplate1, nil, "setting off removes icons")
    Q.Settings:Set("nameplates", true)
    t.ok(N.icons.nameplate1, "back on")
    -- objectif terminé : l'icône disparaît
    Mock.quests.log[179] = { complete = true, objectives = { { text = "Tough Wolf Meat: 8/8", finished = true } } }
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.eq(N.icons.nameplate1, nil, "objective done")
    t.eq(#Mock.errors, 0)
  end,

  icons_are_reused = function(t)
    local Q = load()
    acceptWolves()
    addPlate("nameplate1", 705, "Creature-0-1-0-1-705-00004A1B2C")
    local first = Q.UI.Nameplates.icons.nameplate1
    Mock.fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
    addPlate("nameplate7", 705, "Creature-0-1-0-1-705-00004A1B2E")
    t.ok(Q.UI.Nameplates.icons.nameplate7 == first, "pooled frame reused")
  end,
}
