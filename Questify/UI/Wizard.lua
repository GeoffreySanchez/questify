local addonName, Q = ...

-- Assistant de premier démarrage (spec § 4 : un seul fournisseur actif), en cinq pages :
--   1. bienvenue et addons (QuestieDB, ShortestPath Forever, WaypointUI, TomTom) : état de chacun
--      (chargé, désactivé, activé mais pas encore chargé, périmé, absent, QuestieDB trop ancien),
--      lien CurseForge à copier pour les absents et pour QuestieDB trop ancien (le jeu n'ouvre pas
--      de navigateur), bouton « Activer » pour les désactivés ;
--   2. calcul d'itinéraire par ShortestPath Forever (case active seulement s'il est chargé) ;
--   3. affichage : WaypointUI, TomTom ou repère du jeu (les absents sont désactivés) ;
--   4. automatisations (accepter/rendre, choix de la récompense, vente de la camelote) ;
--   5. récapitulatif et « Terminer ».
-- Chaque page a « Précédent », « Ignorer » (remet les choix de la page à leur valeur actuelle et
-- passe à la suivante) et « Suivant » ; la dernière a « Terminer ». « Recharger l'interface » est
-- visible sur la page des addons, et sur toutes les pages après « Activer ».
-- « Terminer » enregistre tout par Q.Settings:Set, pose Q.char.wizardDone et efface wizardPage.
-- Reprise : la page courante est gardée dans Q.char.wizardPage, les choix faits mais pas encore
-- enregistrés dans Q.char.wizardDraft. Tant que l'assistant n'est pas terminé, il se rouvre sur
-- cette page 3 s après « LOGIN » (donc après /reload ou une reconnexion), jamais en combat, au
-- plus une fois par session. Fermer par la croix ne termine pas : /qf wizard reprend à la même page.
Q.UI = Q.UI or {}
local Wizard = { page = 1, pages = {}, radios = {}, checks = {}, addonRows = {}, recap = {}, enabledNames = {} }
Q.UI.Wizard = Wizard

local L = Q.L

local FRAME_NAME = "QuestifyWizard"
local WIDTH, HEIGHT = 520, 560
local INNER = WIDTH - 48
local AUTO_DELAY = 3
local ROW_H, ROW_LINK_H = 34, 60   -- ligne d'addon sans / avec le lien à copier

local PAGE_ADDONS, PAGE_ROUTING, PAGE_DISPLAY, PAGE_AUTO, PAGE_RECAP = 1, 2, 3, 4, 5
local NUM_PAGES = PAGE_RECAP
Wizard.NUM_PAGES = NUM_PAGES

-- Addons de la page 1. folders : noms de dossier possibles, le premier est celui du TOC publié
-- (QuestieDB.toc, ShortestPathForever.toc, WaypointUI.toc, TomTom.toc) ; les suivants couvrent
-- une installation renommée à la main.
local ADDONS = {
  { id = "questiedb", folders = { "QuestieDB" }, required = true,
    url = "https://www.curseforge.com/wow/addons/questiedb",
    name = "UI_WIZ_ADDON_QUESTIEDB", desc = "UI_WIZ_ADDON_QUESTIEDB_DESC" },
  { id = "shortestpath", folders = { "ShortestPathForever", "ShortestPath" },
    url = "https://www.curseforge.com/wow/addons/shortest-path-forever",
    name = "UI_NAV_SHORTESTPATH", desc = "UI_NAV_SHORTESTPATH_DESC" },
  { id = "waypointui", folders = { "WaypointUI", "Waypoint-UI" },
    url = "https://www.curseforge.com/wow/addons/waypointui",
    name = "UI_NAV_WAYPOINTUI", desc = "UI_NAV_WAYPOINTUI_DESC" },
  { id = "tomtom", folders = { "TomTom" },
    url = "https://www.curseforge.com/wow/addons/tomtom",
    name = "UI_NAV_TOMTOM", desc = "UI_NAV_TOMTOM_DESC" },
}
Wizard.ADDONS = ADDONS

local DISPLAYS = { "waypointui", "tomtom", "native" }
local PROVIDER_TEXT = {
  shortestpath = { "UI_NAV_SHORTESTPATH", "UI_NAV_SHORTESTPATH_DESC" },
  waypointui = { "UI_NAV_WAYPOINTUI", "UI_NAV_WAYPOINTUI_DESC" },
  tomtom = { "UI_NAV_TOMTOM", "UI_NAV_TOMTOM_DESC" },
  native = { "UI_NAV_NATIVE", "UI_NAV_NATIVE_DESC" },
}
local AUTOMATIONS = {
  { "autoQuest", "UI_OPT_AUTOQUEST" },
  { "autoReward", "UI_OPT_AUTOREWARD" },
  { "sellJunk", "UI_OPT_SELLJUNK" },
}
-- Choix de chaque page : « Ignorer » les remet à leur valeur de départ.
local PAGE_KEYS = {
  [PAGE_ROUTING] = { "routing" },
  [PAGE_DISPLAY] = { "display" },
  [PAGE_AUTO] = { "autoQuest", "autoReward", "sellJunk", "rewardRole" },
}

local READY = "Interface\\RaidFrame\\ReadyCheck-Ready"
local NOT_READY = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local WAITING = "Interface\\RaidFrame\\ReadyCheck-Waiting"

local STATUS = {
  loaded = { "UI_WIZ_LOADED", "|cff40ff40", READY },
  missing = { "UI_WIZ_ABSENT", "|cff999999", NOT_READY },
  disabled = { "UI_WIZ_DISABLED", "|cffff9933", WAITING },
  pending = { "UI_WIZ_PENDING", "|cffffd100", WAITING },
  outdated = { "UI_WIZ_OUTDATED", "|cffffd100", WAITING },
  old = { "UI_WIZ_QDB_OLD", "|cffff4040", WAITING },
}
-- États qui affichent le lien CurseForge : addon absent, ou QuestieDB trop ancien (mise à jour).
local SHOW_LINK = { missing = true, old = true }

local function safe(fn)
  return function(...) return Q.SafeCall(fn, ...) end
end

local function playSound(kit)
  if PlaySound and SOUNDKIT and SOUNDKIT[kit] then pcall(PlaySound, SOUNDKIT[kit]) end
end

---------------------------------------------------------------------------
-- Détection
---------------------------------------------------------------------------
-- Fournisseurs : Q.Nav:Detect() (flux C) ; à défaut, les mêmes règles sur les globales.
-- Le repère du jeu (native) est toujours disponible ; questiedb = données lisibles,
-- questiedbOld = QuestieDB chargé mais trop ancien (Q.QDB:Status() == "old").
function Wizard:Detect()
  local d
  if Q.Nav and Q.Nav.Detect then
    local ok, res = pcall(Q.Nav.Detect, Q.Nav)
    if ok and type(res) == "table" then d = res end
  end
  d = d or {
    shortestpath = type(ShortestPathForever) == "table" and ShortestPathForever.API ~= nil,
    waypointui = type(WaypointUIAPI) == "table" and WaypointUIAPI.Navigation ~= nil,
    tomtom = type(TomTom) == "table" and TomTom.AddWaypoint ~= nil,
  }
  d.native = true
  local status
  if Q.QDB and Q.QDB.Status then
    local ok, res = pcall(Q.QDB.Status, Q.QDB)
    if ok then status = res end
  end
  d.questiedb = status == "ok"
  d.questiedbOld = status == "old"
  return d
end

-- État d'un addon par C_AddOns. Chaque appel est protégé : une fonction absente ou qui refuse
-- un nom inconnu ne casse pas l'assistant.
local function addonCall(fn, ...)
  local f = C_AddOns and C_AddOns[fn]
  if type(f) ~= "function" then return false end
  return pcall(f, ...)
end

-- Installé ? DoesAddOnExist, sinon GetAddOnInfo (raison « MISSING » pour un dossier absent).
-- nil : impossible à savoir.
local function isInstalled(folder)
  local ok, exists = addonCall("DoesAddOnExist", folder)
  if ok and exists ~= nil then return exists and true or false end
  local ok2, name, title, _, _, reason = addonCall("GetAddOnInfo", folder)
  if ok2 then return (name ~= nil or title ~= nil) and reason ~= "MISSING" end
  return nil
end

local function isLoaded(folder)
  local ok, loaded = addonCall("IsAddOnLoaded", folder)
  return ok and loaded and true or false
end

-- Activé pour ce personnage ? (0 = désactivé, 1 ou 2 = activé ; booléen sur d'anciens clients)
-- nil : impossible à savoir.
local function playerName()
  local ok, name = pcall(function() return UnitName and UnitName("player") end)
  if ok and type(name) == "string" and name ~= "" then return name end
  return nil
end

local function isEnabled(folder)
  local ok, state = addonCall("GetAddOnEnableState", folder, playerName())
  if not ok then return nil end
  if type(state) == "number" then return state > 0 end
  if type(state) == "boolean" then return state end
  return nil
end

local function loadReason(folder)
  local ok, _, _, _, _, reason = addonCall("GetAddOnInfo", folder)
  if ok then return reason end
  return nil
end

-- AddonState(entry) -> "loaded" | "old" | "pending" | "outdated" | "disabled" | "missing", dossier
-- ("old" : QuestieDB chargé mais trop ancien pour Questify)
function Wizard:AddonState(entry)
  local tooOld = entry.id == "questiedb" and self.detected and self.detected.questiedbOld
  for _, folder in ipairs(entry.folders) do
    if isLoaded(folder) then return tooOld and "old" or "loaded", folder end
  end
  if tooOld then return "old", entry.folders[1] end
  if self.detected and self.detected[entry.id] then return "loaded", entry.folders[1] end
  for _, folder in ipairs(entry.folders) do
    if isInstalled(folder) then
      if isEnabled(folder) == false then return "disabled", folder end
      if loadReason(folder) == "INTERFACE_VERSION" then return "outdated", folder end
      return "pending", folder
    end
  end
  return "missing", entry.folders[1]
end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
  if ok and f then return f end
  return CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
end

local function pageTitle(page, key)
  local t = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  t:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
  t:SetWidth(INNER)
  t:SetJustifyH("LEFT")
  t:SetText(L[key])
  return t
end

local function paragraph(page, text, anchor, gap, font)
  local p = page:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
  p:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -(gap or 8))
  p:SetWidth(INNER)
  p:SetJustifyH("LEFT")
  p:SetWordWrap(true)
  p:SetText(text)
  return p
end

local widgetSeq = 0
local function newButton(kind, parent, template)
  widgetSeq = widgetSeq + 1
  return CreateFrame(kind, FRAME_NAME .. "Widget" .. widgetSeq, parent, template)
end

local function labelFor(widget, text, font)
  local fs = widget:GetParent():CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
  fs:SetPoint("LEFT", widget, "RIGHT", 4, 1)
  fs:SetWidth(INNER - 40)
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  return fs
end

-- Champ en lecture seule qui contient un lien : sélectionné à la prise du focus pour Ctrl+C,
-- toute frappe remet le lien.
local function linkBox(parent, url)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(INNER - 34, 20)
  box:SetAutoFocus(false)
  box.url = url
  box:SetText(url)
  box:SetCursorPosition(0)
  box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
  box:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  box:SetScript("OnTextChanged", function(self, userInput)
    if userInput then
      self:SetText(self.url)
      self:HighlightText()
    end
  end)
  return box
end

function Wizard:BuildAddonsPage(page)
  local title = pageTitle(page, "UI_WIZ_WELCOME_TITLE")
  local intro = paragraph(page, L.UI_WIZ_WELCOME_TEXT, title, 8)
  local heading = paragraph(page, L.UI_WIZ_ADDONS_HEADING, intro, 12, "GameFontNormal")
  local anchor = heading
  for _, entry in ipairs(ADDONS) do
    local row = CreateFrame("Frame", nil, page)
    row:SetSize(INNER, ROW_H)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
    row.entry = entry
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    local name = L[entry.name]
    if entry.required then name = name .. " |cffff8040(" .. L.UI_WIZ_REQUIRED .. ")|r" end
    row.name:SetText(name)
    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.status:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
    row.desc = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.desc:SetPoint("TOPLEFT", row, "TOPLEFT", 22, -19)
    row.desc:SetWidth(INNER - 22)
    row.desc:SetJustifyH("LEFT")
    row.desc:SetText(L[entry.desc])
    row.enable = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.enable:SetSize(90, 20)
    row.enable:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 2)
    row.enable:SetText(L.UI_WIZ_ENABLE)
    row.enable:SetScript("OnClick", safe(function() Wizard:EnableAddon(entry.id) end))
    row.enable:Hide()
    row.link = linkBox(row, entry.url)
    row.link:SetPoint("TOPLEFT", row, "TOPLEFT", 28, -34)
    row.link:Hide()
    self.addonRows[entry.id] = row
    anchor = row
  end
  self.linkHint = paragraph(page, L.UI_WIZ_LINK_HINT, anchor, 6, "GameFontNormalSmall")
  self.restartNote = paragraph(page, L.UI_WIZ_RESTART_NOTE, self.linkHint, 6, "GameFontDisableSmall")
  self.reloadText = paragraph(page, "", self.restartNote, 6, "GameFontGreenSmall")
  self.reloadText:Hide()
end

function Wizard:BuildRoutingPage(page)
  local title = pageTitle(page, "UI_WIZ_P2_TITLE")
  local text = paragraph(page, L.UI_WIZ_P2_TEXT, title, 10)
  local cb = newButton("CheckButton", page, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  cb:SetPoint("TOPLEFT", text, "BOTTOMLEFT", -4, -14)
  cb.label = labelFor(cb, L.UI_WIZ_ROUTING)
  cb:SetScript("OnClick", safe(function(self)
    if not self:IsEnabled() then return end
    Wizard:SetChoice("routing", self:GetChecked() and true or false)
  end))
  self.checks.routing = cb
  local missing = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  missing:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 30, -2)
  missing:SetWidth(INNER - 30)
  missing:SetJustifyH("LEFT")
  missing:SetText(L.UI_WIZ_ROUTING_MISSING)
  self.routingMissing = missing
end

function Wizard:BuildDisplayPage(page)
  local title = pageTitle(page, "UI_WIZ_DISPLAY_TITLE")
  local anchor = paragraph(page, L.UI_WIZ_P3_TEXT, title, 10)
  local gap = 14
  for _, id in ipairs(DISPLAYS) do
    local r = newButton("CheckButton", page, "UIRadioButtonTemplate")
    r:SetSize(16, 16)
    r:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
    r.id = id
    r.label = labelFor(r, L[PROVIDER_TEXT[id][1]])
    r.desc = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    r.desc:SetPoint("TOPLEFT", r, "BOTTOMLEFT", 20, -2)
    r.desc:SetWidth(INNER - 20)
    r.desc:SetJustifyH("LEFT")
    r.desc:SetText(L[PROVIDER_TEXT[id][2]])
    r:SetScript("OnClick", safe(function(self)
      if not self:IsEnabled() then return end
      playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
      Wizard:SelectDisplay(self.id)
      Wizard:SetChoice("display", Wizard.choice.display)
    end))
    self.radios[id] = r
    anchor = r.desc
    gap = 12
  end
end

function Wizard:BuildAutoPage(page)
  local title = pageTitle(page, "UI_WIZ_AUTO_TITLE")
  local anchor = paragraph(page, L.UI_WIZ_P4_TEXT, title, 10)
  local x = -4   -- la première case s'aligne sur le texte, les suivantes sur la case précédente
  for _, def in ipairs(AUTOMATIONS) do
    local cb = newButton("CheckButton", page, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, -10)
    x = 0
    cb.label = labelFor(cb, L[def[2]])
    cb.path = def[1]
    cb:SetScript("OnClick", safe(function(self)
      Wizard:SetChoice(self.path, self:GetChecked() and true or false)
    end))
    self.checks[def[1]] = cb
    anchor = cb
  end
  -- profil de récompense, sous les cases ; masqué pour une classe sans vrai choix
  local b = newButton("Button", page, "UIPanelButtonTemplate")
  b:SetSize(260, 22)
  local reward = self.checks.autoReward
  b:SetPoint("TOPLEFT", reward, "BOTTOMLEFT", 30, -4)
  -- la case suivante passe sous le bouton
  local after = self.checks.sellJunk
  if after then
    after:ClearAllPoints()
    after:SetPoint("TOPLEFT", b, "BOTTOMLEFT", -30, -6)
  end
  b:SetScript("OnClick", safe(function()
    local Rw = Q.Rewards
    if not (Rw and Wizard.choice) then return end
    Wizard:SetChoice("rewardRole", Rw:NextRole(Wizard.choice.rewardRole))
    Wizard:Refresh()
  end))
  self.rewardRoleButton = b
end

function Wizard:BuildRecapPage(page)
  local title = pageTitle(page, "UI_WIZ_RECAP_TITLE")
  local anchor = paragraph(page, L.UI_WIZ_RECAP_TEXT, title, 10)
  local gap = 14
  for _, key in ipairs({ "routing", "display", "autoQuest", "autoReward", "sellJunk" }) do
    local line = paragraph(page, "", anchor, gap)
    self.recap[key] = line
    anchor = line
    gap = 6
  end
  paragraph(page, L.UI_WIZ_RECAP_AFTER, anchor, 16, "GameFontDisableSmall")
end

function Wizard:Create()
  if self.frame then return self.frame end
  local f = newFrame()
  self.frame = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  if f.SetTitle then f:SetTitle(L.UI_WIZ_TITLE) end
  if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, "Interface\\Icons\\INV_Misc_Map_01") end
  if UISpecialFrames then tinsert(UISpecialFrames, FRAME_NAME) end

  local content = CreateFrame("Frame", nil, f)
  content:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -70)
  content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 58)
  for i = 1, NUM_PAGES do
    local page = CreateFrame("Frame", nil, content)
    page:SetAllPoints(content)
    page:Hide()
    self.pages[i] = page
  end
  self:BuildAddonsPage(self.pages[PAGE_ADDONS])
  self:BuildRoutingPage(self.pages[PAGE_ROUTING])
  self:BuildDisplayPage(self.pages[PAGE_DISPLAY])
  self:BuildAutoPage(self.pages[PAGE_AUTO])
  self:BuildRecapPage(self.pages[PAGE_RECAP])

  local step = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  step:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -34)
  self.stepText = step

  local function bottomButton(label, width, onClick)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(label)
    b:SetScript("OnClick", safe(onClick))
    return b
  end
  self.prevButton = bottomButton(L.UI_WIZ_PREV, 110, function() Wizard:Prev() end)
  self.prevButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 4)
  self.nextButton = bottomButton(L.UI_WIZ_NEXT, 110, function() Wizard:Next() end)
  self.nextButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)
  self.finishButton = bottomButton(L.UI_WIZ_FINISH, 110, function() Wizard:Finish() end)
  self.finishButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)
  self.skipButton = bottomButton(L.UI_WIZ_SKIP, 110, function() Wizard:Skip() end)
  self.skipButton:SetPoint("RIGHT", self.nextButton, "LEFT", -6, 0)
  self.reloadButton = bottomButton(L.UI_WIZ_RELOAD, 190, function() Wizard:Reload() end)
  self.reloadButton:SetPoint("BOTTOM", f, "BOTTOM", 0, 30)

  f:Hide()
  -- Branché après le Hide() initial. Fermer sans terminer garde la page (/qf wizard y reprend)
  -- et ne vaut pas refus : l'assistant se rouvrira à la prochaine session, pas dans celle-ci.
  -- Fermé ou terminé, il laisse place au choix des métiers (une fois par session, voir
  -- UI/ProfessionPicker.lua). Un parent caché (Alt+Z) ne compte pas.
  f:HookScript("OnHide", function(self)
    if self:IsShown() then return end
    Wizard.dismissed = true
    if Q.UI.ProfessionPicker then Q:After(0.5, Q.UI.ProfessionPicker.AutoShow) end
  end)
  return f
end

---------------------------------------------------------------------------
-- État et pages
---------------------------------------------------------------------------
local function setEnabled(widget, enabled, label)
  if enabled then widget:Enable() else widget:Disable() end
  if label then
    if enabled then label:SetTextColor(1, 1, 1) else label:SetTextColor(0.5, 0.5, 0.5) end
  end
end

function Wizard:SelectDisplay(id)
  if not (self.detected and self.detected[id]) then id = "native" end
  self.choice.display = id
  for rid, r in pairs(self.radios) do r:SetChecked(rid == id) end
end

-- Choix fait par le joueur : gardé aussi dans le brouillon du personnage (reprise après /reload).
function Wizard:SetChoice(key, value)
  self.choice[key] = value
  if Q.char then
    if type(Q.char.wizardDraft) ~= "table" then Q.char.wizardDraft = {} end
    Q.char.wizardDraft[key] = value
  end
end

-- État de chaque addon de la page 1 : icône, texte, lien des absents, « Activer » des désactivés.
function Wizard:UpdateAddons()
  local anyMissing = false
  for _, entry in ipairs(ADDONS) do
    local row = self.addonRows[entry.id]
    local state, folder = self:AddonState(entry)
    row.state, row.folder = state, folder
    local s = STATUS[state]
    local color = (state == "missing" and entry.required) and "|cffff4040" or s[2]
    row.icon:SetTexture(s[3])
    row.status:SetText(color .. "(" .. L[s[1]] .. ")|r")
    if state == "disabled" then row.enable:Show() else row.enable:Hide() end
    if SHOW_LINK[state] then
      anyMissing = true
      row.link:SetText(entry.url)
      row.link:SetCursorPosition(0)
      row.link:Show()
      row:SetHeight(ROW_LINK_H)
    else
      row.link:Hide()
      row:SetHeight(ROW_H)
    end
  end
  if anyMissing then self.linkHint:Show() else self.linkHint:Hide() end
  if #self.enabledNames > 0 then
    self.reloadText:SetFormattedText(L.UI_WIZ_ENABLED, table.concat(self.enabledNames, ", "))
    self.reloadText:Show()
  else
    self.reloadText:Hide()
  end
end

-- Cases et boutons d'après self.choice.
function Wizard:Refresh()
  local d, c = self.detected, self.choice
  local routing = self.checks.routing
  setEnabled(routing, d.shortestpath, routing.label)
  routing:SetChecked(c.routing)
  if d.shortestpath then self.routingMissing:Hide() else self.routingMissing:Show() end
  for _, id in ipairs(DISPLAYS) do
    local r = self.radios[id]
    setEnabled(r, d[id] and true or false, r.label)
  end
  self:SelectDisplay(c.display)
  for _, def in ipairs(AUTOMATIONS) do self.checks[def[1]]:SetChecked(c[def[1]]) end
  local rb, Rw = self.rewardRoleButton, Q.Rewards
  if rb and Rw then
    local classFile = Q.Player and Q.Player.classFile
    if Rw:HasChoice(classFile) then
      rb:SetText(string.format(L.UI_OPT_REWARD_ROLE, Rw:RoleLabel(c.rewardRole, classFile)))
      rb:Show()
    else
      rb:Hide()
    end
  end
end

-- Les cases sont relues avant le récapitulatif et au moment de terminer : leur état affiché fait foi.
function Wizard:ReadWidgets()
  local c = self.choice
  local routing = self.checks.routing
  c.routing = self.detected.shortestpath and routing:IsEnabled() and routing:GetChecked() and true or false
  for _, def in ipairs(AUTOMATIONS) do
    c[def[1]] = self.checks[def[1]]:GetChecked() and true or false
  end
end

-- Lit la détection et les réglages actuels, reprend le brouillon, puis prépare chaque page.
function Wizard:Load()
  local d = self:Detect()
  self.detected = d
  local display = Q.Settings:Get("nav.display")
  -- Premier passage : le meilleur repère installé (WaypointUI, puis TomTom, puis le jeu).
  if not (Q.char and Q.char.wizardDone) then
    display = (d.waypointui and "waypointui") or (d.tomtom and "tomtom") or "native"
  end
  if not d[display] then display = "native" end
  local initial = {
    routing = d.shortestpath and Q.Settings:Get("nav.routing") == true or false,
    display = display,
    autoQuest = Q.Settings:Get("autoQuest") ~= false,
    autoReward = Q.Settings:Get("autoReward") ~= false,
    sellJunk = Q.Settings:Get("sellJunk") ~= false,
    rewardRole = Q.Rewards and Q.Rewards:Role() or "auto",
  }
  self.initial = initial
  local choice = {}
  for k, v in pairs(initial) do choice[k] = v end
  -- Choix faits avant un /reload : repris s'ils sont encore possibles (addon toujours chargé).
  local draft = Q.char and Q.char.wizardDraft
  if type(draft) == "table" then
    for k, v in pairs(draft) do
      if initial[k] ~= nil and type(v) == type(initial[k]) then choice[k] = v end
    end
  end
  if Q.Rewards then
    -- un brouillon périmé ne doit pas imposer un profil que la classe n'a pas
    local ok = false
    for _, r in ipairs(Q.Rewards:Roles(Q.Player and Q.Player.classFile)) do
      if r == choice.rewardRole then ok = true end
    end
    if not ok then choice.rewardRole = initial.rewardRole end
  end
  if not d.shortestpath then choice.routing = false end
  if not d[choice.display] then choice.display = initial.display end
  self.choice = choice
  self:UpdateAddons()
  self:Refresh()
end

function Wizard:UpdateRecap()
  self:ReadWidgets()
  local c, r = self.choice, self.recap
  local function onOff(v) return v and L.UI_WIZ_ON or L.UI_WIZ_OFF end
  r.routing:SetFormattedText(L.UI_WIZ_RECAP_ROUTING, c.routing and L.UI_NAV_SHORTESTPATH or L.UI_WIZ_OFF)
  local display = PROVIDER_TEXT[c.display] or PROVIDER_TEXT.native
  r.display:SetFormattedText(L.UI_WIZ_RECAP_DISPLAY, L[display[1]])
  r.autoQuest:SetFormattedText(L.UI_WIZ_RECAP_AUTOQUEST, onOff(c.autoQuest))
  r.autoReward:SetFormattedText(L.UI_WIZ_RECAP_AUTOREWARD, onOff(c.autoReward))
  r.sellJunk:SetFormattedText(L.UI_WIZ_RECAP_SELLJUNK, onOff(c.sellJunk))
end

-- Affiche la page n et la garde dans Q.char.wizardPage (reprise après /reload).
function Wizard:SetPage(n)
  n = math.max(1, math.min(NUM_PAGES, math.floor(tonumber(n) or 1)))
  self.page = n
  if Q.char then Q.char.wizardPage = n end
  for i, page in ipairs(self.pages) do
    if i == n then page:Show() else page:Hide() end
  end
  self.prevButton:Show()
  self.prevButton:SetEnabled(n > 1)
  if n < NUM_PAGES then
    self.nextButton:Show()
    self.skipButton:Show()
    self.finishButton:Hide()
  else
    self.nextButton:Hide()
    self.skipButton:Hide()
    self.finishButton:Show()
  end
  if n == PAGE_ADDONS or self.pendingReload then self.reloadButton:Show() else self.reloadButton:Hide() end
  if n == PAGE_RECAP then self:UpdateRecap() end
  self.stepText:SetFormattedText(L.UI_WIZ_STEP, n, NUM_PAGES)
end

function Wizard:Next() self:SetPage(self.page + 1) end
function Wizard:Prev() self:SetPage(self.page - 1) end

-- « Ignorer » : les choix de la page reprennent leur valeur de départ, puis page suivante.
function Wizard:Skip()
  local draft = Q.char and Q.char.wizardDraft
  for _, key in ipairs(PAGE_KEYS[self.page] or {}) do
    self.choice[key] = self.initial[key]
    if type(draft) == "table" then draft[key] = nil end
  end
  self:Refresh()
  self:SetPage(self.page + 1)
end

-- « Activer » : C_AddOns.EnableAddOn pour ce personnage seulement, puis le rechargement est
-- proposé sur toutes les pages.
function Wizard:EnableAddon(id)
  local row = self.addonRows[id]
  if not row or row.state ~= "disabled" then return end
  local f = C_AddOns and C_AddOns.EnableAddOn
  local who = playerName()
  if type(f) ~= "function" or not who then return end
  local ok, err = pcall(f, row.folder, who)
  if not ok then
    Q:ReportError(err)
    return
  end
  self.pendingReload = true
  self.enabledNames[#self.enabledNames + 1] = L[row.entry.name]
  playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
  self:UpdateAddons()
  self:SetPage(self.page)
end

-- « Recharger l'interface » : la page est déjà gardée, l'assistant y reprendra.
function Wizard:Reload()
  if Q.char then Q.char.wizardPage = self.page end
  local reload = ReloadUI or (C_UI and C_UI.Reload)
  if type(reload) == "function" then reload() end
end

-- Show() reprend à la page gardée (1 si aucune) ; Show(n) ouvre la page n.
function Wizard:Show(page)
  self:Create()
  self:Load()
  self:SetPage(page or (Q.char and Q.char.wizardPage) or 1)
  self.frame:Show()
  self.frame:Raise()
end

function Wizard:IsShown()
  return self.frame ~= nil and self.frame:IsShown()
end

-- Vrai si l'assistant a été fermé (croix, Échap ou « Terminer ») pendant cette session.
function Wizard:ClosedThisSession()
  return self.dismissed == true
end

function Wizard:Finish()
  self:ReadWidgets()
  local c = self.choice
  Q.Settings:Set("nav.routing", c.routing)
  Q.Settings:Set("nav.display", c.display or "native")
  Q.Settings:Set("autoQuest", c.autoQuest)
  Q.Settings:Set("autoReward", c.autoReward)
  Q.Settings:Set("sellJunk", c.sellJunk)
  -- profil de butin : propre au personnage (Q.char.rewardRole), hors profils d'options
  if Q.Rewards and c.rewardRole then Q.Rewards:SetRole(c.rewardRole) end
  if Q.char and Q.Rewards and Q.Rewards:HasChoice(Q.Player and Q.Player.classFile) then Q.char.rewardRoleChosen = true end
  if Q.char then
    Q.char.wizardDone = true
    Q.char.wizardPage = nil
    Q.char.wizardDraft = nil
  end
  self.frame:Hide()   -- OnHide : étape suivante de l'accueil, le choix des métiers
  playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
  Q:Print(L.UI_WIZ_DONE)
end

---------------------------------------------------------------------------
-- Ouverture automatique (3 s après la connexion, jamais en combat, une fois par session)
---------------------------------------------------------------------------
local waitingCombat = false

local function autoShow()
  if not Q.char or Q.char.wizardDone or Wizard:IsShown() then return end
  -- déjà ouvert ou fermé par le joueur pendant cette session : pas d'insistance
  if Wizard.autoShown or Wizard.dismissed then return end
  if InCombatLockdown and InCombatLockdown() then
    waitingCombat = true
    return
  end
  Wizard.autoShown = true
  Wizard:Show()
end

Q:On("LOGIN", function()
  if Q.char and not Q.char.wizardDone then Q:After(AUTO_DELAY, autoShow) end
end)

Q:RegisterEvent("PLAYER_REGEN_ENABLED", function()
  if waitingCombat then
    waitingCombat = false
    autoShow()
  end
end)
