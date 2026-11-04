local addonName, Q = ...

-- Fenêtre d'options QuestifyOptions (760 x 560, ButtonFrameTemplate, déplaçable, Échap la ferme).
--   À gauche : les sections du schéma (Core/OptionsSchema.lua), celle choisie en surbrillance.
--   En haut : recherche (SearchBoxTemplate) sur le libellé, les mots-clés et l'infobulle de toutes
--     les options, sans tenir compte des accents ni de la casse ; résultats groupés par section.
--     Vider la recherche ramène à la section choisie.
--   À droite : liste défilante, en-tête de chaque catégorie puis les contrôles : case à cocher,
--     boutons radio ou menu déroulant (WowStyle1DropdownTemplate, sinon radios), curseur
--     (MinimalSliderWithSteppersTemplate) avec sa valeur, boutons d'action ; une icône « i »
--     (Interface\common\help-i) à côté de chaque contrôle montre ce qu'il fait.
--   Section Thème : un aperçu 80 x 40 par thème (Q.Themes:Apply) et l'opacité du fond.
--   Section Profils : profil actif, type de profil, Nouveau / Copier depuis… / Supprimer… /
--     Réinitialiser, Exporter (texte sélectionné, Ctrl+C) et Importer (après confirmation).
-- Chaque changement passe par Q.Settings:Set (ou la fonction set de l'entrée) : les modules
-- réagissent à SETTINGS_CHANGED, la fenêtre se resynchronise.
-- Aussi : une page dans Échap > Options > AddOns (Settings.RegisterCanvasLayoutCategory) avec
-- un bouton qui ouvre cette fenêtre.
Q.UI = Q.UI or {}
local Options = { section = "route", query = "", widgets = {}, headers = {}, sectionButtons = {}, panels = {} }
Q.UI.Options = Options

local L = Q.L
local S = Q.OptionsSchema

local FRAME_NAME = "QuestifyOptions"
local WIDTH, HEIGHT = 760, 560
local SIDEBAR_W = 168
local SECTION_ROW_H = 24
local CONTENT_X = SIDEBAR_W + 22          -- début de la liste défilante (depuis le bord du cadre)
local CONTENT_W = WIDTH - CONTENT_X - 34  -- largeur utile (barre de défilement à droite)
local CONTENT_TOP, CONTENT_BOTTOM = 66, 34
local ROW_GAP = 4
local INDENT = 10
local INFO_TEXTURE = "Interface\\common\\help-i"
local INFO_SIZE = 20
local CONFIRM_DIALOG = "QUESTIFY_OPTIONS_CONFIRM"
local THEME_TILE_W, THEME_TILE_H = 104, 72
local SWATCH_W, SWATCH_H = 80, 40
Options.CONTENT_W = CONTENT_W

---------------------------------------------------------------------------
-- Outils
---------------------------------------------------------------------------
local function playSound(kit)
  if PlaySound and SOUNDKIT and SOUNDKIT[kit] then pcall(PlaySound, SOUNDKIT[kit]) end
end

local function safe(fn)
  return function(...) return Q.SafeCall(fn, ...) end
end

local function player() return Q.Player end

local seq = 0
local function nextName(kind)
  seq = seq + 1
  return FRAME_NAME .. kind .. seq
end

local function hideTooltip() if GameTooltip then GameTooltip:Hide() end end

-- Infobulle d'une entrée : libellé en titre, puis le texte d'aide.
local function showEntryTooltip(owner, e)
  if not (GameTooltip and e) then return end
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  local title = e.label and L[e.label] or e.id
  if e.type == "keybind" then title = string.format(title, Options.KeyText(e)) end
  GameTooltip:SetText(title, 1, 0.82, 0, 1, true)
  if e.tip then GameTooltip:AddLine(L[e.tip], 1, 1, 1, true) end
  GameTooltip:Show()
end

-- Icône « i » : survol = infobulle de l'entrée.
local function infoIcon(parent, e)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(INFO_SIZE, INFO_SIZE)
  local tx = b:CreateTexture(nil, "ARTWORK")
  tx:SetAllPoints(b)
  tx:SetTexture(INFO_TEXTURE)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(b)
  hl:SetTexture(INFO_TEXTURE)
  hl:SetBlendMode("ADD")
  hl:SetAlpha(0.4)
  b.texture, b.entry = tx, e
  b:SetScript("OnEnter", safe(function(self) showEntryTooltip(self, self.entry) end))
  b:SetScript("OnLeave", hideTooltip)
  return b
end

-- Largeur d'un texte sur une ligne, bornée : le texte passe à la ligne au-delà.
local function fitLabel(fs, maxW)
  local w = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
  w = tonumber(w) or maxW
  if w > maxW then
    fs:SetWidth(maxW)
    fs:SetWordWrap(true)
  else
    fs:SetWidth(math.max(1, w + 2))
    fs:SetWordWrap(false)
  end
  local h = tonumber(fs:GetStringHeight()) or 12
  return math.min(w, maxW), math.max(12, h)
end

local function newRow(e)
  local row = CreateFrame("Frame", nil, Options.child)
  row:SetWidth(CONTENT_W)
  row:SetHeight(24)
  row.entry = e
  row.sync = function() end
  row.layout = function() return 24 end
  return row
end

-- Texte de la touche d'un raccourci (GetBindingKey, GetBindingText), « aucune touche » sinon.
function Options.KeyText(e)
  local key
  if type(GetBindingKey) == "function" and e.binding then
    local ok, k = pcall(GetBindingKey, e.binding)
    if ok and type(k) == "string" and k ~= "" then key = k end
  end
  if not key then return L.OPT_KEY_NONE end
  if type(GetBindingText) == "function" then
    local ok, txt = pcall(GetBindingText, key)
    if ok and type(txt) == "string" and txt ~= "" then return txt end
  end
  return key
end

---------------------------------------------------------------------------
-- Confirmation et choix d'un profil
---------------------------------------------------------------------------
if StaticPopupDialogs then
  StaticPopupDialogs[CONFIRM_DIALOG] = {
    text = "%s",
    button1 = YES or L.UI_BTN_YES,
    button2 = NO or L.UI_BTN_NO,
    OnAccept = function() Q.SafeCall(function() Options:AcceptConfirm() end) end,
    OnCancel = function() Options.pending = nil end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
end

-- Confirm(texte, fn) : fenêtre Oui / Non ; fn est appelée sur « Oui ».
function Options:Confirm(text, fn)
  self.pending = fn
  if StaticPopup_Show and StaticPopupDialogs and StaticPopupDialogs[CONFIRM_DIALOG] then
    StaticPopup_Show(CONFIRM_DIALOG, text)
  else
    self:AcceptConfirm()
  end
end

function Options:AcceptConfirm()
  local fn = self.pending
  self.pending = nil
  if fn then fn() end
end

-- Petit menu maison (sans MenuUtil) : une ligne par profil.
local function pickerFrame()
  local p = Options.picker
  if p then return p end
  p = CreateFrame("Frame", FRAME_NAME .. "Picker", UIParent, "BackdropTemplate")
  p:SetFrameStrata("DIALOG")
  p:SetClampedToScreen(true)
  p:EnableMouse(true)
  if p.SetBackdrop then
    p:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 14,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    p:SetBackdropColor(0, 0, 0, 0.92)
  end
  p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  p.title:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -8)
  p.buttons = {}
  p:Hide()
  if UISpecialFrames then tinsert(UISpecialFrames, FRAME_NAME .. "Picker") end
  Options.picker = p
  return p
end

-- Pick(owner, noms, titre, fn) -> "menu" | "fallback" | "none" : fn(nom) au choix d'un profil.
function Options:Pick(owner, names, title, fn)
  if #names == 0 then
    self:Status(L.OPT_PICK_NONE, true)
    return "none"
  end
  local P = Q.Profiles
  if type(MenuUtil) == "table" and type(MenuUtil.CreateContextMenu) == "function" then
    local ok = pcall(MenuUtil.CreateContextMenu, owner, function(_, root)
      root:CreateTitle(title)
      for _, name in ipairs(names) do
        root:CreateButton(P:DisplayName(name), function() Q.SafeCall(fn, name) end, name)
      end
    end)
    if ok then return "menu" end
  end
  local p = pickerFrame()
  p.title:SetText(title)
  local y = 28
  for i, name in ipairs(names) do
    local b = p.buttons[i]
    if not b then
      b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
      b:SetSize(200, 22)
      b:SetScript("OnClick", safe(function(self)
        p:Hide()
        if self.pickFn and self.profile then self.pickFn(self.profile) end
      end))
      p.buttons[i] = b
    end
    b.profile, b.pickFn = name, fn
    b:SetText(P:DisplayName(name))
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -y)
    b:Show()
    y = y + 24
  end
  for i = #names + 1, #p.buttons do p.buttons[i]:Hide() end
  p:SetSize(220, y + 8)
  p:ClearAllPoints()
  p:SetPoint("TOPLEFT", owner or UIParent, "BOTTOMLEFT", 0, -2)
  p:Show()
  return "fallback"
end

---------------------------------------------------------------------------
-- Contrôles
---------------------------------------------------------------------------
local Build = {}

-- Case à cocher : case, libellé (cliquable), « i ».
function Build.toggle(e)
  local row = newRow(e)
  local cb = CreateFrame("CheckButton", nextName("Check"), row, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  cb:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT, 0)
  local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("TOPLEFT", cb, "TOPRIGHT", 2, -6)
  label:SetJustifyH("LEFT")
  local icon = infoIcon(row, e)
  icon:SetPoint("TOPLEFT", label, "TOPRIGHT", 4, 3)
  row.check, row.label, row.info = cb, label, icon
  cb:SetScript("OnClick", safe(function(self)
    local on = self:GetChecked() and true or false
    playSound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    S:Set(e, on, player())
    row.sync()
  end))
  row.sync = function()
    local enabled = S:Enabled(e, player())
    local text = L[e.label]
    if not enabled and e.disabledText then text = text .. " |cff808080" .. L[e.disabledText] .. "|r" end
    label:SetText(text)
    cb:SetChecked(S:Get(e, player()) == true)
    cb:SetEnabled(enabled)
    if enabled then label:SetTextColor(1, 1, 1) else label:SetTextColor(0.5, 0.5, 0.5) end
  end
  row.layout = function()
    local w, h = fitLabel(label, CONTENT_W - INDENT - 28 - INFO_SIZE - 12)
    if cb.SetHitRectInsets then cb:SetHitRectInsets(0, -(w + 4), 0, 0) end
    local height = math.max(26, h + 12)
    row:SetHeight(height)
    return height
  end
  return row
end

-- Titre d'un contrôle (choix, curseur) : libellé et « i ».
local function titleLine(row, e)
  local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 4, -2)
  label:SetJustifyH("LEFT")
  label:SetText(L[e.label])
  local icon = infoIcon(row, e)
  icon:SetPoint("TOPLEFT", label, "TOPRIGHT", 4, 4)
  row.label, row.info = label, icon
  return label
end

-- Menu déroulant de Blizzard_Menu (WowStyle1DropdownTemplate) : nil s'il n'est pas utilisable.
local function newDropdown(row)
  if type(MenuUtil) ~= "table" then return nil end
  local ok, dd = pcall(CreateFrame, "DropdownButton", nil, row, "WowStyle1DropdownTemplate")
  if not (ok and dd and type(dd.SetupMenu) == "function" and type(dd.GenerateMenu) == "function") then
    if ok and dd and dd.Hide then dd:Hide() end
    return nil
  end
  return dd
end

-- Choix : menu déroulant (style "dropdown", si disponible) ou boutons radio.
function Build.select(e)
  if e.style == "themes" then return Build.themes(e) end
  local row = newRow(e)
  titleLine(row, e)
  row.radios = {}
  if e.style == "dropdown" then
    local dd = newDropdown(row)
    if dd then
      dd:SetWidth(260)
      dd:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 8, -24)
      dd:SetupMenu(function(_, root)
        for _, c in ipairs(S:Choices(e, player())) do
          local value = c.value
          local desc = root:CreateRadio(c.text, function() return S:Get(e, player()) == value end,
            function()
              Q.SafeCall(function()
                playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
                S:Set(e, value, player())
                row.sync()
              end)
            end, value)
          if c.disabled and desc and desc.SetEnabled then desc:SetEnabled(false) end
        end
      end)
      row.dropdown = dd
      row.sync = function()
        local label = row.label
        label:SetText(L[e.label])
        pcall(dd.GenerateMenu, dd)
      end
      row.layout = function()
        fitLabel(row.label, CONTENT_W - INDENT - INFO_SIZE - 20)
        row:SetHeight(56)
        return 56
      end
      return row
    end
  end
  local function radio(i)
    local r = row.radios[i]
    if r then return r end
    r = CreateFrame("CheckButton", nextName("Radio"), row, "UIRadioButtonTemplate")
    r:SetSize(16, 16)
    r:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 10, -(22 + (i - 1) * 20))
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", r, "RIGHT", 4, 0)
    text:SetJustifyH("LEFT")
    r.label = text
    r:SetScript("OnClick", safe(function(self)
      if self.disabledChoice then
        self:SetChecked(false)
        return
      end
      playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
      S:Set(e, self.value, player())
      row.sync()
    end))
    row.radios[i] = r
    return r
  end
  row.sync = function()
    local choices = S:Choices(e, player())
    local current = S:Get(e, player())
    for i, c in ipairs(choices) do
      local r = radio(i)
      r.value, r.disabledChoice = c.value, c.disabled
      local text = tostring(c.text)
      if c.disabled then text = text .. " |cff808080" .. L.OPT_NOT_INSTALLED .. "|r" end
      r.label:SetText(text)
      if c.disabled then r.label:SetTextColor(0.5, 0.5, 0.5) else r.label:SetTextColor(1, 1, 1) end
      r:SetChecked(current == c.value)
      r:SetEnabled(not c.disabled)
      r:Show()
      r.label:Show()
    end
    for i = #choices + 1, #row.radios do
      row.radios[i]:Hide()
      row.radios[i].label:Hide()
    end
    row.count = #choices
  end
  row.layout = function()
    fitLabel(row.label, CONTENT_W - INDENT - INFO_SIZE - 20)
    local h = 24 + (row.count or 0) * 20
    row:SetHeight(h)
    return h
  end
  return row
end

-- Thèmes : un aperçu par thème (cadre 80 x 40 sur lequel le thème est appliqué), le thème
-- choisi encadré d'or ; clic = Q.Settings:Set("tracker.theme", clé).
function Build.themes(e)
  local row = newRow(e)
  titleLine(row, e)
  row.tiles = {}
  local function tile(i)
    local t = row.tiles[i]
    if t then return t end
    t = CreateFrame("Button", nil, row)
    t:SetSize(THEME_TILE_W, THEME_TILE_H)
    t:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 8 + (i - 1) * (THEME_TILE_W + 8), -24)
    local sel = t:CreateTexture(nil, "BACKGROUND")
    sel:SetPoint("TOPLEFT", t, "TOPLEFT", (THEME_TILE_W - SWATCH_W) / 2 - 3, -1)
    sel:SetSize(SWATCH_W + 6, SWATCH_H + 6)
    sel:SetColorTexture(1, 0.82, 0, 0.95)
    sel:Hide()
    -- « monde » derrière l'aperçu : le thème transparent reste lisible
    local world = CreateFrame("Frame", nil, t)
    world:SetSize(SWATCH_W, SWATCH_H)
    world:SetPoint("TOP", t, "TOP", 0, -4)
    local ground = world:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(world)
    ground:SetColorTexture(0.30, 0.36, 0.26, 1)
    local swatch = CreateFrame("Frame", nil, world, "BackdropTemplate")
    swatch:SetSize(SWATCH_W, SWATCH_H)
    swatch:SetAllPoints(world)
    local sample = swatch:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sample:SetPoint("CENTER", swatch, "CENTER", 0, 0)
    sample:SetText("Questify")
    local name = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("TOP", world, "BOTTOM", 0, -6)
    name:SetWidth(THEME_TILE_W)
    t:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    t.selected, t.swatch, t.sample, t.name = sel, swatch, sample, name
    t:SetScript("OnClick", safe(function(self)
      playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
      S:Set(e, self.value, player())
      row.sync()
    end))
    t:SetScript("OnEnter", safe(function(self) showEntryTooltip(self, e) end))
    t:SetScript("OnLeave", hideTooltip)
    row.tiles[i] = t
    return t
  end
  row.sync = function()
    local T = Q.Themes
    local choices = S:Choices(e, player())
    local current = T and T:Resolve(S:Get(e, player())) or S:Get(e, player())
    local opacity = T and T:Opacity(Q.Settings:Get("tracker.opacity")) or 1
    for i, c in ipairs(choices) do
      local t = tile(i)
      t.value = c.value
      t.name:SetText(c.text)
      if T then
        local theme = T:Apply(t.swatch, c.value, opacity)
        T:StyleText(t.sample, "title", theme)
      end
      local on = current == c.value
      if on then t.selected:Show(); t.name:SetTextColor(1, 0.82, 0) else t.selected:Hide(); t.name:SetTextColor(1, 1, 1) end
      t:Show()
    end
    for i = #choices + 1, #row.tiles do row.tiles[i]:Hide() end
  end
  row.layout = function()
    fitLabel(row.label, CONTENT_W - INDENT - INFO_SIZE - 20)
    local h = 24 + THEME_TILE_H + 4
    row:SetHeight(h)
    return h
  end
  return row
end

-- Curseur : titre et « i », curseur de Blizzard avec ses flèches, valeur à droite.
local function newSlider(row)
  local ok, s = pcall(CreateFrame, "Frame", nil, row, "MinimalSliderWithSteppersTemplate")
  if ok and s then return s, s.Slider or s end
  local plain = CreateFrame("Slider", nil, row)
  plain:SetOrientation("HORIZONTAL")
  plain:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  return plain, plain
end

function Build.slider(e)
  local row = newRow(e)
  titleLine(row, e)
  local frame, slider = newSlider(row)
  frame:SetSize(280, 26)
  frame:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 4, -22)
  local value = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  value:SetPoint("LEFT", frame, "RIGHT", 10, 0)
  value:SetJustifyH("LEFT")
  row.slider, row.sliderFrame, row.value = slider, frame, value
  local steps = math.max(1, math.floor((e.max - e.min) / e.step + 0.5))
  local start = S:ClampSlider(e, S:Get(e, player())) or e.min
  if type(MinimalSliderWithSteppersMixin) == "table" and type(frame.Init) == "function" then
    frame:Init(start, e.min, e.max, steps)
  else
    slider:SetMinMaxValues(e.min, e.max)
    if slider.SetValueStep then slider:SetValueStep(e.step) end
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  end
  local function show(v) value:SetText(e.format and e.format(v) or tostring(v)) end
  -- après Init (qui pose son propre OnValueChanged) : on s'ajoute à la suite
  slider:HookScript("OnValueChanged", function(_, v)
    Q.SafeCall(function()
      if row.syncing then return end
      local clean = S:ClampSlider(e, v)
      if clean == nil then return end
      show(clean)
      local cur = S:ClampSlider(e, S:Get(e, player()))
      if cur ~= clean then S:Set(e, clean, player()) end
    end)
  end)
  row.sync = function()
    local v = S:ClampSlider(e, S:Get(e, player())) or e.min
    row.syncing = true
    pcall(slider.SetValue, slider, v)
    row.syncing = false
    show(v)
  end
  row.layout = function()
    fitLabel(row.label, CONTENT_W - INDENT - INFO_SIZE - 20)
    row:SetHeight(52)
    return 52
  end
  return row
end

-- Zone de texte à copier (export) : sélectionnée, en lecture seule, « Ctrl+C pour copier ».
local function exportPanel(row, e)
  local box = CreateFrame("EditBox", nextName("Export"), row, "InputBoxTemplate")
  box:SetSize(CONTENT_W - INDENT - 40, 20)
  box:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 12, -32)
  box:SetAutoFocus(false)
  if box.SetMaxLetters then box:SetMaxLetters(0) end
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  box:SetScript("OnTextChanged", function(self, userInput)
    if userInput and self.value then
      self:SetText(self.value)
      self:HighlightText()
    end
  end)
  local hint = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -4, -4)
  hint:SetText(L.OPT_COPY_HINT)
  row.box, row.hint = box, hint
  row.panelHeight = 50
  row.showPanel = function(on)
    row.panelOpen = on
    if on then
      local text = e.text and e.text() or ""
      box.value = text
      box:SetText(text)
      box:Show()
      hint:Show()
      box:SetFocus()
      box:HighlightText()
    else
      box:Hide()
      hint:Hide()
    end
  end
  row.showPanel(false)
end

-- Import : chaîne collée, nom du profil cible (vide : profil actuel), « Appliquer », message.
local function importPanel(row, e)
  local box = CreateFrame("EditBox", nextName("Import"), row, "InputBoxTemplate")
  box:SetSize(CONTENT_W - INDENT - 40, 20)
  box:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 12, -32)
  box:SetAutoFocus(false)
  if box.SetMaxLetters then box:SetMaxLetters(Q.Profiles.MAX_IMPORT + 1) end
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  local hint = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -4, -4)
  hint:SetText(L.OPT_IMPORT_HINT)
  local targetLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  targetLabel:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -10)
  targetLabel:SetText(L.OPT_IMPORT_TARGET)
  local target = CreateFrame("EditBox", nextName("ImportTarget"), row, "InputBoxTemplate")
  target:SetSize(200, 20)
  target:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", 6, -4)
  target:SetAutoFocus(false)
  if target.SetMaxLetters then target:SetMaxLetters(Q.Profiles.MAX_NAME) end
  target:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  local apply = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  apply:SetSize(120, 22)
  apply:SetPoint("LEFT", target, "RIGHT", 12, 0)
  apply:SetText(L.OPT_IMPORT_APPLY)
  local status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", target, "BOTTOMLEFT", -6, -8)
  status:SetWidth(CONTENT_W - INDENT - 40)
  status:SetJustifyH("LEFT")
  row.box, row.hint, row.targetLabel, row.target, row.apply, row.status = box, hint, targetLabel, target, apply, status
  row.panelHeight = 118
  local parts = { box, hint, targetLabel, target, apply, status }
  row.showPanel = function(on)
    row.panelOpen = on
    for _, p in ipairs(parts) do if on then p:Show() else p:Hide() end end
    if on then
      status:SetText("")
      box:SetFocus()
    end
  end
  apply:SetScript("OnClick", safe(function() Options:ApplyImport(row) end))
  row.showPanel(false)
end

-- Bouton d'action (avec zone de saisie, d'export ou d'import selon l'entrée) et « i ».
function Build.action(e)
  local row = newRow(e)
  local x = INDENT + 4
  if e.input then
    local input = CreateFrame("EditBox", nextName("Input"), row, "InputBoxTemplate")
    input:SetSize(180, 20)
    input:SetPoint("TOPLEFT", row, "TOPLEFT", x + 6, -2)
    input:SetAutoFocus(false)
    if input.SetMaxLetters then input:SetMaxLetters(Q.Profiles.MAX_NAME) end
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEnterPressed", function() Q.SafeCall(function() Options:RunAction(e, row.button, row) end) end)
    local hint = input:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("LEFT", input, "LEFT", 2, 0)
    hint:SetText(L.OPT_PROFILE_NEW_HINT)
    input:SetScript("OnTextChanged", function(self)
      local txt = self:GetText()
      if txt and txt ~= "" then hint:Hide() else hint:Show() end
    end)
    row.input, row.inputHint = input, hint
    x = x + 196
  end
  local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  b:SetHeight(22)
  b:SetPoint("TOPLEFT", row, "TOPLEFT", x, 0)
  b:SetText(L[e.label])
  local w = 160
  if b.GetTextWidth then
    local ok, tw = pcall(b.GetTextWidth, b)
    if ok and type(tw) == "number" then w = math.max(120, tw + 30) end
  end
  b:SetWidth(math.min(w, CONTENT_W - x - 40))
  local icon = infoIcon(row, e)
  icon:SetPoint("LEFT", b, "RIGHT", 6, 0)
  row.button, row.info = b, icon
  b:SetScript("OnClick", safe(function(self)
    playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    Options:RunAction(e, self, row)
  end))
  if e.panel == "export" then exportPanel(row, e) elseif e.panel == "import" then importPanel(row, e) end
  row.layout = function()
    local h = 26 + (row.panelOpen and row.panelHeight or 0)
    row:SetHeight(h)
    return h
  end
  return row
end

-- Raccourci du jeu : « Touche … : <touche> » et « i » (la touche se choisit dans les Raccourcis).
function Build.keybind(e)
  local row = newRow(e)
  local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  label:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 6, -4)
  label:SetJustifyH("LEFT")
  local icon = infoIcon(row, e)
  icon:SetPoint("TOPLEFT", label, "TOPRIGHT", 4, 4)
  row.label, row.info = label, icon
  row.sync = function() label:SetText(string.format(L[e.label], Options.KeyText(e))) end
  row.layout = function()
    local _, h = fitLabel(label, CONTENT_W - INDENT - INFO_SIZE - 20)
    local height = math.max(22, h + 8)
    row:SetHeight(height)
    return height
  end
  return row
end

-- Texte d'information.
function Build.info(e)
  local row = newRow(e)
  local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT", row, "TOPLEFT", INDENT + 6, -2)
  text:SetWidth(CONTENT_W - INDENT - 24)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(true)
  text:SetTextColor(0.82, 0.82, 0.82)
  text:SetText(L[e.label])
  row.label = text
  row.layout = function()
    local h = math.max(14, tonumber(text:GetStringHeight()) or 14) + 6
    row:SetHeight(h)
    return h
  end
  return row
end

-- Widget(id) -> ligne du contrôle de cette entrée (créée au premier affichage), ou nil.
function Options:Widget(id)
  return self.widgets[id]
end

function Options:BuildWidget(e)
  local w = self.widgets[e.id]
  if w then return w end
  local fn = Build[e.type]
  if not fn then return nil end
  w = fn(e)
  self.widgets[e.id] = w
  return w
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
-- Status(texte, erreur) : ligne de message en bas de la fenêtre.
function Options:Status(text, isError)
  local st = self.statusText
  if not st then return end
  st:SetText(text or "")
  if isError then st:SetTextColor(1, 0.35, 0.35) else st:SetTextColor(0.4, 1, 0.4) end
end

local function report(ok, err, success)
  if ok then
    if success then
      Options:Status(success, false)
      Q:Print(success)
    end
  else
    Options:Status(err or L.PROFILE_ERR_UNKNOWN, true)
  end
  return ok
end

-- RunAction(entrée, bouton, ligne) : profils (nouveau, copie, suppression, remise à zéro),
-- zone d'export ou d'import, sinon la fonction run de l'entrée.
function Options:RunAction(e, owner, row)
  local P = Q.Profiles
  if e.panel then
    if row and row.showPanel then
      row.showPanel(not row.panelOpen or e.panel == "export")
      self:Render(true)
    end
    return
  end
  if e.input then
    local text = row and row.input and row.input:GetText() or ""
    local name, err = P:Create(text)
    if not name then return report(false, err) end
    P:SetActive(name)
    row.input:SetText("")
    if row.inputHint then row.inputHint:Show() end
    return report(true, nil, string.format(L.PROFILE_CREATED, P:DisplayName(name)))
  end
  if e.pick == "copy" then
    return self:Pick(owner, P:Others(), L.OPT_PICK_COPY, function(name)
      local into = P:Active()
      Options:Confirm(string.format(L.PROFILE_CONFIRM_COPY, P:DisplayName(into), P:DisplayName(name)), function()
        local ok, err2 = P:CopyFrom(name)
        report(ok, err2, string.format(L.PROFILE_COPIED, P:DisplayName(name), P:DisplayName(into)))
      end)
    end)
  end
  if e.pick == "delete" then
    return self:Pick(owner, P:Deletable(), L.OPT_PICK_DELETE, function(name)
      Options:Confirm(string.format(L.PROFILE_CONFIRM_DELETE, P:DisplayName(name)), function()
        local ok, err2 = P:Delete(name)
        report(ok, err2, string.format(L.PROFILE_DELETED, P:DisplayName(name)))
      end)
    end)
  end
  if e.confirm == "reset" then
    local name = P:Active()
    return self:Confirm(string.format(L.PROFILE_CONFIRM_RESET, P:DisplayName(name)), function()
      local ok = P:Reset()
      report(ok, nil, string.format(L.PROFILE_RESET_DONE, P:DisplayName(name)))
    end)
  end
  if e.run then e.run(owner) end
end

-- « Appliquer » de l'import : chaîne lue et contrôlée d'abord (message clair si elle ne convient
-- pas), puis confirmation, puis import dans le profil cible.
function Options:ApplyImport(row)
  local P = Q.Profiles
  local text = row.box:GetText() or ""
  local clean, kept = P:Decode(text)
  if not clean then
    row.status:SetText(kept or L.PROFILE_ERR_CORRUPT)
    row.status:SetTextColor(1, 0.35, 0.35)
    return false
  end
  local target = row.target:GetText() or ""
  local shown = target:match("%S") and target:gsub("^%s+", ""):gsub("%s+$", "") or P:DisplayName(P:Active())
  self:Confirm(string.format(L.PROFILE_CONFIRM_IMPORT, kept, shown), function()
    local ok, msg = P:Import(text, target)
    row.status:SetText(msg or "")
    if ok then
      row.status:SetTextColor(0.4, 1, 0.4)
      row.box:SetText("")
      row.target:SetText("")
      Q:Print(msg)
    else
      row.status:SetTextColor(1, 0.35, 0.35)
    end
  end)
  return true
end

---------------------------------------------------------------------------
-- Cadre
---------------------------------------------------------------------------
local function newFrame()
  local ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
  if ok and f then return f end
  ok, f = pcall(CreateFrame, "Frame", FRAME_NAME, UIParent, "PortraitFrameTemplate")
  if ok and f then return f end
  return CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
end

local function newSearchBox(f)
  local ok, box = pcall(CreateFrame, "EditBox", FRAME_NAME .. "Search", f, "SearchBoxTemplate")
  if not (ok and box) then box = CreateFrame("EditBox", FRAME_NAME .. "Search", f, "InputBoxTemplate") end
  box:SetSize(230, 20)
  box:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -33)
  box:SetAutoFocus(false)
  if box.Instructions and box.Instructions.SetText then box.Instructions:SetText(L.OPT_SEARCH_HINT) end
  box:HookScript("OnTextChanged", function(self)
    Q.SafeCall(function() Options:OnSearchChanged(self:GetText() or "") end)
  end)
  return box
end

local function sectionButton(i, s)
  local b = CreateFrame("Button", nil, Options.sidebar)
  b:SetSize(SIDEBAR_W - 8, SECTION_ROW_H)
  b:SetPoint("TOPLEFT", Options.sidebar, "TOPLEFT", 4, -4 - (i - 1) * SECTION_ROW_H)
  b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
  local sel = b:CreateTexture(nil, "BACKGROUND")
  sel:SetAllPoints(b)
  sel:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
  sel:SetBlendMode("ADD")
  sel:SetVertexColor(1, 0.82, 0, 0.55)
  sel:Hide()
  local text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("LEFT", b, "LEFT", 10, 0)
  text:SetJustifyH("LEFT")
  text:SetText(L[s.label])
  b.selected, b.text, b.sectionId = sel, text, s.id
  b:SetScript("OnClick", safe(function(self)
    playSound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    Options:SelectSection(self.sectionId)
  end))
  return b
end

function Options:Create()
  if self.frame then return self.frame end
  local f = newFrame()
  self.frame = f
  f:SetSize(WIDTH, HEIGHT)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetFrameStrata("HIGH")
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  if f.SetTitle then f:SetTitle(L.OPT_TITLE) end
  if f.SetPortraitToAsset then pcall(f.SetPortraitToAsset, f, "Interface\\Icons\\INV_Misc_Gear_01") end
  if UISpecialFrames then tinsert(UISpecialFrames, FRAME_NAME) end

  self.searchBox = newSearchBox(f)
  local count = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  count:SetPoint("RIGHT", self.searchBox, "LEFT", -10, 0)
  count:SetJustifyH("RIGHT")
  self.countText = count

  -- barre latérale des sections
  local side = CreateFrame("Frame", nil, f)
  side:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -CONTENT_TOP)
  side:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, CONTENT_BOTTOM)
  side:SetWidth(SIDEBAR_W)
  local sideBg = side:CreateTexture(nil, "BACKGROUND")
  sideBg:SetAllPoints(side)
  sideBg:SetColorTexture(0, 0, 0, 0.25)
  local divider = side:CreateTexture(nil, "ARTWORK")
  divider:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, 0)
  divider:SetPoint("BOTTOMLEFT", side, "BOTTOMRIGHT", 0, 0)
  divider:SetWidth(1)
  divider:SetColorTexture(1, 0.82, 0, 0.25)
  self.sidebar = side
  for i, s in ipairs(S.SECTIONS) do self.sectionButtons[i] = sectionButton(i, s) end

  -- liste défilante des contrôles
  local scroll = CreateFrame("ScrollFrame", FRAME_NAME .. "Scroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f, "TOPLEFT", CONTENT_X, -CONTENT_TOP)
  scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, CONTENT_BOTTOM)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(CONTENT_W, 1)
  scroll:SetScrollChild(child)
  self.scroll, self.child = scroll, child

  local empty = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  empty:SetPoint("TOPLEFT", child, "TOPLEFT", INDENT, -12)
  empty:SetWidth(CONTENT_W - 2 * INDENT)
  empty:SetJustifyH("LEFT")
  empty:Hide()
  self.emptyText = empty

  local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 9)
  status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 9)
  status:SetJustifyH("LEFT")
  self.statusText = status

  f:Hide()
  f:HookScript("OnShow", function() playSound("IG_CHARACTER_INFO_OPEN") end)
  f:HookScript("OnHide", function()
    playSound("IG_CHARACTER_INFO_CLOSE")
    if Options.picker then Options.picker:Hide() end
  end)
  return f
end

function Options:IsShown()
  return self.frame ~= nil and self.frame:IsShown()
end

-- Open(section) : ouvre la fenêtre (sur cette section si elle est donnée).
function Options:Open(sectionId)
  self:Create()
  if sectionId and S:Section(sectionId) then
    self.section = sectionId
    if self.query ~= "" then self:SetSearch("") end
  end
  self.frame:Show()
  self:Status("")
  self:Render()
end

function Options:Toggle()
  if self:IsShown() then self.frame:Hide() else self:Open() end
end

function Options:Close()
  if self.frame then self.frame:Hide() end
end

-- SelectSection(id) : section affichée (vide la recherche).
function Options:SelectSection(id)
  if not S:Section(id) then return end
  self.section = id
  if self.query ~= "" then
    self.query = ""
    if self.searchBox then self.searchBox:SetText("") end
  end
  self:Render()
end

-- SetSearch(texte) : recherche dans toutes les sections (vide : retour à la section choisie).
function Options:SetSearch(text)
  self:Create()
  if self.searchBox then self.searchBox:SetText(text or "") end
  self:OnSearchChanged(text or "")
end

function Options:OnSearchChanged(text)
  text = tostring(text or "")
  if text == self.query then return end
  self.query = text
  if self:IsShown() then self:Render() end
end

---------------------------------------------------------------------------
-- Mise en page
---------------------------------------------------------------------------
-- En-tête réutilisable : "section" (grand titre) ou "category" (titre doré et trait).
local function header(i)
  local h = Options.headers[i]
  if h then return h end
  h = CreateFrame("Frame", nil, Options.child)
  h:SetWidth(CONTENT_W)
  local text = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("TOPLEFT", h, "TOPLEFT", 2, 0)
  text:SetJustifyH("LEFT")
  local line = h:CreateTexture(nil, "ARTWORK")
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -3)
  line:SetPoint("RIGHT", h, "RIGHT", -6, 0)
  line:SetColorTexture(1, 0.82, 0, 0.3)
  h.text, h.line = text, line
  Options.headers[i] = h
  return h
end

local function placeHeader(y, label, kind)
  Options.headerUsed = Options.headerUsed + 1
  local h = header(Options.headerUsed)
  h.kind = kind
  h:ClearAllPoints()
  h:SetPoint("TOPLEFT", Options.child, "TOPLEFT", 0, -y)
  h.text:SetFontObject(kind == "section" and "GameFontNormalLarge" or "GameFontNormal")
  h.text:SetText(label)
  if kind == "section" then h.line:Hide() else h.line:Show() end
  h:SetHeight(kind == "section" and 24 or 20)
  h:Show()
  return y + (kind == "section" and 28 or 24)
end

local function placeEntry(e, y)
  local w = Options:BuildWidget(e)
  if not w then return y end
  w:ClearAllPoints()
  w:SetPoint("TOPLEFT", Options.child, "TOPLEFT", 0, -y)
  w.sync()
  local h = w.layout()
  w:Show()
  Options.shown[#Options.shown + 1] = w
  return y + h + ROW_GAP
end

-- Liste d'entrées avec les en-têtes de section (si demandé) et de catégorie.
local function placeList(list, y, withSections)
  local lastSection, lastCategory
  for _, e in ipairs(list) do
    local s = S:Section(e.section)
    if withSections and e.section ~= lastSection then
      if lastSection then y = y + 6 end
      y = placeHeader(y, L[s.label], "section")
      lastCategory = nil
    end
    lastSection = e.section
    if e.category ~= lastCategory then
      local c = s and s.categories[s.categoryIndex[e.category] or 0]
      if lastCategory then y = y + 6 end
      y = placeHeader(y, c and L[c.label] or tostring(e.category), "category")
      lastCategory = e.category
    end
    y = placeEntry(e, y)
  end
  return y
end

function Options:UpdateSidebar()
  local searching = self.query ~= ""
  for _, b in ipairs(self.sectionButtons) do
    local on = b.sectionId == self.section
    if on then b.selected:Show() else b.selected:Hide() end
    if on and not searching then b.text:SetTextColor(1, 1, 1) else b.text:SetTextColor(1, 0.82, 0) end
    if on and searching then b.selected:SetAlpha(0.4) else b.selected:SetAlpha(1) end
  end
end

-- Render(garderDéfilement) : réaffiche la section choisie ou les résultats de la recherche.
function Options:Render(keepScroll)
  if not self.frame then return end
  for _, w in pairs(self.widgets) do w:Hide() end
  for _, h in ipairs(self.headers) do h:Hide() end
  self.headerUsed = 0
  self.shown = {}
  self.emptyText:Hide()
  local p = player()
  local y = 4
  if self.query ~= "" then
    local results = S:Search(self.query, p)
    self.results = results
    self.countText:SetFormattedText(L.OPT_SEARCH_RESULTS, #results)
    if #results == 0 then
      self.emptyText:SetFormattedText(L.OPT_SEARCH_NONE, self.query)
      self.emptyText:Show()
      y = 40
    else
      y = placeList(results, y, true)
    end
  else
    self.results = nil
    self.countText:SetText("")
    local s = S:Section(self.section) or S.SECTIONS[1]
    self.section = s.id
    y = placeHeader(y, L[s.label], "section")
    y = placeList(S:EntriesFor(s.id, p), y, false)
  end
  self.child:SetHeight(math.max(1, y + 8))
  if not keepScroll and self.scroll.SetVerticalScroll then self.scroll:SetVerticalScroll(0) end
  self:UpdateSidebar()
end

-- Sync() : relit la valeur de chaque contrôle affiché (après un changement venu d'ailleurs).
function Options:Sync()
  if not self:IsShown() then return end
  for _, w in ipairs(self.shown or {}) do Q.SafeCall(w.sync) end
end

-- Export des mesures de temps (/qf export) : section Outils, zone de texte ouverte.
function Options:ShowTelemetryExport()
  self:Open("tools")
  local w = self:Widget("exportTelemetry")
  if w and w.showPanel then
    w.showPanel(true)
    self:Render(true)
  end
  return w
end

---------------------------------------------------------------------------
-- Page dans Échap > Options > AddOns
---------------------------------------------------------------------------
function Options:RegisterSettingsCanvas()
  if self.category then return self.category end
  local St = Settings
  if not (type(St) == "table" and type(St.RegisterCanvasLayoutCategory) == "function"
    and type(St.RegisterAddOnCategory) == "function") then return nil end
  local panel = CreateFrame("Frame", FRAME_NAME .. "Canvas")
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
  title:SetText("Questify")
  local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
  text:SetWidth(560)
  text:SetJustifyH("LEFT")
  text:SetText(L.OPT_SETTINGS_TEXT)
  local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  b:SetSize(260, 26)
  b:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -16)
  b:SetText(L.OPT_SETTINGS_OPEN)
  b:SetScript("OnClick", safe(function()
    -- le panneau des options du jeu se ferme d'abord (validation de ses propres réglages)
    local SP = SettingsPanel
    if type(SP) == "table" and SP.IsShown and SP:IsShown() and type(SP.Close) == "function" then
      pcall(SP.Close, SP, true)
    end
    Options:Open()
  end))
  panel.openButton = b
  self.canvas = panel
  local ok, cat = pcall(St.RegisterCanvasLayoutCategory, panel, "Questify")
  if not (ok and cat) then return nil end
  pcall(St.RegisterAddOnCategory, cat)
  self.category = cat
  return cat
end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
Q:On("INIT", function() Options:RegisterSettingsCanvas() end)

Q:On("SETTINGS_CHANGED", function()
  if Q.Profiles and Q.Profiles.applying then return end
  Options:Sync()
end)

-- Profil changé, créé ou supprimé : la liste des profils et toutes les valeurs sont relues.
Q:On("PROFILE_CHANGED", function()
  if Options:IsShown() then Options:Render(true) end
end)
