-- Tests de la vérification de version entre joueurs (Q.VersionCheck, Core/VersionCheck.lua).
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"
local Ext = dofile(Mock.root .. "/tests/mock_ext_versioncheck.lua")

local MINE = "1.2.3"

-- Charge l'addon avec la version MINE (ou opts.version) lue dans le TOC, sans les guides livrés.
local function load(opts)
  opts = opts or {}
  local version = opts.version or MINE
  return Mock.loadAddon(TOC, {
    skipGuides = true,
    savedVariables = opts.savedVariables,
    beforeLogin = function() Mock.tocMeta.Version = version end,
  })
end

local function countSends() return #Ext.sends() end

local function lastSend()
  local list = Ext.sends()
  return list[#list]
end

return {
  semver_compare = function(t)
    local Q = load()
    local VC = Q.VersionCheck
    local order = { "0.1.0", "0.1.1", "0.2.0", "1.0.0" }
    for i = 1, #order - 1 do
      t.eq(VC.Compare(order[i], order[i + 1]), -1, order[i] .. " < " .. order[i + 1])
      t.eq(VC.Compare(order[i + 1], order[i]), 1, order[i + 1] .. " > " .. order[i])
    end
    t.eq(VC.Compare("0.10.0", "0.9.9"), 1, "numeric, not lexical")
    t.eq(VC.Compare("0.9.9", "0.10.0"), -1)
    t.eq(VC.Compare("1.2.3", "1.2.3"), 0)
    -- suffixes ignorés pour la comparaison
    t.eq(VC.Compare("0.2.0-beta", "0.2.0"), 0)
    t.eq(VC.Compare("0.2.0-beta", "0.1.9"), 1)
    t.eq(VC.Compare("1.0.0-alpha.2", "0.9.0-beta"), 1)
    t.eq(VC.Compare("0.2.0+build.7", "0.2.1"), -1)
    t.eq(VC.Parse("0.10.3-beta.1"), { 0, 10, 3 })
    -- textes qui ne sont pas des versions
    for _, bad in ipairs({ "dev", "1.2", "1.2.3.4", "1.2.3beta", "", "v1.2.3", " 1.2.3", "1.2.3-|cffff0000x",
      "1234567.0.0", "1.2.3-" .. string.rep("x", 40) }) do
      t.eq(VC.Parse(bad), nil, "not a version: " .. bad)
      t.eq(VC.Compare(bad, "1.0.0"), nil, "no comparison: " .. bad)
    end
    t.eq(VC.Parse(nil), nil)
    t.eq(VC.Parse(123), nil)
    t.eq(#Mock.errors, 0)
  end,

  prefix_registered_and_option_on_by_default = function(t)
    Ext.install()
    local Q = load()
    t.eq(Q.Settings:Get("versionCheck"), true, "on by default")
    t.eq(Mock.countCalls("C_ChatInfo.RegisterAddonMessagePrefix"), 1)
    t.eq(Mock.lastCall("C_ChatInfo.RegisterAddonMessagePrefix").args[1], "QVVER")
    t.eq(Q.VersionCheck.MyVersion(), MINE, "TOC metadata")
    t.eq(#Mock.errors, 0)
  end,

  higher_version_notifies_once = function(t)
    Ext.install()
    local Q = load()
    Ext.receive("1.3.0", "GUILD", "Ami-Testrealm")
    Ext.receive("1.3.0", "GUILD", "Ami-Testrealm")
    Ext.receive("1.4.0-beta", "PARTY", "Autre-Testrealm")
    t.eq(Mock.countPrinted("is available"), 1, "one chat line per session")
    t.eq(Mock.countPrinted("Questify Vanilla 1.3.0 is available (you have 1.2.3): update via CurseForge."), 1)
    local notices = Mock.callsTo("RaidWarningUtil.AddMessage")
    t.eq(#notices, 1, "one on-screen message")
    t.ok(notices[1].args[1]:find("1.3.0", 1, true), "on-screen text names the version")
    t.eq(notices[1].args[2], ChatTypeInfo["SYSTEM"], "system color")
    t.eq(Q.VersionCheck:NewestSeen(), "1.4.0-beta", "newest version seen")
    t.eq(countSends(), 0, "no reply to a newer version")
    t.eq(#Mock.errors, 0)
  end,

  french_notification = function(t)
    Ext.install()
    Mock.locale = "frFR"
    load()
    Ext.receive("2.0.0", "WHISPER", "Ami-Testrealm")
    t.eq(Mock.countPrinted("Questify Vanilla 2.0.0 est disponible (tu as 1.2.3) : mets à jour via CurseForge."), 1)
    t.eq(#Mock.errors, 0)
  end,

  deprecated_raid_notice_fallback = function(t)
    Ext.install()
    RaidWarningUtil = nil
    load()
    Ext.receive("1.3.0", "GUILD", "Ami-Testrealm")
    local c = Mock.lastCall("RaidNotice_AddMessage")
    t.ok(c, "RaidNotice_AddMessage used when RaidWarningUtil is absent")
    t.eq(c.args[1], RaidWarningFrame)
    t.ok(c.args[2]:find("1.3.0", 1, true))
    t.eq(c.args[3], ChatTypeInfo["SYSTEM"])
    t.eq(#Mock.errors, 0)
  end,

  no_broadcast_alone = function(t)
    Ext.install()             -- ni guilde ni groupe
    load()
    Mock.advance(30)
    Mock.fire("GROUP_ROSTER_UPDATE")
    Mock.advance(120)
    t.eq(countSends(), 0)
    t.eq(#Mock.errors, 0)
  end,

  guild_broadcast_after_login = function(t)
    local S = Ext.install()
    S.guild = true
    load()
    Mock.advance(1)
    t.eq(countSends(), 0, "waits a few seconds after login")
    Mock.advance(10)
    t.eq(Ext.sends(), { { "QVVER", MINE, "GUILD", nil } })
    Mock.advance(600)
    t.eq(countSends(), 1, "once per session")
    t.eq(#Mock.errors, 0)
  end,

  group_channel_choice = function(t)
    local S = Ext.install()
    local Q = load()
    S.party = true
    Mock.fire("GROUP_ROSTER_UPDATE")
    t.eq(lastSend(), { "QVVER", MINE, "PARTY", nil })
    Mock.advance(61)
    S.raid = true
    Mock.fire("GROUP_ROSTER_UPDATE")
    t.eq(lastSend(), { "QVVER", MINE, "RAID", nil })
    Mock.advance(61)
    S.instance = true
    Mock.fire("GROUP_ROSTER_UPDATE")
    t.eq(lastSend(), { "QVVER", MINE, "INSTANCE_CHAT", nil })
    t.eq(countSends(), 3)
    -- groupe d'instance seul (file de donjon) : INSTANCE_CHAT
    S.party, S.raid = false, false
    t.eq(Q.VersionCheck.GroupChannel(), "INSTANCE_CHAT")
    S.instance = false
    t.eq(Q.VersionCheck.GroupChannel(), nil)
    t.eq(#Mock.errors, 0)
  end,

  group_broadcast_at_most_once_per_minute = function(t)
    local S = Ext.install()
    S.party = true
    load()
    Mock.fire("GROUP_ROSTER_UPDATE")
    t.eq(countSends(), 1)
    Mock.advance(10)
    Mock.fire("GROUP_ROSTER_UPDATE")
    Mock.advance(10)
    Mock.fire("GROUP_ROSTER_UPDATE")
    t.eq(countSends(), 1, "rate limited")
    Mock.advance(39)
    t.eq(countSends(), 1, "still inside the minute")
    Mock.advance(2)
    t.eq(countSends(), 2, "one deferred send at the end of the minute")
    Mock.advance(300)
    t.eq(countSends(), 2, "nothing more without a roster change")
    -- hors de la fenêtre : envoi immédiat ; groupe quitté avant la fin de la suivante : rien
    Mock.fire("GROUP_ROSTER_UPDATE")
    t.eq(countSends(), 3, "new minute: sent at once")
    Mock.advance(5)
    Mock.fire("GROUP_ROSTER_UPDATE")
    S.party = false
    Mock.advance(120)
    t.eq(countSends(), 3, "left the group before the deferred send")
    t.eq(#Mock.errors, 0)
  end,

  combat_queues_until_regen = function(t)
    local S = Ext.install()
    S.guild, S.party = true, true
    load()
    Mock.player.combat = true
    Mock.fire("GROUP_ROSTER_UPDATE")
    Mock.advance(20)          -- envoi à la guilde dû pendant le combat
    t.eq(countSends(), 0, "nothing in combat")
    Mock.fire("GROUP_ROSTER_UPDATE")
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    local sends = Ext.sends()
    t.eq(#sends, 2, "both queued sends, once each")
    t.eq(sends[1][3], "PARTY")
    t.eq(sends[2][3], "GUILD")
    Mock.fire("PLAYER_REGEN_ENABLED")
    Mock.advance(30)
    t.eq(countSends(), 2, "queue emptied")
    t.eq(#Mock.errors, 0)
  end,

  chat_lockdown_retries_later = function(t)
    local S = Ext.install()
    S.party, S.lockdown = true, true
    load()
    Mock.fire("GROUP_ROSTER_UPDATE")
    t.eq(countSends(), 0, "messaging locked")
    S.lockdown = false
    Mock.advance(11)
    t.eq(Ext.sends(), { { "QVVER", MINE, "PARTY", nil } })
    t.eq(#Mock.errors, 0)
  end,

  reply_to_older_version_rate_limited = function(t)
    local S = Ext.install()
    S.guild = true
    load()
    Mock.advance(10)          -- envoi à la guilde après la connexion
    local base = countSends()
    t.eq(base, 1)
    Ext.receive("1.0.0", "GUILD", "Alice-Testrealm")
    t.eq(countSends(), base + 1, "reply")
    t.eq(lastSend(), { "QVVER", MINE, "GUILD", nil }, "same channel")
    Mock.advance(10)
    Ext.receive("1.0.0", "GUILD", "Bob-Testrealm")
    t.eq(countSends(), base + 1, "one reply per minute overall")
    Mock.advance(61)
    Ext.receive("1.1.0", "PARTY", "Alice-Testrealm")
    t.eq(countSends(), base + 1, "never twice to the same sender")
    Ext.receive("1.0.0", "WHISPER", "Carol-Testrealm")
    t.eq(countSends(), base + 2)
    t.eq(lastSend(), { "QVVER", MINE, "WHISPER", "Carol-Testrealm" }, "whisper back to the sender")
    Mock.advance(61)
    Ext.receive("1.0.0", "CHANNEL", "Dan-Testrealm")
    t.eq(countSends(), base + 2, "no reply on a numbered channel")
    Ext.receive(MINE, "GUILD", "Erin-Testrealm")
    t.eq(countSends(), base + 2, "same version: nothing")
    t.eq(Mock.countPrinted("is available"), 0)
    t.eq(#Mock.errors, 0)
  end,

  reply_waits_for_combat_end = function(t)
    Ext.install()
    load()
    Mock.player.combat = true
    Ext.receive("1.0.0", "PARTY", "Alice-Testrealm")
    t.eq(countSends(), 0)
    Mock.player.combat = false
    Mock.fire("PLAYER_REGEN_ENABLED")
    t.eq(Ext.sends(), { { "QVVER", MINE, "PARTY", nil } })
    t.eq(#Mock.errors, 0)
  end,

  own_messages_ignored = function(t)
    Ext.install()
    load()
    Ext.receive("9.9.9", "GUILD", "Testeur-Testrealm")
    Ext.receive("9.9.9", "PARTY", "Testeur")
    Ext.receive("0.0.1", "GUILD", "Testeur-Testrealm")
    t.eq(Mock.countPrinted("is available"), 0, "own newer version ignored")
    t.eq(countSends(), 0, "no reply to self")
    t.eq(Mock.countCalls("RaidWarningUtil.AddMessage"), 0)
    -- même nom, autre royaume : un autre joueur
    Ext.receive("9.9.9", "GUILD", "Testeur-Autreroyaume")
    t.eq(Mock.countPrinted("9.9.9 is available"), 1)
    t.eq(#Mock.errors, 0)
  end,

  secret_values_are_ignored = function(t)
    Ext.install()
    local Q = load()
    UnitName = function(unit) if unit == "player" then return Mock.strictSecret("Testeur") end end
    Mock.fire("CHAT_MSG_ADDON", "QVVER", "9.0.0", "GUILD", Mock.strictSecret("Ami-Testrealm"), "", 0, 0, "", 0)
    Mock.fire("CHAT_MSG_ADDON", Mock.strictSecret("QVVER"), "9.0.0", "GUILD", "Ami-Testrealm", "", 0, 0, "", 0)
    Mock.fire("CHAT_MSG_ADDON", "QVVER", Mock.strictSecret("9.0.0"), "GUILD", "Ami-Testrealm", "", 0, 0, "", 0)
    t.eq(Mock.countPrinted("is available"), 0, "secret payload ignored")
    t.eq(Q.VersionCheck:NewestSeen(), nil)
    -- nom du joueur secret : le message d'un autre joueur est traité normalement
    Ext.receive("9.0.0", "GUILD", "Ami-Testrealm")
    t.eq(Mock.countPrinted("9.0.0 is available"), 1)
    t.eq(#Mock.errors, 0)
  end,

  invalid_payloads_ignored = function(t)
    Ext.install()
    local Q = load()
    for _, text in ipairs({ "hello", "|cffff0000 9.9.9", "99999999.0.0", "9.9", "" }) do
      Ext.receive(text, "GUILD", "Ami-Testrealm")
    end
    Ext.receive("9.9.9", "GUILD", "Ami-Testrealm", "OTHERPFX")
    t.eq(Mock.countPrinted("is available"), 0)
    t.eq(countSends(), 0)
    t.eq(Q.VersionCheck:NewestSeen(), nil)
    t.eq(#Mock.errors, 0)
  end,

  option_off_sends_nothing = function(t)
    local S = Ext.install()
    S.guild, S.party = true, true
    load({ savedVariables = { QuestifyVanillaDB = { settings = { versionCheck = false } } } })
    Mock.advance(30)
    Mock.fire("GROUP_ROSTER_UPDATE")
    Ext.receive("1.0.0", "GUILD", "Alice-Testrealm")
    Ext.receive("9.0.0", "GUILD", "Bob-Testrealm")
    Mock.advance(120)
    t.eq(Mock.countCalls("C_ChatInfo.RegisterAddonMessagePrefix"), 0, "prefix not registered")
    t.eq(countSends(), 0, "nothing sent")
    t.eq(Mock.countPrinted("is available"), 0, "nothing shown")
    t.eq(#Mock.errors, 0)
  end,

  option_toggled_in_session = function(t)
    local S = Ext.install()
    S.guild = true
    local Q = load({ savedVariables = { QuestifyVanillaDB = { settings = { versionCheck = false } } } })
    Mock.advance(30)
    t.eq(countSends(), 0)
    Q.Settings:Set("versionCheck", true)
    t.eq(Mock.countCalls("C_ChatInfo.RegisterAddonMessagePrefix"), 1)
    Mock.advance(10)
    t.eq(Ext.sends(), { { "QVVER", MINE, "GUILD", nil } }, "guild broadcast once enabled")
    Q.Settings:Set("versionCheck", false)
    S.party = true
    Mock.fire("GROUP_ROSTER_UPDATE")
    Ext.receive("1.0.0", "GUILD", "Alice-Testrealm")
    Ext.receive("9.0.0", "GUILD", "Bob-Testrealm")
    Mock.advance(120)
    t.eq(countSends(), 1, "nothing after switching off")
    t.eq(Mock.countPrinted("is available"), 0)
    t.eq(#Mock.errors, 0)
  end,

  absent_chat_api_is_silent = function(t)
    local S = Ext.install()
    S.guild, S.party = true, true
    C_ChatInfo = nil
    RaidWarningUtil, RaidNotice_AddMessage, RaidWarningFrame = nil, nil, nil
    local Q = load()
    Mock.advance(30)
    Mock.fire("GROUP_ROSTER_UPDATE")
    Ext.receive("9.0.0", "GUILD", "Ami-Testrealm")
    Mock.fire("PLAYER_REGEN_ENABLED")
    Mock.advance(120)
    t.eq(countSends(), 0)
    t.eq(Mock.countPrinted("is available"), 0)
    t.eq(Q.VersionCheck:NewestSeen(), nil)
    t.eq(#Mock.errors, 0, "no error")
  end,

  absent_group_and_display_apis_are_silent = function(t)
    Ext.install()
    IsInGuild, IsInGroup, IsInRaid, GetNormalizedRealmName = nil, nil, nil, nil
    RaidWarningUtil, RaidNotice_AddMessage = nil, nil
    C_ChatInfo.InChatMessagingLockdown = nil
    load()
    Mock.advance(30)
    Mock.fire("GROUP_ROSTER_UPDATE")
    t.eq(countSends(), 0, "not in a guild or group as far as we can tell")
    Ext.receive("9.0.0", "GUILD", "Ami-Testrealm")
    t.eq(Mock.countPrinted("9.0.0 is available"), 1, "chat line without the on-screen message")
    Ext.receive("1.0.0", "WHISPER", "Alice-Testrealm")
    t.eq(Ext.sends(), { { "QVVER", MINE, "WHISPER", "Alice-Testrealm" } })
    t.eq(#Mock.errors, 0)
  end,

  unparsable_own_version_sends_nothing = function(t)
    local S = Ext.install()
    S.guild, S.party = true, true
    local Q = load({ version = "dev" })
    Q.version = "dev"
    Mock.advance(30)
    Mock.fire("GROUP_ROSTER_UPDATE")
    Ext.receive("9.0.0", "GUILD", "Ami-Testrealm")
    Ext.receive("0.0.1", "GUILD", "Alice-Testrealm")
    t.eq(countSends(), 0)
    t.eq(Mock.countPrinted("is available"), 0)
    t.eq(#Mock.errors, 0)
  end,
}
