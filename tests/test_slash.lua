-- Tests des commandes /questify et /qf.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

local function load(opts)
  Ext.install()
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end   -- routes générées : contenu changeant
  return Mock.loadAddon(TOC, opts)
end

local function qf(msg) SlashCmdList.QUESTIFY(msg) end

return {
  slash_skip_and_back = function(t)
    local Q = load()
    local first = Q.Progress:Current().key
    qf("skip")
    t.ok(Q.char.skipped[first], "current step skipped")
    t.ok(Q.Progress:Current().key ~= first)
    qf("  BACK ")
    t.eq(Q.Progress:Current().key, first, "back reopens it")
    qf("back")
    t.ok(Mock.printed(Q.L.UI_SLASH_NO_BACK), "nothing more to reopen")
    t.eq(#Mock.errors, 0)
  end,

  slash_options_opens_the_options_window = function(t)
    local Q = load()
    qf("options")
    t.ok(QuestifyOptions and QuestifyOptions:IsShown(), "options window")
    t.ok(not (QuestifyJournal and QuestifyJournal:IsShown()), "not the journal")
    qf("options")
    t.ok(QuestifyOptions:IsShown(), "stays open")
    qf("config")
    t.ok(QuestifyOptions:IsShown(), "alias")
    -- /qf options <texte> : ouverte sur cette recherche
    qf("options butin")
    t.eq(Q.UI.Options.query, "butin")
    t.ok(Q.UI.Options:Widget("autoReward"):IsShown(), "search result shown")
    t.eq(#Mock.errors, 0)
  end,

  slash_export = function(t)
    local Q = load()
    Ext.fakeTelemetry(Q, "QV1;A:1=3")
    qf("export")
    t.ok(QuestifyOptions:IsShown())
    t.eq(Q.UI.Options.section, "tools")
    local w = Q.UI.Options:Widget("exportTelemetry")
    t.ok(w.box:IsShown(), "export box open")
    t.eq(w.box:GetText(), "QV1;A:1=3")
    t.ok(Mock.printed(Q.L.UI_SLASH_EXPORTED))
  end,

  slash_debug_toggles = function(t)
    local Q = load()
    t.eq(QuestifyDB.debug, false)
    qf("debug")
    t.eq(QuestifyDB.debug, true)
    t.ok(Mock.printed(Q.L.UI_SLASH_DEBUG_ON))
    qf("debug")
    t.eq(QuestifyDB.debug, false)
    t.ok(Mock.printed(Q.L.UI_SLASH_DEBUG_OFF))
  end,

  slash_reset_confirms_then_wipes = function(t)
    local Q = load()
    Q.char.manual["g:A_DwarfGnome_01:1"] = true
    Q.char.wizardDone = true
    Q.char.classQuests.ignored.X = true
    qf("reset")
    t.eq(Mock.lastCall("StaticPopup_Show").args[1], "QUESTIFY_RESET", "asks first")
    t.eq(Q.char.manual["g:A_DwarfGnome_01:1"], true, "nothing wiped before confirmation")
    local dialog = StaticPopupDialogs.QUESTIFY_RESET
    t.eq(dialog.text, Q.L.UI_RESET_CONFIRM)
    dialog.OnAccept()
    t.eq(next(Q.char.manual), nil, "manual wiped")
    t.eq(Q.char.wizardDone, nil)
    t.eq(next(Q.char.classQuests.ignored), nil)
    t.eq(type(Q.char.skipped), "table", "defaults restored")
    t.ok(QuestifyCharDB == Q.char, "same saved table")
    t.ok(Q.Progress:Current(), "route still running")
    t.ok(Mock.printed(Q.L.UI_RESET_DONE))
    t.eq(#Mock.errors, 0)
  end,

  resets_use_progress_reset_guide = function(t)
    local Q = load()
    t.ok(Q.Progress.ResetGuide, "stream A provides ResetGuide")
    local seen = {}
    local original = Q.Progress.ResetGuide
    Q.Progress.ResetGuide = function(self, id)
      seen[#seen + 1] = id
      return original(self, id)
    end
    -- « Réinitialiser la progression du chapitre » : chapitre courant seulement
    Q.UI.Options:Open("route")
    Mock.click(Q.UI.Options:Widget("resetChapter").button, "LeftButton")
    t.eq(seen, { "A_DwarfGnome_01" })
    -- /qf reset : toutes les validations de session des chapitres sont effacées
    seen = {}
    qf("reset")
    StaticPopupDialogs.QUESTIFY_RESET.OnAccept()
    t.eq(#seen, #Q.Guides:All(), "every chapter reset")
    t.ok(Q.Progress:Current(), "route still running")
    t.eq(#Mock.errors, 0)
  end,

  slash_help_on_unknown = function(t)
    local Q = load()
    qf("whatever")
    t.ok(Mock.printed(Q.L.UI_SLASH_HELP))
    qf("help")
    t.eq(Mock.countPrinted(Q.L.UI_SLASH_HELP), 2)
  end,

  slash_errors_are_contained = function(t)
    local Q = load()
    Q.Progress.Back = function() error("boom") end
    qf("back")
    t.ok(Mock.printed("Questify:"), "error reported once with the prefix")
    t.ok(#Mock.errors >= 1)
  end,
}
