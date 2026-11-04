local addonName, Q = ...

-- Commandes /questify et /qf, et bouton du compartiment d'addons.
--   /qf            ouvre ou ferme le journal
--   /qf skip       passe l'étape courante
--   /qf back       rouvre l'étape précédente
--   /qf options    journal, onglet Options
--   /qf wizard     assistant de navigation
--   /qf export     mesures de temps, prêtes à copier
--   /qf debug      messages de débogage (QuestifyVanillaDB.debug)
--   /qf check      autodiagnostic du client (API, QuestieDB, navigation, route) ; alias /qf diag
--   /qf bug        rapport de bug prêt à copier (alias /qf report) ; /qf bug clear vide les erreurs gardées
--   /qf talents    relevé des arbres de talents du client
--   /qf theme <clé>     thème du suivi (parchment, dark, transparent, gradient) ; seul : la liste
--   /qf opacity <0-100> opacité du fond et de la bordure du suivi ; seul : la valeur actuelle
--   /qf reset      efface la progression du personnage (après confirmation)
local L = Q.L

local RESET_DIALOG = "QUESTIFYVANILLA_RESET"

-- Efface Q.char (même table : c'est la SavedVariable), remet les valeurs par défaut et
-- relance le choix du chapitre.
local function resetCharacter()
  local c = Q.char
  if type(c) ~= "table" then return end
  for k in pairs(c) do c[k] = nil end
  Q.Util.CopyDefaults(c, Q.charDefaults)
  c.wizardDone = nil
  if Q.Progress.Invalidate then Q.Progress.Invalidate() end
  -- ResetGuide (flux A) efface aussi les validations de position gardées pour la session.
  if Q.Progress.ResetGuide then
    for _, g in ipairs(Q.Guides:All()) do Q.Progress:ResetGuide(g.id) end
  end
  local P = Q.Player or {}
  local g = Q.Progress:IsEnabled() and Q.Guides:ForPlayer(P.faction, P.raceKey, P.level)
  if g then
    Q.Progress:SetGuide(g.id)
  else
    Q.Progress:Update()
  end
  Q:Fire("CLASSQUESTS_CHANGED")
  Q:Print(L.UI_RESET_DONE)
end

if StaticPopupDialogs then
  StaticPopupDialogs[RESET_DIALOG] = {
    text = L.UI_RESET_CONFIRM,
    button1 = YES or L.UI_BTN_YES,
    button2 = NO or L.UI_BTN_NO,
    OnAccept = function() Q.SafeCall(resetCharacter) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    preferredIndex = 3,
  }
end

local function journal() return Q.UI and Q.UI.Journal end

local COMMANDS = {}

COMMANDS[""] = function()
  local J = journal()
  if J then J:Toggle() end
end

COMMANDS.skip = function()
  local cur = Q.Progress:Current()
  if cur then Q.Progress:Skip(cur.key) else Q:Print(L.UI_SLASH_NO_STEP) end
end

COMMANDS.back = function()
  if not Q.Progress:Back() then Q:Print(L.UI_SLASH_NO_BACK) end
end

COMMANDS.options = function()
  local J = journal()
  if J then J:ShowTab("options") end
end
COMMANDS.config = COMMANDS.options

COMMANDS.wizard = function()
  if Q.UI and Q.UI.Wizard then Q.UI.Wizard:Show() end
end

COMMANDS.export = function()
  local J = journal()
  if J then
    J:ShowExport()
    Q:Print(L.UI_SLASH_EXPORTED)
  end
end

COMMANDS.debug = function()
  QuestifyVanillaDB = QuestifyVanillaDB or {}
  QuestifyVanillaDB.debug = not QuestifyVanillaDB.debug
  Q:Print(QuestifyVanillaDB.debug and L.UI_SLASH_DEBUG_ON or L.UI_SLASH_DEBUG_OFF)
end

-- Relevé des arbres de talents Forever (C_ClassTalents / C_Traits : nœuds, positions, rangs max,
-- sorts, monnaie) dans QuestifyVanillaDB.talentDump[<jeu>][<classe>] : sert à écrire et vérifier
-- les presets. Échec (API absente, pas de configuration) : Dump affiche lui-même la raison.
COMMANDS.talents = function()
  local n = Q.Talents and Q.Talents:Dump() or 0
  if n > 0 then Q:Print(L.UI_SLASH_TALENTS_DUMPED, n) end
end

-- Réglages rapides du suivi (UI/Themes.lua), en attendant la fenêtre d'options.
local function themeList()
  local parts = {}
  for _, th in ipairs(Q.Themes:List()) do parts[#parts + 1] = th.key .. " (" .. th.label .. ")" end
  return table.concat(parts, ", ")
end

COMMANDS.theme = function(rest)
  local T = Q.Themes
  if not T then return end
  if rest == "" then
    Q:Print(L.UI_SLASH_THEME_LIST, themeList(), L[T:Current().label])
    return
  end
  local key = T:Find(rest)
  if not key then
    Q:Print(L.UI_SLASH_THEME_UNKNOWN, rest, themeList())
    return
  end
  Q.Settings:Set("tracker.theme", key)
  Q:Print(L.UI_SLASH_THEME_SET, L[T:Get(key).label])
end

COMMANDS.opacity = function(rest)
  local T = Q.Themes
  if not T then return end
  local n = tonumber((rest:gsub("%%", "")))
  if not n then
    Q:Print(L.UI_SLASH_OPACITY_HELP, math.floor(T:Opacity(Q.Settings:Get("tracker.opacity")) * 100 + 0.5))
    return
  end
  n = math.max(0, math.min(100, math.floor(n + 0.5)))
  Q.Settings:Set("tracker.opacity", n / 100)
  Q:Print(L.UI_SLASH_OPACITY_SET, n)
end

COMMANDS.check = function()
  Q.Diagnostics:PrintChecks()
end
COMMANDS.diag = COMMANDS.check

COMMANDS.bug = function(rest)
  if rest == "clear" then
    Q:ClearErrors()
    Q:Print(L.REPORT_CLEARED)
    return
  end
  if Q.UI and Q.UI.Report then Q.UI.Report:Show() end
end
COMMANDS.report = COMMANDS.bug

COMMANDS.reset = function()
  if StaticPopup_Show then StaticPopup_Show(RESET_DIALOG) end
end

COMMANDS.help = function()
  Q:Print(L.UI_SLASH_HELP)
end

local function handle(msg)
  local cmd, rest = tostring(msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd, rest = (cmd or ""):lower(), (rest or ""):lower()
  local fn = COMMANDS[cmd] or COMMANDS.help
  fn(rest)
end

SLASH_QUESTIFYVANILLA1 = "/questify"
SLASH_QUESTIFYVANILLA2 = "/qf"
-- Seule une clé est ajoutée : réaffecter la globale SlashCmdList la contaminerait (taint).
SlashCmdList.QUESTIFYVANILLA = function(msg) Q.SafeCall(handle, msg) end

-- Bouton du compartiment d'addons (## AddonCompartmentFunc dans le TOC).
function QuestifyVanilla_OnAddonCompartmentClick()
  Q.SafeCall(function()
    local J = journal()
    if J then J:Toggle() end
  end)
end
