-- Tests du bouton de la minicarte (UI/MinimapButton.lua) : icône du profil de butin, menu des
-- choix rapides, angle gardé, option.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function ext() return dofile(Mock.root .. "/tests/mock_ext_specrole.lua") end

-- opts.spec : API de spécialisation ; opts.menu : MenuUtil factice.
local function load(classFile, opts)
  opts = opts or {}
  local Ext = ext()
  Mock.player.classFile = classFile or "SHAMAN"
  Mock.player.level = opts.level or 20
  if opts.spec then Ext.install() end
  if opts.menu then Ext.installMenu() end
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES } })
  return Q, Ext
end

local function noErrors(t)
  t.eq(#Mock.errors, 0, "no errors: " .. tostring(Mock.errors[1]))
end

local function keys(list, field)
  local out = {}
  for i, e in ipairs(list) do out[i] = e[field or "data"] end
  return out
end

return {
  button_on_the_minimap_shows_the_role_icon = function(t)
    local Q = load("SHAMAN")
    local B = Q.UI.MinimapButton
    local b = B.button
    t.ok(b and b:IsShown(), "created at login")
    t.eq(b:GetParent(), Minimap)
    t.eq({ b:GetSize() }, { 31, 31 })
    t.eq(B.border:GetTexture(), "Interface\\Minimap\\MiniMap-TrackingBorder")
    t.eq(B.background:GetTexture(), "Interface\\Minimap\\UI-Minimap-Background")
    t.eq(B.icon:GetTexture(), B.ICONS.auto)
    t.ok(B:SelectRole("caster"))
    t.eq(B.icon:GetTexture(), B.ICONS.caster, "built-in icon without the spec API")
    Q.Rewards:SetRole("melee")
    t.eq(B.icon:GetTexture(), B.ICONS.melee, "follows a change made elsewhere")
    noErrors(t)
  end,

  spec_icon_used_when_the_api_gives_it = function(t)
    local Q = load("SHAMAN", { spec = true })
    local B = Q.UI.MinimapButton
    B:SelectRole("caster")
    t.eq(B.icon:GetTexture(), 136048, "Elemental icon")
    B:SelectRole("healer")
    t.eq(B.icon:GetTexture(), 136052, "Restoration icon")
    B:SelectRole("auto")
    t.eq(B.icon:GetTexture(), B.ICONS.auto)
    noErrors(t)
  end,

  tooltip_shows_the_current_role = function(t)
    local Q = load("SHAMAN")
    local B = Q.UI.MinimapButton
    B:SelectRole("caster")
    local lines = B:TooltipLines()
    t.eq(lines[1], "Questify")
    t.eq(lines[2], string.format(Q.L.MINIMAP_TIP_ROLE, Q.L.REWARD_SPEC_SHAMAN_CASTER))
    t.eq(lines[3], Q.L.MINIMAP_TIP_LEFT)
    t.eq(#lines, 6)
    B.button._scripts.OnEnter(B.button)
    noErrors(t)
  end,

  menu_has_role_entries_toggles_and_actions = function(t)
    local Q, Ext = load("SHAMAN", { menu = true })
    local B = Q.UI.MinimapButton
    Q.Rewards:SetRole("melee")
    Mock.click(B.button, "LeftButton")
    t.eq(Mock.countCalls("MenuUtil.CreateContextMenu"), 1)
    t.eq(Mock.lastMenu.owner, B.button)
    local titles = Ext.menuElements("title")
    t.eq(titles[1].text, "Questify")
    t.eq(titles[2].text, Q.L.MINIMAP_MENU_LOOT)
    local radios = Ext.menuElements("radio")
    t.eq(keys(radios), { "auto", "caster", "melee", "healer" }, "only the class profiles")
    t.eq(radios[2].text, Q.L.REWARD_SPEC_SHAMAN_CASTER)
    for _, r in ipairs(radios) do t.eq(r.isSelected(r.data), r.data == "melee", "checked: " .. r.data) end
    t.eq(keys(Ext.menuElements("checkbox")), { "autoQuest", "autoReward", "zoneMode", "mapPins" })
    t.eq(keys(Ext.menuElements("button")), { "options", "journal", "wizard", "bug" })
    t.eq(Ext.menuElements("button", "options")[1].text, Q.L.MINIMAP_MENU_OPTIONS)
    t.ok(#Ext.menuElements("divider") >= 1)
    noErrors(t)
  end,

  single_profile_class_menu_lists_its_profile = function(t)
    local Q, Ext = load("ROGUE", { menu = true })
    local B = Q.UI.MinimapButton
    t.ok(B:IsShown(), "button kept for journal access")
    Mock.click(B.button, "LeftButton")
    t.eq(keys(Ext.menuElements("radio")), { "auto", "melee" })
    noErrors(t)
  end,

  selecting_a_role_changes_the_setting_and_icon = function(t)
    local Q, Ext = load("SHAMAN", { menu = true })
    local B = Q.UI.MinimapButton
    Mock.click(B.button, "LeftButton")
    local healer = Ext.menuElements("radio", "healer")[1]
    healer.setSelected(healer.data)
    t.eq(Q.Rewards:Role(), "healer")
    t.eq(B.icon:GetTexture(), B.ICONS.healer)
    t.ok(Mock.printed(string.format(Q.L.MINIMAP_ROLE_SET, Q.L.REWARD_SPEC_SHAMAN_HEALER)), "confirmation line")
    t.ok(healer.isSelected(healer.data))
    noErrors(t)
  end,

  a_toggle_flips_its_setting = function(t)
    local Q, Ext = load("SHAMAN", { menu = true })
    local B = Q.UI.MinimapButton
    local seen = {}
    Q:On("SETTINGS_CHANGED", function(path, value) seen[#seen + 1] = path .. "=" .. tostring(value) end)
    Mock.click(B.button, "LeftButton")
    for _, def in ipairs(B.TOGGLES) do
      local cb = Ext.menuElements("checkbox", def[1])[1]
      t.ok(cb.isSelected(cb.data), def[1] .. " on by default")
      cb.setSelected(cb.data)
      t.eq(Q.Settings:Get(def[1]), false, def[1] .. " off")
      t.ok(not cb.isSelected(cb.data))
      cb.setSelected(cb.data)
      t.eq(Q.Settings:Get(def[1]), true, def[1] .. " back on")
    end
    t.eq(seen[1], "autoQuest=false", "goes through Q.Settings:Set")
    noErrors(t)
  end,

  options_entry_opens_the_options_window = function(t)
    local Q, Ext = load("SHAMAN", { menu = true })
    local B = Q.UI.MinimapButton
    Mock.click(B.button, "LeftButton")
    Ext.menuElements("button", "options")[1].setSelected()
    local O = Q.UI.Options
    t.ok(QuestifyOptions and QuestifyOptions:IsShown(), "options window open")
    O:SelectSection("map")
    t.ok(O:Widget("minimapButton").check, "option checkbox in the options window")
    local J = Q.UI.Journal
    Ext.menuElements("button", "journal")[1].setSelected()
    t.eq(J.tab, "route")
    local opened = {}
    Q.UI.Wizard = { Show = function() opened[#opened + 1] = "wizard" end }
    Q.UI.Report = { Show = function() opened[#opened + 1] = "report" end }
    Ext.menuElements("button", "wizard")[1].setSelected()
    Ext.menuElements("button", "bug")[1].setSelected()
    t.eq(opened, { "wizard", "report" })
    noErrors(t)
  end,

  right_click_toggles_the_journal_and_ctrl_click_opens_the_wizard = function(t)
    local Q = load("SHAMAN", { menu = true })
    local B = Q.UI.MinimapButton
    local J = Q.UI.Journal
    Mock.click(B.button, "RightButton")
    t.ok(J:IsShown())
    Mock.click(B.button, "RightButton")
    t.ok(not J:IsShown())
    local opened = 0
    Q.UI.Wizard = { Show = function() opened = opened + 1 end }
    Mock.player.ctrl = true
    Mock.click(B.button, "LeftButton")
    Mock.player.ctrl = false
    t.eq(opened, 1)
    t.eq(Mock.countCalls("MenuUtil.CreateContextMenu"), 0, "no menu on ctrl+click")
    noErrors(t)
  end,

  angle_persists_and_drag_moves_the_button = function(t)
    local Q, Ext = load("SHAMAN", { spec = true })
    local B = Q.UI.MinimapButton
    B:SetAngle(90)
    t.eq(QuestifyDB.minimapAngle, 90)
    local p, rel, rp, x, y = B.button:GetPoint(1)
    t.eq({ p, rel, rp }, { "CENTER", Minimap, "CENTER" })
    t.near(x, 0, 1e-6); t.ok(y > 50, "above the centre")
    -- glisser : le curseur sous le centre de la minicarte
    Mock.cursor = { x = 0, y = -100 }
    B.button._scripts.OnDragStart(B.button)
    t.ok(B.button._scripts.OnUpdate ~= nil)
    B.button._scripts.OnUpdate(B.button, 0.1)
    B.button._scripts.OnDragStop(B.button)
    t.near(QuestifyDB.minimapAngle, 270, 1e-6)
    t.ok(not B.dragging)
    -- /reload : même angle
    local Q2 = Mock.reload()
    Ext.reinstall()
    local B2 = Q2.UI.MinimapButton
    t.near(B2:Angle(), 270, 1e-6)
    local _, _, _, x2, y2 = B2.button:GetPoint(1)
    t.near(x2, 0, 1e-6); t.ok(y2 < -50, "below the centre after reload")
    noErrors(t)
  end,

  option_hides_the_button = function(t)
    local Q = load("SHAMAN")
    local B = Q.UI.MinimapButton
    t.ok(B:IsShown())
    Q.Settings:Set("minimapButton", false)
    t.ok(not B:IsShown())
    Mock.player.combat = true
    Q.Settings:Set("minimapButton", true)
    t.ok(B:IsShown(), "showing in combat is safe: the button is not secure")
    Mock.player.combat = false
    -- option coupée avant la connexion : pas de bouton
    Q.Settings:Set("minimapButton", false)
    local Q2 = Mock.reload()
    t.ok(not Q2.UI.MinimapButton:IsShown())
    noErrors(t)
  end,

  fallback_menu_without_menuutil = function(t)
    local Q = load("SHAMAN")
    local B = Q.UI.MinimapButton
    t.eq(MenuUtil, nil)
    t.eq(B:OpenMenu(), "fallback")
    local menu = B.fallback
    t.ok(menu:IsShown())
    local byKey = {}
    for _, row in ipairs(menu.rows) do
      if row.entry and row.entry.key then byKey[row.entry.key] = row end
    end
    t.ok(byKey.caster and byKey.autoQuest and byKey.options, "roles, toggles and actions")
    Mock.click(byKey.autoQuest, "LeftButton")
    t.eq(Q.Settings:Get("autoQuest"), false)
    t.ok(menu:IsShown(), "stays open after a toggle")
    Mock.click(byKey.caster, "LeftButton")
    t.eq(Q.Rewards:Role(), "caster")
    t.ok(not menu:IsShown(), "closes after a choice")
    noErrors(t)
  end,
}
