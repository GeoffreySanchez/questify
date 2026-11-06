-- Tests du choix de suite : champs choices et sim des guides (Engine/Guides.lua), cartes et
-- recommandation (Engine/RouteChoice.lua), pause de la bascule et choix (Engine/Progress.lua), popup
-- (UI/RouteChoicePopup.lua) et /qf route.
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function load(opts)
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  if opts.skipGuides == nil then opts.skipGuides = true end
  return Mock.loadAddon(TOC, opts)
end

-- Loch Modan (fin à Stormwind) -> Marche de l'Ouest (défaut, Nain/Gnome) ou Sombrivage, chiffres de la
-- simulation réelle (A_DwarfGnome_03 / _04, A_01).
local function setup(Q, extra)
  extra = extra or {}
  Q:RegisterGuide({ id = "T_FROM", title = "Loch Modan", faction = "Alliance", races = { "Dwarf", "Gnome" },
    minLevel = 11, maxLevel = 14, next = "T_WEST",
    choices = {
      { id = "T_WEST", travel = { kind = "walk", minutes = 3 } },
      { id = "T_DARK", travel = { kind = "boat", minutes = 6 } },
    },
    sim = { steps = 2, endLevel = 15.55, xpPerHour = 21188, minutes = 119 },
    steps = { { "note", "first" }, { "note", "last" } } })
  Q:RegisterGuide({ id = "T_WEST", title = "Westfall", faction = "Alliance", races = { "Dwarf", "Gnome" },
    minLevel = 14, maxLevel = 16, sim = { steps = 45, endLevel = 17.05, xpPerHour = 18038, minutes = 78 },
    steps = { { "accept", 179 }, { "turnin", 179, xp = 500 } } })
  Q:RegisterGuide({ id = "T_DARK", title = "Darkshore", faction = "Alliance",
    minLevel = 16, maxLevel = 19, sim = { steps = 119, endLevel = 19.9, xpPerHour = 26898, minutes = 158 },
    steps = { { "accept", 233 }, { "turnin", 233, xp = 900 }, { "turnin", 170, xp = 100 } } })
  if extra.level then
    Mock.player.level = extra.level
    Mock.fire("PLAYER_LEVEL_UP", extra.level)
  end
  Q.Progress:SetGuide("T_FROM")
end

-- Passe toutes les étapes du chapitre courant (la dernière le finit).
local function finish(Q)
  local keys = {}
  for _, e in ipairs(Q.Progress:Entries()) do
    if e.source == "guide" then keys[#keys + 1] = e.key end
  end
  for _, k in ipairs(keys) do Q.Progress:Skip(k) end
end

local function popup(Q) return Q.UI.RouteChoicePopup end

local RC_FIXTURE = "tests/fixtures/routechoice_fixture.lua"

-- Loch Modan fini au niveau 16 (fixture chargée comme fichier : elle survit à Mock.reload) ; la
-- demande de choix part. opts.combat : en combat à la fin du chapitre ; opts.before(Q) : avant la fin.
local function ready(opts)
  opts = opts or {}
  local Q = load({ extraFiles = { GUIDES, RC_FIXTURE }, beforeLogin = opts.beforeLogin })
  Mock.player.level = opts.level or 16
  Mock.fire("PLAYER_LEVEL_UP", Mock.player.level)
  Q.Progress:SetGuide("T_FROM")
  if opts.before then opts.before(Q) end
  if opts.combat then Mock.player.combat = true end
  finish(Q)
  Mock.advance(0)
  return Q, popup(Q)
end

local function press(P, key)
  local fn = P.frame:GetScript("OnKeyDown")
  fn(P.frame, key)
end

local function enterCombat()
  Mock.player.combat = true
  Mock.fire("PLAYER_REGEN_DISABLED")
end

local function leaveCombat()
  Mock.player.combat = false
  Mock.fire("PLAYER_REGEN_ENABLED")
end

local function shownCards(P)
  local n = 0
  for _, c in ipairs(P.cardFrames) do if c.frame:IsShown() then n = n + 1 end end
  return n
end

local function dismissed(Q, id)
  return type(Q.char.routeChoiceDismissed) == "table" and Q.char.routeChoiceDismissed[id] or nil
end

local function noErrors(t)
  for _, e in ipairs(Mock.errors) do t.ok(false, "error: " .. tostring(e)) end
end

return {
  -- RegisterGuide valide choices (1 à 4 entrées, id, trajet connu) et sim (nombres).
  register_validates_choices_and_sim = function(t)
    local Q = load()
    local function reg(def)
      def.id = def.id or "T_X"
      def.steps = def.steps or { { "note", "x" } }
      return Q:RegisterGuide(def)
    end
    t.eq(reg({ choices = { { id = "A" }, { id = "B" }, { id = "C" }, { id = "D" }, { id = "E" } } }), false, "5 entries")
    t.eq(reg({ choices = { { label = "no id" } } }), false, "missing id")
    t.eq(reg({ choices = { { id = "A", travel = { kind = "teleporter" } } } }), false, "unknown travel kind")
    t.eq(reg({ choices = { { id = "A", races = { 4 } } } }), false, "races not strings")
    t.eq(reg({ sim = { xpPerHour = "fast" } }), false, "sim not a number")
    t.eq(reg({ choices = "A" }), false, "choices not a list")
    t.ok(reg({ id = "T_OK", choices = { { id = "A", travel = { kind = "boat", minutes = 6 }, weight = 0.7 } },
      sim = { steps = 3, endLevel = 12.5, xpPerHour = 9000, minutes = 30 } }))
    local g = Q.Guides:Get("T_OK")
    t.eq(g.choices[1].id, "A"); t.eq(g.choices[1].travel.kind, "boat"); t.eq(g.choices[1].weight, 0.7)
    t.eq(g.sim.xpPerHour, 9000)
  end,

  -- Suites possibles : ordre déclaré, suite par défaut marquée, filtre de race ; sans choices, la suite
  -- par défaut seule.
  choices_filter_and_default = function(t)
    local Q = load()
    setup(Q)
    local from = Q.Guides:Get("T_FROM")
    local opts = Q.Guides:Choices(from, "Dwarf", "Alliance")
    t.eq(#opts, 2)
    t.eq(opts[1].guide.id, "T_WEST"); t.eq(opts[1].default, true)
    t.eq(opts[2].guide.id, "T_DARK"); t.eq(opts[2].default, false)
    local human = Q.Guides:Choices(from, "Human", "Alliance")
    t.eq(#human, 1, "Westfall chapter is Dwarf/Gnome only")
    t.eq(human[1].guide.id, "T_DARK")
    t.eq(#Q.Guides:Choices(from, "Dwarf", "Horde"), 0, "other faction")
    local single = Q.Guides:Choices(Q.Guides:Get("A_DwarfGnome_01"), "Dwarf", "Alliance")
    t.eq(#single, 1); t.eq(single[1].guide.id, "A_DwarfGnome_02"); t.eq(single[1].default, true)
    t.eq(#Q.Guides:Choices(Q.Guides:Get("T_DARK"), "Dwarf", "Alliance"), 0, "end of route")
  end,

  -- Recommandation : le niveau compte (Sombrivage 16-19 trop haut au niveau 15), puis l'XP/h.
  rank_recommends_by_level_then_xp = function(t)
    local Q = load()
    setup(Q)
    local opts = Q.Progress:RouteOptions("T_FROM")
    local cards = Q.RouteChoice:Rank(opts, 15)
    t.eq(#cards, 2)
    t.eq(cards[1].id, "T_WEST"); t.eq(cards[1].recommended, true); t.eq(cards[1].reason, "level")
    t.eq(cards[2].recommended, nil); t.eq(cards[2].warning, "low")
    t.eq(cards[2].quests, 2); t.eq(cards[2].xp, 1000)
    t.eq(cards[2].minutes, 158); t.eq(cards[2].xpPerHour, 26898)
    t.eq(cards[2].travel.kind, "boat")
    cards = Q.RouteChoice:Rank(opts, 15.6)
    t.eq(cards[2].recommended, true, "Darkshore at 15.6")
    t.eq(cards[2].reason, "xp")
    -- égalité parfaite : la suite par défaut
    Q.Guides:Get("T_DARK").sim = nil
    Q.Guides:Get("T_WEST").sim = nil
    -- niveau 16 : dans les deux bandes (14-16 et 16-19), pas de trajet déclaré, pas de sim
    local tie = Q.RouteChoice:Rank({ { guide = Q.Guides:Get("T_DARK") }, { guide = Q.Guides:Get("T_WEST"), default = true } }, 16)
    t.eq(tie[2].recommended, true, "default wins a tie")
    t.eq(tie[2].reason, "default")
  end,

  -- Fin d'un chapitre à deux suites : on reste, aucune étape courante, une seule demande ; le choix fait
  -- passer à la suite et est gardé.
  finished_chapter_waits_for_the_choice = function(t)
    local Q = load()
    setup(Q, { level = 16 })
    local asked = 0
    Q:On("ROUTE_CHOICE_NEEDED", function() asked = asked + 1 end)
    finish(Q)
    t.eq(Q.Progress:Guide().id, "T_FROM", "stays on the finished chapter")
    t.eq(Q.Progress:PendingChoice(), "T_FROM")
    t.eq(Q.Progress:Current(), nil)
    Mock.advance(0)
    t.eq(asked, 1, "asked once")
    Mock.fire("QUEST_LOG_UPDATE")
    Mock.advance(1)
    t.eq(asked, 1, "not asked again")
    local P = popup(Q)
    t.ok(P:IsShown(), "popup shown")
    t.eq(#P.cards, 2)
    local rec = 0
    for _, c in ipairs(P.cards) do if c.recommended then rec = rec + 1 end end
    t.eq(rec, 1, "a single recommended card")
    P:Choose("T_DARK")
    t.ok(not P:IsShown())
    t.eq(Q.Progress:Guide().id, "T_DARK")
    t.eq(Q.Progress:PendingChoice(), nil)
    t.eq(Q.char.routeChoices.T_FROM, "T_DARK")
    t.eq(Q.char.routeChoiceLast, "T_FROM")
    t.eq(Mock.countPrinted(string.format(Q.L.ROUTE_NEXT, "Darkshore")), 1)
    noErrors(t)
  end,

  -- Choix déjà fait (d'avance ou au passage précédent) : pas de demande. Option coupée : la suite par
  -- défaut, sans demande.
  stored_choice_and_option_off = function(t)
    local Q = load()
    setup(Q)
    local asked = 0
    Q:On("ROUTE_CHOICE_NEEDED", function() asked = asked + 1 end)
    Q.char.routeChoices.T_FROM = "T_DARK"
    finish(Q)
    Mock.advance(0)
    t.eq(Q.Progress:Guide().id, "T_DARK"); t.eq(asked, 0)

    Mock.reset()
    Q = load()
    setup(Q)
    asked = 0
    Q:On("ROUTE_CHOICE_NEEDED", function() asked = asked + 1 end)
    Q.Settings:Set("route.choicePopup", false)
    finish(Q)
    Mock.advance(0)
    t.eq(Q.Progress:Guide().id, "T_WEST", "default route"); t.eq(asked, 0)
    t.ok(not popup(Q):IsShown())
    t.eq(Mock.countPrinted(string.format(Q.L.ROUTE_NEXT, "Westfall")), 1)
  end,

  -- « Plus tard » : le choix reste en attente, le suivi le dit, /qf route le rouvre ; « Garder la route
  -- prévue » prend la suite par défaut.
  later_then_slash_route_and_keep = function(t)
    local Q = load()
    setup(Q, { level = 16 })
    finish(Q)
    Mock.advance(0)
    local P = popup(Q)
    P:Hide()
    t.eq(Q.Progress:PendingChoice(), "T_FROM", "still waiting")
    SlashCmdList.QUESTIFY("route")
    t.ok(P:IsShown(), "/qf route reopens it")
    P:Keep()
    t.eq(Q.Progress:Guide().id, "T_WEST")
    noErrors(t)
  end,

  -- En combat : la popup attend la fin du combat.
  combat_defers_the_popup = function(t)
    local Q = load()
    setup(Q, { level = 16 })
    Mock.player.combat = true
    finish(Q)
    Mock.advance(0)
    local P = popup(Q)
    t.ok(not P:IsShown(), "not in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(P:IsShown(), "after combat")
    noErrors(t)
  end,

  -- Choix d'avance depuis le chapitre en cours, puis rechoix depuis le chapitre suivant (/qf route).
  choose_ahead_then_choose_again = function(t)
    local Q = load()
    setup(Q, { level = 16 })
    local P = popup(Q)
    SlashCmdList.QUESTIFY("route")
    t.ok(P:IsShown(), "choice of the current chapter")
    P:Choose("T_DARK")
    t.eq(Q.Progress:Guide().id, "T_FROM", "chapter not finished: stays")
    finish(Q)
    Mock.advance(0)
    t.eq(Q.Progress:Guide().id, "T_DARK", "the choice made ahead is used")
    t.ok(not P:IsShown(), "no question")
    SlashCmdList.QUESTIFY("route")
    t.ok(P:IsShown(), "reopened from the next chapter")
    t.eq(P.fromId, "T_FROM")
    P:Choose("T_WEST")
    t.eq(Q.Progress:Guide().id, "T_WEST")
    t.eq(Q.char.routeChoices.T_FROM, "T_WEST")
    noErrors(t)
  end,

  -- Guides livrés : après Loch Modan, la Marche de l'Ouest (défaut) ou Sombrivage. Au niveau de fin
  -- simulé (15,55), Sombrivage est conseillé pour son XP/h ; au niveau 15, la Marche de l'Ouest (niveau).
  shipped_branch_after_loch_modan = function(t)
    local Q = load({ extraFiles = {}, skipGuides = false })
    local opts = Q.Progress:RouteOptions("A_DwarfGnome_03")
    t.eq(#opts, 2)
    t.eq(opts[1].guide.id, "A_DwarfGnome_04"); t.eq(opts[1].default, true)
    t.eq(opts[2].guide.id, "A_01"); t.eq(opts[2].entry.travel.kind, "boat")
    local cards = Q.RouteChoice:Rank(opts, 15.55)
    t.eq(cards[2].recommended, true, "Darkshore at 15.55"); t.eq(cards[2].reason, "xp")
    t.ok(cards[2].quests > 0 and cards[2].xpPerHour and cards[2].minutes, "metrics from the guide")
    cards = Q.RouteChoice:Rank(opts, 15)
    t.eq(cards[1].recommended, true, "Westfall at 15"); t.eq(cards[1].reason, "level")
    t.eq(#Q.Progress:RouteOptions("A_DwarfGnome_02"), 1, "Dun Morogh: a single next chapter")
    noErrors(t)
  end,

  -- Fenêtre v2 : voile plein écran qui garde les clics, grande fenêtre, cartes hautes, une seule
  -- conseillée (liseré doré, halo animé, badge, raison en clair), points forts, chiffres.
  popup_window_and_cards = function(t)
    local Q, P = ready({ before = function(Q)
      Q.DungeonData = { { key = "DM", name = "The Deadmines", minLevel = 17, maxLevel = 26,
        factions = { "Alliance" }, entrance = { 1436, 42.6, 71.8 }, quests = {} } }
    end })
    t.ok(P:IsShown())
    t.ok(P.frame == QuestifyRouteChoicePopup, "named root frame (Escape)")
    t.ok(P.frame:IsMouseEnabled(), "the veil swallows clicks")
    t.ok(P.veil:IsShown())
    local shown, rec = 0, 0
    for _, c in ipairs(P.cardFrames) do
      if c.frame:IsShown() then
        shown = shown + 1
        local w, h = c.frame:GetSize()
        t.ok(w >= 260 and w <= 340, "card width " .. tostring(w))
        t.ok(h >= 400 and h <= 480, "card height " .. tostring(h))
        if c.data.recommended then
          rec = rec + 1
          t.ok(c.halo:IsShown() and c.pulse:IsPlaying(), "animated halo")
          t.eq(c.badgeText:GetText(), Q.L.UI_ROUTECHOICE_RECOMMENDED)
          t.eq(c.reason:GetText(), Q.L["UI_ROUTECHOICE_REASON_" .. c.data.reason])
        else
          t.ok(not c.halo:IsShown(), "no halo on the other cards")
          t.ok(not c.pulse:IsPlaying())
          t.eq(c.reason:GetText(), "")
        end
      end
    end
    t.eq(shown, 2); t.eq(rec, 1)
    local west, dark = P.cardFrames[1], P.cardFrames[2]
    t.eq(west.name:GetText(), "Westfall")
    t.eq(west.levels:GetText(), string.format(Q.L.UI_ROUTECHOICE_LEVELS, 14, 16))
    t.eq(west.lines[1].text:GetText(), string.format(Q.L.UI_ROUTECHOICE_QUESTS_ONE, 1, "500"))
    t.eq(dark.lines[1].text:GetText(), string.format(Q.L.UI_ROUTECHOICE_QUESTS, 2, "1000"))
    t.eq(dark.lines[2].text:GetText(), string.format(Q.L.UI_ROUTECHOICE_TIME_XPH, "2 h 38", "26898"))
    t.eq(dark.lines[3].text:GetText(), string.format(Q.L.UI_ROUTECHOICE_TRAVEL_MIN, Q.L.UI_ROUTECHOICE_KIND_boat, 6))
    t.eq(dark.lines[3].icon:GetTexture(), P.TRAVEL_ICONS.boat)
    t.ok(west.hlHeader:IsShown(), "highlights of Westfall")
    t.eq(west.highlights[1].text:GetText(), string.format(Q.L.UI_ROUTECHOICE_HL_DUNGEON, "The Deadmines", 17, 26))
    t.ok(not dark.hlHeader:IsShown(), "no data: no highlights section")
    t.eq(P.title:GetText(), Q.L.UI_ROUTECHOICE_TITLE)
    t.eq(P.subtitle:GetText(), string.format(Q.L.UI_ROUTECHOICE_SUBTITLE, "Loch Modan"))
    -- clic sur la carte = « Y aller »
    Mock.click(dark.frame)
    t.ok(not P:IsShown())
    t.eq(Q.char.routeChoices.T_FROM, "T_DARK")
    noErrors(t)
  end,

  -- 3 et 4 cartes, une seule conseillée ; fenêtre dans la largeur de l'écran ; une carte en trop
  -- d'une ouverture précédente est cachée.
  popup_three_and_four_cards = function(t)
    local Q = load({ extraFiles = { GUIDES, RC_FIXTURE } })
    for _, id in ipairs({ "T_C3", "T_C4" }) do
      Q:RegisterGuide({ id = id, title = id, faction = "Alliance", minLevel = 14, maxLevel = 18,
        steps = { { "accept", 179 } } })
    end
    local from = Q.Guides:Get("T_FROM")
    from.choices = { { id = "T_WEST" }, { id = "T_DARK" }, { id = "T_C3" }, { id = "T_C4" } }
    Q.Progress:SetGuide("T_FROM")
    local P = popup(Q)
    UIParent.GetWidth = function() return 1024 end
    UIParent.GetHeight = function() return 768 end
    t.ok(P:Open("T_FROM", true))
    t.eq(shownCards(P), 4)
    local rec = 0
    for _, c in ipairs(P.cardFrames) do if c.frame:IsShown() and c.data.recommended then rec = rec + 1 end end
    t.eq(rec, 1, "a single recommended card")
    t.ok(P.window:GetWidth() <= 1024, "fits the screen width: " .. tostring(P.window:GetWidth()))
    t.ok(P.window:GetHeight() <= 768 * 0.75, "about 70 % of the screen height")
    P:Later()
    from.choices = { { id = "T_WEST" }, { id = "T_DARK" }, { id = "T_C3" } }
    t.ok(P:Open("T_FROM", true))
    t.eq(shownCards(P), 3)
    t.ok(not P.cardFrames[4].frame:IsShown())
    noErrors(t)
  end,

  -- Image de fond : Q.ZoneArt, sinon la carte du monde de la zone (tuiles du client, comme
  -- Blizzard_MapCanvasDetailLayer, à l'échelle pour couvrir la carte), sinon un fond uni ; tuiles
  -- créées une fois et réutilisées.
  popup_background_fallbacks = function(t)
    local Q, P = ready()
    local c = P.cardFrames[1]
    t.eq(c.data.mapId, 1436)
    t.eq(c.artMode, "color", "no image, no map art API")
    t.ok(c.solid:IsShown())
    P:Later()
    C_Map.GetMapArtLayers = function()
      return { { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 } }
    end
    C_Map.GetMapArtLayerTextures = function(id)
      local out = {}
      for i = 1, 12 do out[i] = id * 100 + i end
      return out
    end
    t.ok(P:Open("T_FROM", true))
    t.eq(c.artMode, "map")
    local n = 0
    for _, tx in ipairs(c.tiles) do if tx:IsShown() then n = n + 1 end end
    t.eq(n, 12, "4 columns x 3 rows")
    t.eq(c.tiles[1]:GetTexture(), 143601)
    t.eq(c.tiles[5]:GetTexture(), 143605, "row-major order, like Blizzard")
    local aw, ah = c.art:GetSize()
    local cw, ch = c.canvas:GetSize()
    t.ok(cw >= aw - 0.01 and ch >= ah - 0.01, "the map covers the card")
    t.near(cw / ch, 1002 / 668, 0.001, "map aspect kept")
    local tw = c.tiles[1]:GetWidth()
    local _, _, _, x2 = c.tiles[2]:GetPoint(1)
    local _, _, _, _, y5 = c.tiles[5]:GetPoint(1)
    t.near(x2, tw, 0.001, "second column"); t.near(y5, -tw, 0.001, "second row")
    local first = c.tiles[1]
    P:Later()
    t.ok(P:Open("T_FROM", true))
    t.ok(c.tiles[1] == first and #c.tiles == 12, "tiles reused")
    Q.ZoneArt[1436] = { texture = "Interface\\AddOns\\Questify\\Media\\Zones\\Westfall" }
    P:Later()
    t.ok(P:Open("T_FROM", true))
    t.eq(c.artMode, "image")
    t.eq(c.image:GetTexture(), Q.ZoneArt[1436].texture)
    t.ok(c.image:IsShown()); t.ok(not c.tiles[1]:IsShown())
    noErrors(t)
  end,

  -- Clavier : seulement fenêtre ouverte et hors combat ; flèches / Tab changent de carte (départ sur
  -- la conseillée), Entrée choisit, les autres touches passent au jeu (déplacement).
  popup_keyboard = function(t)
    local Q, P = ready()
    local prop = {}
    P.frame.SetPropagateKeyboardInput = function(_, v) prop[#prop + 1] = v end
    t.eq(P.keyboard, true, "keyboard while shown out of combat")
    local rec
    for i, c in ipairs(P.cards) do if c.recommended then rec = i end end
    local other = rec % 2 + 1
    t.eq(P.focus, rec, "focus starts on the recommended card")
    press(P, "W"); t.eq(prop[#prop], true, "movement keys pass through")
    press(P, "RIGHT"); t.eq(prop[#prop], false); t.eq(P.focus, other)
    press(P, "TAB"); t.eq(P.focus, rec)
    Mock.player.shift = true
    press(P, "TAB"); t.eq(P.focus, other, "Shift-Tab goes back")
    Mock.player.shift = false
    press(P, "LEFT"); t.eq(P.focus, rec)
    press(P, "RIGHT")
    local target = P.cards[P.focus].id
    press(P, "ENTER")
    t.ok(not P:IsShown())
    t.eq(Q.char.routeChoices.T_FROM, target)
    t.eq(P.keyboard, false, "keyboard released")
    noErrors(t)
  end,

  -- Demande en combat : aucun cadre créé, rien de montré ; ouverture à la sortie du combat.
  combat_request_opens_after_combat = function(t)
    local Q, P = ready({ combat = true })
    t.ok(not P:IsShown())
    t.eq(P.frame, nil, "no frame created in combat")
    leaveCombat()
    t.ok(P:IsShown(), "after combat")
    t.eq(P.keyboard, true)
    noErrors(t)
  end,

  -- Ouverte quand le combat commence : fermée d'elle-même (clavier rendu), rouverte à la fin tant
  -- que le choix n'est pas fait ; plusieurs combats de suite.
  combat_closes_and_reopens = function(t)
    local Q, P = ready()
    enterCombat()
    t.ok(not P:IsShown(), "closed in combat")
    t.eq(P.keyboard, false)
    t.eq(dismissed(Q, "T_FROM"), nil, "not a player close")
    leaveCombat()
    t.ok(P:IsShown(), "reopened after combat")
    enterCombat(); leaveCombat()
    t.ok(P:IsShown(), "second fight")
    noErrors(t)
  end,

  -- Choix fait pendant le combat (par une autre voie) : pas de réouverture ; plus rien ensuite.
  combat_choice_made_meanwhile = function(t)
    local Q, P = ready()
    enterCombat()
    Q.Progress:ChooseRoute("T_FROM", "T_WEST")
    leaveCombat()
    t.ok(not P:IsShown())
    t.eq(Q.Progress:Guide().id, "T_WEST")
    Q = Mock.reload()
    Mock.advance(0)
    t.ok(not popup(Q):IsShown(), "choice made: nothing after /reload")
    noErrors(t)
  end,

  -- Fermée par le joueur (« Plus tard », Échap, croix, fermeture par le jeu) : pas de réouverture
  -- automatique, ni après combat, ni au /reload ; /qf route la rouvre.
  closed_by_player_stays_closed = function(t)
    for _, how in ipairs({ "later", "escape", "close", "external" }) do
      Mock.reset()
      local Q, P = ready()
      if how == "later" then Mock.click(P.laterButton)
      elseif how == "escape" then press(P, "ESCAPE")
      elseif how == "close" then Mock.click(P.closeButton)
      else P.frame:Hide() end   -- fermeture par le jeu (UISpecialFrames)
      t.ok(not P:IsShown(), how)
      t.eq(Q.Progress:PendingChoice(), "T_FROM", how .. ": still waiting")
      t.eq(P.keyboard, false, how .. ": keyboard released")
      enterCombat(); leaveCombat()
      t.ok(not P:IsShown(), how .. ": not after combat")
      Q = Mock.reload()
      Mock.advance(0)
      P = popup(Q)
      t.eq(Q.Progress:PendingChoice(), "T_FROM", how .. ": still waiting after /reload")
      t.ok(not P:IsShown(), how .. ": not after /reload")
      Mock.fire("PLAYER_ENTERING_WORLD", false, true)
      t.ok(not P:IsShown(), how .. ": a /reload is not a new session")
      SlashCmdList.QUESTIFY("route")
      t.ok(P:IsShown(), how .. ": /qf route reopens it")
      noErrors(t)
    end
  end,

  -- Nouvelle session (connexion) : le choix fermé par le joueur est redemandé.
  new_session_asks_again = function(t)
    local Q, P = ready()
    P:Later()
    Q = Mock.reload()
    Mock.advance(0)
    P = popup(Q)
    t.ok(not P:IsShown())
    Mock.fire("PLAYER_ENTERING_WORLD", true, false)
    t.ok(P:IsShown(), "new login: asked again")
    noErrors(t)
  end,

  -- /qf route en combat : message, puis ouverture à la sortie du combat.
  manual_request_in_combat = function(t)
    local Q = load({ extraFiles = { GUIDES, RC_FIXTURE } })
    Q.Progress:SetGuide("T_FROM")
    local P = popup(Q)
    Mock.player.combat = true
    SlashCmdList.QUESTIFY("route")
    t.ok(not P:IsShown()); t.eq(P.frame, nil)
    t.eq(Mock.countPrinted(Q.L.UI_ROUTECHOICE_AFTER_COMBAT), 1)
    leaveCombat()
    t.ok(P:IsShown())
    noErrors(t)
  end,

  -- Message « Chapitre suivant » dans la langue du client.
  next_chapter_message_translated = function(t)
    Mock.locale = "frFR"
    local Q = load()
    setup(Q, { level = 16 })
    C_Map.GetMapInfo = function(id) if id == 1439 then return { name = "Sombrivage" } end end
    finish(Q)
    Mock.advance(0)
    popup(Q):Choose("T_DARK")
    t.eq(Mock.countPrinted("Chapitre suivant : Sombrivage."), 1)
    noErrors(t)
  end,

  -- Cartes : nom de la zone dans la langue du client et carte de la zone (image de fond).
  card_title_and_map = function(t)
    Mock.locale = "frFR"
    local Q = load()
    setup(Q)
    C_Map.GetMapInfo = function(id)
      if id == 1436 then return { name = "Marche de l'Ouest" } end
      if id == 1439 then return { name = "Sombrivage" } end
    end
    local cards = Q.RouteChoice:Rank(Q.Progress:RouteOptions("T_FROM"), 15)
    t.eq(cards[1].title, "Marche de l'Ouest"); t.eq(cards[1].mapId, 1436)
    t.eq(cards[2].title, "Sombrivage"); t.eq(cards[2].mapId, 1439)
  end,

  -- Points forts : seulement des données existantes (donjon de la tranche dont l'entrée est dans la
  -- zone, quête de classe qui commence dans la zone, points de vol des étapes) ; rien sinon.
  highlights_from_existing_data = function(t)
    Mock.player.classFile = "WARLOCK"
    local Q = load({ beforeLogin = function(Q)
      Q.ClassQuestData = { WARLOCK = {
        { key = "WARLOCK_1598", title = "English data title", faction = "Alliance", level = 1, quests = { 1598 },
          rewards = {} },
      } }
    end })
    Q.DungeonData = {
      { key = "HIGH", name = "Too High", minLevel = 30, maxLevel = 40, factions = { "Alliance" },
        entrance = { 1436, 1, 1 }, quests = {} },
      { key = "DM", name = "The Deadmines", minLevel = 17, maxLevel = 26, factions = { "Alliance" },
        entrance = { 1436, 42.6, 71.8 }, quests = {} },
      { key = "FAR", name = "Far Away", minLevel = 15, maxLevel = 20, factions = { "Alliance" },
        entrance = { 1439, 1, 1 }, quests = {} },
      { key = "HORDE", name = "Horde Only", minLevel = 15, maxLevel = 20, factions = { "Horde" },
        entrance = { 1436, 1, 1 }, quests = {} },
    }
    -- Marche de l'Ouest 14-16, fin simulée 17,05 : les Mortemines (17+) sont dans la tranche
    Q:RegisterGuide({ id = "T_WF", title = "Westfall", faction = "Alliance", minLevel = 14, maxLevel = 16,
      sim = { endLevel = 17.05 }, steps = { { "fp", 1436, 56.6, 52.6 }, { "goto", 1436, 50, 50 } } })
    local hl = Q.RouteChoice:Highlights(Q.Guides:Get("T_WF"))
    t.eq(#hl, 2)
    t.eq(hl[1].kind, "dungeon"); t.eq(hl[1].name, "The Deadmines"); t.eq(hl[1].minLevel, 17)
    t.eq(hl[2].kind, "fp"); t.eq(hl[2].count, 1)
    -- Forêt d'Elwynn 1-10 : la chaîne de démoniste commence chez Drusilla La Salle (Elwynn)
    Q:RegisterGuide({ id = "T_EL", title = "Elwynn Forest", faction = "Alliance", minLevel = 1, maxLevel = 10,
      steps = { { "goto", 1429, 40, 60 } } })
    hl = Q.RouteChoice:Highlights(Q.Guides:Get("T_EL"))
    t.eq(#hl, 1)
    t.eq(hl[1].kind, "class"); t.eq(hl[1].title, "The Stolen Tome", "quest name, not the data title")
    -- rien à dire : pas de section
    Q:RegisterGuide({ id = "T_NONE", title = "Nowhere", steps = { { "note", "x" } } })
    t.eq(#Q.RouteChoice:Highlights(Q.Guides:Get("T_NONE")), 0)
    t.eq(#Q.RouteChoice:Highlights(nil), 0)
    noErrors(t)
  end,

  -- Une seule suite : bascule comme avant, avec un message discret ; /qf route le dit.
  single_successor_switches_with_a_message = function(t)
    local Q = load()
    local keys = {}
    for _, e in ipairs(Q.Progress:Entries()) do
      if e.source == "guide" then keys[#keys + 1] = e.key end
    end
    for _, k in ipairs(keys) do Q.Progress:MarkDone(k) end
    t.eq(Q.Progress:Guide().id, "A_DwarfGnome_02")
    t.eq(Mock.countPrinted(string.format(Q.L.ROUTE_NEXT, "Dun Morogh")), 1)
    SlashCmdList.QUESTIFY("route")
    t.eq(Mock.countPrinted(Q.L.UI_ROUTECHOICE_NONE), 1)
    t.ok(not popup(Q):IsShown())
  end,
}
