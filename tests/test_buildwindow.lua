-- Tests de la fenêtre du build (UI/BuildWindow.lua) : coquille autonome ou posée sur la fenêtre des
-- talents du jeu, commande /qf build, entrée du menu de la minicarte.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")

local function load(opts)
  opts = opts or {}
  Mock.player.classFile = "SHAMAN"; Mock.player.level = 20
  Mock.player.combat = opts.combat == true
  if opts.menu then Ext.installMenu() end
  return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
end

local function qf(msg) SlashCmdList.QUESTIFY(msg) end

local function inSpecial(name)
  for _, n in ipairs(UISpecialFrames) do if n == name then return true end end
  return false
end

return {
  slash_build_opens_standalone = function(t)
    local Q = load()
    local W = Q.UI.BuildWindow
    t.ok(W, "window module")
    qf("build")
    local f = QuestifyBuildWindow
    t.ok(f and f:IsShown(), "standalone window shown")
    t.ok(f:IsMovable(), "movable")
    t.ok(inSpecial("QuestifyBuildWindow"), "closes with Escape")
    t.eq(f:GetParent(), UIParent)
    t.ok(W:Pane("build"):IsShown(), "build pane shown")
    t.ok(not W:Pane("spells"):IsShown(), "spells pane hidden")
    W:Open("spells")
    t.ok(W:Pane("spells"):IsShown() and not W:Pane("build"):IsShown(), "pane switch")
    t.eq(W:Pane("nope"), nil)
    W:Close()
    t.ok(not f:IsShown(), "closed")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  open_in_combat_defers_to_regen = function(t)
    local Q = load({ combat = true })
    local W = Q.UI.BuildWindow
    qf("build")
    t.ok(not QuestifyBuildWindow, "no frame created in combat")
    t.ok(Mock.printed(Q.L.UI_SLASH_BUILD_COMBAT), "player told")
    t.eq(W:Open("spells"), false)
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(QuestifyBuildWindow and QuestifyBuildWindow:IsShown(), "opened after combat")
    t.ok(W:Pane("spells"):IsShown(), "last requested pane")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  close_in_combat_cancels_deferred_open = function(t)
    local Q = load({ combat = true })
    local W = Q.UI.BuildWindow
    W:Open("build")
    W:Close()
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(not QuestifyBuildWindow, "nothing opened")
  end,

  host_covers_talents_area_without_touching_blizzard = function(t)
    local Q = load()
    local W = Q.UI.BuildWindow
    local host = CreateFrame("Frame", "PlayerSpellsFrame", UIParent)
    host.TalentsFrame = CreateFrame("Frame", nil, host)
    local before = { host:GetFrameLevel(), host.TalentsFrame:GetParent(), host.TalentsFrame:IsShown() }
    W:SetHost(host)
    W:Open("build")
    local pane = W:Pane("build")
    t.ok(pane:IsShown())
    local root = W.root
    t.eq(root:GetParent(), host, "content parented to the host")
    t.ok(root:GetFrameLevel() > 4001, "above ActivateButton")
    t.ok(root:IsMouseEnabled(), "overlay swallows clicks")
    t.ok(W:IsShown(), "visible when hosted")
    t.eq(root:GetFrameStrata(), host:GetFrameStrata())
    local p = { root:GetPoint(1) }
    t.eq(p[2], host.TalentsFrame, "anchored on the talents area")
    t.ok(not (QuestifyBuildWindow and QuestifyBuildWindow:IsShown()), "standalone shell hidden")
    t.eq(host.TalentsFrame:GetParent(), before[2], "talents not reparented")
    t.eq(host.TalentsFrame:IsShown(), before[3], "talents not hidden")
    t.eq(host:GetFrameLevel(), before[1])
    W:Close()
    t.ok(not root:IsShown())
    -- retour à l'autonome
    W:SetHost(nil)
    W:Open("build")
    t.ok(QuestifyBuildWindow:IsShown(), "standalone again")
    t.eq(W.root:GetParent() ~= host, true)
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  host_without_talents_frame_falls_back = function(t)
    local Q = load()
    local W = Q.UI.BuildWindow
    local host = CreateFrame("Frame", nil, UIParent)
    W:SetHost(host)
    W:Open("build")
    t.eq(W.root:GetParent(), host)
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  escape_resets_state_then_host_shows_nothing = function(t)
    local Q = load()
    local W = Q.UI.BuildWindow
    W:Open("build")
    t.ok(W:IsShown())
    QuestifyBuildWindow:Hide()          -- Échap
    t.ok(not W.root:IsShown(), "content closed too")
    t.eq(W.current, nil)
    t.ok(not W:IsShown())
    local host = CreateFrame("Frame", "PlayerSpellsFrame", UIParent)
    host.TalentsFrame = CreateFrame("Frame", nil, host)
    W:SetHost(host)
    t.ok(not W.root:IsShown(), "nothing put back over the talents")
    t.ok(not W:IsShown())
    W:SetHost(nil)
    t.ok(not QuestifyBuildWindow:IsShown() and not W.root:IsShown())
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  sethost_in_combat_is_deferred = function(t)
    local Q = load()
    local W = Q.UI.BuildWindow
    local host = CreateFrame("Frame", "PlayerSpellsFrame", UIParent)
    host.TalentsFrame = CreateFrame("Frame", nil, host)
    W:Open("build")
    t.eq(W.root:GetParent(), QuestifyBuildWindow)
    Mock.player.combat = true
    W:SetHost(host)
    t.eq(W.root:GetParent(), QuestifyBuildWindow, "not reparented in combat")
    t.eq(W.host, nil)
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(W.host, host)
    t.eq(W.root:GetParent(), host, "applied after combat")
    t.ok(W.root:IsShown() and not QuestifyBuildWindow:IsShown())
    -- retour à l'autonome demandé en combat sans coquille créée : aucune création
    QuestifyBuildWindow = nil
    local Q2 = load()
    local W2 = Q2.UI.BuildWindow
    W2:SetHost(host)
    W2:Open("build")
    Mock.player.combat = true
    W2:SetHost(nil)
    t.ok(not QuestifyBuildWindow, "no frame created in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(W2.host, nil)
    t.ok(QuestifyBuildWindow and QuestifyBuildWindow:IsShown(), "standalone after combat")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I1 : hôte gardé mais caché (fenêtre du jeu fermée) : Open passe en autonome, visible.
  open_with_hidden_host_goes_standalone = function(t)
    local Q = load()
    local W = Q.UI.BuildWindow
    local host = CreateFrame("Frame", "FakeHost", UIParent)
    host.TalentsFrame = CreateFrame("Frame", nil, host)
    host:Show()
    W:SetHost(host)
    t.ok(W:Open("build"))
    t.eq(W.root:GetParent(), host)
    W:Close()
    host:Hide()
    t.ok(W:Open("build"))
    t.eq(W.host, nil, "switched to standalone")
    t.ok(QuestifyBuildWindow and QuestifyBuildWindow:IsShown(), "shell shown")
    t.ok(W:IsShown(), "content visible")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  minimap_has_build_entry = function(t)
    local Q = load({ menu = true })
    local B = Q.UI.MinimapButton
    Mock.click(B.button, "LeftButton")
    local keys = {}
    for i, e in ipairs(Ext.menuElements("button")) do keys[i] = e.data end
    t.eq(keys, { "options", "journal", "build", "wizard", "bug" })
    t.eq(Ext.menuElements("button", "build")[1].text, Q.L.MINIMAP_MENU_BUILD)
    Ext.menuElements("button", "build")[1].setSelected()
    t.ok(QuestifyBuildWindow and QuestifyBuildWindow:IsShown(), "entry opens the window")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,
}
