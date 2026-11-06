-- Route fictive (tests de tools/apr) : faction Horde, race Scourge (= Undead chez Questify).
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Test-Horde-Glade"] = {
    label = L["Fixture Glade"] .. " (1-6)",
    category = APR.CATEGORIES.Leveling,
    mapID = 9910,
    conditions = { Faction = "Horde", Race = { APR.RACES.Scourge } },
    steps = {
        { PickUp = { 401 }, Zone = 9910, _index = 1 },
        { Done = { 401 }, Zone = 9910, _index = 2 },
    },
}
