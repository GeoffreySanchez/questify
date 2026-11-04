local addonName, Q = ...

-- Textes de la vérification de version entre joueurs (Core/VersionCheck.lua). Toutes les clés
-- commencent par VERSION_ pour ne pas entrer en collision avec les textes des autres modules.
Q:RegisterStrings({
  enUS = {
    -- ligne de discussion : version reçue, version installée
    VERSION_AVAILABLE = "Questify Vanilla %s is available (you have %s): update via CurseForge.",
    -- message court au milieu de l'écran : version reçue
    VERSION_AVAILABLE_SHORT = "Questify Vanilla %s is available on CurseForge",
    -- case à cocher de l'option versionCheck (onglet Options du journal)
    VERSION_OPT = "Tell me when a newer version exists (silent message to guild and group)",
  },
  frFR = {
    VERSION_AVAILABLE = "Questify Vanilla %s est disponible (tu as %s) : mets à jour via CurseForge.",
    VERSION_AVAILABLE_SHORT = "Questify Vanilla %s est disponible sur CurseForge",
    VERSION_OPT = "Me prévenir d'une nouvelle version (message silencieux à la guilde et au groupe)",
  },
})
