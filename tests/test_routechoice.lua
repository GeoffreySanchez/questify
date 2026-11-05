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
