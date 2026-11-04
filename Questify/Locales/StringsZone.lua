local addonName, Q = ...

-- Textes du mode zone (Engine/ZoneMode.lua, suivi, repères de carte). Toutes les clés commencent
-- par ZONE_ pour ne pas entrer en collision avec les textes des autres modules.
Q:RegisterStrings({
  enUS = {
    ZONE_OPT = "Zone mode: nearby objectives grouped into one visit",
    ZONE_TITLE = "Zone: %s",
    ZONE_HEAD = "Zone: %s — %s (%s)",
    ZONE_N_OBJ_ONE = "%d objective",
    ZONE_N_OBJ = "%d objectives",
    ZONE_N_QUEST_ONE = "%d quest",
    ZONE_N_QUEST = "%d quests",
    ZONE_HINT_OUTSIDE = "Go to the zone (green marker), everything is done in one visit",
    ZONE_GROUP_OBJECTS = "Objects",
    ZONE_GROUP_NAMED = "Elites and named",
    ZONE_GROUP_MOBS = "Monsters",
    ZONE_LOOT_FROM = "Loot %s (%s)",
    ZONE_NEEDS = "needs %s",
    ZONE_PIN = "Zone of the current step",
  },
  frFR = {
    ZONE_OPT = "Mode zone : objectifs proches regroupés en une visite",
    ZONE_TITLE = "Zone : %s",
    ZONE_HEAD = "Zone : %s — %s (%s)",
    ZONE_N_OBJ_ONE = "%d objectif",
    ZONE_N_OBJ = "%d objectifs",
    ZONE_N_QUEST_ONE = "%d quête",
    ZONE_N_QUEST = "%d quêtes",
    ZONE_HINT_OUTSIDE = "Aller dans la zone (repère vert), tout s'y fait en une seule visite",
    ZONE_GROUP_OBJECTS = "Objets",
    ZONE_GROUP_NAMED = "Élites et nommés",
    ZONE_GROUP_MOBS = "Monstres",
    ZONE_LOOT_FROM = "Ramasser %s (%s)",
    ZONE_NEEDS = "il faut %s",
    ZONE_PIN = "Zone de l'étape en cours",
  },
})
