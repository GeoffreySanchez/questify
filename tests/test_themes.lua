-- Tests des thèmes du suivi (Q.Themes, UI/Themes.lua) : fond, bordure, couleurs du texte,
-- opacité, retour au parchemin, réglage à chaud, commandes /qf theme et /qf opacity.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")

local function load(opts)
  Ext.install()
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end   -- routes générées : contenu changeant
  return Mock.loadAddon(TOC, opts)
end

local function qf(msg) SlashCmdList.QUESTIFY(msg) end

-- Espion : chaque appel des méthodes nommées est noté dans log[nom] = { { args... }, ... }, puis
-- passé à la méthode d'origine (celle du mock, ou un appel sans effet).
local function spy(obj, names, log)
  for _, name in ipairs(names) do
    local orig = obj[name]
    log[name] = log[name] or {}
    rawset(obj, name, function(self, ...)
      table.insert(log[name], { ... })
      if type(orig) == "function" then return orig(self, ...) end
    end)
  end
  return log
end

local TEXTURE_CALLS = { "SetColorTexture", "SetGradient", "SetAtlas", "SetAlpha", "SetBlendMode" }

-- Cadre BackdropTemplate dont la bordure et les textures créées ensuite sont espionnées.
local function spyFrame()
  local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  local log = spy(f, { "SetBackdrop", "SetBackdropBorderColor", "SetAlpha" }, {})
  log.textures = {}
  local create = f.CreateTexture
  rawset(f, "CreateTexture", function(self, ...)
    local tx = create(self, ...)
    local tlog = spy(tx, TEXTURE_CALLS, {})
    log.textures[tx] = tlog
    return tx
  end)
  return f, log
end

local function last(list) return list and list[#list] end

local function color(fs) return { fs:GetTextColor() } end

return {
  defaults_are_parchment_at_ninety_percent = function(t)
    local Q = load()
    t.eq(Q.Settings.defaults.tracker.theme, "parchment")
    t.eq(Q.Settings.defaults.tracker.opacity, 0.9)
    t.eq(Q.Settings:Get("tracker.theme"), "parchment")
    t.eq(Q.Settings:Get("tracker.opacity"), 0.9)
    local T = Q.UI.Tracker
    t.eq(T.themeKey, "parchment", "tracker starts on parchment")
    t.eq(T.frame.qvThemeBackground, "atlas", "parchment atlas")
    t.eq(T.frame.qvThemeBg:GetAtlas(), "QuestBG-Parchment")
    t.eq(T.frame.qvThemeBg:GetAlpha(), 0.9)
    t.eq(#Mock.errors, 0)
  end,

  list_and_get = function(t)
    local Q = load()
    local list = Q.Themes:List()
    local keys = {}
    for i, th in ipairs(list) do keys[i] = th.key end
    t.eq(keys, { "parchment", "dark", "transparent", "gradient" })
    t.eq(list[1].label, "Parchment")
    t.eq(list[4].label, "Grey fade")
    for _, th in ipairs(list) do
      local theme = Q.Themes:Get(th.key)
      t.eq(theme.key, th.key)
      for _, role in ipairs({ "title", "body", "dim", "distance" }) do
        t.eq(#Q.Themes:TextColor(role, theme), 3, th.key .. " " .. role)
      end
      t.ok(theme.background and theme.shadow and theme.bar, th.key .. " complete")
    end
  end,

  french_labels = function(t)
    Mock.locale = "frFR"
    local Q = load()
    local labels = {}
    for i, th in ipairs(Q.Themes:List()) do labels[i] = th.label end
    t.eq(labels, { "Parchemin", "Noir", "Transparent", "Fondu de gris" })
  end,

  each_theme_applies_without_error = function(t)
    local Q = load()
    local expected = { parchment = "atlas", dark = "color", transparent = "none", gradient = "color" }
    for _, th in ipairs(Q.Themes:List()) do
      local f, log = spyFrame()
      local theme = Q.Themes:Apply(f, th.key, 0.9)
      t.eq(theme.key, th.key)
      t.eq(f.qvThemeBackground, expected[th.key], th.key .. " background")
      if th.key == "transparent" then
        t.eq(#log.SetBackdrop, 1)
        t.eq(log.SetBackdrop[1][1], nil, "no border")
        t.ok(not f.qvThemeBg:IsShown() and not f.qvThemeGradient:IsShown(), "no background")
      else
        t.ok(f.qvThemeBg:IsShown() or f.qvThemeGradient:IsShown(), th.key .. " background shown")
      end
      -- puis sur le suivi lui-même
      Q.Settings:Set("tracker.theme", th.key)
      t.eq(Q.UI.Tracker.themeKey, th.key)
      t.eq(Q.UI.Tracker.frame.qvThemeKey, th.key)
    end
    t.eq(#Mock.errors, 0)
  end,

  borders_use_backdrop_edge_only = function(t)
    local Q = load()
    for _, key in ipairs({ "parchment", "dark" }) do
      local f, log = spyFrame()
      Q.Themes:Apply(f, key, 1)
      local info = last(log.SetBackdrop)[1]
      t.eq(info.edgeFile, "Interface\\Tooltips\\UI-Tooltip-Border", key)
      t.eq(info.bgFile, nil, "background is a separate texture")
    end
    local f, log = spyFrame()
    Q.Themes:Apply(f, "gradient", 1)
    t.eq(last(log.SetBackdrop)[1], nil, "gradient: no border")
  end,

  opacity_changes_only_background_alpha = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    local f = T.frame
    local log = spy(f, { "SetBackdropBorderColor", "SetAlpha" }, {})
    local title, body = color(T.title), color(T.currentText)
    local text = T.currentText:GetText()
    Q.Settings:Set("tracker.opacity", 0.4)
    t.eq(f.qvThemeBg:GetAlpha(), 0.4, "background alpha")
    local border = last(log.SetBackdropBorderColor)
    t.near(border[4], 0.4, 0.0001, "border alpha follows")
    t.eq(#log.SetAlpha, 0, "frame alpha untouched")
    t.eq(f:GetAlpha(), 1)
    t.eq(color(T.title), title, "title colour unchanged")
    t.eq(color(T.currentText), body, "body colour unchanged")
    t.eq(color(T.currentText)[4], 1, "text fully opaque")
    t.eq(T.currentText:GetText(), text, "text unchanged")
    -- hors bornes : ramené entre 0 et 1
    Q.Settings:Set("tracker.opacity", 3)
    t.eq(f.qvThemeBg:GetAlpha(), 1)
    Q.Settings:Set("tracker.opacity", -1)
    t.eq(f.qvThemeBg:GetAlpha(), 0)
    Q.Settings:Set("tracker.opacity", "junk")
    t.eq(f.qvThemeBg:GetAlpha(), 0.9, "unreadable value: default")
    t.eq(#Mock.errors, 0)
  end,

  invalid_key_falls_back_to_parchment = function(t)
    local Q = load()
    t.eq(Q.Themes:Get("nope").key, "parchment")
    t.eq(Q.Themes:Get(nil).key, "parchment")
    t.eq(Q.Themes:Get(42).key, "parchment")
    t.eq(Q.Themes:Find("nope"), nil)
    local f = spyFrame()
    t.eq(Q.Themes:Apply(f, "nope", 0.5).key, "parchment")
    t.eq(f.qvThemeKey, "parchment")
    Q.Settings:Set("tracker.theme", "dark")
    Q.Settings:Set("tracker.theme", "nope")
    t.eq(Q.UI.Tracker.themeKey, "parchment", "tracker back on parchment")
    t.eq(#Mock.errors, 0)
  end,

  setting_change_reapplies_live = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    local th = Q.Themes
    -- parchemin : encre brune, noms de quête en ambre foncé, pas d'ombre
    t.eq(color(T.currentText), { 0.17, 0.10, 0.03, 1 })
    t.ok(T.currentText:GetText():find("|cff7a3d00Dwarven Outfitters", 1, true), "quest name darkened")
    t.ok(not T.currentText:GetText():find("|cffffd100", 1, true))
    local spied = spy(T.title, { "SetShadowColor" }, {})
    Q.Settings:Set("tracker.theme", "dark")
    t.eq(T.themeKey, "dark")
    t.eq(T.frame.qvThemeBackground, "color")
    t.eq(color(T.title), { 1, 0.82, 0, 1 }, "light title")
    t.eq(color(T.currentText), { 1, 1, 1, 1 }, "light body")
    t.eq(color(T.nextLines[1].text), { 0.5, 0.5, 0.5, 1 }, "grey next steps")
    t.ok(T.currentText:GetText():find("|cffffd100Dwarven Outfitters", 1, true), "original quest colour")
    t.eq(last(spied.SetShadowColor)[4], 1, "shadow on")
    Q.Settings:Set("tracker.theme", "parchment")
    t.ok(T.currentText:GetText():find("|cff7a3d00Dwarven Outfitters", 1, true), "back to parchment")
    t.eq(last(spied.SetShadowColor)[4], 0, "no shadow on parchment")
    -- lignes créées après le changement de thème : déjà aux couleurs du thème
    Q.Settings:Set("tracker.theme", "dark")
    local chunk = T:TextChunk(#T.textChunks + 1)
    t.eq(color(chunk), { 1, 1, 1, 1 })
    t.eq(#Mock.errors, 0)
  end,

  unchanged_settings_do_not_reapply = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    t.eq(T:ApplyTheme(), false, "nothing changed")
    Q.Settings:Set("tracker.nextSteps", 2)
    t.eq(T.themeKey, "parchment")
    t.eq(T:ApplyTheme(true), true, "forced")
  end,

  recolor_maps_codes_on_parchment_only = function(t)
    local Q = load()
    local th = Q.Themes
    local s = "Accept |cffffd100Quest|r from |cff00ff96Npc|r, kill |cFFFF6060Mob|r"
    t.eq(th:Recolor(s, th:Get("dark")), s, "dark: identity")
    t.eq(th:Recolor(s, th:Get("transparent")), s)
    t.eq(th:Recolor(s, th:Get("parchment")),
      "Accept |cff7a3d00Quest|r from |cff00663aNpc|r, kill |cffa31414Mob|r")
    t.eq(th:Recolor("plain text", th:Get("parchment")), "plain text")
    t.eq(th:Recolor("|cff123456odd|r", th:Get("parchment")), "|cff123456odd|r", "unknown code kept")
    t.eq(th:Recolor(nil), nil)
  end,

  gradient_uses_set_gradient_and_create_color = function(t)
    local Q = load()
    CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end
    local f, log = spyFrame()
    Q.Themes:Apply(f, "gradient", 0.5)
    t.eq(f.qvThemeBackground, "gradient")
    local tlog = log.textures[f.qvThemeGradient]
    local call = last(tlog.SetGradient)
    t.eq(call[1], "VERTICAL")
    t.eq(call[2].a, 0, "transparent at the bottom")
    t.eq(call[3].a, 1, "dark grey at the top")
    t.ok(call[3].r < 0.2, "dark grey")
    t.eq(last(tlog.SetColorTexture), { 1, 1, 1, 1 }, "white texture")
    t.eq(f.qvThemeGradient:GetAlpha(), 0.5, "opacity on the gradient")
    t.ok(not f.qvThemeBg:IsShown(), "solid background hidden")
    t.eq(#Mock.errors, 0)
  end,

  missing_atlas_falls_back_to_colour = function(t)
    local Q = load()
    C_Texture = { GetAtlasInfo = function() return nil end }
    local f, log = spyFrame()
    Q.Themes:Apply(f, "parchment", 0.9)
    t.eq(f.qvThemeBackground, "color")
    local tlog = log.textures[f.qvThemeBg]
    t.eq(#tlog.SetAtlas, 0, "atlas not set")
    local c = last(tlog.SetColorTexture)
    t.ok(c and c[1] > 0.8 and c[3] < c[1], "parchment-like colour")
    t.ok(f.qvThemeBg:IsShown())
    t.eq(f.qvThemeBg:GetAlpha(), 0.9)
    -- API en erreur : même repli
    C_Texture = { GetAtlasInfo = function() error("boom") end }
    Q.Themes:Apply(f, "parchment", 0.9)
    t.eq(f.qvThemeBackground, "color")
    -- atlas présent : utilisé
    C_Texture = { GetAtlasInfo = function(name) return name == "QuestBG-Parchment" and { width = 1 } or nil end }
    Q.Themes:Apply(f, "parchment", 0.9)
    t.eq(f.qvThemeBackground, "atlas")
    t.eq(last(tlog.SetAtlas)[1], "QuestBG-Parchment")
    -- sur le suivi
    C_Texture = { GetAtlasInfo = function() return nil end }
    Q.Settings:Set("tracker.theme", "dark")
    Q.Settings:Set("tracker.theme", "parchment")
    t.eq(Q.UI.Tracker.frame.qvThemeBackground, "color")
    t.eq(#Mock.errors, 0)
  end,

  transparent_outlines_text_and_restores_font = function(t)
    local Q = load()
    local fs = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rawset(fs, "GetFont", function() return "Fonts\\FRIZQT__.TTF", 12, "" end)
    local log = spy(fs, { "SetFont", "SetShadowOffset" }, {})
    Q.Themes:StyleText(fs, "body", Q.Themes:Get("transparent"))
    t.eq(last(log.SetFont), { "Fonts\\FRIZQT__.TTF", 12, "OUTLINE" })
    t.eq(last(log.SetShadowOffset), { 1, -1 })
    Q.Themes:StyleText(fs, "body", Q.Themes:Get("dark"))
    t.eq(last(log.SetFont), { "Fonts\\FRIZQT__.TTF", 12, "" }, "outline removed")
    local n = #log.SetFont
    Q.Themes:StyleText(fs, "title", Q.Themes:Get("gradient"))
    t.eq(#log.SetFont, n, "same flags: font left alone")
  end,

  alert_glows_blend_per_theme = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    local log = spy(T.glows[1], { "SetBlendMode" }, {})
    Q.Settings:Set("tracker.theme", "dark")
    t.eq(last(log.SetBlendMode)[1], "ADD")
    Q.Settings:Set("tracker.theme", "parchment")
    t.eq(last(log.SetBlendMode)[1], "BLEND", "visible on a light background")
  end,

  slash_theme = function(t)
    local Q = load()
    qf("theme dark")
    t.eq(Q.Settings:Get("tracker.theme"), "dark")
    t.eq(Q.UI.Tracker.themeKey, "dark")
    t.ok(Mock.printed(string.format(Q.L.UI_SLASH_THEME_SET, "Black")))
    qf("theme  Grey Fade ")
    t.eq(Q.Settings:Get("tracker.theme"), "gradient", "by label, any case")
    qf("theme bogus")
    t.eq(Q.Settings:Get("tracker.theme"), "gradient", "unknown: unchanged")
    t.ok(Mock.printed('Unknown theme "bogus"'))
    qf("theme")
    t.ok(Mock.printed("parchment (Parchment), dark (Black), transparent (Transparent), gradient (Grey fade)"))
    t.ok(Mock.printed("Current theme: Grey fade"))
    t.ok(Q.L.UI_SLASH_HELP:find("/qf theme", 1, true), "in the help")
    t.eq(#Mock.errors, 0)
  end,

  slash_opacity = function(t)
    local Q = load()
    local T = Q.UI.Tracker
    qf("opacity 50")
    t.eq(Q.Settings:Get("tracker.opacity"), 0.5)
    t.eq(T.frame.qvThemeBg:GetAlpha(), 0.5, "applied live")
    t.ok(Mock.printed(string.format(Q.L.UI_SLASH_OPACITY_SET, 50)))
    qf("opacity 75%")
    t.eq(Q.Settings:Get("tracker.opacity"), 0.75)
    qf("opacity 150")
    t.eq(Q.Settings:Get("tracker.opacity"), 1)
    qf("opacity -5")
    t.eq(Q.Settings:Get("tracker.opacity"), 0)
    qf("opacity")
    t.ok(Mock.printed(string.format(Q.L.UI_SLASH_OPACITY_HELP, 0)), "current value")
    qf("opacity abc")
    t.eq(Q.Settings:Get("tracker.opacity"), 0, "unchanged")
    t.ok(Q.L.UI_SLASH_HELP:find("/qf opacity", 1, true), "in the help")
    t.eq(#Mock.errors, 0)
  end,
}
