-- Tests de l'assistant de navigation du premier démarrage (Q.UI.Wizard).
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

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

local function goToPage(W, n)
  while W.page < n do Mock.click(W.nextButton, "LeftButton") end
end

return {
  wizard_shows_once_and_saves = function(t)
    Mock.addons.TomTom = true
    local Q = load()
    local W = Q.UI.Wizard
    t.ok(not (QuestifyVanillaWizard and QuestifyVanillaWizard:IsShown()), "not before 3 s")
    Mock.advance(3)
    local f = QuestifyVanillaWizard
    t.ok(f and f:IsShown(), "shown 3 s after login")
    t.eq(Q.char.wizardDone, nil, "not marked done while open")
    t.eq(W.page, 1)
    t.ok(not W.finishButton:IsShown(), "finish only on the last page")
    goToPage(W, 3)
    t.ok(W.radios.tomtom:IsEnabled(), "TomTom present")
    t.ok(W.radios.tomtom:GetChecked(), "best installed marker preselected on first run")
    Mock.click(W.radios.native, "LeftButton")
    t.ok(W.radios.native:GetChecked() and not W.radios.tomtom:GetChecked())
    Mock.click(W.radios.tomtom, "LeftButton")
    t.ok(W.radios.tomtom:GetChecked() and not W.radios.native:GetChecked(), "one choice only")
    goToPage(W, 4)
    t.ok(W.finishButton:IsShown())
    W.checks.autoReward:SetChecked(false)
    Mock.click(W.finishButton, "LeftButton")
    t.eq(Q.Settings:Get("nav.display"), "tomtom")
    t.eq(Q.Settings:Get("nav.routing"), false)
    t.eq(Q.Settings:Get("autoQuest"), true)
    t.eq(Q.Settings:Get("autoReward"), false)
    t.eq(Q.char.wizardDone, true)
    t.ok(not f:IsShown(), "closed")
    -- après /reload : plus d'affichage automatique
    local Q2 = Mock.reload()
    Mock.advance(5)
    t.ok(not (QuestifyVanillaWizard and QuestifyVanillaWizard:IsShown()), "not shown again")
    t.eq(Q2.Settings:Get("nav.display"), "tomtom")
    t.eq(#Mock.errors, 0)
  end,

  wizard_disables_missing_providers = function(t)
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    -- page 1 : un état par fournisseur, avec une phrase
    t.ok(plain(W.providerRows.tomtom.status:GetText()):find(Q.L.UI_WIZ_MISSING, 1, true))
    t.ok(plain(W.providerRows.native.status:GetText()):find(Q.L.UI_WIZ_FOUND, 1, true))
    t.eq(W.providerRows.waypointui.desc:GetText(), Q.L.UI_NAV_WAYPOINTUI_DESC)
    goToPage(W, 2)
    t.ok(not W.checks.routing:IsEnabled(), "routing disabled without ShortestPath")
    t.eq(W.checks.routing:GetChecked(), false)
    goToPage(W, 3)
    t.ok(not W.radios.tomtom:IsEnabled(), "TomTom missing")
    t.ok(not W.radios.waypointui:IsEnabled(), "WaypointUI missing")
    t.ok(W.radios.native:IsEnabled(), "native always available")
    t.ok(W.radios.native:GetChecked(), "native selected by default")
    Mock.click(W.radios.tomtom, "LeftButton")          -- bouton désactivé : ignoré
    t.ok(W.radios.native:GetChecked())
    goToPage(W, 4)
    Mock.click(W.finishButton, "LeftButton")
    t.eq(Q.Settings:Get("nav.display"), "native")
    t.eq(#Mock.errors, 0)
  end,

  wizard_routing_with_shortestpath = function(t)
    Mock.addons.ShortestPathForever = true
    Mock.addons.WaypointUI = true
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    goToPage(W, 2)
    t.ok(W.checks.routing:IsEnabled())
    W.checks.routing:SetChecked(true)
    Mock.click(W.checks.routing, "LeftButton")
    goToPage(W, 3)
    t.ok(W.radios.waypointui:GetChecked(), "WaypointUI preferred on first run")
    Mock.click(W.radios.waypointui, "LeftButton")
    goToPage(W, 4)
    Mock.click(W.finishButton, "LeftButton")
    t.eq(Q.Settings:Get("nav.routing"), true)
    t.eq(Q.Settings:Get("nav.display"), "waypointui")
  end,

  wizard_rerun_keeps_current_choice = function(t)
    Mock.addons.WaypointUI = true
    Mock.addons.TomTom = true
    local Q = load({ savedVariables = { QuestifyVanillaCharDB = { wizardDone = true },
      QuestifyVanillaDB = { settings = { nav = { display = "tomtom", routing = false } } } } })
    local W = Q.UI.Wizard
    W:Show()
    t.ok(W.radios.tomtom:GetChecked(), "saved choice kept when the wizard is run again")
  end,

  wizard_not_done_while_open = function(t)
    local Q = load()
    Q.UI.Wizard:Show()
    t.ok(QuestifyVanillaWizard:IsShown())
    t.eq(Q.char.wizardDone, nil, "creation does not mark the wizard done")
    Mock.click(Q.UI.Wizard.nextButton, "LeftButton")
    t.eq(Q.char.wizardDone, nil)
  end,

  wizard_uses_nav_detect = function(t)
    local Q = load()
    Ext.fakeNavDetect(Q, { tomtom = true, waypointui = false, shortestpath = false })
    local W = Q.UI.Wizard
    W:Show()
    t.ok(plain(W.providerRows.tomtom.status:GetText()):find(Q.L.UI_WIZ_FOUND, 1, true), "Q.Nav:Detect used")
    goToPage(W, 3)
    t.ok(W.radios.tomtom:IsEnabled())
  end,

  wizard_previous_and_close = function(t)
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    goToPage(W, 3)
    Mock.click(W.prevButton, "LeftButton")
    t.eq(W.page, 2)
    t.ok(W.pages[2]:IsShown() and not W.pages[3]:IsShown())
    t.ok(plain(W.stepText:GetText()):find("2", 1, true))
    -- fermeture sans terminer : réglages inchangés, plus d'ouverture automatique
    QuestifyVanillaWizard:Hide()
    t.eq(Q.char.wizardDone, true)
    t.eq(Q.Settings:Get("nav.display"), "native")
  end,

  wizard_waits_for_combat_end = function(t)
    local Q = load()
    Mock.player.combat = true
    Mock.advance(3)
    t.ok(not (QuestifyVanillaWizard and QuestifyVanillaWizard:IsShown()), "not during combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(QuestifyVanillaWizard and QuestifyVanillaWizard:IsShown(), "after combat")
  end,

  wizard_slash_command = function(t)
    local Q = load({ savedVariables = { QuestifyVanillaCharDB = { wizardDone = true } } })
    Mock.advance(3)
    t.ok(not (QuestifyVanillaWizard and QuestifyVanillaWizard:IsShown()))
    SlashCmdList.QUESTIFYVANILLA("wizard")
    t.ok(QuestifyVanillaWizard:IsShown())
    t.eq(Q.UI.Wizard.page, 1)
  end,
}
