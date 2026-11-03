-- Tests des utilitaires (Q.Util), des réglages (Q.Settings) et de Q.SafeCall.
local TOC = "Questify_Vanilla/Questify_Vanilla.toc"

return {
  hasbit_above_32_bits = function(t)
    local Q = Mock.loadAddon(TOC)
    t.ok(Q.Util.HasBit(4294967373, 4))             -- le masque Alliance contient Nain
    t.ok(Q.Util.HasBit(4294967373, 4294967296))    -- et Skyborne Alliance
    t.ok(not Q.Util.HasBit(4294967373, 2))         -- pas Orc
    t.ok(not Q.Util.HasBit(4294967373, 8589934592)) -- pas Skyborne Horde
    t.ok(Q.Util.MaskAllows(0, 2) and Q.Util.MaskAllows(nil, 2))
    t.ok(not Q.Util.MaskAllows(4294967373, 2))
  end,

  settings_set_fires = function(t)
    local Q = Mock.loadAddon(TOC)
    local got; Q:On("SETTINGS_CHANGED", function(p, v) got = p .. "=" .. tostring(v) end)
    Q.Settings:Set("autoQuest", false)
    t.eq(got, "autoQuest=false"); t.eq(Q.Settings:Get("autoQuest"), false)
  end,

  settings_defaults_and_nested_paths = function(t)
    local Q = Mock.loadAddon(TOC)
    t.eq(Q.Settings:Get("autoQuest"), true)
    t.eq(Q.Settings:Get("autoReward"), true)
    t.eq(Q.Settings:Get("dungeonQuests"), true)
    t.eq(Q.Settings:Get("nav.routing"), false)
    t.eq(Q.Settings:Get("tracker.locked"), false)
    t.eq(Q.Settings:Get("tracker.scale"), 1)
    t.eq(Q.Settings:Get("tracker.nextSteps"), 3)
    t.eq(Q.Settings:Get("tracker.showMobs"), true)
    t.eq(Q.Settings:Get("nameplates"), true)
    t.eq(Q.Settings:Get("telemetry"), true)
    t.eq(Q.Settings:Get("does.not.exist"), nil)
    local path
    Q:On("SETTINGS_CHANGED", function(p) path = p end)
    Q.Settings:Set("tracker.point", { "CENTER", 10, 20 })
    t.eq(path, "tracker.point")
    t.eq(Q.Settings:Get("tracker.point")[2], 10)
    t.eq(Q.db.settings.tracker.point[3], 20)
  end,

  safecall_reports_once = function(t)
    local Q = Mock.loadAddon(TOC)
    Q.SafeCall(function() error("boom") end); Q.SafeCall(function() error("boom") end)
    t.eq(Mock.countPrinted("boom"), 1)
  end,

  safecall_returns_values = function(t)
    local Q = Mock.loadAddon(TOC)
    local ok, a, b = Q.SafeCall(function(x, y) return x + y, "z" end, 2, 3)
    t.eq(ok, true); t.eq(a, 5); t.eq(b, "z")
    local ok2 = Q.SafeCall(function() error("nope") end)
    t.eq(ok2, false)
  end,

  is_secret = function(t)
    local Q = Mock.loadAddon(TOC)
    t.ok(Q.Util.IsSecret(Mock.secret(5)))
    t.ok(not Q.Util.IsSecret(5))
    t.ok(not Q.Util.IsSecret(nil))
  end,

  is_secret_asks_client_first = function(t)
    local Q = Mock.loadAddon(TOC)
    local trap = Mock.strictSecret(42)
    t.fails(function() return trap == Mock.strictSecret(1) end, "strict secret refuses comparison")
    t.fails(function() return trap < Mock.strictSecret(1) end, "strict secret refuses ordering")
    t.fails(function() return trap .. "" end, "strict secret refuses concatenation")
    t.ok(Q.Util.IsSecret(trap), "strict secret detected")
    -- ordre : issecretvalue est consulté avant tout, même pour nil, et sa réponse suffit
    local seen = 0
    issecretvalue = function(v) seen = seen + 1; return rawequal(v, trap) end
    t.ok(Q.Util.IsSecret(trap))
    t.eq(seen, 1)
    t.eq(Q.Util.IsSecret(nil), false)
    t.eq(seen, 2, "client API called first, before any test on the value")
    -- l'API échoue : valeur considérée secrète, sauf nil
    issecretvalue = function() error("restricted") end
    t.eq(Q.Util.IsSecret(trap), true)
    t.eq(Q.Util.IsSecret(5), true)
    t.eq(Q.Util.IsSecret(nil), false)
    issecretvalue = nil
    t.eq(Q.Util.IsSecret(5), false, "older client without the API")
    t.eq(Q.Util.IsSecret(nil), false)
  end,

  round_and_distance_format = function(t)
    local Q = Mock.loadAddon(TOC)
    t.eq(Q.Util.Round(1.26, 1), 1.3)
    t.eq(Q.Util.Round(84.6), 85)
    t.eq(Q.Util.FormatDistance(84.6), "85 yd")
    t.eq(Q.Util.FormatDistance(1234), "1.2 km")
  end,

  copy_defaults_fills_missing_only = function(t)
    local Q = Mock.loadAddon(TOC)
    local defaults = { a = 1, b = { c = 2, d = 3 }, e = true }
    local dst = { a = 5, b = { c = 9 }, e = false }
    Q.Util.CopyDefaults(dst, defaults)
    t.eq(dst, { a = 5, b = { c = 9, d = 3 }, e = false })
    local fresh = Q.Util.CopyDefaults({}, defaults)
    t.ok(fresh.b ~= defaults.b, "nested tables are copied")
  end,

  constants = function(t)
    local Q = Mock.loadAddon(TOC)
    t.eq(Q.RACE_BY_ID[3].key, "Dwarf"); t.eq(Q.RACE_BY_ID[3].bit, 4)
    t.eq(Q.RACE_BY_ID[95].bit, 4294967296); t.eq(Q.RACE_BY_ID[96].bit, 8589934592)
    t.eq(Q.CLASS_BITS.WARLOCK, 256); t.eq(Q.CLASS_BITS.DRUID, 1024)
  end,

  timers_are_safe = function(t)
    local Q = Mock.loadAddon(TOC)
    local n = 0
    Q:After(1, function() n = n + 1 end)
    Q:After(1, function() error("timer-fail") end)
    local tk = Q:NewTicker(0.5, function() n = n + 10 end)
    Mock.advance(1)
    t.eq(n, 21)
    tk:Cancel()
    Mock.advance(2)
    t.eq(n, 21)
    t.eq(Mock.countPrinted("timer-fail"), 1)
  end,
}
