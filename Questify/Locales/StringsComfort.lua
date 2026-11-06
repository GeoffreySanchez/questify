local addonName, Q = ...

-- Textes du confort de jeu : vols automatiques, pierre de foyer, alerte de danger, alerte
-- d'avant-poste (sacs, réparation, nourriture, boisson), XP/h. Toutes les clés commencent par COMFORT_ pour ne pas entrer en collision avec
-- les textes des autres modules.
Q:RegisterStrings({
  enUS = {
    -- Options (journal, onglet Options)
    COMFORT_OPT_TITLE = "Comfort",
    COMFORT_OPT_AUTOFLY = "Take the step's flight at the flight master (hold Shift to choose yourself)",
    COMFORT_OPT_HEARTH = "Hearthstone cooldown and walking or flying hint on hearth steps",
    COMFORT_OPT_DANGER = "Warn about elites and monsters 3+ levels above you",
    COMFORT_OPT_SUPPLIES = "Before heading out: warn about full bags, repairs, food and drink",
    COMFORT_OPT_XPRATE = "XP per hour and time to level in the tracker",

    -- Nombres et durées
    COMFORT_DECIMAL = ".",
    COMFORT_THOUSANDS = "%sk",
    COMFORT_MINUTES = "%d min",
    COMFORT_HOURS = "%d h %02d",
    COMFORT_LESS_MINUTE = "< 1 min",

    -- XP/h (en-tête du suivi)
    COMFORT_XP_RATE = "%s XP/h",
    COMFORT_XP_RATE_LEVEL = "%s XP/h · level in %s",
    COMFORT_CHAPTER_XP = "~%s XP left",

    -- Pierre de foyer
    COMFORT_HEARTH_READY = "Hearthstone ready",
    COMFORT_HEARTH_WAIT = "Hearthstone in %s",
    COMFORT_HEARTH_WALK = "On foot: about %s (%s)",
    COMFORT_HEARTH_FLY = "Faster: fly to %s",
    COMFORT_HEARTH_BIND = "Current home: %s",

    -- Vols automatiques
    COMFORT_TAXI_FLYING = "Flying to %s (hold Shift at the flight master to choose yourself).",
    COMFORT_TAXI_UNREACHABLE = "%s cannot be reached from this flight master yet.",
    COMFORT_TAXI_NOT_FOUND = "No flight path found for %s: pick it on the map.",

    -- Danger
    COMFORT_DANGER_ELITE = "Elite nearby: %s (level %s)",
    COMFORT_DANGER_HIGH = "Dangerous: %s (level %s)",
    COMFORT_DANGER_UNKNOWN = "a monster",
    COMFORT_DANGER_CHAT_ELITE = "Careful: %s, elite level %s, is nearby.",
    COMFORT_DANGER_RARE = "Rare nearby: %s (level %s)",
    COMFORT_DANGER_CHAT_RARE = "Rare: %s, level %s, is nearby.",

    -- Alerte d'avant-poste : lignes du suivi
    COMFORT_BAGS_FULL = "Bags almost full: %s",
    COMFORT_SLOTS_FREE = "%d of %d slots free",
    COMFORT_SLOTS_FREE_ONE = "%d of %d slots free",
    COMFORT_REPAIR = "Gear at %d%%: repair before heading out",
    COMFORT_NO_FOOD = "No food in your bags",
    COMFORT_NO_DRINK = "No drink in your bags",
    -- Alerte d'avant-poste : discussion et milieu de l'écran (problèmes regroupés)
    COMFORT_SUPPLY_ALERT = "Before you head out: %s.",
    COMFORT_LIST_SEP = ", ",
    COMFORT_PART_REPAIR = "gear at %d%%",
    COMFORT_PART_FOOD = "no food",
    COMFORT_PART_DRINK = "no drink",
  },
  frFR = {
    COMFORT_OPT_TITLE = "Confort",
    COMFORT_OPT_AUTOFLY = "Prendre le vol de l'étape chez le maître de vol (Maj pour choisir toi-même)",
    COMFORT_OPT_HEARTH = "Recharge de la pierre de foyer et trajet à pied ou en vol sur les étapes de foyer",
    COMFORT_OPT_DANGER = "Prévenir des élites et des monstres de 3 niveaux ou plus au-dessus de toi",
    COMFORT_OPT_SUPPLIES = "Avant de repartir : prévenir des sacs pleins, des réparations, de la nourriture et de la boisson",
    COMFORT_OPT_XPRATE = "XP par heure et temps avant le prochain niveau dans le suivi",

    COMFORT_DECIMAL = ",",
    COMFORT_THOUSANDS = "%sk",
    COMFORT_MINUTES = "%d min",
    COMFORT_HOURS = "%d h %02d",
    COMFORT_LESS_MINUTE = "< 1 min",

    COMFORT_XP_RATE = "%s XP/h",
    COMFORT_XP_RATE_LEVEL = "%s XP/h · niveau dans %s",
    COMFORT_CHAPTER_XP = "~%s XP restants",

    COMFORT_HEARTH_READY = "Pierre prête",
    COMFORT_HEARTH_WAIT = "Pierre dans %s",
    COMFORT_HEARTH_WALK = "À pied : environ %s (%s)",
    COMFORT_HEARTH_FLY = "Plus rapide : vol vers %s",
    COMFORT_HEARTH_BIND = "Foyer actuel : %s",

    COMFORT_TAXI_FLYING = "Vol vers %s (Maj chez le maître de vol pour choisir toi-même).",
    COMFORT_TAXI_UNREACHABLE = "%s n'est pas encore accessible depuis ce maître de vol.",
    COMFORT_TAXI_NOT_FOUND = "Aucun point de vol trouvé pour %s : choisis-le sur la carte.",

    COMFORT_DANGER_ELITE = "Élite proche : %s (niveau %s)",
    COMFORT_DANGER_HIGH = "Dangereux : %s (niveau %s)",
    COMFORT_DANGER_UNKNOWN = "un monstre",
    COMFORT_DANGER_CHAT_ELITE = "Attention : %s, élite niveau %s, est tout près.",
    COMFORT_DANGER_RARE = "Rare proche : %s (niveau %s)",
    COMFORT_DANGER_CHAT_RARE = "Rare : %s, niveau %s, est tout près.",

    COMFORT_BAGS_FULL = "Sacs presque pleins : %s",
    COMFORT_SLOTS_FREE = "%d places libres sur %d",
    COMFORT_SLOTS_FREE_ONE = "%d place libre sur %d",
    COMFORT_REPAIR = "Équipement à %d %% : répare avant de repartir",
    COMFORT_NO_FOOD = "Pas de nourriture dans les sacs",
    COMFORT_NO_DRINK = "Pas de boisson dans les sacs",
    COMFORT_SUPPLY_ALERT = "Avant de repartir : %s.",
    COMFORT_LIST_SEP = ", ",
    COMFORT_PART_REPAIR = "équipement à %d %%",
    COMFORT_PART_FOOD = "pas de nourriture",
    COMFORT_PART_DRINK = "pas de boisson",
  },
})
