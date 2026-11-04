-- Tests de la spécialisation et du profil de butin (Automation/SpecRole.lua).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local GUIDES = "tests/fixtures/guide_fixture.lua"

local function ext() return dofile(Mock.root .. "/tests/mock_ext_specrole.lua") end

-- Charge l'addon pour un personnage de cette classe et de ce niveau, API de spécialisation incluse.
local function load(classFile, level, opts)
  local Ext = ext()
  Mock.player.classFile = classFile or "SHAMAN"
  Mock.player.level = level or 20
  Ext.install()
  opts = opts or {}
  opts.extraFiles = opts.extraFiles or { GUIDES }
  local Q = Mock.loadAddon(TOC, opts)
  return Q, Ext
end

-- Choix de spécialisation par le joueur : l'évènement, puis le délai de regroupement.
local function pickSpec(index)
  Mock.spec.index = index
  Mock.fire("PLAYER_SPECIALIZATION_CHANGED", "player")
  Mock.fire("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
  Mock.advance(1)
end

local function noErrors(t)
  t.eq(#Mock.errors, 0, "no errors: " .. tostring(Mock.errors[1]))
end

return {
  int_damager_shaman_melee_shows_popup_and_yes_sets_caster = function(t)
    local Q = load("SHAMAN", 20)
    local SR = Q.SpecRole
    Q.char.rewardRole = "melee"
    pickSpec(1)   -- Élémentaire : DAMAGER, Intelligence
    t.ok(SR:IsShown(), "popup shown")
    t.eq(SR.current.profile, "caster")
    t.eq(SR.current.specID, 262)
    t.ok(SR.text:GetText():find("Elemental", 1, true), "spec name in the text")
    t.eq(SR.noButton:GetText(), string.format(Q.L.SPECROLE_NO, Q.L.REWARD_SPEC_SHAMAN_MELEE))
    Mock.click(SR.yesButton, "LeftButton")
    t.eq(Q.char.rewardRole, "caster")
    t.ok(not SR:IsShown(), "closed after Yes")
    t.ok(Mock.printed(string.format(Q.L.MINIMAP_ROLE_SET, Q.L.REWARD_SPEC_SHAMAN_CASTER)), "confirmation line")
    -- même spécialisation ensuite : rien à proposer
    pickSpec(1)
    t.ok(not SR:IsShown())
    noErrors(t)
  end,

  no_is_remembered_per_spec_and_a_new_spec_asks_again = function(t)
    local Q = load("SHAMAN", 20)
    local SR = Q.SpecRole
    Q.char.rewardRole = "melee"
    pickSpec(1)
    t.ok(SR:IsShown())
    Mock.click(SR.noButton, "LeftButton")
    t.ok(not SR:IsShown())
    t.eq(Q.char.rewardRole, "melee", "role kept")
    t.eq(Q.char.specRoleAnswered[262], true)
    t.ok(Mock.printed(string.format(Q.L.SPECROLE_KEPT, Q.L.REWARD_SPEC_SHAMAN_MELEE)))
    pickSpec(1)
    t.ok(not SR:IsShown(), "not asked again for Elemental")
    -- après /reload, la vérification de connexion ne redemande pas non plus
    local Ext = ext()
    Q.char.wizardDone = true   -- sinon l'assistant s'ouvre et la vérification de connexion l'attend
    local Q2 = Mock.reload()
    Ext.reinstall()
    Mock.advance(10)
    t.ok(not Q2.SpecRole:IsShown(), "still remembered after reload")
    -- autre spécialisation : la question revient
    Mock.spec.index = 3
    Mock.fire("ACTIVE_TALENT_GROUP_CHANGED", 1, 2)
    Mock.advance(1)
    t.ok(Q2.SpecRole:IsShown(), "Restoration asks")
    t.eq(Q2.SpecRole.current.profile, "healer")
    noErrors(t)
  end,

  same_spec_as_role_shows_nothing = function(t)
    local Q = load("SHAMAN", 20)
    Q.char.rewardRole = "caster"
    pickSpec(1)
    t.ok(not Q.SpecRole:IsShown())
    Q.char.rewardRole = "healer"
    pickSpec(3)
    t.ok(not Q.SpecRole:IsShown())
    noErrors(t)
  end,

  combat_queues_the_popup = function(t)
    local Q = load("SHAMAN", 20)
    local SR = Q.SpecRole
    Q.char.rewardRole = "melee"
    Mock.player.combat = true
    pickSpec(1)
    t.ok(not SR:IsShown(), "never shown in combat")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(SR:IsShown(), "shown when combat ends")
    -- un combat qui commence la cache, la fin du combat la repropose
    Mock.player.combat = true
    Mock.fire("PLAYER_REGEN_DISABLED")
    t.ok(not SR:IsShown(), "hidden at combat start")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.ok(SR:IsShown(), "back after combat")
    t.eq(SR.current.profile, "caster")
    noErrors(t)
  end,

  no_spec_or_missing_api_is_silent = function(t)
    local Q = load("SHAMAN", 20)
    local SR = Q.SpecRole
    Q.char.rewardRole = "melee"
    for _, index in ipairs({ false, 0, 5 }) do   -- aucune, zéro, spécialisation de départ
      pickSpec(index or nil)
      t.ok(not SR:IsShown(), "no popup for index " .. tostring(index))
    end
    t.eq(SR:Detect(), nil)
    Mock.spec.selection = false
    pickSpec(1)
    t.ok(not SR:IsShown(), "spec selection disabled for the class")
    Mock.spec.selection = true
    Mock.spec.fail = true
    pickSpec(1)
    t.ok(not SR:IsShown(), "failing API")
    Mock.spec.fail = false
    C_SpecializationInfo = nil
    pickSpec(1)
    t.ok(not SR:IsShown(), "missing API")
    t.eq(SR:Detect(), nil)
    t.eq(SR:IconForProfile("caster", "SHAMAN"), nil)
    t.ok(type(SR:Describe()) == "string")
    noErrors(t)
  end,

  below_spec_level_does_nothing = function(t)
    local Q = load("SHAMAN", 9)
    Q.char.rewardRole = "melee"
    pickSpec(1)
    t.ok(not Q.SpecRole:IsShown())
    noErrors(t)
  end,

  hunter_damager_maps_to_ranged = function(t)
    local Q = load("HUNTER", 20)
    local SR = Q.SpecRole
    t.eq(SR:ProfileFor("DAMAGER", 2, "HUNTER"), "ranged")
    t.eq(SR:ProfileFor("DAMAGER", 4, "HUNTER"), "ranged")
    Q.char.rewardRole = "melee"
    pickSpec(2)   -- Précision
    t.ok(SR:IsShown())
    t.eq(SR.current.profile, "ranged")
    Mock.click(SR.yesButton, "LeftButton")
    t.eq(Q.char.rewardRole, "ranged")
    noErrors(t)
  end,

  mapping_keeps_only_class_profiles = function(t)
    local Q = load("SHAMAN", 20)
    local SR = Q.SpecRole
    t.eq(SR:ProfileFor("HEALER", 4, "PRIEST"), "healer")
    t.eq(SR:ProfileFor("DAMAGER", 4, "PRIEST"), "caster")
    t.eq(SR:ProfileFor("TANK", 1, "WARRIOR"), "tank")
    t.eq(SR:ProfileFor("DAMAGER", 1, "WARRIOR"), "melee")
    t.eq(SR:ProfileFor("DAMAGER", 2, "DRUID"), "melee")
    t.eq(SR:ProfileFor("DAMAGER", 4, "DRUID"), "caster")
    t.eq(SR:ProfileFor("TANK", 2, "DRUID"), "tank")
    t.eq(SR:ProfileFor("TANK", 1, "SHAMAN"), "auto", "no tank profile for a shaman")
    t.eq(SR:ProfileFor("HEALER", 4, "MAGE"), "auto")
    t.eq(SR:ProfileFor(nil, nil, "SHAMAN"), "auto")
  end,

  login_check_offers_once_when_role_is_auto = function(t)
    local Ext = ext()
    Mock.player.classFile, Mock.player.level = "SHAMAN", 20
    Ext.install()
    Mock.spec.index = 1
    Mock.spec.initialized = false   -- données pas encore prêtes à la connexion
    -- assistant déjà terminé (sinon il s'ouvre à la connexion et la question l'attend)
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES },
      savedVariables = { QuestifyVanillaCharDB = { wizardDone = true } } })
    t.eq(Q.char.rewardRole, "auto")
    Mock.advance(6)
    t.ok(not Q.SpecRole:IsShown(), "waits for the spec data")
    Mock.spec.initialized = true
    Mock.advance(3)
    t.ok(Q.SpecRole:IsShown(), "offered at login")
    t.eq(Q.SpecRole.current.profile, "caster")
    t.eq(Q.SpecRole.noButton:GetText(), string.format(Q.L.SPECROLE_NO, Q.L.REWARD_ROLE_AUTO))
    noErrors(t)
  end,

  login_check_waits_for_the_wizard = function(t)
    local Ext = ext()
    Mock.player.classFile, Mock.player.level = "SHAMAN", 20
    Ext.install()
    Mock.spec.index = 1
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES } })
    local shown = true
    Q.UI.Wizard = { IsShown = function() return shown end }
    Mock.advance(12)
    t.ok(not Q.SpecRole:IsShown(), "waits while the wizard is open")
    shown = false
    Mock.advance(6)
    t.ok(Q.SpecRole:IsShown(), "asked once the wizard is closed")
    noErrors(t)
  end,

  single_profile_class_is_never_asked = function(t)
    local Q = load("MAGE", 20)
    pickSpec(2)
    Mock.advance(10)
    t.ok(not Q.SpecRole:IsShown())
    noErrors(t)
  end,

  role_changed_elsewhere_closes_the_popup = function(t)
    local Q = load("SHAMAN", 20)
    Q.char.rewardRole = "melee"
    pickSpec(1)
    t.ok(Q.SpecRole:IsShown())
    Q.Rewards:SetRole("caster")
    t.ok(not Q.SpecRole:IsShown(), "nothing left to offer")
    noErrors(t)
  end,

  bug_report_has_the_spec_line = function(t)
    local Q = load("SHAMAN", 20)
    Mock.spec.index = 1
    Q.char.rewardRole = "melee"
    local report = Q.Diagnostics:Report()
    t.ok(report:find("Spec: Elemental (id 262, DAMAGER, stat 4) -> caster; reward role melee", 1, true), report)
  end,

  wizard_role_sets_the_chosen_flag = function(t)
    local DExt = dofile(Mock.root .. "/tests/mock_ext_d.lua")
    local WExt = dofile(Mock.root .. "/tests/mock_ext_wizard.lua")
    DExt.install(); WExt.install()
    Mock.player.classFile = "SHAMAN"
    local Q = Mock.loadAddon(TOC, { extraFiles = { GUIDES }, skipGuides = true })
    t.eq(Q.char.rewardRoleChosen, nil)
    local W = Q.UI.Wizard
    W:Show(4)
    W:Finish()
    t.eq(Q.char.rewardRoleChosen, true)
  end,
}
