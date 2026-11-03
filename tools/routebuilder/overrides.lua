-- tools/routebuilder/overrides.lua : corrections manuelles appliquées par build.lua après relecture
-- des rapports (docs/routes/<planId>.md). Fichier de données pur (chargé dans un environnement vide).
--
--   force       = { [questId] = true }                 -- garder la quête même si écartée (rendement, niveau)
--   drop        = { [questId] = "raison" }             -- écarter la quête (raison reprise dans le rapport)
--   pin         = { [questId] = { mapId, x, y } }      -- site d'objectif imposé (0-100)
--   insertAfter = { [planId] = { { afterQuestTurnin = questId, step = { "note", "..." } }, ... } }
--                                                      -- étape ajoutée après le rendu d'une quête
--                                                      -- (afterQuestTurnin = 0 : en tête du chapitre)
return {
  force = {},
  drop = {},
  pin = {},
  insertAfter = {},
}
