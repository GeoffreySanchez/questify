local addonName, Q = ...

-- Textes du bouton de la minicarte (UI/MinimapButton.lua) et de la fenêtre « spécialisation et
-- profil de butin » (Automation/SpecRole.lua). Les clés commencent par MINIMAP_ ou SPECROLE_ pour
-- ne pas entrer en collision avec les textes des autres modules.
Q:RegisterStrings({
  enUS = {
    -- case à cocher de l'option minimapButton (onglet Options du journal)
    MINIMAP_OPT = "Minimap button",
    -- bulle d'aide du bouton : titre, profil de butin actuel, puis les clics
    MINIMAP_TIP_TITLE = "Questify",
    MINIMAP_TIP_ROLE = "Loot: %s",
    MINIMAP_TIP_LEFT = "Left-click: quick choices",
    MINIMAP_TIP_RIGHT = "Right-click: journal",
    MINIMAP_TIP_CTRL = "Ctrl+click: setup wizard",
    MINIMAP_TIP_DRAG = "Drag: move",
    -- menu des choix rapides (clic gauche)
    MINIMAP_MENU_TITLE = "Questify",
    MINIMAP_MENU_LOOT = "Quest reward",
    MINIMAP_MENU_AUTOQUEST = "Accept / turn in automatically",
    MINIMAP_MENU_AUTOREWARD = "Choose the reward",
    MINIMAP_MENU_ZONEMODE = "Zone mode",
    MINIMAP_MENU_MAPPINS = "Map pins",
    MINIMAP_MENU_OPTIONS = "Options…",
    MINIMAP_MENU_JOURNAL = "Journal",
    MINIMAP_MENU_WIZARD = "Setup wizard",
    MINIMAP_MENU_BUG = "Report a bug (/qf bug)",
    -- ligne de discussion après un changement de profil : nom du profil
    MINIMAP_ROLE_SET = "Quest reward profile: %s.",
    -- fenêtre de spécialisation : nom de la spécialisation, nom du profil proposé
    SPECROLE_TEXT = "You picked the %s specialization. Use the %s loot profile for quest rewards?",
    SPECROLE_YES = "Yes",
    -- profil actuel, gardé
    SPECROLE_NO = "No, keep %s",
    SPECROLE_KEPT = "Quest reward profile kept: %s. You can change it from the minimap button.",
  },
  frFR = {
    MINIMAP_OPT = "Bouton de la minicarte",
    MINIMAP_TIP_TITLE = "Questify",
    MINIMAP_TIP_ROLE = "Butin : %s",
    MINIMAP_TIP_LEFT = "Clic gauche : choix rapides",
    MINIMAP_TIP_RIGHT = "Clic droit : journal",
    MINIMAP_TIP_CTRL = "Ctrl+clic : assistant de démarrage",
    MINIMAP_TIP_DRAG = "Glisser : déplacer",
    MINIMAP_MENU_TITLE = "Questify",
    MINIMAP_MENU_LOOT = "Butin de quête",
    MINIMAP_MENU_AUTOQUEST = "Accepter / rendre automatiquement",
    MINIMAP_MENU_AUTOREWARD = "Choisir la récompense",
    MINIMAP_MENU_ZONEMODE = "Mode zone",
    MINIMAP_MENU_MAPPINS = "Épingles sur la carte",
    MINIMAP_MENU_OPTIONS = "Options…",
    MINIMAP_MENU_JOURNAL = "Journal",
    MINIMAP_MENU_WIZARD = "Assistant de démarrage",
    MINIMAP_MENU_BUG = "Signaler un bug (/qf bug)",
    MINIMAP_ROLE_SET = "Profil de butin de quête : %s.",
    SPECROLE_TEXT = "Tu as choisi la spécialisation %s. Utiliser le profil de butin %s pour les récompenses ?",
    SPECROLE_YES = "Oui",
    SPECROLE_NO = "Non, garder %s",
    SPECROLE_KEPT = "Profil de butin gardé : %s. Il se change par le bouton de la minicarte.",
  },
})
