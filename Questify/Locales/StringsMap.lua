local addonName, Q = ...

-- Textes des repères de carte (UI/MapPins.lua : carte du monde et minicarte). Toutes les clés
-- commencent par MAP_ pour ne pas entrer en collision avec les textes des autres modules.
Q:RegisterStrings({
  enUS = {
    MAP_OPT_PINS = "Show the next steps on the world map and minimap",
    MAP_PIN_CURRENT = "Current step",
    MAP_PIN_UPCOMING = "Upcoming step (#%d)",
    MAP_PIN_CLICK = "Click: navigate here",
  },
  frFR = {
    MAP_OPT_PINS = "Afficher les prochaines étapes sur la carte du monde et la minicarte",
    MAP_PIN_CURRENT = "Étape en cours",
    MAP_PIN_UPCOMING = "Étape à venir (n° %d)",
    MAP_PIN_CLICK = "Clic : y aller",
  },
})
