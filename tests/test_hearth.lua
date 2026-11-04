-- Tests de la pierre de foyer dans le suivi (Q.Hearth, Engine/Hearth.lua).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_comfort.lua")

local function load()
  Ext.install()
  return Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
end

local function plain(s) return (tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

-- Étape courante « hearth » vers Dun Morogh ; le foyer a été lié en (40, 50) juste avant.
local function hearthStep(Q)
  Q.Progress:InsertSteps("test", { { "sethearth", 1426, 40, 50 }, { "hearth", 1426 } })
  Q.Progress:MarkDone("i:test:1")
  local cur = Q.Progress:Current()
  assert(cur and cur.step.action == "hearth", "current step is hearth")
  return cur
end

-- Pierre en recharge : encore `left` secondes.
local function cooldown(left)
  Mock.advance(10)
  Mock.comfort.cooldown = { start = Mock.now, duration = left, enable = 1 }
end

local function trackerText(Q)
  local parts = {}
  for _, chunk in ipairs(Q.UI.Tracker.textChunks) do
    if chunk:IsShown() then parts[#parts + 1] = plain(chunk:GetText()) end
  end
  return table.concat(parts, "\n")
end

local function has(text, s) return text:find(s, 1, true) ~= nil end

return {
  ready_stone_shown_on_hearth_step = function(t)
    local Q = load()
    local cur = hearthStep(Q)
    t.eq(Q.Hearth:Remaining(), 0)
    local lines = Q.Hearth:Lines(cur)
    t.eq(#lines, 1)
    t.eq(plain(lines[1]), Q.L.COMFORT_HEARTH_READY)
    t.ok(has(trackerText(Q), Q.L.COMFORT_HEARTH_READY), "tracker shows the stone state")
    t.eq(#Mock.errors, 0)
  end,

  cooldown_and_walking_hint = function(t)
    local Q = load()
    local cur = hearthStep(Q)
    cooldown(30 * 60)
    local lines = Q.Hearth:Lines(cur)
    t.eq(plain(lines[1]), string.format(Q.L.COMFORT_HEARTH_WAIT, "30 min"))
    -- joueur en (29.9, 71.2), foyer en (40, 50) : environ 855 yards, 3 minutes à 7 yd/s
    t.ok(lines[2], "hint line")
    t.ok(has(plain(lines[2]), "3 min"), "walk time: " .. plain(lines[2]))
    t.ok(has(plain(lines[2]), "yd"), "distance")
    Mock.fire("BAG_UPDATE_COOLDOWN")
    t.ok(has(trackerText(Q), "30 min"), "tracker refreshed")
  end,

  no_hint_when_ready_soon = function(t)
    local Q = load()
    local cur = hearthStep(Q)
    cooldown(90)
    local lines = Q.Hearth:Lines(cur)
    t.eq(#lines, 1, "countdown only")
    t.eq(plain(lines[1]), string.format(Q.L.COMFORT_HEARTH_WAIT, "2 min"))
  end,

  known_flight_path_near_destination = function(t)
    local Q = load()
    local cur = hearthStep(Q)
    cooldown(40 * 60)
    Mock.player.x, Mock.player.y = 95, 5   -- loin : plus de 5 minutes à pied
    Mock.comfort.mapNodes[1426] = { { name = "Kharanos, Dun Morogh", x = 0.41, y = 0.51, faction = 2 } }
    local lines = Q.Hearth:Lines(cur)
    t.eq(plain(lines[2]), string.format(Q.L.COMFORT_HEARTH_FLY, "Kharanos, Dun Morogh"))
    -- point de vol inconnu ou de l'autre faction : conseil de marche
    Mock.comfort.mapNodes[1426] = { { name = "Kharanos, Dun Morogh", x = 0.41, y = 0.51, undiscovered = true },
      { name = "Horde camp", x = 0.40, y = 0.50, faction = 1 } }
    lines = Q.Hearth:Lines(cur)
    t.ok(has(plain(lines[2]), "km"), "walking hint: " .. plain(lines[2]))
  end,

  countdown_refreshes_the_tracker = function(t)
    local Q = load()
    hearthStep(Q)
    cooldown(20)
    Mock.fire("BAG_UPDATE_COOLDOWN")
    t.ok(has(trackerText(Q), string.format(Q.L.COMFORT_HEARTH_WAIT, Q.L.COMFORT_LESS_MINUTE)), trackerText(Q))
    Mock.advance(30)   -- le minuteur (5 s) voit la pierre prête
    t.ok(has(trackerText(Q), Q.L.COMFORT_HEARTH_READY), "ready after the cooldown")
    t.eq(#Mock.errors, 0)
  end,

  sethearth_shows_current_home = function(t)
    local Q = load()
    Mock.player.bind = "Kharanos"
    Q.Progress:InsertSteps("test", { { "sethearth", 1426, 40, 50 } })
    local cur = Q.Progress:Current()
    t.eq(plain(Q.Hearth:Lines(cur)[1]), string.format(Q.L.COMFORT_HEARTH_BIND, "Kharanos"))
    t.ok(has(trackerText(Q), "Kharanos"))
  end,

  other_steps_and_option_off = function(t)
    local Q = load()
    t.eq(Q.Hearth:Lines(Q.Progress:Current()), nil, "accept step")
    local cur = hearthStep(Q)
    Q.Settings:Set("hearthHints", false)
    t.eq(Q.Hearth:Lines(cur), nil)
    t.ok(not has(trackerText(Q), Q.L.COMFORT_HEARTH_READY), "tracker without the line")
  end,

  no_stone_in_bags = function(t)
    local Q = load()
    local cur = hearthStep(Q)
    Mock.comfort.itemCount[6948] = 0
    t.eq(Q.Hearth:Lines(cur), nil)
  end,

  works_in_combat = function(t)
    local Q = load()
    local cur = hearthStep(Q)
    Mock.player.combat = true
    cooldown(30 * 60)
    Mock.fire("BAG_UPDATE_COOLDOWN")
    t.ok(Q.Hearth:Lines(cur)[1], "display only, allowed in combat")
    t.eq(#Mock.errors, 0)
  end,

  missing_api_is_silent = function(t)
    local Q = load()
    local cur = hearthStep(Q)
    C_Container.GetItemCooldown = nil
    C_Item.GetItemCooldown = nil
    GetItemCooldown = nil
    C_Item.GetItemCount = nil
    GetBindLocation = nil
    C_TaxiMap = nil
    t.eq(Q.Hearth:Lines(cur), nil)
    Mock.advance(10)
    Q.Progress:InsertSteps("test", { { "sethearth", 1426, 40, 50 } })
    t.eq(Q.Hearth:Lines(Q.Progress:Current()), nil)
    t.eq(#Mock.errors, 0)
  end,

  secret_values_are_ignored = function(t)
    local Q = load()
    local cur = hearthStep(Q)
    Mock.comfort.cooldown = { start = Mock.strictSecret(5), duration = Mock.strictSecret(3600), enable = 1 }
    t.eq(Q.Hearth:Lines(cur), nil)
    Mock.comfort.itemCount[6948] = Mock.strictSecret(1)
    Mock.comfort.cooldown = { start = 0, duration = 0, enable = 1 }
    t.eq(#Q.Hearth:Lines(cur), 1, "secret count: still shown")
    GetBindLocation = function() return Mock.strictSecret("Kharanos") end
    Q.Progress:InsertSteps("test", { { "sethearth", 1426, 40, 50 } })
    t.eq(Q.Hearth:Lines(Q.Progress:Current()), nil)
    Mock.advance(10)
    t.eq(#Mock.errors, 0)
  end,

  without_questiedb_does_nothing = function(t)
    Mock.addons.QuestieDB = false
    local Q = load()
    t.eq(Q.Hearth:Lines({ key = "x", step = { action = "hearth", mapId = 1426 } }), nil)
    Mock.fire("BAG_UPDATE_COOLDOWN")
    Mock.advance(10)
    t.eq(#Mock.errors, 0)
  end,
}
