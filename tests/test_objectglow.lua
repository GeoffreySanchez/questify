-- Tests de l'animation autour de l'objet à utiliser (Q.UI.ObjectGlow), accrochée au cadre d'écran
-- du marqueur 3D natif (C_Navigation, simulé ici).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

local nav   -- état du C_Navigation simulé

local function installNav()
  nav = { frame = CreateFrame("Frame", "MockNavigationFrame", UIParent), clamped = false, distance = 4 }
  C_Navigation = {
    GetFrame = function() return nav.frame end,
    WasClampedToScreen = function() return nav.clamped end,
    GetDistance = function() return nav.distance end,
  }
end

-- Étape « Faire » 3361 objectif 2 : la cible est le coffre de Felix (objet 178084).
local function load(opts)
  Ext.install()
  installNav()
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end
  local Q = Mock.loadAddon(TOC, opts)
  Q:RegisterGuide({ id = "T_obj", faction = "Alliance", steps = { { "complete", 3361, obj = 2 }, { "complete", 179 } } })
  Mock.quests.log[3361] = { objectives = {
    { text = "Felix's Box: 0/1", finished = false },
    { text = "Felix's Chest: 0/1", finished = false },
    { text = "Felix's Bucket of Bolts: 0/1", finished = false },
  } }
  Q.Progress:SetGuide("T_obj")
  Mock.advance(0.2)
  return Q
end

local function glowing(Q)
  local G = Q.UI.ObjectGlow
  return G.frame ~= nil and G.frame:IsShown() and G.frame:GetAlpha() == 1
end

return {
  glow_around_object_target = function(t)
    local Q = load()
    t.eq(Q.UI.Tracker.target.kind, "object")
    local G = Q.UI.ObjectGlow
    t.ok(glowing(Q), "visible over the object")
    local p, rel, rp = G.frame:GetPoint(1)
    t.eq(p, "CENTER"); t.ok(rel == nav.frame, "follows the native 3D marker on screen"); t.eq(rp, "CENTER")
    t.ok(G.anims[1]:IsPlaying() and G.anims[2]:IsPlaying(), "spinning star and first wave")
    Mock.advance(0.7)
    t.ok(G.anims[3]:IsPlaying(), "second wave half a period later")
    t.eq({ G.frame:GetSize() }, { G:SizeFor(4), G:SizeFor(4) })
    t.eq(#Mock.errors, 0)
  end,

  size_shrinks_with_distance_and_hidden_far = function(t)
    local Q = load()
    local G = Q.UI.ObjectGlow
    t.eq(G:SizeFor(0), 150); t.eq(G:SizeFor(50), 60); t.eq(G:SizeFor(nil), 150)
    nav.distance = 25
    Mock.advance(0.2)
    t.eq(G.frame:GetWidth(), G:SizeFor(25))
    nav.distance = 80
    Mock.advance(0.2)
    t.ok(not glowing(Q), "too far: nothing")
    t.ok(not G.anims[1]:IsPlaying(), "animations stopped")
    nav.distance = 10
    Mock.advance(0.2)
    t.ok(glowing(Q), "back in range")
  end,

  hidden_when_marker_off_screen = function(t)
    local Q = load()
    nav.clamped = true
    Mock.advance(0.2)
    t.ok(not glowing(Q), "marker stuck to the screen edge: the object is not in view")
    nav.clamped = false
    nav.frame = nil
    Mock.advance(0.2)
    t.ok(not glowing(Q), "no navigation frame")
  end,

  no_glow_for_monsters_or_npcs = function(t)
    local Q = load()
    Mock.quests.log[3361] = { objectives = {
      { text = "Felix's Box: 0/1", finished = false },
      { text = "Felix's Chest: 1/1", finished = true },
      { text = "Felix's Bucket of Bolts: 0/1", finished = false },
    } }
    Mock.quests.log[179] = { objectives = { { text = "Tough Wolf Meat: 0/8", finished = false } } }
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(0.3)
    t.eq(Q.Progress:Current().step.questId, 179, "wolves now")
    t.ok(Q.UI.Tracker.target == nil or Q.UI.Tracker.target.kind ~= "object")
    t.ok(not glowing(Q))
  end,

  off_with_option_or_other_display = function(t)
    local Q = load()
    Q.Settings:Set("objectGlow", false)
    Mock.advance(0.2)
    t.ok(not glowing(Q), "option off")
    Q.Settings:Set("objectGlow", true)
    Mock.advance(0.2)
    t.ok(glowing(Q))
    rawset(Q.Nav, "Active", function() return nil, "tomtom" end)
    Mock.advance(0.2)
    t.ok(not glowing(Q), "TomTom: no native marker to follow")
  end,

  nothing_without_navigation_api = function(t)
    Ext.install()
    C_Navigation = nil
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
    Mock.advance(0.2)
    t.eq(Q.UI.ObjectGlow.frame, nil, "client without C_Navigation: no frame at all")
    t.eq(#Mock.errors, 0)
  end,
}
