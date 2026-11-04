local addonName, Q = ...

-- Textes du flux C : navigation, automatisation des quêtes, choix de récompense.
Q:RegisterStrings({
  enUS = {
    NAV_SHORTESTPATH = "ShortestPath Forever",
    NAV_WAYPOINTUI = "WaypointUI",
    NAV_TOMTOM = "TomTom",
    NAV_NATIVE = "Built-in waypoint",

    REWARD_UPGRADE = "Reward: %s (an upgrade over your equipped item)",
    REWARD_VENDOR = "Reward: %s (nothing improves your gear, so the highest vendor price: %s)",
    REWARD_NOT_LOADED = "Reward items are not loaded yet: choose your reward yourself.",
    COIN_GOLD = "g",
    COIN_SILVER = "s",
    COIN_COPPER = "c",
  },
  frFR = {
    NAV_SHORTESTPATH = "ShortestPath Forever",
    NAV_WAYPOINTUI = "WaypointUI",
    NAV_TOMTOM = "TomTom",
    NAV_NATIVE = "Marqueur du jeu",

    REWARD_UPGRADE = "Récompense : %s (meilleure que ton objet équipé)",
    REWARD_VENDOR = "Récompense : %s (rien n'améliore ton équipement, donc le plus gros prix de revente : %s)",
    REWARD_NOT_LOADED = "Les objets de récompense ne sont pas encore chargés : choisis ta récompense toi-même.",
    COIN_GOLD = "po",
    COIN_SILVER = "pa",
    COIN_COPPER = "pc",
  },
})
