local addonName, Q = ...

-- Schéma des options (fenêtre UI/Options.lua, profils Core/Profiles.lua) : liste déclarative de
-- toutes les options visibles par le joueur, rangées par section puis par catégorie.
-- Chaque entrée :
--   id, section, category ;
--   type : "toggle" (case à cocher), "select" (choix), "slider" (curseur), "action" (bouton),
--          "keybind" (raccourci du jeu, en lecture), "info" (texte), "hidden" (valeur de profil
--          sans contrôle, par exemple la position du suivi) ;
--   label, tip : clés de Q.L (texte du contrôle, infobulle de l'icône « i ») ;
--   keywords : mots de recherche en plus (français et anglais, jamais traduits) ;
--   path : chemin de Q.Settings (lu et écrit par Q.Settings:Get/Set, donc enregistré dans le
--          profil actif) ; sinon get() / set(value) (profil de butin, profils…) ;
--   select : choices = { { value, label } } ou fonction(player) -> { { value, text, disabled } } ;
--            values = liste des valeurs admises à l'import (fonction possible) ; style = "radio",
--            "dropdown" ou "themes" ;
--   slider : min, max, step, integer (arrondi à l'unité), format(value) -> texte ;
--   action : run(owner), panel = "export" | "import" (zone de texte sous le bouton), input (zone
--            de saisie avant le bouton) ;
--   keybind : binding (nom de l'action dans Bindings.xml) ;
--   visible(player) : faux pour cacher l'entrée (options propres à certaines classes) ;
--   enabled(player) : faux pour griser le contrôle (addon facultatif absent…).
-- Toute valeur par défaut de Settings.defaults doit avoir une entrée avec ce chemin : un test
-- compare les deux listes. Les champs de Q.charDefaults sont soit une option du schéma, soit
-- l'état de progression du personnage (Schema.CHAR_STATE), gardé hors des profils.
local Schema = {}
Q.OptionsSchema = Schema

---------------------------------------------------------------------------
-- Sections (ordre de la barre latérale) et catégories (ordre dans la section)
---------------------------------------------------------------------------
Schema.SECTIONS = {
  { id = "route", label = "OPT_SEC_ROUTE", categories = {
    { id = "path", label = "OPT_CAT_ROUTE_PATH" },
    { id = "progress", label = "OPT_CAT_ROUTE_PROGRESS" } } },
  { id = "navigation", label = "OPT_SEC_NAV", categories = {
    { id = "routing", label = "OPT_CAT_NAV_ROUTING" },
    { id = "display", label = "OPT_CAT_NAV_DISPLAY" },
    { id = "flights", label = "OPT_CAT_NAV_FLIGHTS" } } },
  { id = "automation", label = "OPT_SEC_AUTO", categories = {
    { id = "quests", label = "OPT_CAT_AUTO_QUESTS" },
    { id = "merchants", label = "OPT_CAT_AUTO_MERCHANTS" },
    { id = "targeting", label = "OPT_CAT_AUTO_TARGETING" } } },
  { id = "loot", label = "OPT_SEC_LOOT", categories = {
    { id = "auto", label = "OPT_CAT_LOOT_AUTO" },
    { id = "profile", label = "OPT_CAT_LOOT_PROFILE" } } },
  { id = "class", label = "OPT_SEC_CLASS", categories = {
    { id = "spells", label = "OPT_CAT_CLASS_SPELLS" },
    { id = "professions", label = "OPT_CAT_CLASS_PROFESSIONS" },
    { id = "dungeons", label = "OPT_CAT_CLASS_DUNGEONS" } } },
  { id = "map", label = "OPT_SEC_MAP", categories = {
    { id = "worldmap", label = "OPT_CAT_MAP_WORLD" },
    { id = "markers", label = "OPT_CAT_MAP_MARKERS" },
    { id = "minimap", label = "OPT_CAT_MAP_MINIMAP" } } },
  { id = "tracker", label = "OPT_SEC_TRACKER", categories = {
    { id = "layout", label = "OPT_CAT_TRACKER_LAYOUT" },
    { id = "content", label = "OPT_CAT_TRACKER_CONTENT" } } },
  { id = "theme", label = "OPT_SEC_THEME", categories = {
    { id = "theme", label = "OPT_CAT_THEME_THEME" },
    { id = "background", label = "OPT_CAT_THEME_BACKGROUND" } } },
  { id = "comfort", label = "OPT_SEC_COMFORT", categories = {
    { id = "hearth", label = "OPT_CAT_COMFORT_HEARTH" },
    { id = "warnings", label = "OPT_CAT_COMFORT_WARNINGS" } } },
  { id = "tools", label = "OPT_SEC_TOOLS", categories = {
    { id = "wizards", label = "OPT_CAT_TOOLS_WIZARDS" },
    { id = "measures", label = "OPT_CAT_TOOLS_MEASURES" },
    { id = "diagnostics", label = "OPT_CAT_TOOLS_DIAG" },
    { id = "versions", label = "OPT_CAT_TOOLS_VERSIONS" } } },
  { id = "profiles", label = "OPT_SEC_PROFILES", categories = {
    { id = "active", label = "OPT_CAT_PROFILES_ACTIVE" },
    { id = "manage", label = "OPT_CAT_PROFILES_MANAGE" },
    { id = "share", label = "OPT_CAT_PROFILES_SHARE" } } },
}

-- État de progression du personnage (QuestifyCharDB) : jamais dans un profil. Le profil de butin
-- (Q.char.rewardRole, entrée « rewardRole ») est lui aussi propre au personnage : son entrée n'a pas
-- de chemin de réglage, il n'est donc ni exporté ni changé par un changement de profil.
Schema.CHAR_STATE = {
  guideId = true, manual = true, skipped = true, inserted = true, classQuests = true, telemetry = true,
  wizardDone = true, specRoleAnswered = true,
}

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function L() return Q.L end
local function classOf(player)
  return (player and player.classFile) or (Q.Player and Q.Player.classFile)
end
local function hasRoleChoice(player)
  return Q.Rewards ~= nil and Q.Rewards:HasChoice(classOf(player))
end
local function ui(name) return Q.UI and Q.UI[name] end
local function percent(v) return string.format("%d %%", math.floor((tonumber(v) or 0) * 100 + 0.5)) end

-- Fournisseurs de navigation détectés (Q.Nav:Detect), sans erreur si le module manque.
local function detected()
  local ok, d = false, nil
  if Q.Nav and Q.Nav.Detect then ok, d = pcall(Q.Nav.Detect, Q.Nav) end
  return ok and type(d) == "table" and d or { native = true }
end

---------------------------------------------------------------------------
-- Actions (appelées par la fenêtre ; chacune protégée par Q.SafeCall côté fenêtre)
---------------------------------------------------------------------------
local Actions = {}
Schema.Actions = Actions

-- Réinitialise les étapes cochées ou passées du chapitre courant (Q.Progress:ResetGuide).
function Actions.ResetChapter()
  local guide = Q.Progress and Q.Progress:Guide()
  if not (guide and Q.char) then return end
  if Q.Progress.ResetGuide then
    Q.Progress:ResetGuide(guide.id)
  else
    local prefix = "g:" .. guide.id .. ":"
    for _, t in ipairs({ Q.char.manual or {}, Q.char.skipped or {} }) do
      local keys = {}
      for k in pairs(t) do
        if type(k) == "string" and k:sub(1, #prefix) == prefix then keys[#keys + 1] = k end
      end
      for _, k in ipairs(keys) do t[k] = nil end
    end
    if Q.Progress.Invalidate then Q.Progress.Invalidate() end
    Q.Progress:Update()
  end
  Q:Print(L().UI_OPT_RESET_DONE, guide.title or guide.id)
end

-- Texte des mesures de temps (Q.Telemetry:Export), ou un message si le module manque.
function Actions.TelemetryText()
  local tm = Q.Telemetry
  if tm and tm.Export then
    local ok, s = pcall(tm.Export, tm)
    if ok and type(s) == "string" then return s end
    if not ok then Q:ReportError(s) end
  end
  return L().UI_TELEMETRY_UNAVAILABLE
end

---------------------------------------------------------------------------
-- Entrées
---------------------------------------------------------------------------
local E = {}
Schema.entries = E
local function add(e) E[#E + 1] = e; return e end

-- Route -------------------------------------------------------------------
add({ id = "zoneMode", section = "route", category = "path", type = "toggle", path = "zoneMode",
  label = "ZONE_OPT", tip = "OPT_TIP_ZONEMODE",
  keywords = "zone mode regrouper grouper objectifs proches visite nearby objectives group" })
add({ id = "openJournal", section = "route", category = "path", type = "action",
  label = "OPT_OPEN_JOURNAL", tip = "OPT_TIP_OPEN_JOURNAL",
  keywords = "journal chapitre chapitres etapes chapter chapters steps liste",
  run = function()
    local J = ui("Journal")
    if J then J:ShowTab("route") end
  end })
add({ id = "resetChapter", section = "route", category = "progress", type = "action",
  label = "UI_OPT_RESET_CHAPTER", tip = "OPT_TIP_RESET_CHAPTER",
  keywords = "reinitialiser remettre zero progression chapitre reset progress chapter",
  run = function() Actions.ResetChapter() end })
add({ id = "routeClicks", section = "route", category = "progress", type = "info",
  label = "OPT_INFO_ROUTE_CLICKS", keywords = "passer etape revenir skip back clic droit right click" })

-- Navigation --------------------------------------------------------------
add({ id = "nav.routing", section = "navigation", category = "routing", type = "toggle", path = "nav.routing",
  label = "OPT_NAV_ROUTING", tip = "OPT_TIP_NAV_ROUTING",
  keywords = "itineraire trajet shortestpath chemin vols bateaux portails route planning path",
  enabled = function() return detected().shortestpath == true end,
  disabledText = "OPT_NOT_INSTALLED" })
add({ id = "nav.display", section = "navigation", category = "display", type = "select", path = "nav.display",
  label = "OPT_NAV_DISPLAY", tip = "OPT_TIP_NAV_DISPLAY", style = "radio",
  keywords = "repere marqueur fleche tomtom waypointui waypoint arrow marker fleche navigation",
  values = { "native", "tomtom", "waypointui" },
  choices = function()
    local d = detected()
    local Lx = L()
    return {
      { value = "native", text = Lx.UI_NAV_NATIVE },
      { value = "tomtom", text = Lx.UI_NAV_TOMTOM, disabled = not d.tomtom },
      { value = "waypointui", text = Lx.UI_NAV_WAYPOINTUI, disabled = not d.waypointui },
    }
  end })
add({ id = "autoFly", section = "navigation", category = "flights", type = "toggle", path = "autoFly",
  label = "COMFORT_OPT_AUTOFLY", tip = "OPT_TIP_AUTOFLY",
  keywords = "vol vols maitre de vol taxi griffon flight flights flight master" })

-- Automatisation ----------------------------------------------------------
add({ id = "autoQuest", section = "automation", category = "quests", type = "toggle", path = "autoQuest",
  label = "UI_OPT_AUTOQUEST", tip = "OPT_TIP_AUTOQUEST",
  keywords = "accepter rendre quetes automatique accept turn in quests auto" })
add({ id = "sellJunk", section = "automation", category = "merchants", type = "toggle", path = "sellJunk",
  label = "UI_OPT_SELLJUNK", tip = "OPT_TIP_SELLJUNK",
  keywords = "vendre camelote gris marchand sell junk grey gray vendor merchant" })
add({ id = "tracker.autoTarget", section = "automation", category = "targeting", type = "toggle",
  path = "tracker.autoTarget", label = "UI_OPT_AUTOTARGET", tip = "OPT_TIP_AUTOTARGET",
  keywords = "cibler ciblage touche crane monstre target targeting key skull monster" })
add({ id = "keyAutoTarget", section = "automation", category = "targeting", type = "keybind",
  binding = "CLICK QuestifyAutoTarget:LeftButton", label = "OPT_KEY_AUTOTARGET", tip = "OPT_TIP_KEY_AUTOTARGET",
  keywords = "raccourci touche clavier ciblage keybind binding key shortcut target" })

-- Butin -------------------------------------------------------------------
add({ id = "autoReward", section = "loot", category = "auto", type = "toggle", path = "autoReward",
  label = "UI_OPT_AUTOREWARD", tip = "OPT_TIP_AUTOREWARD",
  keywords = "butin loot recompense reward choisir choix automatique objet item" })
add({ id = "upgradePopup", section = "loot", category = "auto", type = "toggle", path = "upgradePopup",
  label = "UI_OPT_UPGRADE", tip = "OPT_TIP_UPGRADE",
  keywords = "butin loot amelioration equipement upgrade gear annonce popup" })
-- Propre au personnage (Q.char.rewardRole, par Q.Rewards), hors profils d'options.
add({ id = "rewardRole", section = "loot", category = "profile", type = "select", style = "dropdown",
  label = "OPT_REWARD_ROLE", tip = "OPT_TIP_REWARD_ROLE", perCharacter = true, noExport = true,
  keywords = "butin loot recompense reward profil role specialisation spec statistiques stats",
  visible = hasRoleChoice,
  choices = function(player)
    local Rw = Q.Rewards
    local out = {}
    if not Rw then return out end
    local cf = classOf(player)
    for _, role in ipairs(Rw:Roles(cf)) do out[#out + 1] = { value = role, text = Rw:RoleLabel(role, cf) } end
    return out
  end,
  get = function(player) return Q.Rewards and Q.Rewards:Role(classOf(player)) or "auto" end,
  set = function(value) if Q.Rewards then Q.Rewards:SetRole(value) end end })
add({ id = "specRolePrompt", section = "loot", category = "profile", type = "toggle", path = "specRolePrompt",
  label = "OPT_SPECROLE_PROMPT", tip = "OPT_TIP_SPECROLE_PROMPT",
  keywords = "butin loot specialisation spec proposer proposition changement profil role prompt offer",
  visible = hasRoleChoice })
add({ id = "lootSingle", section = "loot", category = "profile", type = "info", label = "OPT_INFO_LOOT_SINGLE",
  keywords = "butin loot profil role", visible = function(player) return not hasRoleChoice(player) end })

-- Classe et donjons -------------------------------------------------------
add({ id = "trainerAlert", section = "class", category = "spells", type = "toggle", path = "trainerAlert",
  label = "UI_OPT_TRAINER", tip = "OPT_TIP_TRAINER",
  keywords = "maitre de classe entraineur sorts trainer spells class" })
add({ id = "talentAlert", section = "class", category = "spells", type = "toggle", path = "talentAlert",
  label = "UI_OPT_TALENTS", tip = "OPT_TIP_TALENTS",
  keywords = "talents talent rappel build conseils reminder advice" })
add({ id = "talentBuild", section = "class", category = "spells", type = "action",
  label = "UI_OPT_TALENT_BUILD", tip = "OPT_TIP_TALENT_BUILD", keywords = "talents talent build choisir choose",
  run = function()
    local P = ui("TalentPicker")
    if P then P:Show() end
  end })
add({ id = "professions", section = "class", category = "professions", type = "action",
  label = "UI_OPT_PROFESSIONS", tip = "OPT_TIP_PROFESSIONS",
  keywords = "metiers metier minage herboristerie depecage cuisine professions profession mining herbalism",
  run = function()
    local P = ui("ProfessionPicker")
    if P then P:Show() end
  end })
add({ id = "dungeonSuggest", section = "class", category = "dungeons", type = "toggle", path = "dungeonSuggest",
  label = "DUNGEON_OPT_SUGGEST", tip = "OPT_TIP_DUNGEON_SUGGEST",
  keywords = "donjon donjons proposer alerte instance dungeon dungeons suggest" })
add({ id = "dungeonQuests", section = "class", category = "dungeons", type = "toggle", path = "dungeonQuests",
  label = "UI_OPT_DUNGEON", tip = "OPT_TIP_DUNGEON_QUESTS",
  keywords = "donjon donjons quetes instance dungeon quests route" })
add({ id = "openClassQuests", section = "class", category = "dungeons", type = "action",
  label = "OPT_OPEN_CLASS", tip = "OPT_TIP_OPEN_CLASS",
  keywords = "quetes de classe donjons journal class quests dungeons",
  run = function()
    local J = ui("Journal")
    if J then J:ShowTab("class") end
  end })

-- Carte et repères --------------------------------------------------------
add({ id = "mapPins", section = "map", category = "worldmap", type = "toggle", path = "mapPins",
  label = "MAP_OPT_PINS", tip = "OPT_TIP_MAPPINS",
  keywords = "carte monde minicarte reperes epingles map world minimap pins markers" })
add({ id = "nameplates", section = "map", category = "markers", type = "toggle", path = "nameplates",
  label = "UI_OPT_NAMEPLATES", tip = "OPT_TIP_NAMEPLATES",
  keywords = "barres de nom icone monstre objectif nameplates icon monster objective" })
add({ id = "objectGlow", section = "map", category = "markers", type = "toggle", path = "objectGlow",
  label = "UI_OPT_OBJECTGLOW", tip = "OPT_TIP_OBJECTGLOW",
  keywords = "objet lueur animation brillance object glow highlight" })
add({ id = "minimapButton", section = "map", category = "minimap", type = "toggle", path = "minimapButton",
  label = "MINIMAP_OPT", tip = "OPT_TIP_MINIMAP",
  keywords = "minicarte bouton icone minimap button icon" })

-- Suivi -------------------------------------------------------------------
add({ id = "tracker.locked", section = "tracker", category = "layout", type = "toggle", path = "tracker.locked",
  label = "UI_OPT_LOCKED", tip = "OPT_TIP_LOCKED",
  keywords = "suivi verrouiller bloquer deplacer tracker lock move position" })
add({ id = "tracker.scale", section = "tracker", category = "layout", type = "slider", path = "tracker.scale",
  label = "OPT_TRACKER_SCALE", tip = "OPT_TIP_TRACKER_SCALE", min = 0.6, max = 1.6, step = 0.05,
  format = percent, keywords = "suivi taille echelle grossir tracker size scale zoom" })
add({ id = "tracker.width", section = "tracker", category = "layout", type = "slider", path = "tracker.width",
  label = "OPT_TRACKER_WIDTH", tip = "OPT_TIP_TRACKER_WIDTH", min = 220, max = 480, step = 10, integer = true,
  format = function(v) return string.format("%d px", math.floor((tonumber(v) or 0) + 0.5)) end,
  keywords = "suivi largeur taille tracker width size" })
add({ id = "tracker.nextSteps", section = "tracker", category = "layout", type = "slider",
  path = "tracker.nextSteps", label = "OPT_TRACKER_NEXT", tip = "OPT_TIP_TRACKER_NEXT",
  min = 0, max = 10, step = 1, integer = true,
  format = function(v) return tostring(math.floor((tonumber(v) or 0) + 0.5)) end,
  keywords = "suivi etapes suivantes nombre lignes tracker next steps count lines" })
add({ id = "tracker.point", section = "tracker", category = "layout", type = "hidden", path = "tracker.point" })
add({ id = "trackerResetPosition", section = "tracker", category = "layout", type = "action",
  label = "OPT_TRACKER_RESET_POS", tip = "OPT_TIP_TRACKER_RESET_POS",
  keywords = "suivi position replacer origine deplacer tracker reset position move",
  run = function() Q.Settings:Set("tracker.point", nil) end })
add({ id = "tracker.showMobs", section = "tracker", category = "content", type = "toggle",
  path = "tracker.showMobs", label = "UI_OPT_SHOWMOBS", tip = "OPT_TIP_SHOWMOBS",
  keywords = "suivi monstres liste tuer tracker monsters mobs list kill" })
add({ id = "showXPRate", section = "tracker", category = "content", type = "toggle", path = "showXPRate",
  label = "COMFORT_OPT_XPRATE", tip = "OPT_TIP_XPRATE",
  keywords = "suivi experience xp heure niveau tracker xp per hour level rate" })
add({ id = "questItemButton", section = "tracker", category = "content", type = "toggle",
  path = "questItemButton", label = "UI_OPT_QUESTITEM", tip = "OPT_TIP_QUESTITEM",
  keywords = "objet de quete bouton utiliser quest item button use" })
add({ id = "keyQuestItem", section = "tracker", category = "content", type = "keybind",
  binding = "CLICK QuestifyQuestItem:LeftButton", label = "OPT_KEY_QUESTITEM", tip = "OPT_TIP_KEY_QUESTITEM",
  keywords = "raccourci touche clavier objet de quete keybind binding key shortcut quest item" })

-- Thème -------------------------------------------------------------------
add({ id = "tracker.theme", section = "theme", category = "theme", type = "select", style = "themes",
  path = "tracker.theme", label = "OPT_THEME", tip = "OPT_TIP_THEME",
  keywords = "theme apparence fond parchemin noir transparent fondu gris style look background parchment dark",
  values = function()
    local out = {}
    for _, th in ipairs(Q.Themes and Q.Themes:List() or {}) do out[#out + 1] = th.key end
    return out
  end,
  choices = function()
    local out = {}
    for _, th in ipairs(Q.Themes and Q.Themes:List() or {}) do out[#out + 1] = { value = th.key, text = th.label } end
    return out
  end })
add({ id = "tracker.opacity", section = "theme", category = "background", type = "slider", path = "tracker.opacity",
  label = "OPT_OPACITY", tip = "OPT_TIP_OPACITY", min = 0, max = 1, step = 0.05, format = percent,
  keywords = "theme fond transparence opacite alpha background opacity transparency" })

-- Confort -----------------------------------------------------------------
add({ id = "hearthHints", section = "comfort", category = "hearth", type = "toggle", path = "hearthHints",
  label = "COMFORT_OPT_HEARTH", tip = "OPT_TIP_HEARTH",
  keywords = "pierre de foyer foyer recharge hearthstone hearth cooldown" })
add({ id = "dangerAlert", section = "comfort", category = "warnings", type = "toggle", path = "dangerAlert",
  label = "COMFORT_OPT_DANGER", tip = "OPT_TIP_DANGER",
  keywords = "danger elite elites alerte monstres niveau warning elite level" })
add({ id = "supplyReminders", section = "comfort", category = "warnings", type = "toggle", path = "supplyReminders",
  label = "COMFORT_OPT_SUPPLIES", tip = "OPT_TIP_SUPPLIES",
  keywords = "vendre reparer sacs ville rappel sell repair bags town reminder" })

-- Outils ------------------------------------------------------------------
add({ id = "wizard", section = "tools", category = "wizards", type = "action",
  label = "MINIMAP_MENU_WIZARD", tip = "OPT_TIP_WIZARD",
  keywords = "assistant demarrage configuration wizard setup navigation",
  run = function()
    local W = ui("Wizard")
    if W then W:Show() end
  end })
add({ id = "telemetry", section = "tools", category = "measures", type = "toggle", path = "telemetry",
  label = "UI_OPT_TELEMETRY", tip = "OPT_TIP_TELEMETRY",
  keywords = "mesures temps telemetrie etape measures time telemetry step" })
add({ id = "exportTelemetry", section = "tools", category = "measures", type = "action", panel = "export",
  label = "UI_OPT_EXPORT", tip = "OPT_TIP_EXPORT_TELEMETRY",
  keywords = "exporter mesures copier export measures copy telemetry",
  text = function() return Actions.TelemetryText() end })
add({ id = "report", section = "tools", category = "diagnostics", type = "action",
  label = "REPORT_BUTTON", tip = "OPT_TIP_REPORT",
  keywords = "bug rapport erreur signaler report error",
  run = function()
    local R = ui("Report")
    if R then R:Show() end
  end })
add({ id = "selfCheck", section = "tools", category = "diagnostics", type = "action",
  label = "OPT_SELFCHECK", tip = "OPT_TIP_SELFCHECK",
  keywords = "diagnostic verification check diag autodiagnostic",
  run = function() if Q.Diagnostics then Q.Diagnostics:PrintChecks() end end })
add({ id = "versionCheck", section = "tools", category = "versions", type = "toggle", path = "versionCheck",
  label = "VERSION_OPT", tip = "OPT_TIP_VERSION",
  keywords = "version mise a jour nouvelle guilde groupe update new version" })

-- Profils -----------------------------------------------------------------
add({ id = "profile.active", section = "profiles", category = "active", type = "select", style = "dropdown",
  label = "OPT_PROFILE_ACTIVE", tip = "OPT_TIP_PROFILE_ACTIVE", noExport = true,
  keywords = "profil profils actif changer profile profiles active switch",
  choices = function()
    local out = {}
    local P = Q.Profiles
    for _, name in ipairs(P and P:List() or {}) do out[#out + 1] = { value = name, text = P:DisplayName(name) } end
    return out
  end,
  get = function() return Q.Profiles and Q.Profiles:Active() end,
  set = function(value) if Q.Profiles then Q.Profiles:SetActive(value) end end })
add({ id = "profile.mode", section = "profiles", category = "active", type = "select", style = "radio",
  label = "OPT_PROFILE_MODE", tip = "OPT_TIP_PROFILE_MODE", noExport = true,
  keywords = "profil compte personnage partage profile account character per shared",
  choices = function()
    local Lx = L()
    return { { value = "account", text = Lx.OPT_PROFILE_MODE_ACCOUNT },
      { value = "character", text = Lx.OPT_PROFILE_MODE_CHAR } }
  end,
  get = function() return Q.Profiles and Q.Profiles:Mode() end,
  set = function(value) if Q.Profiles then Q.Profiles:SetMode(value) end end })
add({ id = "profile.new", section = "profiles", category = "manage", type = "action", input = true,
  label = "OPT_PROFILE_NEW", tip = "OPT_TIP_PROFILE_NEW",
  keywords = "profil nouveau creer profile new create" })
add({ id = "profile.copy", section = "profiles", category = "manage", type = "action", pick = "copy",
  label = "OPT_PROFILE_COPY", tip = "OPT_TIP_PROFILE_COPY",
  keywords = "profil copier dupliquer profile copy duplicate" })
add({ id = "profile.delete", section = "profiles", category = "manage", type = "action", pick = "delete",
  label = "OPT_PROFILE_DELETE", tip = "OPT_TIP_PROFILE_DELETE",
  keywords = "profil supprimer effacer profile delete remove" })
add({ id = "profile.reset", section = "profiles", category = "manage", type = "action", confirm = "reset",
  label = "OPT_PROFILE_RESET", tip = "OPT_TIP_PROFILE_RESET",
  keywords = "profil reinitialiser defaut profile reset defaults" })
add({ id = "profile.export", section = "profiles", category = "share", type = "action", panel = "export",
  label = "OPT_PROFILE_EXPORT", tip = "OPT_TIP_PROFILE_EXPORT",
  keywords = "profil exporter partager chaine copier profile export share string copy",
  text = function() return Q.Profiles and Q.Profiles:Export() or "" end })
add({ id = "profile.import", section = "profiles", category = "share", type = "action", panel = "import",
  label = "OPT_PROFILE_IMPORT", tip = "OPT_TIP_PROFILE_IMPORT",
  keywords = "profil importer partager chaine coller profile import share string paste" })

---------------------------------------------------------------------------
-- Index
---------------------------------------------------------------------------
local byId, byPath, sectionIndex = {}, {}, {}
for i, s in ipairs(Schema.SECTIONS) do
  sectionIndex[s.id] = i
  s.categoryIndex = {}
  for j, c in ipairs(s.categories) do s.categoryIndex[c.id] = j end
end
for i, e in ipairs(E) do
  e.order = i
  byId[e.id] = e
  if e.path then byPath[e.path] = e end
end

function Schema:Entry(id) return byId[id] end
function Schema:EntryForPath(path) return byPath[path] end
function Schema:Section(id) return self.SECTIONS[sectionIndex[id] or 0] end
function Schema:SectionIndex(id) return sectionIndex[id] end

-- Paths() -> { [chemin] = entrée } : toutes les valeurs de réglage connues (profils, import).
function Schema:Paths()
  return byPath
end

-- Visible(entry, player) : entrée affichable pour ce personnage (et pas cachée).
function Schema:Visible(e, player)
  if e.type == "hidden" then return false end
  if e.visible then
    local ok, v = pcall(e.visible, player)
    return ok and v == true
  end
  return true
end

-- Enabled(entry, player) : contrôle utilisable (faux : grisé, par exemple addon absent).
function Schema:Enabled(e, player)
  if not e.enabled then return true end
  local ok, v = pcall(e.enabled, player)
  return ok and v == true
end

-- Choices(entry, player) -> { { value, text, disabled } }
function Schema:Choices(e, player)
  local list = e.choices
  if type(list) == "function" then
    local ok, res = pcall(list, player)
    list = ok and type(res) == "table" and res or {}
  end
  local out = {}
  for _, c in ipairs(list or {}) do
    out[#out + 1] = { value = c.value, text = c.text or (c.label and L()[c.label]) or tostring(c.value),
      disabled = c.disabled == true }
  end
  return out
end

-- Valeur courante d'une entrée (réglage, ou fonction get).
function Schema:Get(e, player)
  if e.path then return Q.Settings:Get(e.path) end
  if e.get then
    local ok, v = pcall(e.get, player)
    if ok then return v end
  end
  return nil
end

-- Nouvelle valeur : par Q.Settings:Set (les modules réagissent à SETTINGS_CHANGED) ou e.set.
-- Curseurs ramenés entre min et max et sur le pas ; choix refusé hors de la liste.
function Schema:Set(e, value, player)
  if e.type == "slider" then
    value = self:ClampSlider(e, value)
    if value == nil then return false end
  elseif e.type == "select" then
    local ok = false
    for _, c in ipairs(self:Choices(e, player)) do
      if c.value == value and not c.disabled then ok = true end
    end
    if not ok then return false end
  elseif e.type == "toggle" then
    value = value and true or false
  end
  if e.path then
    Q.Settings:Set(e.path, value)
    return true
  end
  if e.set then
    e.set(value, player)
    return true
  end
  return false
end

local function roundTo(v, decimals)
  local m = 10 ^ decimals
  return math.floor(v * m + 0.5) / m
end

-- Curseur : nombre ramené entre min et max, sur le pas (ou nil si ce n'est pas un nombre).
function Schema:ClampSlider(e, value)
  local v = tonumber(value)
  if not v or v ~= v or v == math.huge or v == -math.huge then return nil end
  v = math.max(e.min, math.min(e.max, v))
  if e.integer then return math.floor(v + 0.5) end
  return roundTo(v, 4)
end

-- Valeurs admises pour un choix (import) : e.values, sinon celles de la liste des choix.
function Schema:Values(e)
  local vals = e.values
  if type(vals) == "function" then
    local ok, res = pcall(vals)
    vals = ok and res or nil
  end
  if type(vals) ~= "table" then
    vals = {}
    for _, c in ipairs(self:Choices(e)) do vals[#vals + 1] = c.value end
  end
  return vals
end

local ANCHORS = {
  TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
  BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}
local MAX_OFFSET = 10000

-- Validate(entry, value) -> ok, valeur propre : contrôle d'une valeur importée.
-- Case : booléen ; choix : une valeur de la liste ; curseur : nombre ramené entre min et max ;
-- position du suivi : { point, point relatif, x, y }.
function Schema:Validate(e, value)
  if e.type == "toggle" then
    if type(value) == "boolean" then return true, value end
    return false
  elseif e.type == "select" then
    for _, v in ipairs(self:Values(e)) do
      if v == value then return true, value end
    end
    return false
  elseif e.type == "slider" then
    if type(value) ~= "number" then return false end
    local v = self:ClampSlider(e, value)
    if v == nil then return false end
    return true, v
  elseif e.path == "tracker.point" then
    if type(value) ~= "table" then return false end
    local p, rp, x, y = value[1], value[2], value[3], value[4]
    if not (ANCHORS[p] and ANCHORS[rp] and type(x) == "number" and type(y) == "number") then return false end
    if x ~= x or y ~= y then return false end
    for k in pairs(value) do
      if type(k) ~= "number" or k < 1 or k > 4 or k % 1 ~= 0 then return false end
    end
    x = math.max(-MAX_OFFSET, math.min(MAX_OFFSET, x))
    y = math.max(-MAX_OFFSET, math.min(MAX_OFFSET, y))
    return true, { p, rp, roundTo(x, 1), roundTo(y, 1) }
  end
  return false
end

---------------------------------------------------------------------------
-- Recherche
---------------------------------------------------------------------------
-- Lettres accentuées (UTF-8, deux octets) ramenées à leur lettre de base, en minuscule.
local FOLD = {}
local function fold(chars, base)
  for c in chars:gmatch("[\192-\223][\128-\191]") do FOLD[c] = base end
end
fold("àáâãäåÀÁÂÃÄÅ", "a")
fold("çÇ", "c")
fold("èéêëÈÉÊË", "e")
fold("ìíîïÌÍÎÏ", "i")
fold("ñÑ", "n")
fold("òóôõöøÒÓÔÕÖØ", "o")
fold("ùúûüÙÚÛÜ", "u")
fold("ýÿÝ", "y")
fold("œŒ", "oe")
fold("æÆ", "ae")
fold("ß", "ss")

-- Normalize(texte) -> minuscules sans accents ni codes de couleur, espaces simples.
function Schema.Normalize(s)
  if type(s) ~= "string" then return "" end
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
  s = s:gsub("[\192-\223][\128-\191]", function(c) return FOLD[c] end)
  s = s:lower()
  s = s:gsub("[%s%p]+", " ")
  return s
end
local normalize = Schema.Normalize

-- Texte où chercher : libellé, infobulle, mots-clés et libellés des choix.
function Schema:Haystack(e, player)
  local Lx = L()
  local parts = { e.label and Lx[e.label] or "", e.tip and Lx[e.tip] or "", e.keywords or "" }
  if e.type == "select" then
    for _, c in ipairs(self:Choices(e, player)) do parts[#parts + 1] = tostring(c.text) end
  end
  return " " .. normalize(table.concat(parts, " ")) .. " "
end

-- Search(texte, player) -> entrées visibles qui contiennent tous les mots de la recherche,
-- dans l'ordre des sections puis du schéma. Recherche vide : liste vide.
function Schema:Search(query, player)
  local words = {}
  for w in normalize(query):gmatch("%S+") do words[#words + 1] = w end
  local out = {}
  if #words == 0 then return out end
  for _, e in ipairs(E) do
    if self:Visible(e, player) then
      local hay = self:Haystack(e, player)
      local all = true
      for _, w in ipairs(words) do
        if not hay:find(w, 1, true) then all = false; break end
      end
      if all then out[#out + 1] = e end
    end
  end
  table.sort(out, function(a, b)
    local sa, sb = sectionIndex[a.section] or 99, sectionIndex[b.section] or 99
    if sa ~= sb then return sa < sb end
    return a.order < b.order
  end)
  return out
end

-- EntriesFor(sectionId, player) -> entrées visibles de la section, rangées par catégorie.
function Schema:EntriesFor(sectionId, player)
  local s = self:Section(sectionId)
  local out = {}
  if not s then return out end
  for _, e in ipairs(E) do
    if e.section == sectionId and self:Visible(e, player) then out[#out + 1] = e end
  end
  table.sort(out, function(a, b)
    local ca, cb = s.categoryIndex[a.category] or 99, s.categoryIndex[b.category] or 99
    if ca ~= cb then return ca < cb end
    return a.order < b.order
  end)
  return out
end
