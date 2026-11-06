-- Routes fictives (tests de tools/apr). Quêtes 101-110 : vallée (1-6) ; 201-209 : collines (6-10) ;
-- 301 : route réservée aux mages ; 501 : donjon ; 601 : route lointaine (40-42), sans chapitre.
local L = LibStub("AceLocale-3.0"):GetLocale("APR")

APR.RouteQuestStepList["Test-Alliance-Valley"] = {
    label = L["Fixture Valley"] .. " (1-6)",
    expansion = APR.EXPANSIONS.Forever,
    category = APR.CATEGORIES.Leveling,
    mapID = 9901,
    conditions = { Faction = "Alliance", Race = { APR.RACES.Human, APR.RACES.Dwarf } },
    nextRoute = {
        "Test-Alliance-Hills",
        { route = "Test-Alliance-Mage", conditions = { Class = APR.Classes.Mage } },
    },
    steps = {
        { PickUp = { 101, 102 }, Coord = APR.worldCoordinateConverter:ConvertMapCoordinate(9901, 50, 50), Zone = 9901, _index = 1 },
        { SetHS = 101, Zone = 9901, _index = 2 },
        { Qpart = { [101] = { 1 } }, Note = { "TEST_INSIDE_CAVE" }, Zone = 9901, _index = 3 },
        { Qpart = { [102] = { 1 } }, Note = { "TEST_GO_UPSTAIRS" }, Range = math.min(30, 40), Zone = 9901, _index = 4 },
        { PickUp = { 103 }, Class = "WARRIOR", Zone = 9901, _index = 5 },
        { Done = { 103 }, Class = APR.Classes.Warrior, Zone = 9901, _index = 6 },
        { UseHS = 102, UseHSIfAvailable = true, Zone = 9901, _index = 7 },
        { Done = { 102, 101 }, Zone = 9901, _index = 8 },
        { PickUp = { 104 }, Race = "Dwarf", Zone = 9901, _index = 9 },
        { Done = { 104 }, Race = "Dwarf", Zone = 9901, _index = 10 },
        { PickUp = { 105 }, Hardcore = true, Zone = 9901, _index = 11 },
        { PickUp = { 106 }, Note = { "TEST_AUCTION_HOUSE_CHECK" }, Zone = 9901, _index = 12 },
        { Done = { 106 }, Zone = 9901, _index = 13 },
        { PickUp = { 110 }, Zone = 9901, _index = 14 },
    },
}

APR.RouteQuestStepList["Test-Alliance-Hills"] = {
    label = L["Fixture Hills"] .. " (6-10)",
    category = APR.CATEGORIES.Leveling,
    mapID = 9902,
    conditions = { Faction = "Alliance", MinLevel = 6 },
    steps = {
        { PickUp = { 201, 202, 203 }, Zone = 9902, _index = 1 },
        { PickUp = { 204, 205, 206, 207, 208, 209 }, Zone = 9902, _index = 2 },
        { Qpart = { [201] = { 1 }, [202] = { 1 } }, Fillers = { [203] = { 1 } }, Zone = 9902, _index = 3 },
        { Done = { 204, 205, 206, 207, 208, 209 }, Zone = 9902, _index = 4 },
        { Done = { 201, 202, 203 }, Zone = 9902, _index = 5 },
    },
}

APR.RouteQuestStepList["Test-Alliance-Mage"] = {
    label = L["Fixture Mage"] .. " (6-10)",
    category = APR.CATEGORIES.Leveling,
    mapID = 9902,
    conditions = { Faction = "Alliance", Class = APR.Classes.Mage },
    steps = {
        { PickUp = { 301 }, Zone = 9902, _index = 1 },
    },
}

APR.RouteQuestStepList["Test-Alliance-Dungeon"] = {
    label = L["Fixture Dungeon"],
    category = APR.CATEGORIES.Dungeons,
    mapID = 9903,
    conditions = { MinLevel = 8 },
    steps = {
        { PickUp = { 501 }, Zone = 9903, _index = 1 },
    },
}

APR.RouteQuestStepList["Test-Alliance-Far"] = {
    label = L["Fixture Far"] .. " (40-42)",
    category = APR.CATEGORIES.Leveling,
    mapID = 9904,
    conditions = { Faction = "Alliance", MinLevel = 40 },
    steps = {
        { PickUp = { 601 }, Zone = 9904, _index = 1 },
        { Done = { 601 }, Zone = 9904, _index = 2 },
    },
}
