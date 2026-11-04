-- Tests du rapport de bug (/qf bug).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

return {
  bug_report_has_the_essentials = function(t)
    Ext.install()
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
    Q:ReportError("Interface/AddOns/Questify_Vanilla/X.lua:1: boom")
    Q.UI.BugReport:Show()
    local B = Q.UI.BugReport
    t.ok(B.frame:IsShown())
    local txt = B.box:GetText()
    for _, needle in ipairs({ "Questify Vanilla", "QuestieDB", "WARRIOR", "carte 1426", "A_DwarfGnome_01",
      "accept q179", "suivante", "Navigation", "boom" }) do
      t.ok(txt:find(needle, 1, true), needle)
    end
    t.eq(#Mock.errors, 1, "only the error we reported")
  end,
}
