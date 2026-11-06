-- tools/routebuilder/overrides.lua : corrections manuelles appliquées par build.lua après relecture
-- des rapports (docs/routes/<planId>.md). Fichier de données pur (chargé dans un environnement vide).
--
--   force       = { [questId] = true }                 -- garder la quête même si écartée (rendement, niveau)
--   drop        = { [questId] = "raison" }             -- écarter la quête (raison reprise dans le rapport)
--   pin         = { [questId] = { mapId, x, y } }      -- site d'objectif imposé (0-100)
--   insertAfter = { [planId] = { { afterQuestTurnin = questId, step = { "note", "..." } }, ... } }
--                                                      -- étape ajoutée après le rendu d'une quête
--                                                      -- (afterQuestTurnin = 0 : en tête du chapitre)
-- Les textes des étapes `note` sont en anglais, comme toutes les notes générées (affichées telles quelles).
-- Les notes de donjon sont `optional` : masquées quand les quêtes de donjon sont désactivées.
return {
  force = {
    [140] = true, -- Captain Sander's Hidden Treasure (2e étape de la chaîne, rendement 7.3), écartée par le budget d'XP
  },
  drop = {
    [34] = "Bellygrub is a level 24 elite; done at 22 it drags Worgen in the Woods forward",
    [173] = "Worgen in the Woods chain: Nightbane mobs 27-31, above the 22-26 band",
    [631] = "The Thandol Span (31, req 28) gates a 157-170 mob grind at Dun Modr",
    [217] = "In Defense of the King's Lands, last part: Grawmug (17) and his guards (16), never at a safe level in Loch Modan (11-14)",
    [1056] = "Journey to Stonetalon Peak: 1,133 yd detour for a flight path the route never uses",
  },
  pin = {
    [98071] = { 1424, 70.0, 79.0 }, -- Brewer's Trade : Dun Garok (aucune donnée d'objectif)
    [98059] = { 1424, 29.7, 41.6 }, -- Hillsbrad's Hoard : table de l'hôtel de ville de Hillsbrad
    [11] = { 1429, 26.46, 86.65 }, -- Riverpaw Gnoll Bounty : groupe ouest (apparition de Riverpaw Runt 97), près de Westbrook
  },
  insertAfter = {
    A_DwarfGnome_03 = {
      { afterQuestTurnin = 301, step = { "note", "The Hall of Thanes is under Ironforge (levels 13-18): run it on this visit, or abandon Old Ironforge Incursion",
          optional = true, dungeon = "The Hall of Thanes" } },
    },
    A_04 = {
      { afterQuestTurnin = 0, step = { "note", "You pass through Stormwind: run The Stockade now for Crime and Punishment and What Comes Around..., or abandon them",
          optional = true, dungeon = "The Stockade" } },
      { afterQuestTurnin = 292, step = { "note", "Last pass near the Excavation Site: run it now, or abandon Highland Hides, Horrors in the Highland, Lost in the Thicket Things and Prehistoric Prism",
          optional = true, dungeon = "Excavation Site: Wetlands" } },
    },
  },
}
