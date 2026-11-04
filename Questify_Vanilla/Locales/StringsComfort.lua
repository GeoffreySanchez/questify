local addonName, Q = ...

-- Textes du confort de jeu : vols automatiques, pierre de foyer, alerte de danger, sacs et
-- réparation, XP/h. Toutes les clés commencent par COMFORT_ pour ne pas entrer en collision avec
-- les textes des autres modules.
Q:RegisterStrings({
  enUS = {
    -- Options (journal, onglet Options)
    COMFORT_OPT_TITLE = "Comfort",
    COMFORT_OPT_AUTOFLY = "Take the step's flight at the flight master (hold Shift to choose yourself)",
    COMFORT_OPT_HEARTH = "Hearthstone cooldown and walking or flying hint on hearth steps",
    COMFORT_OPT_DANGER = "Warn about elites and monsters 3+ levels above you",
    COMFORT_OPT_SUPPLIES = "Remind me to sell and repair before leaving town",
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
    COMFORT_DANGER_CHAT_HIGH = "Careful: %s, level %s, is nearby.",

    -- Sacs et réparation
    COMFORT_BAGS_FULL = "Bags almost full (%d free): sell before leaving town",
    COMFORT_REPAIR = "Gear at %d%%: repair before leaving town",
    COMFORT_BAGS_CHAT = "Your bags are almost full (%d free slot(s)): sell before you leave town.",
    COMFORT_REPAIR_CHAT = "Your gear is at %d%%: repair before you leave town.",
  },
  frFR = {
    COMFORT_OPT_TITLE = "Confort",
    COMFORT_OPT_AUTOFLY = "Prendre le vol de l'étape chez le maître de vol (Maj pour choisir toi-même)",
    COMFORT_OPT_HEARTH = "Recharge de la pierre de foyer et trajet à pied ou en vol sur les étapes de foyer",
    COMFORT_OPT_DANGER = "Prévenir des élites et des monstres de 3 niveaux ou plus au-dessus de toi",
    COMFORT_OPT_SUPPLIES = "Rappel pour vendre et réparer avant de quitter la ville",
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
    COMFORT_DANGER_CHAT_HIGH = "Attention : %s, niveau %s, est tout près.",

    COMFORT_BAGS_FULL = "Sacs presque pleins (%d libres) : vends avant de quitter la ville",
    COMFORT_REPAIR = "Équipement à %d %% : répare avant de quitter la ville",
    COMFORT_BAGS_CHAT = "Tes sacs sont presque pleins (%d place(s) libre(s)) : vends avant de quitter la ville.",
    COMFORT_REPAIR_CHAT = "Ton équipement est à %d %% : répare avant de quitter la ville.",
  },
})
