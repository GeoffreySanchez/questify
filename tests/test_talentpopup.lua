-- Tests de la popup de talent (Q.UI.TalentPopup).
local TOC = "Questify/Questify.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"
local Ext = dofile(Mock.root .. "/tests/mock_ext_d.lua")
local Spec = dofile(Mock.root .. "/tests/mock_ext_specrole.lua")
local Traits = dofile(Mock.root .. "/tests/mock_ext_traits.lua")
local PS = dofile(Mock.root .. "/tests/mock_ext_playerspells.lua")

local CONCUSSION, FURY = 16035, 16039
local NAMES = { [CONCUSSION] = "Concussion", [FURY] = "Elemental Fury" }
local GROUPS = { { name = "Élémentaire", talents = { { CONCUSSION, 1, 3, 5 }, { FURY, 1, 2, 3 } } } }
local traits, opened

local function load(level, opts)
  opts = opts or {}
  Ext.install()
  Mock.player.classFile = "SHAMAN"; Mock.player.level = level
  Mock.player.combat = false
  Spec.install()
  Mock.spec.index = 1
  traits = Traits.install({ groups = GROUPS, ranks = opts.ranks or {}, unspent = opts.unspent or math.max(0, level - 9) })
  if opts.learn then Traits.installLearn(traits, {}) end
  C_Spell = { GetSpellName = function(id) return NAMES[id] end,
    GetSpellTexture = function(id) return 900000 + id end }
  opened = 0
  PlayerSpellsUtil = { ToggleClassTalentFrame = function() opened = opened + 1 end }
  -- fenêtre des talents déjà chargée par le jeu (cachée) : Talents:OpenFrame peut l'ouvrir (I10)
  if not opts.noFrame then PS.install({}) end
  local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
  if opts.noBuild then
    Q.TalentBuildData = {}
    Q.Builds:SetActive(nil, nil)   -- le chargement avait déjà suivi le build fourni
  else
    Q.TalentBuildData = { SHAMAN = {
      { key = "ele1", class = "SHAMAN", specID = 262, name = { enUS = "Elemental leveling" }, official = true,
        order = opts.order or { CONCUSSION, CONCUSSION, FURY, CONCUSSION } },
    } }
  end
  -- Le suivi a déjà lu l'alerte pendant le chargement, avant les builds du test : départ à neuf.
  local P = Q.UI.TalentPopup
  P:Hide(); P.frame = nil; P.icons = {}
  Q.char.talentPopup = { seen = 0, level = 0 }
  if opts.settings then for k, v in pairs(opts.settings) do Q.Settings:Set(k, v) end end
  return Q
end

local function shown(Q)
  local f = Q.UI.TalentPopup.frame
  return f ~= nil and f:IsShown()
end

-- Alerte réelle, sans la popup que son TALENTS_DUE vient d'ouvrir ; état à zéro.
local function realAlert(Q)
  local real = Q.Talents:Alert()
  Q.UI.TalentPopup:Hide()
  Q.char.talentPopup = { seen = 0, level = 0 }
  return real
end

local function stubLearn(Q, result)
  local calls = {}
  Q.TalentLearn.Learn = function(_, tree, due)
    calls[#calls + 1] = { tree = tree, due = due }
    return result
  end
  return calls
end

return {
  shows_once_per_point = function(t)
    local Q = load(10)
    Q.Talents:Alert()
    t.ok(shown(Q), "popup on the new point")
    local P = Q.UI.TalentPopup
    t.eq(P.title:GetText(), string.format(Q.L.TALENT_POPUP_LEVEL, 10))
    t.eq(P.buildLine:GetText(), string.format(Q.L.TALENT_POPUP_BUILD, "Elemental leveling"))
    t.eq(P.icons[1].tex:GetTexture(), 900000 + CONCUSSION)
    t.eq(P.name:GetText(), "Concussion")
    t.eq(P.treeLine:GetText(), string.format(Q.L.TALENT_POPUP_TREE, "Élémentaire", 1, 5))
    P:Hide()
    t.eq(Q.char.talentPopup.seen, 1)
    Q.Talents:Alert()
    Q:Fire("TALENTS_DUE", Q.Talents:Alert())
    t.ok(not shown(Q), "same point: not shown again")
    -- session suivante : même nombre de points, même niveau
    Q:Fire("TALENTS_DUE", Q.Talents:Alert())
    t.ok(not shown(Q), "not again at the next login")
    -- niveau 11 : second point
    Mock.player.level = 11; Q.Player.level = 11
    traits.quantity = 2
    Q.Talents:Alert()
    t.ok(shown(Q), "next point shows again")
    t.eq(#Mock.errors, 0)
  end,

  points_title_when_several = function(t)
    local Q = load(12, { unspent = 3 })
    Q.Talents:Alert()
    t.eq(Q.UI.TalentPopup.title:GetText(), string.format(Q.L.TALENT_POPUP_POINTS, 3))
  end,

  spent_points_lower_seen = function(t)
    local Q = load(11, { unspent = 2 })
    Q.Talents:Alert()
    t.eq(Q.char.talentPopup.seen, 2)
    traits.quantity = 1
    Mock.fire("TRAIT_CONFIG_UPDATED", 1)
    t.eq(Q.char.talentPopup.seen, 1)
    traits.quantity = 2
    Q.Talents:Alert()
    t.ok(shown(Q), "a point after spending shows again")
  end,

  waits_out_of_combat = function(t)
    local Q = load(10)
    Mock.player.combat = true
    Q.Talents:Alert()
    t.ok(Q.UI.TalentPopup.frame == nil, "no frame created in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(shown(Q), "shown when combat ends")
    t.eq(#Mock.errors, 0)
  end,

  combat_start_hides_and_resumes = function(t)
    local Q = load(10)
    Q.Talents:Alert()
    t.ok(shown(Q))
    Mock.player.combat = true
    Mock.fire("PLAYER_REGEN_DISABLED")
    t.ok(not shown(Q))
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(shown(Q))
  end,

  snooze_until_next_point = function(t)
    local Q = load(10)
    Q.Talents:Alert()
    local P = Q.UI.TalentPopup
    Mock.click(P.laterButton)
    t.ok(not shown(Q))
    t.eq(Q.char.talentPopup.seen, 1)
    Q.Talents:Alert()
    t.ok(not shown(Q), "still snoozed")
    Q:Fire("TALENTS_DUE", Q.Talents:Alert())
    t.ok(not shown(Q), "still snoozed on a new TALENTS_DUE")
    Mock.player.level = 11; Q.Player.level = 11
    traits.quantity = 2
    Q.Talents:Alert()
    t.ok(shown(Q), "next point wakes it")
  end,

  learn_click_calls_learn_with_due = function(t)
    local Q = load(10)
    local calls = stubLearn(Q, "ok")
    Q.Talents:Alert()
    local alert = Q.Talents:Alert()
    Mock.click(Q.UI.TalentPopup.learnButton)
    t.eq(#calls, 1)
    t.eq(calls[1].due[1].spellID, CONCUSSION)
    t.ok(calls[1].tree ~= nil)
    t.ok(not shown(Q), "hidden after success")
    t.ok(not Mock.printed(string.format(Q.L.TALENT_LEARNED, "Concussion")), "not before the commit ends (I4)")
    Q:Fire("TALENT_COMMIT", "done", calls[1].due)
    t.ok(Mock.printed(string.format(Q.L.TALENT_LEARNED, "Concussion")), "confirmation printed")
    t.eq(alert.unspent, 1)
    t.eq(#Mock.errors, 0)
  end,

  learn_in_combat_stays_pending = function(t)
    local Q = load(10)
    local calls = stubLearn(Q, "combat")
    Q.Talents:Alert()
    Mock.click(Q.UI.TalentPopup.learnButton)
    t.ok(not shown(Q))
    calls = stubLearn(Q, "ok")
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(shown(Q), "reopens after combat")
  end,

  learn_failure_opens_frame = function(t)
    for _, result in ipairs({ "unavailable", "failed" }) do
      local Q = load(10)
      stubLearn(Q, result)
      Mock.prints = {}
      Q.Talents:Alert()
      Mock.click(Q.UI.TalentPopup.learnButton)
      t.eq(opened, 1, result)
      t.ok(Mock.printed(Q.L.TALENT_LEARN_FALLBACK), result)
      t.ok(not shown(Q), result)
    end
    -- fenêtre des talents pas encore chargée par le jeu (I10) : la touche des talents est donnée
    Mock.reset()
    local Q = load(10, { noFrame = true })
    stubLearn(Q, "failed")
    Q.Talents:Alert()
    Mock.click(Q.UI.TalentPopup.learnButton)
    t.eq(opened, 0)
    t.ok(Mock.printed(string.format(Q.L.TALENT_LEARN_FALLBACK_KEY, "N")))
  end,

  open_button_opens_frame = function(t)
    local Q = load(10)
    Q.Talents:Alert()
    Mock.click(Q.UI.TalentPopup.openButton)
    t.eq(opened, 1)
    t.ok(not shown(Q))
  end,

  no_build_shows_choose_button = function(t)
    local Q = load(10, { noBuild = true })
    local P = Q.UI.TalentPopup
    Q:Fire("TALENTS_DUE", Q.Talents:Alert())
    t.ok(shown(Q))
    t.ok(P.chooseButton:IsShown())
    t.eq(P.chooseButton:GetText(), Q.L.UI_TALENT_NO_BUILD)
    t.ok(not P.learnButton:IsShown())
    t.ok(not P.openButton:IsShown())
    Q.UI.BuildWindow = nil
    Mock.click(P.chooseButton)
    t.eq(opened, 1, "falls back to the talent frame without BuildWindow")
    local got
    Q.UI.BuildWindow = { Open = function(_, tab) got = tab end }
    Q.Talents:Alert()
    P:Show()
    Mock.click(P.chooseButton)
    t.eq(got, "build")
  end,

  respects_talentAlert_off = function(t)
    local Q = load(10, { settings = { talentAlert = false } })
    Q.Talents:Alert()
    Q:Fire("TALENTS_DUE", { unspent = 1, due = {} })
    t.ok(not shown(Q))
    t.ok(Q.UI.TalentPopup.frame == nil)
  end,
  nil_tree_waits_then_shows = function(t)
    local Q = load(10)
    local real = realAlert(Q)
    local early = { unspent = 1, due = {}, build = real.build, tree = nil, deviates = false }
    Q:Fire("TALENTS_DUE", early)
    t.ok(not shown(Q), "no tree: not shown")
    t.eq(Q.char.talentPopup.seen, 0)
    t.eq(Q.char.talentPopup.level, 0)
    Q:Fire("TALENTS_DUE", { unspent = 1, due = {}, build = real.build, tree = real.tree })
    t.ok(not shown(Q), "build without due: not shown")
    t.eq(Q.char.talentPopup.seen, 0)
    Q:Fire("TALENTS_DUE", real)
    t.ok(shown(Q), "shown once the tree is ready")
    t.eq(Q.char.talentPopup.seen, 1)
    t.eq(#Mock.errors, 0)
  end,

  shown_popup_refilled_by_later_due = function(t)
    local Q = load(10)
    local real = Q.Talents:Alert()
    Q:Fire("TALENTS_DUE", real)
    local P = Q.UI.TalentPopup
    t.ok(shown(Q))
    t.ok(not P.icons[2].holder:IsShown())
    Q:Fire("TALENTS_DUE", { unspent = 1, due = { real.due[1], real.due[1] }, build = real.build, tree = real.tree })
    t.ok(P.icons[2].holder:IsShown(), "refilled")
    t.eq(#P.alert.due, 2)
  end,

  nothing_shows_before_char_exists = function(t)
    local Q = load(10)
    local real = realAlert(Q)
    local char = Q.char
    Q.char = nil
    Q:Fire("TALENTS_DUE", real)
    t.ok(not shown(Q), "no Q.char: not shown")
    Q.char = char
    t.eq(char.talentPopup.seen, 0, "state untouched")
    Q:Fire("TALENTS_DUE", real)
    t.ok(shown(Q))
    Mock.player.level = 9; Q.Player.level = 9
    Q.UI.TalentPopup:Hide(); char.talentPopup.seen = 0
    Q:Fire("TALENTS_DUE", real)
    t.ok(not shown(Q), "below level 10")
    t.eq(#Mock.errors, 0)
  end,

  snooze_after_points_spent = function(t)
    local Q = load(11, { unspent = 2 })
    Q.Talents:Alert()
    t.ok(shown(Q))
    traits.quantity = 1   -- un point dépensé sans évènement
    Mock.click(Q.UI.TalentPopup.laterButton)
    t.eq(Q.char.talentPopup.seen, 1)
  end,

  -- I5 : « Apprendre » relit l'état au clic ; dépense faite ailleurs : la popup se cache (plus de point) et
  -- rien n'est acheté ni coupé.
  learn_rereads_the_state_at_click = function(t)
    local Q = load(12, { unspent = 1, learn = true })
    local P = Q.UI.TalentPopup
    t.ok(P:Show())
    traits.ranks[CONCUSSION] = 1
    traits.quantity = 0
    Mock.fire("TRAIT_CONFIG_UPDATED", Traits.CONFIG)
    t.ok(not shown(Q), "hidden: no point left")
    P:Learn()
    t.eq(Mock.countCalls("PurchaseRank"), 0, "nothing bought")
    t.ok(Q.TalentLearn:IsAvailable(), "learning not cut")
    -- état changé sans évènement, popup ouverte : l'achat suit l'arbre du moment
    Mock.reset()
    Q = load(12, { unspent = 2 })
    P = Q.UI.TalentPopup
    local calls = stubLearn(Q, "ok")
    t.ok(P:Show())
    t.eq(#P.alert.due, 2)
    traits.ranks[CONCUSSION] = 1
    traits.quantity = 1
    Mock.click(P.learnButton)
    t.eq(#calls, 1)
    t.eq(#calls[1].due, 1, "fresh due list")
    t.eq(calls[1].due[1].rank, 2)
  end,

  -- I4 : points déjà en attente : la popup demande de les valider, ne coupe pas l'apprentissage.
  learn_with_staged_points_asks_to_apply = function(t)
    local Q = load(12, { unspent = 2, learn = true })
    local P = Q.UI.TalentPopup
    t.ok(P:Show())
    traits.staged[CONCUSSION] = 1
    Mock.click(P.learnButton)
    t.ok(shown(Q), "stays open")
    t.ok(P.notice:IsShown())
    t.eq(P.notice:GetText(), Q.L.TALENT_POPUP_STAGED)
    t.eq(Mock.countCalls("PurchaseRank"), 0)
    t.ok(Q.TalentLearn:IsAvailable())
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I4 : succès annoncé à la fin de la validation (TRAIT_CONFIG_UPDATED), pas au clic.
  learned_message_waits_for_the_commit = function(t)
    local Q = load(10, { learn = true })
    local P = Q.UI.TalentPopup
    t.ok(P:Show())
    Mock.click(P.learnButton)
    t.eq(Mock.countCalls("PurchaseRank"), 1)
    t.eq(Mock.countCalls("CommitConfig"), 1)
    t.ok(not shown(Q))
    local msg = string.format(Q.L.TALENT_LEARNED, "Concussion")
    t.ok(not Mock.printed(msg), "not during the apply cast")
    Traits.commit(traits)
    t.eq(Mock.countPrinted(msg), 1)
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- I4 : CONFIG_COMMIT_FAILED (incantation interrompue) : message d'échec, l'apprentissage reste possible.
  commit_failure_message_keeps_learning = function(t)
    local Q = load(10, { learn = true })
    local P = Q.UI.TalentPopup
    t.ok(P:Show())
    Mock.click(P.learnButton)
    Mock.fire("CONFIG_COMMIT_FAILED", Traits.CONFIG)
    t.ok(Mock.printed(Q.L.TALENT_LEARN_COMMIT_FAILED))
    t.ok(not Mock.printed(string.format(Q.L.TALENT_LEARNED, "Concussion")))
    t.ok(Q.TalentLearn:IsAvailable())
  end,

  -- R33 (I2) : build actif obsolète : seulement « Tu as N point(s) de talent à dépenser », aucun bouton.
  obsolete_build_popup_has_only_a_message = function(t)
    local Q = load(12, { unspent = 2 })
    Q.db.builds = { SHAMAN = { { key = "u1", class = "SHAMAN", name = "Mine", official = false,
      order = { 51505, CONCUSSION } } } }
    Q.char.builds = { active = { [1] = "u1" }, picked = {} }
    local P = Q.UI.TalentPopup
    Q:Fire("TALENTS_DUE", Q.Talents:Alert())
    t.ok(shown(Q), "shown once for the point")
    t.ok(P.message:IsShown())
    t.eq(P.message:GetText(), string.format(Q.L.TALENT_POPUP_MESSAGE_MANY, 2))
    for _, b in ipairs({ P.learnButton, P.openButton, P.laterButton, P.chooseButton }) do
      t.ok(not b:IsShown(), "no button")
    end
    t.ok(not P.icons[1].holder:IsShown(), "no talent proposed")
    t.eq(P.name:GetText(), "")
    Mock.click(P.dismiss)
    t.ok(not shown(Q), "a click closes it")
    t.eq(Q.char.talentPopup.seen, 2, "once per point")
    Q:Fire("TALENTS_DUE", Q.Talents:Alert())
    t.ok(not shown(Q), "not again for the same points")
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- R33 : l'arbre ne suit plus le build (un point pris ailleurs) : même message, aucun bouton.
  deviating_tree_popup_has_only_a_message = function(t)
    local Q = load(11, { unspent = 1, ranks = { [FURY] = 1 } })
    local P = Q.UI.TalentPopup
    local a = Q.Talents:Alert()
    t.eq(a.deviates, true)
    t.ok(shown(Q))
    t.eq(P.message:GetText(), Q.L.TALENT_POPUP_MESSAGE_ONE)
    for _, b in ipairs({ P.learnButton, P.openButton, P.laterButton, P.chooseButton }) do
      t.ok(not b:IsShown(), "no button")
    end
    t.ok(not P.icons[1].holder:IsShown())
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- R33 : la popup à message se ferme seule après 10 s ; jamais en combat.
  message_popup_closes_after_10_seconds = function(t)
    local Q = load(11, { unspent = 1, ranks = { [FURY] = 1 } })
    Mock.player.combat = true
    Q.Talents:Alert()
    t.ok(Q.UI.TalentPopup.frame == nil, "nothing in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(shown(Q), "after combat")
    Mock.advance(9.9)
    t.ok(shown(Q), "still shown before 10 s")
    Mock.advance(0.2)
    t.ok(not shown(Q), "closed after 10 s")
    -- nouvelle popup à message : son propre délai, pas celui d'avant
    Q.char.talentPopup.seen = 0
    Q:Fire("TALENTS_DUE", Q.Talents:Alert())
    t.ok(shown(Q))
    Mock.advance(5)
    t.ok(shown(Q))
    Mock.advance(5.1)
    t.ok(not shown(Q))
    t.eq(#Mock.errors, 0, tostring(Mock.errors[1]))
  end,

  -- M4 : plus de talents que d'icônes : « +N » ; infobulle du sort sur chaque icône.
  more_talents_than_icons_and_icon_tooltips = function(t)
    local order = { CONCUSSION, CONCUSSION, CONCUSSION, CONCUSSION, CONCUSSION, FURY, FURY, FURY }
    local Q = load(17, { unspent = 8, order = order })
    local P = Q.UI.TalentPopup
    t.ok(P:Show())
    t.eq(#P.alert.due, 8)
    t.ok(P.icons[5].holder:IsShown())
    t.ok(P.more:IsShown())
    t.eq(P.more:GetText(), string.format(Q.L.TALENT_POPUP_MORE, 3))
    local holder = P.icons[1].holder
    holder:GetScript("OnEnter")(holder)
    t.eq(Mock.lastCall("GameTooltip:SetSpellByID").args[1], CONCUSSION)
    t.eq(Mock.tooltip.owner, holder)
    holder:GetScript("OnLeave")(holder)
    t.ok(not Mock.tooltip.shown)
    -- cinq talents au plus : pas de « +N »
    Mock.reset()
    Q = load(12, { unspent = 3 })
    P = Q.UI.TalentPopup
    t.ok(P:Show())
    t.ok(not P.more:IsShown())
  end,
}
