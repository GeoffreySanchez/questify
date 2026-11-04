-- Tests de l'assistant du premier démarrage (Q.UI.Wizard).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")
local WExt = dofile(Mock.root .. "/tests/mock_ext_wizard.lua")

local URL = {
  questiedb = "https://www.curseforge.com/wow/addons/questiedb",
  shortestpath = "https://www.curseforge.com/wow/addons/shortest-path-forever",
  waypointui = "https://www.curseforge.com/wow/addons/waypointui",
  tomtom = "https://www.curseforge.com/wow/addons/tomtom",
}

-- states : états des addons pour le complément C_AddOns (voir tests/mock_ext_wizard.lua).
local function load(opts, states)
  Ext.install()
  WExt.install(states)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end   -- routes générées : contenu changeant
  return Mock.loadAddon(TOC, opts)
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

local function goToPage(W, n)
  while W.page < n do Mock.click(W.nextButton, "LeftButton") end
end

local function shown(W) return W.frame ~= nil and W.frame:IsShown() end

return {
  wizard_shows_once_and_saves = function(t)
    Mock.addons.TomTom = true
    local Q = load()
    local W = Q.UI.Wizard
    t.ok(not shown(W), "not before 3 s")
    Mock.advance(3)
    local f = QuestifyWizard
    t.ok(f and f:IsShown(), "shown 3 s after login")
    t.eq(Q.char.wizardDone, nil, "not marked done while open")
    t.eq(W.page, 1)
    t.eq(W.NUM_PAGES, 5)
    t.ok(not W.finishButton:IsShown(), "finish only on the last page")
    goToPage(W, 3)
    t.ok(W.radios.tomtom:IsEnabled(), "TomTom present")
    t.ok(W.radios.tomtom:GetChecked(), "best installed marker preselected on first run")
    Mock.click(W.radios.native, "LeftButton")
    t.ok(W.radios.native:GetChecked() and not W.radios.tomtom:GetChecked())
    Mock.click(W.radios.tomtom, "LeftButton")
    t.ok(W.radios.tomtom:GetChecked() and not W.radios.native:GetChecked(), "one choice only")
    goToPage(W, 4)
    W.checks.autoReward:SetChecked(false)
    goToPage(W, 5)
    t.ok(W.finishButton:IsShown())
    t.ok(not W.nextButton:IsShown() and not W.skipButton:IsShown(), "no Next / Skip on the last page")
    t.ok(plain(W.recap.display:GetText()):find("TomTom", 1, true), "summary shows the marker")
    t.ok(plain(W.recap.autoReward:GetText()):find(Q.L.UI_WIZ_OFF, 1, true), "summary reads the boxes")
    Mock.click(W.finishButton, "LeftButton")
    t.eq(Q.Settings:Get("nav.display"), "tomtom")
    t.eq(Q.Settings:Get("nav.routing"), false)
    t.eq(Q.Settings:Get("autoQuest"), true)
    t.eq(Q.Settings:Get("autoReward"), false)
    t.eq(Q.Settings:Get("sellJunk"), true)
    t.eq(Q.char.wizardDone, true)
    t.ok(not f:IsShown(), "closed")
    -- après /reload : plus d'affichage automatique
    local Q2 = WExt.reload()
    Mock.advance(5)
    t.ok(not shown(Q2.UI.Wizard), "not shown again")
    t.eq(Q2.Settings:Get("nav.display"), "tomtom")
    t.eq(#Mock.errors, 0)
  end,

  wizard_links_only_for_missing_addons = function(t)
    Mock.addons.TomTom = true
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    local rows = W.addonRows
    t.eq(rows.questiedb.state, "loaded", "QuestieDB loaded by the mock")
    t.eq(rows.tomtom.state, "loaded")
    t.eq(rows.waypointui.state, "missing")
    t.eq(rows.shortestpath.state, "missing")
    t.ok(not rows.questiedb.link:IsShown(), "no link for an installed addon")
    t.ok(not rows.tomtom.link:IsShown())
    t.ok(rows.waypointui.link:IsShown(), "link for a missing addon")
    t.ok(rows.shortestpath.link:IsShown())
    t.eq(rows.waypointui.link:GetText(), URL.waypointui)
    t.eq(rows.shortestpath.link:GetText(), URL.shortestpath)
    t.eq(rows.tomtom.link:GetText(), URL.tomtom, "link text ready even when hidden")
    t.ok(W.linkHint:IsShown(), "copy hint shown")
    t.eq(W.linkHint:GetText(), Q.L.UI_WIZ_LINK_HINT)
    t.eq(W.restartNote:GetText(), Q.L.UI_WIZ_RESTART_NOTE)
    t.ok(plain(rows.waypointui.status:GetText()):find(Q.L.UI_WIZ_ABSENT, 1, true))
    t.ok(plain(rows.tomtom.status:GetText()):find(Q.L.UI_WIZ_LOADED, 1, true))
    t.eq(rows.waypointui.desc:GetText(), Q.L.UI_NAV_WAYPOINTUI_DESC)
    t.ok(not rows.waypointui.enable:IsShown(), "nothing to enable")
    -- champ en lecture seule : sélection à la prise du focus, toute frappe remet le lien
    local box = rows.waypointui.link
    local highlights = 0
    rawset(box, "HighlightText", function(_, a, b) if a == nil then highlights = highlights + 1 end end)
    box:GetScript("OnEditFocusGained")(box)
    t.eq(highlights, 1, "text selected on focus")
    box:SetText("abc")
    box:GetScript("OnTextChanged")(box, true)
    t.eq(box:GetText(), URL.waypointui, "read only")
    t.eq(highlights, 2)
    t.eq(#Mock.errors, 0)
  end,

  wizard_all_installed_no_link = function(t)
    Mock.addons.TomTom = true
    Mock.addons.WaypointUI = true
    Mock.addons.ShortestPathForever = true
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    for _, entry in ipairs(W.ADDONS) do
      t.eq(W.addonRows[entry.id].state, "loaded", entry.id)
      t.ok(not W.addonRows[entry.id].link:IsShown(), entry.id)
    end
    t.ok(not W.linkHint:IsShown(), "no copy hint without links")
  end,

  wizard_candidate_folders = function(t)
    local Q = load(nil, { ["Waypoint-UI"] = "disabled", ShortestPath = "loaded" })
    local W = Q.UI.Wizard
    W:Show()
    t.eq(W.addonRows.waypointui.state, "disabled", "other folder name found")
    t.eq(W.addonRows.waypointui.folder, "Waypoint-UI")
    t.eq(W.addonRows.shortestpath.state, "loaded")
    Mock.click(W.addonRows.waypointui.enable, "LeftButton")
    t.eq(Mock.lastCall("C_AddOns.EnableAddOn").args[1], "Waypoint-UI")
  end,

  wizard_enable_then_reload_resumes = function(t)
    local Q = load(nil, { WaypointUI = "disabled", TomTom = "outdated" })
    local W = Q.UI.Wizard
    Mock.advance(3)
    t.ok(shown(W))
    local row = W.addonRows.waypointui
    t.eq(row.state, "disabled")
    t.ok(row.enable:IsShown(), "Enable button for a disabled addon")
    t.ok(not row.link:IsShown(), "installed: no link")
    t.ok(plain(row.status:GetText()):find(Q.L.UI_WIZ_DISABLED, 1, true))
    t.eq(W.addonRows.tomtom.state, "outdated")
    t.ok(not W.addonRows.tomtom.enable:IsShown())
    t.ok(W.reloadButton:IsShown(), "reload offered on the addons page")
    t.ok(not W.reloadText:IsShown())
    goToPage(W, 2)
    t.ok(not W.reloadButton:IsShown(), "no reload elsewhere before Enable")
    Mock.click(W.prevButton, "LeftButton")
    Mock.click(row.enable, "LeftButton")
    local call = Mock.lastCall("C_AddOns.EnableAddOn")
    t.ok(call, "EnableAddOn called")
    t.eq(call.args[1], "WaypointUI")
    t.eq(call.args[2], "Testeur", "enabled for this character only")
    t.eq(row.state, "pending")
    t.ok(not row.enable:IsShown())
    t.ok(plain(row.status:GetText()):find(Q.L.UI_WIZ_PENDING, 1, true))
    t.ok(W.reloadText:IsShown(), "reload message after Enable")
    t.ok(plain(W.reloadText:GetText()):find("WaypointUI", 1, true))
    goToPage(W, 3)
    t.ok(W.reloadButton:IsShown(), "reload offered on every page after Enable")
    t.ok(not W.radios.waypointui:IsEnabled(), "not loaded yet")
    Mock.click(W.reloadButton, "LeftButton")
    t.eq(Mock.countCalls("ReloadUI"), 1, "ReloadUI called")
    t.eq(Q.char.wizardPage, 3)
    -- après le rechargement : l'assistant reprend sur la même page, WaypointUI chargé
    local Q2 = WExt.reload()
    local W2 = Q2.UI.Wizard
    t.ok(not shown(W2), "not before 3 s")
    Mock.advance(3)
    t.ok(shown(W2), "reopened after /reload")
    t.eq(W2.page, 3, "same page")
    t.ok(W2.pages[3]:IsShown())
    t.ok(W2.radios.waypointui:IsEnabled(), "WaypointUI now loaded")
    t.ok(W2.radios.waypointui:GetChecked(), "best marker preselected")
    t.eq(W2.addonRows.waypointui.state, "loaded")
    t.ok(not W2.reloadButton:IsShown(), "nothing left to reload")
    t.eq(#Mock.errors, 0)
  end,

  wizard_enable_needs_player_name = function(t)
    local Q = load(nil, { TomTom = "disabled" })
    local W = Q.UI.Wizard
    W:Show()
    UnitName = function() return nil end
    Mock.click(W.addonRows.tomtom.enable, "LeftButton")
    t.eq(Mock.countCalls("C_AddOns.EnableAddOn"), 0, "no character name: nothing enabled")
    t.eq(W.addonRows.tomtom.state, "disabled")
    t.ok(not W.pendingReload)
    t.eq(#Mock.errors, 0)
  end,

  wizard_opens_without_questiedb = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    local W = Q.UI.Wizard
    t.ok(Mock.printed(Q.L.NEED_QUESTIEDB), "chat explains the dependency")
    Mock.advance(3)
    t.ok(shown(W), "wizard opens without QuestieDB")
    t.eq(W.page, 1)
    local row = W.addonRows.questiedb
    t.eq(row.state, "missing")
    t.ok(plain(row.name:GetText()):find(Q.L.UI_WIZ_REQUIRED, 1, true), "marked required")
    t.ok(row.link:IsShown(), "QuestieDB link shown")
    t.eq(row.link:GetText(), URL.questiedb)
    t.ok(W.linkHint:IsShown())
    -- le suivi : message et bouton « Lien » qui rouvre l'assistant sur la page des addons
    local T = Q.UI.Tracker
    t.eq(T.message:GetText(), Q.L.NEED_QUESTIEDB)
    t.ok(T.qdbLink and T.qdbLink:IsShown(), "link button in the tracker")
    t.eq(T.qdbLink:GetText(), Q.L.UI_WIZ_LINK_BUTTON)
    goToPage(W, 3)
    QuestifyWizard:Hide()
    Mock.click(T.qdbLink, "LeftButton")
    t.ok(shown(W), "tracker button opens the wizard")
    t.eq(W.page, 1, "on the addons page")
    t.eq(#Mock.errors, 0)
  end,

  wizard_questiedb_too_old = function(t)
    Mock.qdbContract = 3                     -- RequireContract(4) échoue
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    local row = W.addonRows.questiedb
    t.eq(row.state, "old")
    t.ok(plain(row.status:GetText()):find(Q.L.UI_WIZ_QDB_OLD, 1, true))
    t.ok(row.link:IsShown(), "link to update it")
    t.eq(row.link:GetText(), URL.questiedb)
    t.ok(Q.UI.Tracker.qdbLink, "tracker link button too")
    t.eq(#Mock.errors, 0)
  end,

  wizard_next_skip_previous = function(t)
    Mock.addons.TomTom = true
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    t.eq(W.page, 1)
    t.ok(W.prevButton:IsShown() and not W.prevButton:IsEnabled(), "Previous disabled on page 1")
    t.ok(W.skipButton:IsShown() and W.nextButton:IsShown())
    Mock.click(W.skipButton, "LeftButton")
    t.eq(W.page, 2, "Skip moves on")
    Mock.click(W.nextButton, "LeftButton")
    t.eq(W.page, 3)
    t.ok(W.pages[3]:IsShown() and not W.pages[2]:IsShown())
    t.ok(plain(W.stepText:GetText()):find("3", 1, true))
    -- Ignorer remet le choix de la page
    Mock.click(W.radios.native, "LeftButton")
    t.eq(W.choice.display, "native")
    t.eq(Q.char.wizardDraft.display, "native")
    Mock.click(W.skipButton, "LeftButton")
    t.eq(W.page, 4)
    t.eq(W.choice.display, "tomtom", "skipped page keeps the starting choice")
    t.ok(W.radios.tomtom:GetChecked() and not W.radios.native:GetChecked())
    t.eq(Q.char.wizardDraft.display, nil)
    W.checks.autoQuest:SetChecked(false)
    Mock.click(W.checks.autoQuest, "LeftButton")
    W.checks.sellJunk:SetChecked(false)
    Mock.click(W.checks.sellJunk, "LeftButton")
    Mock.click(W.skipButton, "LeftButton")
    t.eq(W.page, 5)
    t.ok(W.checks.autoQuest:GetChecked() and W.checks.sellJunk:GetChecked(), "automations restored")
    Mock.click(W.prevButton, "LeftButton")
    t.eq(W.page, 4)
    Mock.click(W.prevButton, "LeftButton")
    t.eq(W.page, 3)
    t.eq(Q.char.wizardPage, 3, "page saved on every change")
    t.eq(Q.char.wizardDone, nil)
  end,

  wizard_finish_clears_page = function(t)
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    goToPage(W, 4)
    W.checks.sellJunk:SetChecked(false)
    Mock.click(W.checks.sellJunk, "LeftButton")
    t.eq(Q.char.wizardPage, 4)
    t.eq(Q.char.wizardDraft.sellJunk, false)
    goToPage(W, 5)
    Mock.click(W.finishButton, "LeftButton")
    t.eq(Q.char.wizardDone, true)
    t.eq(Q.char.wizardPage, nil, "page cleared")
    t.eq(Q.char.wizardDraft, nil, "draft cleared")
    t.eq(Q.Settings:Get("sellJunk"), false)
    -- relancé à la main : depuis le début
    SlashCmdList.QUESTIFY("wizard")
    t.eq(W.page, 1)
  end,

  wizard_close_keeps_page = function(t)
    local Q = load()
    local W = Q.UI.Wizard
    Mock.advance(3)
    goToPage(W, 3)
    QuestifyWizard:Hide()
    t.eq(Q.char.wizardDone, nil, "closing is not finishing")
    t.eq(Q.char.wizardPage, 3, "page kept")
    t.eq(Q.Settings:Get("nav.display"), "native", "settings unchanged")
    -- pas de nouvelle ouverture automatique dans la même session
    Q:Fire("LOGIN")
    Mock.advance(5)
    t.ok(not shown(W), "not nagged within the session")
    -- /qf wizard reprend à la même page
    SlashCmdList.QUESTIFY("wizard")
    t.ok(shown(W))
    t.eq(W.page, 3)
    QuestifyWizard:Hide()
    -- session suivante : rouvert sur la même page
    local Q2 = WExt.reload()
    Mock.advance(3)
    t.ok(shown(Q2.UI.Wizard), "reopened next session")
    t.eq(Q2.UI.Wizard.page, 3)
    t.eq(#Mock.errors, 0)
  end,

  wizard_draft_survives_reload = function(t)
    Mock.addons.TomTom = true
    local Q = load()
    local W = Q.UI.Wizard
    Mock.advance(3)
    goToPage(W, 3)
    Mock.click(W.radios.native, "LeftButton")
    goToPage(W, 4)
    W.checks.autoReward:SetChecked(false)
    Mock.click(W.checks.autoReward, "LeftButton")
    local Q2 = WExt.reload()
    Mock.advance(3)
    local W2 = Q2.UI.Wizard
    t.eq(W2.page, 4)
    t.ok(not W2.checks.autoReward:GetChecked(), "unsaved choice kept across /reload")
    t.ok(W2.radios.native:GetChecked() and not W2.radios.tomtom:GetChecked())
    goToPage(W2, 5)
    Mock.click(W2.finishButton, "LeftButton")
    t.eq(Q2.Settings:Get("nav.display"), "native")
    t.eq(Q2.Settings:Get("autoReward"), false)
  end,

  wizard_disables_missing_providers = function(t)
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    goToPage(W, 2)
    t.ok(not W.checks.routing:IsEnabled(), "routing disabled without ShortestPath")
    t.eq(W.checks.routing:GetChecked(), false)
    t.ok(W.routingMissing:IsShown())
    goToPage(W, 3)
    t.ok(not W.radios.tomtom:IsEnabled(), "TomTom missing")
    t.ok(not W.radios.waypointui:IsEnabled(), "WaypointUI missing")
    t.ok(W.radios.native:IsEnabled(), "native always available")
    t.ok(W.radios.native:GetChecked(), "native selected by default")
    Mock.click(W.radios.tomtom, "LeftButton")          -- bouton désactivé : ignoré
    t.ok(W.radios.native:GetChecked())
    goToPage(W, 5)
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
    goToPage(W, 5)
    t.ok(plain(W.recap.routing:GetText()):find("ShortestPath Forever", 1, true))
    Mock.click(W.finishButton, "LeftButton")
    t.eq(Q.Settings:Get("nav.routing"), true)
    t.eq(Q.Settings:Get("nav.display"), "waypointui")
  end,

  wizard_rerun_keeps_current_choice = function(t)
    Mock.addons.WaypointUI = true
    Mock.addons.TomTom = true
    local Q = load({ savedVariables = { QuestifyCharDB = { wizardDone = true },
      QuestifyDB = { settings = { nav = { display = "tomtom", routing = false } } } } })
    local W = Q.UI.Wizard
    W:Show()
    t.ok(W.radios.tomtom:GetChecked(), "saved choice kept when the wizard is run again")
  end,

  wizard_not_done_while_open = function(t)
    local Q = load()
    Q.UI.Wizard:Show()
    t.ok(QuestifyWizard:IsShown())
    t.eq(Q.char.wizardDone, nil, "creation does not mark the wizard done")
    Mock.click(Q.UI.Wizard.nextButton, "LeftButton")
    t.eq(Q.char.wizardDone, nil)
  end,

  wizard_uses_nav_detect = function(t)
    local Q = load()
    Ext.fakeNavDetect(Q, { tomtom = true, waypointui = false, shortestpath = false })
    local W = Q.UI.Wizard
    W:Show()
    t.eq(W.addonRows.tomtom.state, "loaded", "Q.Nav:Detect used")
    goToPage(W, 3)
    t.ok(W.radios.tomtom:IsEnabled())
  end,

  wizard_without_addon_api = function(t)
    -- client sans DoesAddOnExist / GetAddOnInfo / GetAddOnEnableState : absent = pas chargé
    local Q = load()
    C_AddOns.DoesAddOnExist, C_AddOns.GetAddOnInfo, C_AddOns.GetAddOnEnableState = nil, nil, nil
    local W = Q.UI.Wizard
    W:Show()
    t.eq(W.addonRows.questiedb.state, "loaded")
    t.eq(W.addonRows.tomtom.state, "missing")
    t.ok(W.addonRows.tomtom.link:IsShown())
    t.eq(#Mock.errors, 0)
  end,

  wizard_waits_for_combat_end = function(t)
    local Q = load()
    Mock.player.combat = true
    Mock.advance(3)
    t.ok(not shown(Q.UI.Wizard), "not during combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(QuestifyWizard and QuestifyWizard:IsShown(), "after combat")
  end,

  wizard_slash_command = function(t)
    local Q = load({ savedVariables = { QuestifyCharDB = { wizardDone = true } } })
    Mock.advance(3)
    t.ok(not shown(Q.UI.Wizard))
    SlashCmdList.QUESTIFY("wizard")
    t.ok(QuestifyWizard:IsShown())
    t.eq(Q.UI.Wizard.page, 1)
  end,

  wizard_french_labels = function(t)
    Mock.locale = "frFR"
    local Q = load()
    local W = Q.UI.Wizard
    W:Show()
    t.eq(W.prevButton:GetText(), "Précédent")
    t.eq(W.nextButton:GetText(), "Suivant")
    t.eq(W.skipButton:GetText(), "Ignorer")
    t.eq(W.finishButton:GetText(), "Terminer")
    t.eq(W.reloadButton:GetText(), "Recharger l'interface")
    t.eq(W.addonRows.tomtom.enable:GetText(), "Activer")
    t.eq(W.linkHint:GetText(), "Ctrl+C pour copier, puis colle le lien dans ton navigateur.")
  end,
}
